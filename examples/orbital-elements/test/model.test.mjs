import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { PRESETS, MU, RAD, TAU, state, advance, secularRates, norm, dot, cross, wrap, csv } from '../model.js';
const near = (a,b,tolerance=1e-9) => assert.ok(Math.abs(a-b)<=tolerance, `${a} != ${b}`);
test('right-handed orthonormal frame, energy, momentum and Kepler time', () => {
  for (const p of Object.values(PRESETS)) {
    const initial = state(p), {P,Q,W} = initial.frame;
    for (const v of [P,Q,W]) near(norm(v),1);
    near(dot(P,Q),0); near(dot(P,W),0); near(dot(Q,W),0);
    near(dot(cross(P,Q),W),1);
    for (let j=0;j<=100;j++) {
      const s=state(advance(p,initial.period*j/100));
      near(dot(s.v,s.v)/2-MU/s.radius,initial.energy);
      near(norm(cross(s.r,s.v)),initial.h,1e-7);
      near(dot(s.r,W),0,1e-9);
      near(wrap(s.M-initial.M-TAU*j/100+Math.PI),Math.PI,1e-12);
    }
    state(advance(p,initial.period)).r.forEach((x,i)=>near(x,initial.r[i],1e-7));
  }
});
test('browser states match independent Julia reference, with and without J2', () => {
  const rows = readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split('\n').slice(1);
  assert.equal(rows.length,108);
  for (const row of rows) {
    const [name,j2,...values]=row.split(',');
    const [fraction,t,...expected]=values.map(Number);
    near(t,state(PRESETS[name]).period*fraction,1e-8);
    const p=advance(PRESETS[name],t,j2==='1'), s=state(p);
    [...s.r,...s.v,p.nu,p.raan,p.argp].forEach((value,i)=>near(value,expected[i],i<3?1e-7:1e-8));
  }
});
test('singularities, retrograde nodes, critical inclination, fast perigee passage', () => {
  assert.ok(state(PRESETS.geo).circular && state(PRESETS.geo).equatorial);
  assert.ok(state({...PRESETS.gps,i:180}).equatorial);
  assert.ok(secularRates(PRESETS.gps).raan<0);
  assert.ok(secularRates(PRESETS.sso).raan>0);
  near(secularRates(PRESETS.molniya).argp,0,1e-13);
  const p={...PRESETS.gto,nu:0}, a=advance(p,60);
  const q={...p,nu:180}, b=advance(q,60);
  assert.ok(a.nu>wrap((b.nu-180)*RAD)/RAD*10);
  for (const nu of [0,.001,30,90,180,270,359.99]) {
    const p={...PRESETS.gps,e:.95,nu};
    const s=state(p), z=state(advance(p,1));
    near(wrap(z.M-s.M-s.n+Math.PI),Math.PI,1e-12);
  }
});
test('ascending and descending crossings use the actual eccentric-orbit radius', () => {
  const p=PRESETS.gto;
  const asc=state({...p,nu:-p.argp}), desc=state({...p,nu:180-p.argp});
  near(asc.r[2],0); near(desc.r[2],0);
  assert.ok(asc.v[2]>0 && desc.v[2]<0);
  assert.ok(Math.abs(asc.radius-desc.radius)>1000);
});
test('rejects nonelliptic/nonfinite elements and exports a complete orbit', () => {
  for (const fields of [{a:0},{e:1},{e:-1},{i:181},{raan:NaN}]) assert.throws(()=>state({...PRESETS.gps,...fields}),RangeError);
  assert.throws(()=>advance(PRESETS.gps,Infinity),RangeError);
  const rows=csv(PRESETS.gto,true).trim().split('\n');
  assert.equal(rows.length,362);
  assert.equal(rows[0].split(',').length,10);
  for (const row of rows.slice(1)) assert.ok(row.split(',').every(x=>Number.isFinite(Number(x))));
});
