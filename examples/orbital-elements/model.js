import { kepler3 } from 'astronomia/kepler';

export const MU = 398600.4418;
export const EARTH_RADIUS = 6378.137;
export const J2 = 1.08262668e-3;
export const RAD = Math.PI / 180;
export const TAU = 2 * Math.PI;
export const PRESETS = {
  gps: { name: 'GPS', a: 26560, e: 0.01, i: 55, raan: 40, argp: 45, nu: 30 },
  iss: { name: 'ISS-like', a: 6797, e: 0.0007, i: 51.6, raan: 139.1, argp: 206.2, nu: 30 },
  sso: { name: 'Sun-sync', a: 7078.137, e: 0.001, i: 98.19, raan: 20, argp: 90, nu: 30 },
  geo: { name: 'GEO', a: 42164, e: 0, i: 0, raan: 0, argp: 0, nu: 30 },
  gto: { name: 'GTO', a: 24371, e: 0.73, i: 28.5, raan: 40, argp: 35, nu: 20 },
  molniya: { name: 'Molniya', a: 26600, e: 0.74, i: 63.4349488, raan: 30, argp: 270, nu: 60 },
};
export const wrap = value => ((value % TAU) + TAU) % TAU;
export const norm = v => Math.hypot(...v);
export const dot = (a, b) => a.reduce((sum, x, i) => sum + x * b[i], 0);
export const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];

export function validate(elements) {
  for (const key of ['a', 'e', 'i', 'raan', 'argp', 'nu']) {
    if (!Number.isFinite(elements[key])) throw new RangeError(`${key} must be finite`);
  }
  if (elements.a <= 0 || elements.e < 0 || elements.e >= 1 || elements.i < 0 || elements.i > 180) {
    throw new RangeError('This viewer requires a > 0, 0 <= e < 1 and 0 <= i <= 180 degrees');
  }
  return elements;
}

// Columns of Rz(RAAN) Rx(i) Rz(argument of periapsis), in a right-handed ECI frame.
export function basis(elements) {
  validate(elements);
  const O = elements.raan * RAD, i = elements.i * RAD, w = elements.argp * RAD;
  const cO = Math.cos(O), sO = Math.sin(O), ci = Math.cos(i), si = Math.sin(i);
  const cw = Math.cos(w), sw = Math.sin(w);
  return {
    P: [cO * cw - sO * sw * ci, sO * cw + cO * sw * ci, sw * si],
    Q: [-cO * sw - sO * cw * ci, -sO * sw + cO * cw * ci, cw * si],
    W: [sO * si, -cO * si, ci],
    N: [cO, sO, 0],
    B: [-sO * ci, cO * ci, si],
  };
}
export const transform = (x, y, frame) => frame.P.map((p, i) => p * x + frame.Q[i] * y);

export function anomalies(e, nu) {
  const E = wrap(Math.atan2(Math.sqrt(1 - e * e) * Math.sin(nu), e + Math.cos(nu)));
  return { E, M: wrap(E - e * Math.sin(E)) };
}

export function state(elements) {
  validate(elements);
  const { a, e } = elements, nu = elements.nu * RAD;
  const frame = basis(elements), p = a * (1 - e * e);
  const radius = p / (1 + e * Math.cos(nu));
  const factor = Math.sqrt(MU / p);
  const r = transform(radius * Math.cos(nu), radius * Math.sin(nu), frame);
  const v = transform(-factor * Math.sin(nu), factor * (e + Math.cos(nu)), frame);
  const n = Math.sqrt(MU / a ** 3);
  const { E, M } = anomalies(e, nu);
  return { r, v, radius, speed: norm(v), frame, E, M, n, period: TAU / n,
    perigee: a * (1 - e) - EARTH_RADIUS, apogee: a * (1 + e) - EARTH_RADIUS,
    energy: -MU / (2 * a), h: Math.sqrt(MU * p),
    flightPath: Math.atan2(e * Math.sin(nu), 1 + e * Math.cos(nu)),
    circular: e < 1e-8, equatorial: Math.abs(Math.sin(elements.i * RAD)) < 1e-8 };
}

export function secularRates(elements) {
  const { a, e, i } = validate(elements);
  const p = a * (1 - e * e), n = Math.sqrt(MU / a ** 3), c = Math.cos(i * RAD);
  const k = J2 * n * (EARTH_RADIUS / p) ** 2;
  return { raan: -1.5 * k * c, argp: 0.75 * k * (5 * c * c - 1) };
}

export function advance(elements, seconds, withJ2 = false) {
  if (!Number.isFinite(seconds)) throw new RangeError('time must be finite');
  const current = state(elements), M = wrap(current.M + current.n * seconds);
  const E = kepler3(elements.e, M);
  const nu = wrap(Math.atan2(Math.sqrt(1 - elements.e ** 2) * Math.sin(E), Math.cos(E) - elements.e));
  const rates = withJ2 ? secularRates(elements) : { raan: 0, argp: 0 };
  return { ...elements, nu: nu / RAD,
    raan: wrap(elements.raan * RAD + rates.raan * seconds) / RAD,
    argp: wrap(elements.argp * RAD + rates.argp * seconds) / RAD };
}

export function sample(elements, count = 360, withJ2 = false) {
  const period = state(elements).period;
  return Array.from({ length: count + 1 }, (_, j) => {
    const t = period * j / count, p = advance(elements, t, withJ2), s = state(p);
    return { t, ...p, ...s };
  });
}
export function csv(elements, withJ2 = false) {
  const header = 'time_s,x_km,y_km,z_km,vx_km_s,vy_km_s,vz_km_s,true_anomaly_deg,raan_deg,argp_deg';
  return header + '\n' + sample(elements, 360, withJ2).map(s =>
    [s.t, ...s.r, ...s.v, s.nu, s.raan, s.argp].map(n => n.toPrecision(15)).join(',')).join('\n') + '\n';
}
