(function (root) {
  'use strict';

  function solve(mode, m1, m2, g, time) {
    if (!['fixed', 'movable'].includes(mode) || ![m1, m2, g, time].every(Number.isFinite) ||
        m1 <= 0 || m2 <= 0 || g <= 0 || time < 0) {
      throw new RangeError('Use a supported system, positive masses and gravity, and nonnegative time.');
    }

    if (mode === 'fixed') {
      // Positive: right mass m2 down, left mass m1 up.
      const acceleration = (m2 - m1) * g / (m1 + m2);
      const tension = 2 * m1 * m2 * g / (m1 + m2);
      const displacement = 0.5 * acceleration * time * time;
      return {
        mode, m1, m2, g, time, acceleration, tension,
        m1Displacement: -displacement, m2Displacement: displacement,
        m1Velocity: -acceleration * time, m2Velocity: acceleration * time,
        constraint: -displacement + displacement,
      };
    }

    // Positive: free mass m1 down, movable load m2 up.
    const loadAcceleration = (2 * m1 - m2) * g / (4 * m1 + m2);
    const freeAcceleration = 2 * loadAcceleration;
    const tension = m1 * (g - freeAcceleration);
    const loadDisplacement = 0.5 * loadAcceleration * time * time;
    const freeDisplacement = 2 * loadDisplacement;
    return {
      mode, m1, m2, g, time, acceleration: loadAcceleration,
      freeAcceleration, tension,
      m1Displacement: freeDisplacement, m2Displacement: -loadDisplacement,
      m1Velocity: freeAcceleration * time, m2Velocity: -loadAcceleration * time,
      constraint: freeDisplacement + 2 * (-loadDisplacement),
    };
  }

  function duration(mode, m1, m2, g) {
    const acceleration = solve(mode, m1, m2, g, 0).acceleration;
    const stroke = mode === 'fixed' ? 0.75 : acceleration < 0 ? 0.3 : 0.5;
    return Math.abs(acceleration) < 1e-9 ? 3 : Math.sqrt(2 * stroke / Math.abs(acceleration));
  }

  const api = { solve, duration };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.PLAtwoodModel = api;
}(typeof window !== 'undefined' ? window : globalThis));
