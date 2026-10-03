const assert = require('node:assert/strict');
const test = require('node:test');
const { solve, duration } = require('../model.js');

function close(actual, expected, tolerance = 1e-10) {
  assert.ok(Math.abs(actual - expected) < tolerance, `${actual} differs from ${expected}`);
}

test('fixed pulley matches the article worked example', () => {
  const s = solve('fixed', 3, 5, 9.81, 0.6);
  close(s.acceleration, 9.81 / 4);
  close(s.tension, 2 * 3 * 5 * 9.81 / 8);
  close(s.m1Displacement, -s.m2Displacement);
  close(s.tension - 3 * 9.81, 3 * s.acceleration);
  close(5 * 9.81 - s.tension, 5 * s.acceleration);
  close(s.constraint, 0);
});

test('movable pulley matches the article worked example and two-to-one constraint', () => {
  const s = solve('movable', 4, 6, 9.81, 0.7);
  close(s.acceleration, 2 * 9.81 / 22);
  close(s.m1Displacement, -2 * s.m2Displacement);
  close(s.m1Velocity, -2 * s.m2Velocity);
  close(4 * 9.81 - s.tension, 4 * s.freeAcceleration);
  close(2 * s.tension - 6 * 9.81, 6 * s.acceleration);
  close(s.constraint, 0);
});

test('balanced and reversed mass cases preserve signs and tension', () => {
  const fixed = solve('fixed', 4, 4, 9.81, 2);
  const movable = solve('movable', 3, 6, 9.81, 2);
  close(fixed.acceleration, 0);
  close(fixed.tension, 4 * 9.81);
  close(movable.acceleration, 0);
  close(movable.tension, 3 * 9.81);
  assert.ok(solve('fixed', 6, 2, 9.81, 1).acceleration < 0);
  assert.ok(solve('movable', 2, 6, 9.81, 1).acceleration < 0);
  close(duration('fixed', 4, 4, 9.81), 3);
  close(duration('movable', 4, 6, 9.81), Math.sqrt(1 / (2 * 9.81 / 22)));
  close(duration('movable', 2, 6, 9.81), Math.sqrt(0.6 / Math.abs(solve('movable', 2, 6, 9.81, 0).acceleration)));
});

test('nonphysical inputs are rejected', () => {
  for (const args of [['other', 3, 5, 9.81, 0], ['fixed', 0, 5, 9.81, 0],
    ['fixed', 3, 5, 0, 0], ['movable', 3, 5, 9.81, -1],
    ['fixed', Number.NaN, 5, 9.81, 0]]) {
    assert.throws(() => solve(...args), RangeError);
  }
});
