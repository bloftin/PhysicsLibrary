import { scaleLinear } from 'd3';
import { createIcons, RotateCcw, Download, MoveUpRight, FunctionSquare, Table2, Ruler } from 'lucide';
import { MODES, SAMPLES, PRESETS, preset, validate, analyze, terms, curves, errorAt, normalizeTarget, polynomialLabel, csv } from './model.js';
const $ = id => document.getElementById(id), icons = { RotateCcw, Download, MoveUpRight, FunctionSquare, Table2, Ruler };
const C = { u: '#087d86', v: '#c74e46', p: '#967011', r: '#6b70a0', ink: '#29383d', muted: '#5c7279', grid: '#dce6e8' };
const fmt = (value, digits = 5) => value === null ? 'Undefined' : Math.abs(value) < 1e-10 ? '0' : String(Number(value.toPrecision(digits)));
let p = preset(), selected = 'general', product = 'original', drag = null, vectorView = null;
const saved = new Map();
function error(message = '') { $('error').textContent = message; $('error').hidden = !message; }
function change(fn) {
  try { p = validate(fn({ ...p, u: [...p.u], v: [...p.v] })); selected = 'custom'; error(); sync(); }
  catch (e) { error(e.message); $('fit').checked = p.fit; }
}
function switchMode(mode) {
  saved.set(p.mode, { p, selected });
  const previous = saved.get(mode);
  p = previous?.p || preset(mode); selected = previous?.selected || Object.keys(PRESETS[mode])[0];
  drag = null; error(); sync();
}
function weightLabel() {
  if (p.weight === 'uniform') return 'w(x) = 1';
  if (p.weight === 'quadratic') return 'w(x) = 1 + x²';
  return p.a === 0 && p.b === 1 ? 'w(x) = 2x' : `w(x) = 2(x ${p.a < 0 ? '+ ' + Math.abs(p.a) : '− ' + p.a})/${p.b - p.a}`;
}
function sync() {
  document.body.dataset.mode = p.mode;
  for (const mode of MODES) $('mode-' + mode).setAttribute('aria-pressed', String(mode === p.mode));
  $('example').replaceChildren(...Object.entries({ ...PRESETS[p.mode], custom: 'Custom objects' }).map(([id, name]) => { const option = new Option(name, id); option.disabled = id === 'custom'; return option; }));
  $('example').value = selected;
  const isFunction = p.mode === 'functions', isMatrix = p.mode === 'matrices';
  $('function-settings').hidden = !isFunction; $('residual-toggle').hidden = !isFunction; $('object-legend').hidden = isMatrix;
  $('interval').value = `${p.a},${p.b}`; $('weight').value = p.weight;
  $('samples').value = SAMPLES.indexOf(p.n); $('samples-value').value = p.n;
  $('entry-kind').textContent = isFunction ? 'Power' : isMatrix ? 'Entry' : 'Index';
  $('u-label').textContent = isMatrix ? 'u = A' : 'u'; $('v-label').textContent = isMatrix ? 'v = B' : 'v';
  const labels = isFunction ? ['1', 'x', 'x²', 'x³'] : isMatrix ? ['1,1', '1,2', '2,1', '2,2'] : ['1', '2'];
  $('entries').replaceChildren(...p.u.map((_, i) => {
    const row = document.createElement('div'); row.className = 'entry-row';
    const label = document.createElement('span'); label.textContent = labels[i]; row.append(label);
    for (const key of ['u', 'v']) {
      const input = document.createElement('input'); input.type = 'number'; input.min = -100; input.max = 100; input.step = 'any'; input.id = key + '-' + i; input.value = Number(p[key][i].toPrecision(5));
      input.setAttribute('aria-label', `${key} ${isFunction ? 'coefficient of' : 'entry'} ${labels[i]}`);
      input.addEventListener('change', () => change(q => { q[key][i] = input.valueAsNumber; return q; })); row.append(input);
    }
    return row;
  }));
  $('space-title').textContent = isFunction ? 'Functions on an interval' : isMatrix ? 'Matrices as abstract vectors' : 'Vectors in the plane';
  $('dimension').textContent = isFunction ? 'Real polynomials of degree ≤ 3' : isMatrix ? 'Real 2×2 matrices: dimension 4' : 'Euclidean space: dimension 2';
  $('definition').textContent = isFunction ? `⟨u, v⟩ = ∫[${p.a}, ${p.b}] w(x)u(x)v(x) dx` : isMatrix ? '⟨A, B⟩ = tr(AᵀB) = Σ AᵢⱼBᵢⱼ' : '⟨u, v⟩ = u₁v₁ + u₂v₂';
  $('objects').textContent = isFunction ? `u(x) = ${polynomialLabel(p.u)}; v(x) = ${polynomialLabel(p.v)}; ${weightLabel()}.` : isMatrix ? 'u = A, v = B. Matching entries are multiplied and summed; these are not physical position vectors.' : `u = (${p.u.map(x => fmt(x)).join(', ')}), v = (${p.v.map(x => fmt(x)).join(', ')}).`;
  $('entry-note').textContent = isFunction ? 'Entries are coefficients in 1, x, x², x³. The selected interval and weight define the inner product.' : isMatrix ? 'Row,column labels identify the matrix entries. Every tile is one coordinate in a four-dimensional space.' : 'Edit components or drag either vector tip in the object view. Both plot axes use the same scale.';
  $('normalize').disabled = analyze(p).vv === 0;
  $('fit').checked = p.fit;
  draw(); createIcons({ icons });
}
function canvas(id) {
  const node = $(id), box = node.getBoundingClientRect(), w = box.width, h = box.height, dpr = Math.min(devicePixelRatio || 1, 2);
  if (node.width !== Math.round(w * dpr) || node.height !== Math.round(h * dpr)) { node.width = Math.round(w * dpr); node.height = Math.round(h * dpr); }
  const ctx = node.getContext('2d'); ctx.setTransform(dpr, 0, 0, dpr, 0, 0); ctx.clearRect(0, 0, w, h); ctx.lineCap = 'round'; return { ctx, w, h };
}
function text(ctx, value, x, y, color = C.muted, align = 'left', size = 11) { ctx.font = `${size}px Arial`; ctx.fillStyle = color; ctx.textAlign = align; ctx.fillText(value, x, y); }
function line(ctx, x1, y1, x2, y2, color, width = 1, dash = []) {
  ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dash); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); ctx.setLineDash([]);
}
function dot(ctx, x, y, color, r = 4) { ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fillStyle = color; ctx.fill(); }
function arrow(ctx, x1, y1, x2, y2, color, width = 2.5, dash = []) {
  line(ctx, x1, y1, x2, y2, color, width, dash);
  const length = Math.hypot(x2 - x1, y2 - y1);
  if (length < 7) { dot(ctx, x2, y2, color, 3); return; }
  const angle = Math.atan2(y2 - y1, x2 - x1);
  ctx.beginPath(); ctx.moveTo(x2, y2); ctx.lineTo(x2 - 9 * Math.cos(angle - .4), y2 - 9 * Math.sin(angle - .4)); ctx.lineTo(x2 - 9 * Math.cos(angle + .4), y2 - 9 * Math.sin(angle + .4)); ctx.closePath(); ctx.fillStyle = color; ctx.fill();
}
function frame(id, xd, yd, xlabel, ylabel, showXticks = true) {
  const c = canvas(id), { ctx, w, h } = c, pad = { l: 45, r: 17, t: 29, b: 38 };
  const x = scaleLinear().domain(xd).range([pad.l, w - pad.r]), y = scaleLinear().domain(yd).range([h - pad.b, pad.t]);
  const xticks = !showXticks ? [] : w < 330 ? [xd[0], xd[1]] : x.ticks(3), yticks = y.ticks(3);
  for (const v of xticks) { line(ctx, x(v), pad.t, x(v), h - pad.b, C.grid); text(ctx, fmt(v, 3), x(v), h - pad.b + 17, C.muted, v === xd[0] ? 'left' : v === xd[1] ? 'right' : 'center'); }
  for (const v of yticks) { line(ctx, pad.l, y(v), w - pad.r, y(v), C.grid); text(ctx, fmt(v, 3), pad.l - 7, y(v) + 4, C.muted, 'right'); }
  if (yd[0] <= 0 && yd[1] >= 0) line(ctx, pad.l, y(0), w - pad.r, y(0), '#aebfc3');
  text(ctx, ylabel, pad.l, 15, C.ink); text(ctx, xlabel, (pad.l + w - pad.r) / 2, h - 4, C.muted, 'center');
  return { ...c, pad, x, y };
}
function clip(c, fn) { c.ctx.save(); c.ctx.beginPath(); c.ctx.rect(c.pad.l, c.pad.t, c.w - c.pad.l - c.pad.r, c.h - c.pad.t - c.pad.b); c.ctx.clip(); fn(); c.ctx.restore(); }
function trace(c, data, key, color, dash = []) {
  const { ctx, x, y } = c; ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = 2.3; ctx.setLineDash(dash);
  data.forEach((d, i) => i ? ctx.lineTo(x(d.x), y(d[key])) : ctx.moveTo(x(d.x), y(d[key]))); ctx.stroke(); ctx.setLineDash([]);
}
function plane(id, limit, abstract = false) {
  const { ctx, w, h } = canvas(id), cx = w / 2, cy = h / 2, scale = Math.min(w - 86, h - 67) / (2 * limit);
  const x = value => cx + scale * value, y = value => cy - scale * value;
  for (const v of [-limit, 0, limit]) {
    line(ctx, x(v), y(-limit), x(v), y(limit), C.grid); line(ctx, x(-limit), y(v), x(limit), y(v), C.grid);
    if (v !== 0) { text(ctx, fmt(v, 3), x(v), y(-limit) + 17, C.muted, 'center'); text(ctx, fmt(v, 3), x(-limit) - 7, y(v) + 4, C.muted, 'right'); }
  }
  line(ctx, x(-limit), cy, x(limit), cy, '#aebfc3'); line(ctx, cx, y(-limit), cx, y(limit), '#aebfc3');
  text(ctx, abstract ? 'along v̂' : 'x₁', Math.min(w - 10, x(limit) + 55), cy + 18, C.ink, 'right'); text(ctx, abstract ? 'perp' : 'x₂', cx + 8, 15, C.ink);
  return { ctx, w, h, x, y, scale, cx, cy, limit };
}
function drawVectors(a) {
  const limit = drag?.limit || Math.max(2, Math.ceil(1.25 * Math.max(...p.u.map(Math.abs), ...p.v.map(Math.abs), ...a.projection.map(Math.abs))));
  const c = plane('objects-plot', limit), { ctx, x, y } = c; vectorView = c;
  arrow(ctx, x(0), y(0), x(a.projection[0]), y(a.projection[1]), C.p, 5);
  arrow(ctx, x(0), y(0), x(p.v[0]), y(p.v[1]), C.v);
  arrow(ctx, x(0), y(0), x(p.u[0]), y(p.u[1]), C.u);
  arrow(ctx, x(a.projection[0]), y(a.projection[1]), x(p.u[0]), y(p.u[1]), C.r, 2, [4, 4]);
  $('object-caption').textContent = 'Teal u and coral v share a Euclidean plane. Gold c v is the trial approximation; the dashed residual joins its tip to u. Plot limits follow the current objects, with equal units on both axes.';
}
function drawFunctions(a) {
  const data = curves(p, a), show = $('show-residual').checked;
  const keys = ['u', 'v', 'projection', ...(show ? ['residual'] : [])], max = Math.max(.1, ...data.flatMap(d => keys.map(key => Math.abs(d[key])))) * 1.18;
  const c = frame('objects-plot', [p.a, p.b], [-max, max], 'x', 'function value');
  clip(c, () => { trace(c, data, 'v', C.v, [5, 4]); trace(c, data, 'u', C.u); trace(c, data, 'projection', C.p); if (show) trace(c, data, 'residual', C.r, [3, 4]); });
  $('object-caption').textContent = 'The curves are the objects, not arrows meeting at an angle. The graph scale follows their values; the reported inner-product angle belongs to the whole functions and the selected measure.';
}
function drawMatrices(a) {
  const { ctx, w, h } = canvas('objects-plot'), max = Math.max(1, ...[...p.u, ...p.v, ...a.projection, ...a.residual].map(Math.abs));
  const values = [p.u, p.v, a.projection, a.residual], labels = ['u = A', 'v = B', 'c v', 'r = u − c v'];
  const cell = Math.min(48, (w / 2 - 28) / 2), groupH = h / 2;
  for (let group = 0; group < 4; group++) {
    const cx = (group % 2 + .5) * w / 2, top = Math.floor(group / 2) * groupH + 34;
    text(ctx, labels[group], cx, top - 13, C.ink, 'center', 12);
    for (let i = 0; i < 4; i++) {
      const value = values[group][i], x = cx + (i % 2 - 1) * cell, y = top + Math.floor(i / 2) * cell;
      const intensity = Math.min(1, Math.abs(value) / max), color = value >= 0 ? [8, 125, 134] : [199, 78, 70];
      ctx.fillStyle = `rgb(${color.map(channel => Math.round(255 + (channel - 255) * intensity * .5)).join(',')})`; ctx.fillRect(x, y, cell - 1, cell - 1);
      text(ctx, fmt(value, 4), x + cell / 2, y + cell / 2 + 4, C.ink, 'center', 11);
    }
  }
  $('object-caption').textContent = 'All four matrices use one shared cell-color scale, set by the largest current entry. Positive and negative entries have different hues. Projection and residual are matrices too.';
}
function drawProducts(a) {
  const residual = product === 'residual', q = terms(p, a, residual ? a.residual : p.u), exact = residual ? a.rv : a.uv;
  const sum = q.reduce((s, d) => s + d.value, 0), pos = q.reduce((s, d) => s + Math.max(0, d.value), 0), neg = q.reduce((s, d) => s + Math.min(0, d.value), 0);
  if (p.mode === 'functions') {
    const data = curves(p, a), key = residual ? 'residualProduct' : 'product', max = Math.max(.01, ...data.map(d => Math.abs(d[key]))) * 1.15;
    const c = frame('products-plot', [p.a, p.b], [-max, max], 'x', residual ? 'w(x) r(x) v(x)' : 'w(x) u(x) v(x)'), { ctx, x, y } = c;
    clip(c, () => {
      // One continuous area, clipped by sign, avoids seams resembling extra sample rectangles.
      for (const positive of [true, false]) {
        ctx.save(); ctx.beginPath(); ctx.rect(0, positive ? 0 : y(0), c.w, positive ? y(0) : c.h - y(0)); ctx.clip();
        ctx.fillStyle = positive ? '#c4e2e4' : '#efd0ca'; ctx.beginPath(); ctx.moveTo(x(data[0].x), y(0));
        for (const d of data) ctx.lineTo(x(d.x), y(d[key]));
        ctx.lineTo(x(data.at(-1).x), y(0)); ctx.closePath(); ctx.fill(); ctx.restore();
      }
      if ($('rectangles').checked) for (const d of q) {
        ctx.strokeStyle = d.value >= 0 ? C.u : C.v; ctx.lineWidth = .7;
        ctx.strokeRect(x(d.position - d.dx / 2), Math.min(y(0), y(d.value / d.dx)), x(d.position + d.dx / 2) - x(d.position - d.dx / 2), Math.abs(y(0) - y(d.value / d.dx)));
      }
      trace(c, data, key, C.ink);
    });
    $('exact-title').textContent = 'Analytic integral'; $('sample-result').hidden = false; $('sample-sum').textContent = fmt(sum);
    $('product-caption').textContent = `${weightLabel()}. Signed shading belongs to the integrand. Rectangles use midpoint values × Δx, with Δx = ${fmt((p.b - p.a) / p.n)}. Absolute sampling error: ${fmt(Math.abs(sum - exact))}. N changes the approximation, not the analytic projection.`;
  } else {
    const max = Math.max(.1, ...q.map(d => Math.abs(d.value))) * 1.2, c = frame('products-plot', [0, q.length], [-max, max], 'matching component / entry', 'signed product', false), { ctx, x, y } = c;
    clip(c, () => { for (let i = 0; i < q.length; i++) { const value = q[i].value; ctx.fillStyle = value >= 0 ? C.u : C.v; ctx.fillRect(x(i + .18), Math.min(y(0), y(value)), x(i + .82) - x(i + .18), Math.abs(y(value) - y(0))); } });
    for (let i = 0; i < q.length; i++) text(ctx, q[i].label, x(i + .5), c.h - 20, C.ink, 'center');
    $('exact-title').textContent = 'Sum of products'; $('sample-result').hidden = true;
    $('product-caption').textContent = 'Teal bars contribute positively; coral bars contribute negatively. Add the signed matched-component products to obtain one scalar. A zero sum may result from cancellation, even when neither object is zero.';
  }
  $('exact-sum').textContent = fmt(exact);
  $('sample-signs').textContent = `${p.mode === 'functions' ? 'Sampled sums' : 'Sums'}: positive ${fmt(pos)}; negative ${fmt(neg)}`;
  $('terms-title').textContent = p.mode === 'functions' ? 'From sampled lists to an integral' : 'Multiply matching coordinates, then add';
  $('position-title').textContent = p.mode === 'functions' ? 'Midpoint xᵢ' : p.mode === 'matrices' ? 'Entry (row,col)' : 'Component';
  $('source-title').textContent = residual ? 'r' : 'u';
  $('terms').replaceChildren(...q.map(d => {
    const tr = document.createElement('tr');
    for (const [i, value] of [p.mode === 'functions' ? fmt(d.position) : d.label, fmt(d.u), fmt(d.v), fmt(d.weight * d.dx), fmt(d.value)].entries()) { const td = document.createElement('td'); td.textContent = value; if (i === 4) td.className = d.value >= 0 ? 'positive' : 'negative'; tr.append(td); }
    return tr;
  }));
  $('terms-caption').textContent = p.mode === 'functions' ? `Displayed source: ${residual ? 'residual r' : 'u'}. Measure = w(xᵢ) Δx. The ${p.n} midpoint terms add to ${fmt(sum)}, an approximation to the analytic integral ${fmt(exact)}. Equivalently the sampled vectors have coordinates √(wᵢΔx)uᵢ and √(wᵢΔx)vᵢ.` : `Displayed source: ${residual ? 'residual r' : 'u'}. The measure is 1 for every coordinate. Matrix entries are read row by row; the Frobenius product uses all four.`;
}
function drawGeometry(a) {
  if (a.nv === 0) { const { ctx, w, h } = canvas('geometry'); text(ctx, 'v = 0: no unit target direction', w / 2, h / 2 - 12, C.ink, 'center', 13); text(ctx, 'The zero subspace has only the zero projection.', w / 2, h / 2 + 14, C.muted, 'center', w < 350 ? 10 : 12); return; }
  const limit = Math.max(.1, Math.max(a.nv, a.nu, Math.abs(a.c * a.nv)) * 1.3), c = plane('geometry', limit, true), { ctx, x, y } = c;
  arrow(ctx, x(0), y(0), x(a.c * a.nv), y(0), C.p, 5);
  arrow(ctx, x(0), y(0), x(a.nv), y(0), C.v);
  arrow(ctx, x(0), y(0), x(a.along), y(a.perpendicular), C.u);
  arrow(ctx, x(a.c * a.nv), y(0), x(a.along), y(a.perpendicular), C.r, 2, [4, 4]);
  if (a.perpendicular * c.scale > 14 && Math.abs(a.rv) < 1e-9 * Math.max(1, a.nu * a.nv)) {
    line(ctx, x(a.along) - 8, y(0), x(a.along) - 8, y(0) - 8, C.muted); line(ctx, x(a.along) - 8, y(0) - 8, x(a.along), y(0) - 8, C.muted);
  }
}
function drawError(a) {
  const center = a.optimal ?? 0, span = Math.max(1, Math.abs(center) * .6, Math.abs(a.c - center) * 1.25), low = center - span, high = center + span;
  const data = Array.from({ length: 161 }, (_, i) => { const x = low + (high - low) * i / 160; return { x, value: errorAt(p, x) }; });
  const max = Math.max(.01, ...data.map(d => d.value)) * 1.14, c = frame('error-plot', [low, high], [0, max], 'coefficient c', 'E(c) = ‖u − c v‖²');
  clip(c, () => { trace(c, data, 'value', C.ink); if (a.optimal !== null) dot(c.ctx, c.x(a.optimal), c.y(errorAt(p, a.optimal)), C.p, 6); dot(c.ctx, c.x(a.c), c.y(a.error2), C.r, 3.5); });
  $('error-caption').textContent = a.vv ? 'Gold marks the minimum; purple marks the current trial. The curve is quadratic in c, with curvature set by ‖v‖². Axes follow the current coefficient range and error scale.' : 'With v = 0, E(c) = ‖u‖² is constant. There is no unique minimizing coefficient, although every trial produces the same zero projection object.';
}
function draw() {
  const a = analyze(p), orthogonal = Math.abs(a.rv) < 1e-9 * Math.max(1, a.nu * a.nv);
  $('residual-key').hidden = p.mode === 'functions' && !$('show-residual').checked;
  $('inner').textContent = fmt(a.uv); $('norms').textContent = `${fmt(a.nu)} / ${fmt(a.nv)}`; $('angle').textContent = a.angle === null ? 'Undefined' : fmt(a.angle, 4) + '°';
  $('optimal').textContent = a.optimal === null ? 'Non-unique' : fmt(a.optimal); $('residual-test').textContent = fmt(a.rv); $('error2').textContent = fmt(a.error2);
  $('coefficient').disabled = p.fit; $('coefficient-number').disabled = p.fit;
  const extent = Math.max(4, Math.abs(a.c) * 1.3, Math.abs(a.optimal ?? 0) * 1.3);
  $('coefficient').min = -extent; $('coefficient').max = extent; $('coefficient').value = a.c; $('coefficient-number').value = Number(a.c.toPrecision(6));
  $('projection-status').textContent = a.vv === 0 ? 'Zero target: the projection is the zero object and every coefficient gives the same error. Division by ‖v‖² and the angle are undefined.' : orthogonal ? 'The residual has zero inner product with v to numerical precision. This is the least-squares projection onto its span.' : 'This trial is not optimal: the residual still has a component along v. Move c toward the error minimum or restore the optimal coefficient.';
  if (a.uu === 0 && a.vv > 0) $('projection-status').textContent += ' The source is zero, so its angle is undefined.';
  const projectedNorm2 = a.c * a.c * a.vv, cross = 2 * a.c * a.rv;
  $('pythagoras').textContent = a.vv > 0 && orthogonal ? `Pythagoras: ‖u‖² = ‖c v‖² + ‖r‖² : ${fmt(a.uu)} = ${fmt(projectedNorm2)} + ${fmt(a.error2)}` : `General identity: ‖u‖² = ‖c v‖² + ‖r‖² + 2c⟨r, v⟩ : ${fmt(a.uu)} = ${fmt(projectedNorm2)} + ${fmt(a.error2)} ${cross < 0 ? '−' : '+'} ${fmt(Math.abs(cross))}`;
  $('object-title').textContent = p.mode === 'functions' ? 'Functions and trial approximation' : p.mode === 'matrices' ? 'Matrix objects and residual' : 'Objects and trial approximation';
  if (p.mode === 'vectors') drawVectors(a); else if (p.mode === 'functions') drawFunctions(a); else drawMatrices(a);
  drawProducts(a); drawGeometry(a); drawError(a);
}
for (const mode of MODES) $('mode-' + mode).addEventListener('click', () => switchMode(mode));
$('example').addEventListener('change', () => { selected = $('example').value; p = preset(p.mode, selected); error(); sync(); });
$('interval').addEventListener('change', () => change(q => { [q.a, q.b] = $('interval').value.split(',').map(Number); return q; }));
$('weight').addEventListener('change', () => change(q => ({ ...q, weight: $('weight').value })));
$('samples').addEventListener('input', () => change(q => ({ ...q, n: SAMPLES[Number($('samples').value)] })));
for (const id of ['rectangles', 'show-residual']) $(id).addEventListener('change', draw);
$('product').addEventListener('change', () => { product = $('product').value; draw(); });
$('fit').addEventListener('change', () => change(q => ({ ...q, fit: $('fit').checked, c: analyze(q).c })));
for (const id of ['coefficient', 'coefficient-number']) $(id).addEventListener(id === 'coefficient' ? 'input' : 'change', () => change(q => ({ ...q, fit: false, c: $(id).valueAsNumber })));
$('normalize').addEventListener('click', () => change(normalizeTarget));
$('reset').addEventListener('click', () => { p = preset(p.mode); selected = Object.keys(PRESETS[p.mode])[0]; product = 'original'; $('product').value = product; $('rectangles').checked = true; $('show-residual').checked = false; error(); sync(); });
$('download').addEventListener('click', () => { const url = URL.createObjectURL(new Blob([csv(p)], { type: 'text/csv' })), link = document.createElement('a'); link.href = url; link.download = 'inner-product-' + p.mode + '.csv'; link.click(); setTimeout(() => URL.revokeObjectURL(url), 1000); });
$('objects-plot').addEventListener('pointerdown', event => {
  if (p.mode !== 'vectors') return;
  const box = $('objects-plot').getBoundingClientRect(), x = event.clientX - box.left, y = event.clientY - box.top, view = vectorView;
  const distances = ['u', 'v'].map(key => [key, Math.hypot(x - view.x(p[key][0]), y - view.y(p[key][1]))]).sort((a, b) => a[1] - b[1]);
  if (distances[0][1] > 22) return;
  drag = { key: distances[0][0], limit: view.limit }; $('objects-plot').setPointerCapture(event.pointerId);
});
$('objects-plot').addEventListener('pointermove', event => {
  if (!drag) return;
  const box = $('objects-plot').getBoundingClientRect(), view = vectorView;
  const point = [(event.clientX - box.left - view.cx) / view.scale, (view.cy - event.clientY + box.top) / view.scale].map(x => Math.max(-100, Math.min(100, x)));
  change(q => ({ ...q, [drag.key]: point }));
});
for (const event of ['pointerup', 'pointercancel', 'lostpointercapture']) $('objects-plot').addEventListener(event, () => { if (drag) { drag = null; draw(); } });
const observer = new ResizeObserver(draw); for (const id of ['objects-plot', 'products-plot', 'geometry', 'error-plot']) observer.observe($(id));
sync();
