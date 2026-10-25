export const TAU = 2 * Math.PI;
export const DURATION = 4;
export const BOUNDS = Object.freeze({ A: [0, .05], f: [.25, 4], phi: [-Math.PI, Math.PI] });
export const PRESETS = Object.freeze({
  explore: 'Explore', example1: '1: 4 cm, 2 Hz', example2: '2: 6 mm, T = 0.40 s',
  rising: 'Equilibrium, rising', falling: 'Equilibrium, falling', sine: 'Equivalent sine', zero: 'Zero amplitude'
});

export function parameters(raw = {}) {
  const p = { A: .03, f: 1, phi: 0, form: 'cos', ...raw };
  for (const [key, [lo, hi]] of Object.entries(BOUNDS)) {
    if (!Number.isFinite(p[key]) || p[key] < lo - 1e-12 || p[key] > hi + 1e-12) {
      throw new RangeError(`Invalid ${key}.`);
    }
  }
  if (!['cos', 'sin'].includes(p.form)) throw new RangeError('Unknown trigonometric form.');
  return p;
}
export const wrap = angle => ((angle % TAU) + TAU) % TAU;
export const principal = angle => wrap(angle + Math.PI) - Math.PI;
export function metrics(p) { return { T: 1 / p.f, f: p.f, omega: TAU * p.f, observed: p.A > 0 }; }
export function fromRate(kind, value) {
  if (!Number.isFinite(value) || value <= 0) throw new RangeError('Enter a positive finite repetition rate.');
  if (kind === 'frequency') return value;
  if (kind === 'period') return 1 / value;
  if (kind === 'angular') return value / TAU;
  throw new RangeError('Unknown rate notation.');
}
export function sample(p, t) {
  const theta = TAU * p.f * t + p.phi;
  const c = Math.cos(theta), s = Math.sin(theta);
  return { t, theta, c, s, u: p.A * (p.form === 'cos' ? c : s),
    slope: p.A * TAU * p.f * (p.form === 'cos' ? -s : c) };
}
export function changeForm(p, form) {
  if (!['cos', 'sin'].includes(form)) throw new RangeError('Unknown trigonometric form.');
  return parameters({ ...p, form, phi: form === p.form ? p.phi : principal(p.phi + (form === 'sin' ? Math.PI / 2 : -Math.PI / 2)) });
}
export function preset(id = 'explore') {
  if (!Object.hasOwn(PRESETS, id)) throw new RangeError('Unknown example.');
  let p = parameters(), t = .125, unit = 'cm';
  if (id === 'example1') { p = parameters({ A: .04, f: 2 }); t = 0; }
  if (id === 'example2') { p = parameters({ A: .006, f: 2.5, phi: Math.PI / 2 }); t = 0; unit = 'mm'; }
  if (id === 'rising') { p = parameters({ phi: -Math.PI / 2 }); t = 0; }
  if (id === 'falling') { p = parameters({ phi: Math.PI / 2 }); t = 0; }
  if (id === 'sine') p = parameters({ form: 'sin', phi: Math.PI / 2 });
  if (id === 'zero') p = parameters({ A: 0 });
  return { p, t, unit };
}
export function comparison(p, mode) {
  if (mode === 'off') return null;
  if (mode === 'double') return { ...p, f: 2 * p.f };
  if (mode === 'phase') return { ...p, phi: p.form === 'cos' ? 0 : Math.PI / 2 };
  throw new RangeError('Unknown comparison.');
}
export function history(p, count = 1601) {
  return Array.from({ length: count }, (_, i) => sample(p, DURATION * i / (count - 1)));
}
export function landmarks(p) {
  const T = 1 / p.f;
  return Array.from({ length: 5 }, (_, i) => ({ quarter: i, ...sample(p, i * T / 4) }));
}
export function arc(theta, radius) {
  if (!Number.isFinite(radius) || radius < .5 || radius > 1.5) throw new RangeError('Invalid reference radius.');
  const angle = wrap(theta);
  return { angle, radius, length: radius * angle };
}
export function csv(raw, mode = 'off') {
  const p = parameters(raw), q = comparison(p, mode), m = metrics(p);
  const rows = ['A_m,f_Hz,T_s,omega_rad_per_s,phi_rad,form,t_s,phase_rad,u_m,du_dt_m_per_s,comparison,comparison_u_m'];
  for (const d of history(p)) rows.push([p.A, p.f, m.T, m.omega, p.phi, p.form, d.t, d.theta, d.u, d.slope, mode, q ? sample(q, d.t).u : ''].join(','));
  return rows.join('\n') + '\n';
}
