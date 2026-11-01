import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {csvParse} from 'd3';
import {K,MASK,PRESETS,preset,validate,fieldAt,pairForce,forces,probeResult,resizeCharges,separationRange,setSeparation,inverseSquare,csv} from '../model.js';
const near=(a,b,tol=2e-11)=>assert.ok(Math.abs(a-b)<=tol*Math.max(1,Math.abs(b)),`${a} != ${b}`);
const load=name=>csvParse(readFileSync(new URL('../'+name,import.meta.url),'utf8'));
const configs=load('configurations.csv'),cases=new Map();
for(const row of configs){if(!cases.has(row.case))cases.set(row.case,[]);cases.get(row.case).push({q:+row.q_C,x:+row.x_m,y:+row.y_m});}
test('1440 independent 256-bit Julia field values and 28 force vectors',()=>{
  const fields=load('fields.csv'),fs=load('forces.csv');assert.equal(fields.length,1440);assert.equal(fs.length,28);
  for(const row of fields){const e=fieldAt(cases.get(row.case),{x:+row.x_m,y:+row.y_m});near(e.x,+row.Ex_N_per_C);near(e.y,+row.Ey_N_per_C);near(e.magnitude,+row.E_N_per_C);}
  for(const row of fs){const qs=cases.get(row.case),i=+row.index-1,f=forces(qs)[i],e=fieldAt(qs,qs[i],i);near(f.x,+row.Fx_N);near(f.y,+row.Fy_N);near(f.magnitude,+row.F_N);near(e.x,+row.E_external_x_N_per_C);near(e.y,+row.E_external_y_N_per_C);}
});
test('sign, units, inverse square and equal opposite pair forces',()=>{
  near(K,8.9875517862e9,1e-10);
  const p=preset(),f=forces(p.charges);assert.ok(f[0].x>0&&f[1].x<0);near(f[0].magnitude,K*1e-12/4);
  const doubled=setSeparation(p,4);near(forces(doubled.charges)[0].magnitude,f[0].magnitude/4);
  const half=setSeparation(p,1);near(forces(half.charges)[0].magnitude,4*f[0].magnitude);
  const both=p.charges.map(c=>({...c,q:2*c.q}));near(forces(both)[0].magnitude,4*f[0].magnitude);
  for(const name of Object.keys(PRESETS)){const qs=preset(name).charges;for(let i=0;i<qs.length;i++)for(let j=i+1;j<qs.length;j++){const a=pairForce(qs,i,j),b=pairForce(qs,j,i);near(a.x,-b.x);near(a.y,-b.y);}const net=forces(qs);near(net.reduce((s,f)=>s+f.x,0),0);near(net.reduce((s,f)=>s+f.y,0),0);}
  assert.ok(forces(preset('like').charges)[0].x<0);
});
test('self-exclusion, superposition and neutral virtual test charge',()=>{
  for(const [name,qs]of cases){const fs=forces(qs);for(const [i,c]of qs.entries()){const e=fieldAt(qs,c,i);near(fs[i].x,c.q*e.x);near(fs[i].y,c.q*e.y);}}
  const p=preset('triangle'),e=fieldAt(p.charges,p.probe),parts=p.charges.map(c=>fieldAt([c],p.probe));near(e.x,parts.reduce((s,e)=>s+e.x,0));near(e.y,parts.reduce((s,e)=>s+e.y,0));
  const positive=probeResult(p),negative=probeResult({...p,testQ:-p.testQ}),zero=probeResult({...p,testQ:0});near(positive.field.x,negative.field.x);near(positive.force.x,-negative.force.x);near(zero.force.magnitude,0);near(zero.field.magnitude,positive.field.magnitude);
});
test('singular points, rendering mask and exact cancellations are distinguished',()=>{
  const p=preset('positive');assert.equal(fieldAt(p.charges,p.charges[0]),null);
  assert.equal(probeResult({...p,probe:{x:0,y:0}}).status,'singular');assert.equal(probeResult({...p,probe:{x:MASK/2,y:0}}).status,'masked');assert.ok(fieldAt(p.charges,{x:MASK/2,y:0}).magnitude>0);
  near(fieldAt(preset('like').charges,{x:0,y:0}).magnitude,0);near(forces(preset('balance').charges)[1].magnitude,0);
  const z=preset('zero');near(fieldAt(z.charges,z.charges[0]).magnitude,0);assert.ok(forces(z.charges).every(f=>f.magnitude===0));
});
test('configurations, position bounds and separation updates retain geometry',()=>{
  for(const name of Object.keys(PRESETS)){const p=preset(name);for(const n of [2,3,4,5,6])assert.equal(resizeCharges(p,n).charges.length,n);}
  const p=preset(),s=separationRange(p);near(s.r,2);near(s.max,5);
  const rotated=validate({...p,charges:[{x:-.5,y:-.5,q:1e-6},{x:.5,y:.5,q:-1e-6}]});const moved=setSeparation(rotated,2);near(moved.charges[1].x-moved.charges[0].x,moved.charges[1].y-moved.charges[0].y);
  for(const bad of [()=>setSeparation(p,.1),()=>setSeparation(p,6),()=>resizeCharges(p,7),()=>validate({...p,charges:[p.charges[0],{...p.charges[1],x:-1}]}),()=>validate({...p,testQ:NaN}),()=>validate({...p,charges:p.charges.map(c=>({...c,q:6e-6}))})])assert.throws(bad);
});
test('inverse-square reference curve and complete force CSV exports',()=>{
  const p=preset(),data=inverseSquare(p);assert.equal(data.length,181);near(data[0].force,K*1e-12/.3**2);near(data.at(-1).r,5);
  const diagonal=validate({...p,charges:[{x:-2.5,y:-2.5,q:1e-6},{x:2.5,y:2.5,q:-1e-6}]});near(inverseSquare(diagonal).at(-1).r,Math.sqrt(50));
  const rows=csvParse(csv(preset('six')));assert.equal(rows.length,6);assert.ok(!/NaN|Infinity|undefined/.test(csv(preset('zero'))));near(+rows[0].q_C,1e-6);
});
