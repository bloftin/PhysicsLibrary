import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { createIcons, Play, Pause, RotateCcw, Rotate3d, CircleDot, MoveHorizontal, Orbit, Maximize, Download, ArrowUpRight } from 'lucide';
import { PRESETS, EARTH_RADIUS, RAD, TAU, state, advance, secularRates, csv } from './model.js';

const $ = id => document.getElementById(id);
const keys = ['a', 'e', 'i', 'raan', 'argp', 'nu'];
const icons = { Play, Pause, RotateCcw, Rotate3d, CircleDot, MoveHorizontal, Orbit, Maximize, Download, ArrowUpRight };
const colors = { a: 0xedc96b, e: 0xe99873, i: 0x44d2b2, raan: 0xec8bbc, argp: 0x81c7ed, nu: 0xc8ef81 };
const vector = a => new THREE.Vector3(...a);
const scaled = a => vector(a).divideScalar(EARTH_RADIUS);
const fmt = (n, digits = 1) => n.toLocaleString('en-US', { minimumFractionDigits: digits, maximumFractionDigits: digits });
let elements = { ...PRESETS.gps }, epoch = { ...elements }, elapsed = 0, playing = false;
let pinned = '', hovered = '', cameraView = 'oblique', renderer, controls, camera;
let satellite, velocityArrow, phaseArc, phaseLabel, staticGroup, annotations = [];
let span = 6, needsRender = true, lastTime = 0, lastGeometry = 0, lastReadout = 0;
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x10191b);
const viewport = $('viewport');

function setPlaying(value) {
  playing = value && state(elements).perigee > 0;
  $('play').innerHTML = `<i data-lucide="${playing ? 'pause' : 'play'}"></i>`;
  $('play').title = $('play').ariaLabel = playing ? 'Pause orbit' : 'Play orbit';
  createIcons({ icons });
}
function line(points, color, opacity = 1, dashed = false) {
  const geometry = new THREE.BufferGeometry().setFromPoints(points);
  const material = dashed
    ? new THREE.LineDashedMaterial({ color, transparent: true, opacity, dashSize: span * .025, gapSize: span * .018 })
    : new THREE.LineBasicMaterial({ color, transparent: true, opacity });
  material.userData.baseOpacity = opacity;
  const result = new THREE.Line(geometry, material);
  if (dashed) result.computeLineDistances();
  return result;
}
function curve(u, v, radius, angle = TAU) {
  const count = Math.max(2, Math.ceil(Math.abs(angle) * 36));
  return Array.from({ length: count + 1 }, (_, k) => {
    const t = angle * k / count;
    return vector(u).multiplyScalar(radius * Math.cos(t)).addScaledVector(vector(v), radius * Math.sin(t));
  });
}
function label(text, position, css = '', priority = 4, owner = '') {
  const node = document.createElement('span');
  node.className = `scene-label ${css}`;
  node.textContent = text;
  $('labels').append(node);
  const annotation = { node, position, priority, owner };
  annotations.push(annotation);
  return annotation;
}
function point(position, color, radius = span * .012) {
  const mesh = new THREE.Mesh(new THREE.SphereGeometry(radius, 16, 12), new THREE.MeshBasicMaterial({ color }));
  mesh.position.copy(position);
  return mesh;
}
function arrowLength(s) {
  const perigeeSpeed = s.h / (elements.a * (1 - elements.e));
  return span * .30 * s.speed / perigeeSpeed;
}
function disposeGroup(group) {
  if (!group) return;
  scene.remove(group);
  group.traverse(obj => { obj.geometry?.dispose(); obj.material?.dispose(); });
}
function disc(radius, normal, color) {
  const mesh = new THREE.Mesh(new THREE.CircleGeometry(radius, 128), new THREE.MeshBasicMaterial({
    color, side: THREE.DoubleSide, transparent: true, opacity: .065, depthWrite: false,
  }));
  mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), vector(normal));
  mesh.userData.plane = true;
  return mesh;
}
function angle(group, key, u, v, degrees, radius, text) {
  const obj = line(curve(u, v, radius, degrees * RAD), colors[key], .95);
  obj.userData.highlight = key;
  obj.userData.angle = true;
  group.add(obj);
  const middle = degrees * RAD / 2;
  const pos = vector(u).multiplyScalar((radius + span * .025) * Math.cos(middle))
    .addScaledVector(vector(v), (radius + span * .025) * Math.sin(middle));
  const item = label(text, pos, 'angle', 1, key);
  item.angle = true;
  return { obj, item };
}
function buildGeometry() {
  if (!renderer) return;
  disposeGroup(staticGroup);
  annotations.forEach(a => a.node.remove());
  annotations = [];
  staticGroup = new THREE.Group();
  scene.add(staticGroup);
  const s = state(elements), f = s.frame;
  const maxR = elements.a * (1 + elements.e) / EARTH_RADIUS;
  span = Math.max(1.8, maxR * 1.15);
  const U = [1, 0, 0], V = [0, 1, 0], Z = [0, 0, 1];
  staticGroup.add(disc(span * .94, Z, 0x68aada), disc(span * .94, f.W, colors.i));
  const equator = line(curve(U, V, span * .94), 0x68aada, .23);
  equator.userData.plane = true;
  const orbital = line(curve(f.P, f.Q, span * .94), colors.i, .32);
  orbital.userData.plane = true;
  staticGroup.add(equator, orbital);
  for (const [axis, name] of [[U, 'X / equinox'], [V, 'Y'], [Z, 'Z / north']]) {
    staticGroup.add(line([vector(axis).multiplyScalar(-span), vector(axis).multiplyScalar(span)], 0x839ca5, .25, true));
    label(name, vector(axis).multiplyScalar(span), 'axis', 5);
  }
  const orbitPoints = Array.from({ length: 513 }, (_, k) => scaled(state({ ...elements, nu: k * 360 / 512 }).r));
  const orbitLine = line(orbitPoints, colors.nu, .95);
  orbitLine.userData.highlight = 'e';
  staticGroup.add(orbitLine);
  const perigee = vector(f.P).multiplyScalar(elements.a * (1 - elements.e) / EARTH_RADIUS);
  const apogee = vector(f.P).multiplyScalar(-elements.a * (1 + elements.e) / EARTH_RADIUS);
  const centre = vector(f.P).multiplyScalar(-elements.a * elements.e / EARTH_RADIUS);
  const major = line([apogee, perigee], colors.a, .7, true);
  major.userData.highlight = 'a';
  staticGroup.add(major);
  if (!s.circular) {
    staticGroup.add(point(perigee, colors.a), point(apogee, colors.a));
    label('Perigee', perigee, 'apsides', 3, 'a');
    label('Apogee', apogee, 'apsides', 3, 'a');
    const offset = line([new THREE.Vector3(), centre], colors.e, .8);
    offset.userData.highlight = 'e';
    staticGroup.add(offset, point(centre, colors.e, span * .008));
    if (elements.e > .02) label('Ellipse centre', centre, '', 6, 'e');
  }
  label('Earth / focus', new THREE.Vector3(0, 0, 1.1), 'axis', 4);
  if (!s.equatorial) {
    const node = line([vector(f.N).multiplyScalar(-span), vector(f.N).multiplyScalar(span)], colors.raan, .75, true);
    node.userData.highlight = 'raan';
    staticGroup.add(node);
    for (const [nu, name] of [[-elements.argp, 'Ascending node'], [180 - elements.argp, 'Descending node']]) {
      const pos = scaled(state({ ...elements, nu }).r);
      staticGroup.add(point(pos, colors.raan));
      label(name, pos, 'nodes', 3, 'raan');
    }
    angle(staticGroup, 'raan', U, V, elements.raan, Math.max(1.08, span * .36), '\u03a9 / RAAN');
    angle(staticGroup, 'i', [-Math.sin(elements.raan * RAD), Math.cos(elements.raan * RAD), 0], Z,
      elements.i, Math.max(1.18, span * .47), 'i / inclination');
    if (!s.circular) angle(staticGroup, 'argp', f.N, f.B, elements.argp, Math.max(1.28, span * .55), '\u03c9 / perigee');
  }
  const phase = angle(staticGroup, 'nu', f.P, f.Q, elements.nu, Math.max(1.4, span * .67),
    s.circular ? 'Orbital phase' : '\u03bd / true anomaly');
  phaseArc = phase.obj; phaseLabel = phase.item;
  satellite = point(scaled(s.r), colors.nu, span * .024);
  satellite.userData.satellite = true;
  staticGroup.add(satellite);
  label('Satellite', satellite.position.clone(), 'satellite', 0, 'nu');
  const length = arrowLength(s);
  velocityArrow = new THREE.ArrowHelper(vector(s.v).normalize(), satellite.position, length, colors.nu, length * .22, length * .12);
  staticGroup.add(velocityArrow);
  const radiusLine = line([new THREE.Vector3(), satellite.position], colors.nu, .5);
  radiusLine.userData.radiusLine = true;
  staticGroup.add(radiusLine);
  applyDisplay();
  needsRender = true;
}
function updatePhase() {
  if (!satellite) return;
  const s = state(elements);
  satellite.position.copy(scaled(s.r));
  annotations.find(a => a.node.classList.contains('satellite')).position.copy(satellite.position);
  const radius = Math.max(1.4, span * .67);
  const points = curve(s.frame.P, s.frame.Q, radius, elements.nu * RAD);
  phaseArc.geometry.dispose();
  phaseArc.geometry = new THREE.BufferGeometry().setFromPoints(points);
  const middle = elements.nu * RAD / 2;
  phaseLabel.position.copy(vector(s.frame.P).multiplyScalar((radius + span * .025) * Math.cos(middle))
    .addScaledVector(vector(s.frame.Q), (radius + span * .025) * Math.sin(middle)));
  velocityArrow.position.copy(satellite.position);
  velocityArrow.setDirection(vector(s.v).normalize());
  const length = arrowLength(s);
  velocityArrow.setLength(length, length * .22, length * .12);
  const radiusLine = staticGroup.children.find(o => o.userData.radiusLine);
  radiusLine.geometry.attributes.position.setXYZ(1, ...satellite.position.toArray());
  radiusLine.geometry.attributes.position.needsUpdate = true;
  needsRender = true;
}
function applyDisplay() {
  const highlight = hovered || pinned;
  if (staticGroup) staticGroup.traverse(obj => {
    if (obj.userData.plane) obj.visible = $('planes').checked;
    if (obj.userData.angle) obj.visible = $('angles').checked;
    if (obj.material?.userData.baseOpacity !== undefined) {
      obj.material.opacity = obj.material.userData.baseOpacity * (!highlight || obj.userData.highlight === highlight ? 1 : .25);
    }
  });
  if (velocityArrow) velocityArrow.visible = $('velocity').checked;
  $('labels').hidden = !$('labels-toggle').checked;
  needsRender = true;
}
function positionLabels() {
  if (!camera) return;
  const width = viewport.clientWidth, height = viewport.clientHeight;
  const top = width < 421 ? 110 : 95, bottom = height - $('viewport').parentElement.querySelector('.scene-footer').offsetHeight - 6;
  const occupied = [];
  for (const a of [...annotations].sort((a, b) => a.priority - b.priority)) {
    a.node.style.display = 'block';
    const p = a.position.clone().project(camera);
    const w = a.node.offsetWidth, h = a.node.offsetHeight;
    const x = (p.x + 1) * width / 2, y = (1 - p.y) * height / 2;
    if (p.z < -1 || p.z > 1 || (a.angle && !$('angles').checked)) { a.node.style.display = 'none'; continue; }
    let placed = false;
    for (const [dx, dy] of [[7, -h - 5], [7, 5], [-w - 7, -h - 5], [-w - 7, 5], [-w / 2, -h - 12]]) {
      const rect = { x: x + dx, y: y + dy, w, h };
      if (rect.x < 4 || rect.x + w > width - 4 || rect.y < top || rect.y + h > bottom) continue;
      if (occupied.some(o => rect.x < o.x + o.w + 3 && rect.x + w + 3 > o.x && rect.y < o.y + o.h + 3 && rect.y + h + 3 > o.y)) continue;
      a.node.style.transform = `translate(${rect.x}px,${rect.y}px)`;
      a.node.style.opacity = (hovered || pinned) && a.owner && a.owner !== (hovered || pinned) ? '.45' : '1';
      occupied.push(rect); placed = true; break;
    }
    if (!placed) a.node.style.display = 'none';
  }
}
function fit() {
  if (!camera) return;
  const aspect = viewport.clientWidth / viewport.clientHeight;
  const half = span * 1.45;
  camera.left = -half * Math.max(1, aspect); camera.right = -camera.left;
  camera.top = half * Math.max(1, 1 / aspect); camera.bottom = -camera.top;
  camera.near = .01; camera.far = span * 40; camera.zoom = 1;
  camera.updateProjectionMatrix();
  controls.target.set(0, 0, 0);
  const f = state(elements).frame;
  const dirs = { oblique: [1.5, -2.1, 1.6], north: [.001, 0, 1], node: f.N, orbit: f.W };
  camera.position.copy(vector(dirs[cameraView]).normalize().multiplyScalar(span * 8));
  camera.up.copy(cameraView === 'north' ? new THREE.Vector3(0, 1, 0) : new THREE.Vector3(0, 0, 1));
  camera.lookAt(0, 0, 0); controls.update();
  needsRender = true;
}
function resize() {
  if (!renderer) return;
  renderer.setSize(viewport.clientWidth, viewport.clientHeight, false);
  fit();
}
function readouts(sync = true) {
  const s = state(elements), rates = secularRates(elements);
  for (const key of keys) {
    const digits = key === 'e' ? 4 : key === 'a' ? 0 : ['raan', 'argp'].includes(key) ? 3 : 1;
    if (sync && document.activeElement !== $(`num-${key}`)) $(`num-${key}`).value = elements[key].toFixed(digits);
    $(`rng-${key}`).value = elements[key];
  }
  for (const [id, value] of Object.entries({ perigee: `${fmt(s.perigee, 0)} km`, apogee: `${fmt(s.apogee, 0)} km`,
    period: `${fmt(s.period / 3600, 2)} h`, 'speed-value': `${fmt(s.speed, 3)} km/s`,
    'position-vector': s.r.map(n => fmt(n, 3)).join(' / '), 'velocity-vector': s.v.map(n => fmt(n, 6)).join(' / '),
    altitude: `${fmt(s.radius - EARTH_RADIUS)} km`, 'flight-path': `${fmt(s.flightPath / RAD, 3)} deg`,
    'eccentric-anomaly': `${fmt(s.E / RAD, 3)} deg`, 'mean-anomaly': `${fmt(s.M / RAD, 3)} deg`,
    energy: fmt(s.energy, 6), momentum: fmt(s.h, 3), 'node-rate': fmt(rates.raan * 86400 / RAD, 5),
    'apsidal-rate': fmt(rates.argp * 86400 / RAD, 5) })) $(id).textContent = value;
  $('elapsed').textContent = `${fmt(elapsed / 3600, 2)} h`;
  $('elapsed').dataset.seconds = elapsed;
  $('frame-mode').textContent = $('j2').checked ? 'ECI / secular J2' : 'Earth-centered inertial';
  const warnings = [];
  if (s.circular) warnings.push('Circular orbit: perigee is undefined; phase uses the selected in-plane reference.');
  if (s.equatorial) warnings.push('Equatorial orbit: ascending node and RAAN are undefined. The selected rotation fixes the in-plane reference.');
  $('singularities').hidden = !warnings.length; $('singularities').textContent = warnings.join(' ');
  $('collision').hidden = s.perigee > 0;
  $('collision').textContent = 'This orbit intersects Earth. Playback is paused; the geometry is mathematical only.';
  $('play').disabled = s.perigee <= 0;
  if (s.perigee <= 0 && playing) setPlaying(false);
}
function change(key, value) {
  setPlaying(false);
  const oldA = elements.a, oldE = elements.e;
  elements = { ...elements, [key]: value }; epoch = { ...elements }; elapsed = 0;
  document.querySelectorAll('[data-preset]').forEach(b => b.ariaPressed = 'false');
  readouts(); buildGeometry();
  if (oldA !== elements.a || oldE !== elements.e) fit();
}

for (const key of keys) {
  const number = $(`num-${key}`), range = $(`rng-${key}`);
  range.addEventListener('input', () => change(key, Number(range.value)));
  number.addEventListener('input', () => {
    const valid = number.value !== '' && Number.isFinite(number.valueAsNumber) && number.valueAsNumber >= Number(number.min) && number.valueAsNumber <= Number(number.max);
    number.ariaInvalid = String(!valid);
    if (valid) change(key, number.valueAsNumber);
  });
  number.addEventListener('change', () => {
    const value = Number.isFinite(number.valueAsNumber) ? Math.max(Number(number.min), Math.min(Number(number.max), number.valueAsNumber)) : elements[key];
    number.value = value; number.ariaInvalid = 'false'; change(key, value);
  });
}
document.querySelectorAll('[data-preset]').forEach(button => button.addEventListener('click', () => {
  setPlaying(false); elements = { ...PRESETS[button.dataset.preset] }; epoch = { ...elements }; elapsed = 0;
  document.querySelectorAll('[data-preset]').forEach(b => b.ariaPressed = String(b === button));
  readouts(); buildGeometry(); fit();
}));
const tabs = [...document.querySelectorAll('[data-tab]')];
tabs.forEach((button, index) => {
  button.tabIndex = index === 0 ? 0 : -1;
  button.addEventListener('click', () => tabs.forEach(b => {
    b.ariaSelected = String(b === button); b.tabIndex = b === button ? 0 : -1;
    $(`${b.dataset.tab}-panel`).hidden = b !== button;
  }));
  button.addEventListener('keydown', event => {
    const destinations = { ArrowRight: (index + 1) % tabs.length, ArrowLeft: (index + tabs.length - 1) % tabs.length,
      Home: 0, End: tabs.length - 1 };
    if (destinations[event.key] === undefined) return;
    event.preventDefault(); const target = tabs[destinations[event.key]]; target.click(); target.focus();
  });
});
document.querySelectorAll('[data-highlight]').forEach(button => {
  button.addEventListener('click', () => {
    pinned = pinned === button.dataset.highlight ? '' : button.dataset.highlight;
    document.querySelectorAll('[data-highlight]').forEach(b => b.ariaPressed = String(b.dataset.highlight === pinned)); applyDisplay();
  });
  button.addEventListener('mouseenter', () => { hovered = button.dataset.highlight; applyDisplay(); });
  button.addEventListener('mouseleave', () => { hovered = ''; applyDisplay(); });
});
document.querySelectorAll('[data-view]').forEach(button => button.addEventListener('click', () => {
  cameraView = button.dataset.view;
  document.querySelectorAll('[data-view]').forEach(b => b.ariaPressed = String(b === button)); fit();
}));
for (const id of ['planes', 'angles', 'velocity', 'labels-toggle']) $(id).addEventListener('change', applyDisplay);
$('j2').addEventListener('change', () => { epoch = { ...elements }; elapsed = 0; readouts(); });
$('play').addEventListener('click', () => setPlaying(!playing));
$('reset').addEventListener('click', () => { setPlaying(false); elements = { ...epoch }; elapsed = 0; readouts(); buildGeometry(); });
$('fit').addEventListener('click', fit);
$('download').addEventListener('click', () => {
  const url = URL.createObjectURL(new Blob([csv(elements, $('j2').checked)], { type: 'text/csv' }));
  const link = document.createElement('a'); link.href = url; link.download = 'orbital-elements.csv'; link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
document.addEventListener('visibilitychange', () => { if (document.hidden) setPlaying(false); });

try {
  renderer = new THREE.WebGLRenderer({ canvas: $('orbit'), antialias: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  camera = new THREE.OrthographicCamera();
  controls = new OrbitControls(camera, $('orbit'));
  controls.enablePan = false; controls.enableDamping = false; controls.minZoom = .2; controls.maxZoom = 8;
  controls.addEventListener('change', () => { needsRender = true; });
  const earth = new THREE.Mesh(new THREE.SphereGeometry(1, 64, 48), new THREE.MeshPhongMaterial({ color: 0x174d58, shininess: 30 }));
  scene.add(earth, new THREE.AmbientLight(0xbedce8, 1.4));
  const sunlight = new THREE.DirectionalLight(0xfff2d0, 2.2); sunlight.position.set(-3, -4, 6); scene.add(sunlight);
  for (let latitude = -60; latitude <= 60; latitude += 30) {
    const z = Math.sin(latitude * RAD) * 1.006, radius = Math.cos(latitude * RAD) * 1.006;
    const points = curve([1, 0, 0], [0, 1, 0], radius).map(p => p.add(new THREE.Vector3(0, 0, z)));
    scene.add(line(points, 0x73c0ca, latitude === 0 ? .65 : .28));
  }
  for (let longitude = 0; longitude < 180; longitude += 30) {
    scene.add(line(curve([Math.cos(longitude * RAD), Math.sin(longitude * RAD), 0], [0, 0, 1], 1.006), 0x73c0ca, .28));
  }
  new ResizeObserver(resize).observe(viewport);
  $('orbit').addEventListener('webglcontextlost', event => { event.preventDefault(); setPlaying(false); $('render-error').hidden = false; });
  $('orbit').addEventListener('webglcontextrestored', () => { $('render-error').hidden = true; needsRender = true; });
} catch (error) {
  console.warn('Orbital viewer WebGL unavailable:', error.message);
  $('render-error').hidden = false;
}
createIcons({ icons });
readouts(); buildGeometry(); resize();
function frame(time) {
  const dt = lastTime ? Math.min((time - lastTime) / 1000, .1) : 0; lastTime = time;
  if (playing) {
    const speed = $('speed').value;
    const multiplier = speed === 'orbit' ? state(epoch).period / 12 : speed === 'day' ? 7200 : Number(speed);
    elapsed += dt * multiplier;
    elements = advance(epoch, elapsed, $('j2').checked);
    if ($('j2').checked && time - lastGeometry > 100) { buildGeometry(); lastGeometry = time; }
    else updatePhase();
    if (time - lastReadout > 90) { readouts(); lastReadout = time; }
  }
  if (renderer && needsRender && !document.hidden) {
    renderer.render(scene, camera); positionLabels(); needsRender = false;
  }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
