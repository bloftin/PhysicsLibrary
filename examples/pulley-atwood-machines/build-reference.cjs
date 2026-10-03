const fs = require('node:fs');
const path = require('node:path');
const { solve, duration } = require('./model.js');

const cases = [
  ['atwood', 'fixed', 3, 5, 9.81],
  ['balanced', 'fixed', 4, 4, 9.81],
  ['movable', 'movable', 4, 6, 9.81],
  ['movable-balanced', 'movable', 3, 6, 9.81],
];
const rows = ['case,mode,m1_kg,m2_kg,gravity_m_s2,time_s,m1_down_m,m2_down_m,m1_down_m_s,m2_down_m_s,load_up_m_s2,tension_N,constraint_m'];
for (const [name, mode, m1, m2, g] of cases) {
  const finish = duration(mode, m1, m2, g);
  for (let i = 0; i <= 120; i++) {
    const s = solve(mode, m1, m2, g, finish * i / 120);
    rows.push([name, mode, m1, m2, g, s.time, s.m1Displacement, s.m2Displacement,
      s.m1Velocity, s.m2Velocity, s.acceleration, s.tension, s.constraint].join(','));
  }
}
fs.writeFileSync(path.join(__dirname, 'reference.csv'), rows.join('\n') + '\n');
