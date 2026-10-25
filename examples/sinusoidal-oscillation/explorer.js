import { scaleLinear } from 'd3';
import { createIcons, Play, Pause, StepBack, StepForward, RotateCcw, Download, LocateFixed } from 'lucide';
import { TAU, DURATION, parameters, preset, metrics, fromRate, sample, changeForm, comparison, history, landmarks, arc, csv } from './model.js';
const $ = id => document.getElementById(id);
const icons = { Play, Pause, StepBack, StepForward, RotateCcw, Download, LocateFixed };
const colors = { ink: '#29383d', teal: '#087d86', coral: '#c74e46', gold: '#967011', muted: '#5c7279', grid: '#dce6e8' };
let { p, t, unit } = preset(), example = 'explore', radius = 1, speed = .25, mode = 'off';
let running = false, last = 0, raf = null;
const fmt = (x, n = 5) => Math.abs(x) < 1e-11 ? '0' : String(Number(x.toPrecision(n)));
const factor = () => unit === 'mm' ? 1000 : 100;
function error(message = '') { $('error').textContent = message; $('error').hidden = !message; }
function playIcon(name) { $('play').innerHTML = `<i data-lucide="${name}"></i>`; createIcons({ icons }); }
function stop() {
  running = false; if (raf !== null) { cancelAnimationFrame(raf); raf = null; }
  $('play').setAttribute('aria-pressed', 'false'); $('play').setAttribute('aria-label', 'Play clock'); $('play').title = 'Play clock'; playIcon('play');
}
function change(fn) {
  try { p = parameters(fn({ ...p })); example = 'custom'; error(); sync(); }
  catch (e) { error(e.message); }
}
function rateInput() {
  const kind = $('rate-mode').value, m = metrics(p);
  const settings = { frequency: ['Frequency f (Hz)', .25, 4, p.f], period: ['Period T (s)', .25, 4, m.T], angular: ['Angular rate ω (rad/s)', TAU / 4, TAU * 4, m.omega] }[kind];
  $('rate-label').textContent = settings[0]; $('rate').min = settings[1]; $('rate').max = settings[2]; $('rate').value = settings[3];
}
function sync() {
  const m = metrics(p), f = factor();
  $('example').value = example; $('unit').value = unit;
  $('amplitude-unit').textContent = unit; $('amplitude').max = .05 * f; $('amplitude').step = .0001 * f;
  $('amplitude').value = p.A * f; $('amplitude-value').value = fmt(p.A * f);
  $('phase').value = p.phi; $('phase-range').value = p.phi; $('phase-value').value = `${fmt(p.phi)} rad / ${fmt(p.phi * 180 / Math.PI)}°`;
  $('form').value = p.form; rateInput();
  $('equation').textContent = `u(t) = ${fmt(p.A * f)} ${p.form}(${fmt(m.omega)}t ${p.phi < 0 ? '−' : '+'} ${fmt(Math.abs(p.phi))}) ${unit}`;
  $('period-title').textContent = (p.A ? '' : 'Nominal ') + 'period T'; $('frequency-title').textContent = (p.A ? '' : 'Nominal ') + 'frequency f';
  $('period-readout').textContent = fmt(m.T) + ' s'; $('frequency-readout').textContent = fmt(p.f) + ' Hz'; $('omega-readout').textContent = fmt(m.omega) + ' rad/s';
  $('timing-note').textContent = p.A ? `One period advances the phase by ωT = 2π rad. At ${fmt(p.f)} Hz, ${fmt(p.f)} cycles and ${fmt(m.omega)} radians of phase elapse per second.` : 'Zero amplitude: the value is constant. There is no observable phase or smallest positive period. The phase clock and rate readouts show nominal generator settings only.';
  $('table-unit').textContent = `u (${unit})`;
  $('landmarks').replaceChildren(...landmarks(p).map(d => {
    const tr = document.createElement('tr'); tr.dataset.time = d.t;
    const values = [['0', 'T/4', 'T/2', '3T/4', 'T'][d.quarter], fmt(d.t), fmt(d.theta), fmt(d.u * f), motion(d)];
    for (const value of values) { const cell = document.createElement('td'); cell.textContent = value; tr.append(cell); }
    const cell = document.createElement('td'), button = document.createElement('button');
    button.innerHTML = '<i data-lucide="locate-fixed"></i>'; button.title = 'Select ' + values[0]; button.setAttribute('aria-label', 'Select landmark ' + values[0]);
    button.addEventListener('click', () => { stop(); t = d.t; draw(); }); cell.append(button); tr.append(cell); return tr;
  }));
  createIcons({ icons }); draw();
}
function motion(d) {
  if (p.A === 0) return 'Constant';
  if (Math.abs(d.slope) < 1e-10) return d.u > 0 ? 'Positive turning point' : 'Negative turning point';
  return d.slope > 0 ? 'Rising' : 'Falling';
}
function canvas(id) {
  const c = $(id), box = c.getBoundingClientRect(), w = box.width, h = box.height, dpr = Math.min(devicePixelRatio || 1, 2);
  if (c.width !== Math.round(w * dpr) || c.height !== Math.round(h * dpr)) { c.width = Math.round(w * dpr); c.height = Math.round(h * dpr); }
  const ctx = c.getContext('2d'); ctx.setTransform(dpr, 0, 0, dpr, 0, 0); ctx.clearRect(0, 0, w, h); ctx.lineCap = 'round'; return { ctx, w, h };
}
function text(ctx, value, x, y, color = colors.muted, align = 'left', size = 12) {
  ctx.font = `${size}px Arial`; ctx.fillStyle = color; ctx.textAlign = align; ctx.fillText(value, x, y);
}
function line(ctx, x1, y1, x2, y2, color, width = 1, dash = []) {
  ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dash); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); ctx.setLineDash([]);
}
function dot(ctx, x, y, color, r = 5) { ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fillStyle = color; ctx.fill(); }
function circle(ctx, x, y, r, color, width = 1) { ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.stroke(); }
function drawClock(d) {
  const { ctx, w, h } = canvas('clock'), cx = w / 2, cy = h / 2, maxR = Math.min(w / 2 - 36, h / 2 - 34), R = radius * maxR / 1.5;
  const px = cx + R * d.c, py = cy - R * d.s;
  line(ctx, cx - maxR - 10, cy, cx + maxR + 10, cy, colors.grid); line(ctx, cx, cy - maxR - 10, cx, cy + maxR + 10, colors.grid);
  circle(ctx, cx, cy, R, '#c6d6d9');
  const a = arc(d.theta, radius);
  if (a.angle > 1e-10) { ctx.beginPath(); ctx.arc(cx, cy, R, 0, -a.angle, true); ctx.strokeStyle = colors.gold; ctx.lineWidth = 3; ctx.stroke(); }
  line(ctx, cx, cy, cx + R, cy, '#aebfc3', 1, [3, 4]);
  line(ctx, cx, cy, px, py, colors.teal, 2.5); dot(ctx, px, py, colors.teal, 4.5);
  if (p.A > 0) {
    const qx = p.form === 'cos' ? px : cx, qy = p.form === 'cos' ? cy : py;
    line(ctx, px, py, qx, qy, colors.coral, 1.5, [4, 4]); dot(ctx, qx, qy, colors.coral, 5);
  }
  text(ctx, 'x', cx + maxR + 17, cy + 4, colors.ink); text(ctx, 'y', cx - 8, cy - maxR - 16, colors.ink, 'right');
  text(ctx, `r = ${fmt(radius)} cm`, 12, 19, colors.muted, 'left', 11);
  text(ctx, p.A ? (p.form === 'cos' ? 'Horizontal projection: cos θ' : 'Vertical projection: sin θ') : 'Nominal phase reference; no observable oscillation', w / 2, h - 12, colors.muted, 'center', w < 340 ? 10 : 11);
}
function drawBead(d) {
  const { ctx, w } = canvas('bead'), x = scaleLinear().domain([-.05, .05]).range([25, w - 25]);
  text(ctx, `One marked point: u (${unit})`, 12, 20, colors.ink, 'left', 11);
  line(ctx, x(-.05), 47, x(.05), 47, colors.grid, 2);
  for (const value of [-.05, 0, .05]) {
    line(ctx, x(value), 42, x(value), 52, colors.muted);
    text(ctx, fmt(value * factor()), x(value), 74, colors.muted, value < 0 ? 'left' : value > 0 ? 'right' : 'center', 11);
  }
  dot(ctx, x(d.u), 47, colors.coral, 6);
}
function drawHistory(d) {
  const { ctx, w, h } = canvas('history'), left = 46, right = w - 16, top = 49, bottom = h - 42;
  const x = scaleLinear().domain([0, DURATION]).range([left, right]), y = scaleLinear().domain([-.055, .055]).range([bottom, top]);
  for (const v of [-.05, 0, .05]) { line(ctx, left, y(v), right, y(v), colors.grid); text(ctx, fmt(v * factor()), left - 8, y(v) + 4, colors.muted, 'right', 11); }
  for (const v of w < 360 ? [0, 2, 4] : [0, 1, 2, 3, 4]) { line(ctx, x(v), top, x(v), bottom, colors.grid); text(ctx, v, x(v), bottom + 18, colors.muted, v === 0 ? 'left' : v === 4 ? 'right' : 'center', 11); }
  text(ctx, `u (${unit})`, left, 14, colors.ink, 'left', 11); text(ctx, 'time t (s)', (left + right) / 2, h - 5, colors.muted, 'center', 11);
  if (p.A > 0) {
    const T = metrics(p).T;
    line(ctx, x(0), 38, x(T), 38, colors.muted); for (const q of [0, T]) line(ctx, x(q), 35, x(q), 41, colors.muted);
    text(ctx, 'T = ' + fmt(T) + ' s', Math.max(left + 34, (x(0) + x(T)) / 2), 29, colors.muted, 'center', 11);
  }
  ctx.save(); ctx.beginPath(); ctx.rect(left, top, right - left, bottom - top); ctx.clip();
  function trace(q, color, dash = []) {
    ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = 2.3; ctx.setLineDash(dash);
    history(q).forEach((v, i) => i ? ctx.lineTo(x(v.t), y(v.u)) : ctx.moveTo(x(v.t), y(v.u))); ctx.stroke(); ctx.setLineDash([]);
  }
  const q = comparison(p, mode);
  if (q) trace(q, colors.gold, [5, 4]);
  if (p.A > 0) for (const v of [-p.A, p.A]) line(ctx, left, y(v), right, y(v), '#bfcdd0', 1, [3, 6]);
  trace(p, colors.coral); line(ctx, x(t), top, x(t), bottom, colors.teal, 1, [4, 4]); dot(ctx, x(t), y(d.u), colors.coral, 5); ctx.restore();
  $('compare-key').hidden = !q;
  $('comparison-note').textContent = !q ? 'The coral event is the same displacement shown by the marked point. Amplitude and time axes do not auto-scale.' : mode === 'double' ? `Dashed gold: f = ${fmt(q.f)} Hz, ω = ${fmt(metrics(q).omega)} rad/s, T = ${fmt(metrics(q).T)} s; same A and initial phase.` : 'Dashed gold: the same amplitude and frequency, with the phase of a zero-phase cosine. This comparison is unchanged by switching trigonometric convention.';
}
function draw() {
  const d = sample(p, t), a = arc(d.theta, radius);
  $('time').value = t; $('time-value').value = fmt(t) + ' s'; $('event-time').textContent = 't = ' + fmt(t) + ' s';
  $('back').disabled = t <= 0; $('next').disabled = t >= DURATION;
  $('displacement').textContent = fmt(d.u * factor()) + ' ' + unit; $('motion').textContent = `${motion(d)}. u = ${fmt(d.u * factor())} ${unit}.`;
  $('radius-value').value = fmt(radius);
  $('cycles').textContent = fmt(p.f * t); $('elapsed-phase').textContent = fmt(TAU * p.f * t) + ' rad';
  $('initial-phase').textContent = fmt(p.phi) + ' rad'; $('total-phase').textContent = fmt(d.theta) + ' rad';
  $('circle-angle').textContent = fmt(a.angle) + ' rad'; $('arc-length').textContent = fmt(a.length) + ' cm'; $('radian-ratio').textContent = fmt(a.angle) + ' rad';
  $('projection-label').textContent = `Projection ${p.form} θ`;
  $('projection').textContent = p.A ? fmt(p.form === 'cos' ? d.c : d.s) + ' = u/A' : 'u/A undefined at A = 0';
  for (const tr of $('landmarks').children) tr.dataset.active = String(Math.abs(+tr.dataset.time - t) < 1e-8);
  drawClock(d); drawBead(d); drawHistory(d);
}
$('example').addEventListener('change', () => { stop(); ({ p, t, unit } = preset($('example').value)); example = $('example').value; error(); sync(); });
$('unit').addEventListener('change', () => { unit = $('unit').value; sync(); });
$('amplitude').addEventListener('input', () => change(q => ({ ...q, A: Number($('amplitude').value) / factor() })));
$('rate-mode').addEventListener('change', () => { error(); rateInput(); });
$('rate').addEventListener('change', () => change(q => ({ ...q, f: fromRate($('rate-mode').value, $('rate').valueAsNumber) })));
$('form').addEventListener('change', () => change(q => changeForm(q, $('form').value)));
$('phase').addEventListener('change', () => change(q => ({ ...q, phi: $('phase').valueAsNumber })));
$('phase-range').addEventListener('input', () => change(q => ({ ...q, phi: Number($('phase-range').value) })));
$('radius').addEventListener('input', () => { radius = Number($('radius').value); draw(); });
$('compare').addEventListener('change', () => { mode = $('compare').value; draw(); });
$('time').addEventListener('input', () => { stop(); t = Number($('time').value); draw(); });
$('history').addEventListener('click', event => {
  const box = $('history').getBoundingClientRect(), x = event.clientX - box.left, y = event.clientY - box.top;
  if (x < 46 || x > box.width - 16 || y < 49 || y > box.height - 42) return;
  stop(); t = DURATION * (x - 46) / (box.width - 62); draw();
});
for (const [id, direction] of [['back', -1], ['next', 1]]) $(id).addEventListener('click', () => { stop(); t = Math.max(0, Math.min(DURATION, t + direction * metrics(p).T / 4)); draw(); });
$('speed').addEventListener('change', () => { speed = Number($('speed').value); });
$('play').addEventListener('click', () => {
  if (running) { stop(); return; }
  if (t >= DURATION) t = 0;
  running = true; last = performance.now(); $('play').setAttribute('aria-pressed', 'true'); $('play').setAttribute('aria-label', 'Pause clock'); $('play').title = 'Pause clock'; playIcon('pause'); raf = requestAnimationFrame(animate);
});
function animate(now) {
  if (!running) return;
  t = Math.min(DURATION, t + Math.min(.1, (now - last) / 1000) * speed); last = now; draw();
  if (t >= DURATION) stop(); else raf = requestAnimationFrame(animate);
}
$('reset').addEventListener('click', () => {
  stop(); ({ p, t, unit } = preset()); example = 'explore'; radius = 1; speed = .25; mode = 'off';
  $('radius').value = 1; $('speed').value = '.25'; $('compare').value = 'off'; $('rate-mode').value = 'frequency'; error(); sync();
});
$('download').addEventListener('click', () => {
  const url = URL.createObjectURL(new Blob([csv(p, mode)], { type: 'text/csv' })), a = document.createElement('a');
  a.href = url; a.download = 'sinusoidal-oscillation.csv'; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
});
document.addEventListener('visibilitychange', () => { if (document.hidden) stop(); }); window.addEventListener('pagehide', stop);
const observer = new ResizeObserver(draw); for (const id of ['clock', 'bead', 'history']) observer.observe($(id));
sync();
