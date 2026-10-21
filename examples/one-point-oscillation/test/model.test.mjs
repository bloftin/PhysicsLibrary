import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULTS,SHAPES,UNITS,parameters,cycle,sample,history,crossingPair,frequencyWindow,csv} from '../model.js';
const near=(a,b,tol=1e-9)=>assert.ok(Math.abs(a-b)<tol*Math.max(1,Math.abs(a),Math.abs(b)),`${a} != ${b}`);
function table(file){const [head,...rows]=readFileSync(new URL('../'+file,import.meta.url),'utf8').trim().split(/\r?\n/),keys=head.split(',');return rows.map(row=>Object.fromEntries(row.split(',').map((v,i)=>[keys[i],v])));}
const references=table('reference.csv'),cases=new Map();for(const r of references)cases.set(r.case,{shape:r.shape,A:+r.A,T:+r.T,axis:+r.axis,unit:r.unit,level:+r.level,f2:+r.f2});
test('3612 independent Julia samples, including corners, zero motion, reversal and fast records',()=>{
 assert.equal(references.length,3612);assert.equal(cases.size,12);
 for(const r of references){const d=sample(cases.get(r.case),+r.t);for(const key of ['u','physical','velocity','distance','cycles','crossings','f','period','progress']){if(r[key]==='')assert.equal(d[key],null,`${r.case} ${key}`);else near(d[key],+r[key]);}assert.equal(d.direction,r.direction);}
});
test('independent Julia crossing times, equal displacement and opposite rates',()=>{
 const rows=table('crossings.csv');assert.equal(rows.length,12);
 for(const row of rows){const p=cases.get(row.case),pair=crossingPair(p);if(row.defined==='0'){assert.equal(pair,null);continue;}for(const [key,time,u,v] of [['first','t1','u1','v1'],['second','t2','u2','v2'],['repeat','t_repeat','u_repeat','v_repeat']]){near(pair[key].t,+row[time]);near(pair[key].u,+row[u]);near(pair[key].velocity,+row[v]);}near(pair.gap,+row.gap);near(pair.first.u,p.A*p.level);assert.ok(pair.first.velocity*pair.second.velocity<0);near(pair.repeat.t-pair.first.t,p.T);near(pair.first.velocity,pair.repeat.velocity);assert.ok(pair.gap<p.T);}
});
test('exact distance, amplitude and complete-pattern timing',()=>{
 for(const shape of Object.keys(SHAPES)){const p={...DEFAULTS,shape};near(sample(p,p.T/2).u,0);near(sample(p,p.T/2).distance,2*p.A);assert.equal(sample(p,p.T/2).cycles,0);assert.equal(sample(p,p.T/2).crossings,1);near(sample(p,p.T).distance,4*p.A);assert.equal(sample(p,p.T).crossings,2);assert.equal(sample(p,p.T).cycles,1);const values=history(p,6001);let distance=0;for(let i=1;i<values.length;i++){assert.ok(values[i].distance>=values[i-1].distance-1e-12);assert.ok(Math.abs(values[i].u)<=p.A+1e-12);distance+=Math.abs(values[i].u-values[i-1].u);}near(distance,12*p.A);near(values.at(-1).distance,distance);
 for(const s of [.03,.11,.29,.4,.53,.72,.9]){const t=s*p.T,h=1e-6,d=sample(p,t);near(d.velocity,(sample(p,t+h).u-sample(p,t-h).u)/(2*h),1e-8);near(sample(p,t+p.T).u,d.u);near(sample(p,t+p.T).velocity,d.velocity);}}
});
test('axis and display-unit changes never change the physical trajectory or distance',()=>{
 for(const p of cases.values())for(const t of [0,.11*p.T,.5*p.T,2.91*p.T]){const a=sample(p,t),b=sample({...p,axis:-p.axis},t);near(a.physical,b.physical);near(a.u,-b.u);near(a.distance,b.distance);for(const unit of Object.keys(UNITS))assert.deepEqual(sample({...p,unit},t),a);}
});
test('flat lines have no observed fundamental period; triangle corners have no derivative',()=>{
 const p={...DEFAULTS,A:0};for(const t of [0,.5,1,100]){const d=sample(p,t);assert.equal(d.u,0);assert.equal(d.distance,0);assert.equal(d.period,null);assert.equal(d.f,null);assert.equal(d.cycles,0);assert.equal(d.crossings,0);}assert.equal(crossingPair(p),null);
 assert.equal(sample({...DEFAULTS,shape:'triangle'},DEFAULTS.T/4).velocity,null);assert.equal(sample({...DEFAULTS,shape:'rounded'},DEFAULTS.T/4).velocity,0);
 assert.equal(sample({...DEFAULTS,A:1e-14},.1).direction,'positive','direction does not depend on a velocity unit threshold');
});
test('one-second frequency comparison and bounded, SI-unit CSV',()=>{
 const four=frequencyWindow({...DEFAULTS,T:.25,f2:20});near(four.firstHz,4);near(four.first.progress,4);assert.equal(four.first.cycles,4);near(four.secondHz,20);assert.equal(four.second.cycles,20);const slow=frequencyWindow(DEFAULTS);near(slow.first.progress,.5);assert.equal(slow.first.cycles,0);
 for(const shape of Object.keys(SHAPES)){const text=csv({...DEFAULTS,shape}),rows=text.trim().split('\n');assert.equal(rows.length,1202);assert.equal(new Set(rows.map(r=>r.split(',').length)).size,1);assert.ok(!/NaN|Infinity|undefined/.test(text));assert.equal(csv({...DEFAULTS,shape,unit:'m'}),csv({...DEFAULTS,shape,unit:'mm'}));}
 for(const bad of [{A:-1e-13},{A:.06},{T:0},{T:Infinity},{unit:'km'},{axis:0},{shape:'constructor'},{f2:30},{level:1}])assert.throws(()=>parameters(bad));assert.throws(()=>sample(DEFAULTS,-1));assert.throws(()=>history(DEFAULTS,2));assert.throws(()=>history(DEFAULTS,101,0));
});
