import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULTS,PRESETS,parameters,scales,classification,response,evaluate,trajectory,csv} from '../model.js';
const close=(a,b,tol=2e-7)=>assert.ok(Math.abs(a-b)<tol*(1+Math.abs(b)),`${a} != ${b}`);
test('Julia reference: nine cases, all state and energy quantities',()=>{
  const lines=readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split(/\r?\n/);
  const headers=lines.shift().split(',');
  assert.equal(lines.length,729);
  const grouped=new Map();
  for(const line of lines){const values=line.split(',');const r=Object.fromEntries(headers.map((k,i)=>[k,values[i]]));if(!grouped.has(r.case))grouped.set(r.case,[]);grouped.get(r.case).push(r);}
  for(const rows of grouped.values()){
    const first=rows[0],p={mode:first.mode};for(const k of Object.keys(DEFAULTS))if(k!=='mode')p[k]=Number(first[k]);
    const actual=trajectory(p,80);
    for(let i=0;i<rows.length;i++)for(const [key,col] of Object.entries({t:'time_s',x:'x_m',v:'v_m_s',a:'a_m_s2',K:'kinetic_J',U:'potential_J',E:'mechanical_J',Q:'dissipated_J',W:'drive_work_J',F:'drive_force_N',balance:'balance_error_J'}))close(actual[i][key],Number(rows[i][col]));
  }
});
test('independent harmonic, critical damping, and resonant analytic solutions',()=>{
  for(const t of [0,.1,1,5]){
    const harmonic=evaluate(DEFAULTS,t);close(harmonic.x,Math.cos(2*t),1e-10);close(harmonic.v,-2*Math.sin(2*t),1e-10);
    close(evaluate({...DEFAULTS,...PRESETS.critical},t).x,(1+2*t)*Math.exp(-2*t),1e-10);
    close(evaluate({...DEFAULTS,...PRESETS.undamped},t).x,.2*t*Math.sin(2*t),1e-10);
  }
});
test('finite energy balances and dissipative free motion for every preset',()=>{
  for(const preset of Object.values(PRESETS)){
    const p={...DEFAULTS,...preset},rows=trajectory(p);
    for(const r of rows){for(const v of Object.values(r))assert.ok(Number.isFinite(v));assert.ok(Math.abs(r.balance)<1e-6);assert.ok(r.Q>=-1e-9);}
    if(p.mode==='damped')for(let i=1;i<rows.length;i++)assert.ok(rows[i].E<=rows[i-1].E+1e-9);
  }
});
test('phase, damping class, resonant singularity, equilibrium, and bounds',()=>{
  assert.equal(classification({...DEFAULTS,...PRESETS.critical}),'Critically damped');
  assert.equal(classification({...DEFAULTS,...PRESETS.overdamped}),'Overdamped');
  assert.equal(response({...DEFAULTS,...PRESETS.undamped}),Infinity);
  assert.equal(response({}),0);
  const p={...DEFAULTS,mode:'driven',phase:90};close(evaluate(p,0).F,0,1e-12);
  for(const r of trajectory({...DEFAULTS,x0:0,v0:0},20))assert.equal(r.x,0);
  for(const raw of [{m:0},{k:NaN},{mode:'bad'},{ratio:0},{cycles:13}])assert.throws(()=>parameters(raw));
  assert.throws(()=>evaluate(DEFAULTS,-1));assert.throws(()=>trajectory(DEFAULTS,19));
  assert.equal(scales(DEFAULTS).c,0);
  assert.equal(csv(DEFAULTS,trajectory(DEFAULTS,20)).trim().split('\n').length,23);
});
