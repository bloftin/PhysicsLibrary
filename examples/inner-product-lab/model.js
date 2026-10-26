export const MODES = ['vectors', 'functions', 'matrices'];
export const SAMPLES = [4, 8, 16, 32, 64, 128];
export const PRESETS = {
  vectors: { general: 'Projection', orthogonal: 'Orthogonal', opposite: 'Obtuse angle', zero: 'Zero target' },
  functions: { square: 'x² onto 1', cubic: 'x³ onto x', cancel: '1 and x: cancellation', interval: '1 and x on [0, 1]', weighted: 'Weighted x onto 1', norm: 'Norm of x', quadratic: 'Weight 1 + x²' },
  matrices: { trace: 'Remove the trace', symmetric: 'Symmetric vs skew', general: 'General matrices', zero: 'Zero target' }
};
export function preset(mode = 'vectors', id = Object.keys(PRESETS[mode] || {})[0]) {
  if (!MODES.includes(mode) || !Object.hasOwn(PRESETS[mode], id)) throw new RangeError('Unknown mode or example.');
  const p = { mode, u: [3, 2], v: [2, 1], a: -1, b: 1, weight: 'uniform', n: 16, fit: true, c: 0 };
  if (mode === 'vectors') {
    if (id === 'orthogonal') { p.u = [1, 1]; p.v = [1, -1]; }
    if (id === 'opposite') { p.u = [-2, 1]; p.v = [3, 0]; }
    if (id === 'zero') p.v = [0, 0];
  }
  if (mode === 'functions') {
    p.u = [0, 0, 1, 0]; p.v = [1, 0, 0, 0];
    if (id === 'cubic') { p.u = [0, 0, 0, 1]; p.v = [0, 1, 0, 0]; }
    if (id === 'cancel' || id === 'interval') { p.u = [1, 0, 0, 0]; p.v = [0, 1, 0, 0]; }
    if (id === 'interval' || id === 'weighted') { p.a = 0; p.b = 1; }
    if (id === 'weighted') { p.u = [0, 1, 0, 0]; p.weight = 'ramp'; }
    if (id === 'norm') { p.u = [0, 1, 0, 0]; p.v = [0, 1, 0, 0]; }
    if (id === 'quadratic') { p.u = [1, 1, 0, 0]; p.v = [1, 0, 1, 0]; p.weight = 'quadratic'; }
  }
  if (mode === 'matrices') {
    p.u = [3, 2, -1, 1]; p.v = [1, 0, 0, 1];
    if (id === 'symmetric') { p.u = [1, 2, 2, -1]; p.v = [0, -1, 1, 0]; }
    if (id === 'general') { p.u = [1, -2, 3, 1]; p.v = [2, 1, 0, -1]; }
    if (id === 'zero') p.v = [0, 0, 0, 0];
  }
  return validate(p);
}
export function validate(raw) {
  const p = { ...raw, u: [...raw.u], v: [...raw.v] };
  if (!MODES.includes(p.mode)) throw new RangeError('Unknown space.');
  const count = p.mode === 'vectors' ? 2 : 4;
  for (const key of ['u', 'v']) if (p[key].length !== count || p[key].some(x => !Number.isFinite(x) || Math.abs(x) > 100)) throw new RangeError('Entries must be finite numbers between −100 and 100.');
  if (![-1, 0].includes(p.a) || ![1, 2].includes(p.b) || p.a >= p.b) throw new RangeError('Unknown interval.');
  if (!['uniform', 'ramp', 'quadratic'].includes(p.weight) || !SAMPLES.includes(p.n)) throw new RangeError('Unknown weight or sample count.');
  if (typeof p.fit !== 'boolean' || !Number.isFinite(p.c) || Math.abs(p.c) > 1e8) throw new RangeError('Invalid trial coefficient.');
  return p;
}
export function poly(coefficients, x) { return coefficients.reduceRight((value, c) => value * x + c, 0); }
function multiply(a, b) {
  const out = Array(a.length + b.length - 1).fill(0);
  for (let i = 0; i < a.length; i++) for (let j = 0; j < b.length; j++) out[i + j] += a[i] * b[j];
  return out;
}
export function weightCoefficients(p) {
  if (p.weight === 'ramp') return [-2 * p.a / (p.b - p.a), 2 / (p.b - p.a)];
  return p.weight === 'quadratic' ? [1, 0, 1] : [1];
}
export function inner(p, u, v) {
  if (p.mode !== 'functions') return u.reduce((sum, x, i) => sum + x * v[i], 0);
  const product = multiply(multiply(u, v), weightCoefficients(p));
  return product.reduce((sum, c, i) => sum + c * (p.b ** (i + 1) - p.a ** (i + 1)) / (i + 1), 0);
}
export function analyze(raw) {
  const p = validate(raw), uv = inner(p, p.u, p.v), uu = Math.max(0, inner(p, p.u, p.u)), vv = Math.max(0, inner(p, p.v, p.v));
  const optimal = vv > 0 ? uv / vv : null, c = p.fit ? (optimal ?? 0) : p.c;
  const projection = p.v.map(x => c * x), residual = p.u.map((x, i) => x - projection[i]);
  const error2 = Math.max(0, inner(p, residual, residual)), rv = inner(p, residual, p.v);
  const cosine = uu > 0 && vv > 0 ? Math.max(-1, Math.min(1, uv / Math.sqrt(uu * vv))) : null;
  const angle = cosine === null ? null : Math.acos(cosine) * 180 / Math.PI;
  const nu = Math.sqrt(uu), nv = Math.sqrt(vv), along = nv > 0 ? uv / nv : null;
  return { uv, uu, vv, nu, nv, optimal, c, projection, residual, error2, rv, cosine, angle, along,
    perpendicular: along === null ? null : Math.sqrt(Math.max(0, uu - along * along)) };
}
export function terms(p, a = analyze(p), source = p.u) {
  if (p.mode !== 'functions') return source.map((u, i) => ({ position: i, label: p.mode === 'matrices' ? `${1 + Math.floor(i / 2)},${1 + i % 2}` : String(i + 1), u, v: p.v[i], weight: 1, dx: 1, value: u * p.v[i] }));
  const dx = (p.b - p.a) / p.n, w = weightCoefficients(p);
  return Array.from({ length: p.n }, (_, i) => {
    const position = p.a + (i + .5) * dx, u = poly(source, position), v = poly(p.v, position), weight = poly(w, position);
    return { position, label: String(i + 1), u, v, weight, dx, value: u * v * weight * dx };
  });
}
export function curves(p, a = analyze(p), count = 401) {
  return Array.from({ length: count }, (_, i) => {
    const x = p.a + (p.b - p.a) * i / (count - 1), u = poly(p.u, x), v = poly(p.v, x), w = poly(weightCoefficients(p), x);
    return { x, u, v, projection: a.c * v, residual: u - a.c * v, product: w * u * v, residualProduct: w * (u - a.c * v) * v };
  });
}
export function errorAt(p, c) { const residual = p.u.map((u, i) => u - c * p.v[i]); return Math.max(0, inner(p, residual, residual)); }
export function normalizeTarget(raw) {
  const p = validate(raw), n = Math.sqrt(inner(p, p.v, p.v));
  if (!(n > 0)) throw new RangeError('The zero target cannot be normalized.');
  return validate({ ...p, v: p.v.map(x => x / n), c: p.fit ? p.c : p.c * n });
}
export function polynomialLabel(v) {
  const powers = ['1', 'x', 'x²', 'x³'];
  const parts = v.flatMap((c, i) => c === 0 ? [] : [(c < 0 ? '− ' : '+ ') + (i === 0 || Math.abs(c) !== 1 ? String(Number(Math.abs(c).toPrecision(4))) : '') + (i ? powers[i] : '')]);
  return parts.length ? parts.join(' ').replace(/^\+ /, '') : '0';
}
export function csv(raw) {
  const p = validate(raw), a = analyze(p);
  const rows = ['mode,a,b,weight,optimal_c,trial_c,inner_product,norm_u,norm_v,residual_inner_v,error_squared,index,position,u,v,measure_weight,dx,contribution,residual_contribution,fit,u0,u1,u2,u3,v0,v1,v2,v3'];
  const residualTerms = terms(p, a, a.residual);
  const coordinates = [...p.u, ...Array(4 - p.u.length).fill(''), ...p.v, ...Array(4 - p.v.length).fill('')];
  for (const [i, q] of terms(p, a).entries()) rows.push([p.mode,p.a,p.b,p.weight,a.optimal??'',a.c,a.uv,a.nu,a.nv,a.rv,a.error2,i+1,q.position,q.u,q.v,q.weight,q.dx,q.value,residualTerms[i].value,p.fit,...coordinates].join(','));
  return rows.join('\n') + '\n';
}
