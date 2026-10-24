import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {csvParse} from 'd3';
import {TAU,parameters,preset,metrics,sample,phase,changeForm,crest,snapshot,history,csv} from '../model.js';
const close=(a,b,tol=2e-12)=>assert.ok(Math.abs(a-b)<tol,`${a} != ${b}`);
test('2856 independent Julia space-time samples, phases and fixed-branch crests',()=>{
 const rows=csvParse(readFileSync(new URL('../reference.csv',import.meta.url),'utf8'));assert.equal(rows.length,2856);
 for(const row of rows){const p=parameters({A:+row.A_m,lambda:+row.lambda_m,f:+row.f_Hz,phi:+row.phi_rad,direction:+row.direction,form:row.form,probe:+row.probe_m}),d=sample(p,+row.x_m,+row.t_s);close(d.u,+row.u_m);close(d.theta,+row.phase_rad);if(row.crest_x_m==='')assert.equal(crest(p,d.t),null);else close(crest(p,d.t).x,+row.crest_x_m);}
});
test('article parameter values and the exact worked event',()=>{
 const one=preset('example1'),m=metrics(one.p);close(m.k,4*Math.PI);close(m.omega,10*Math.PI);close(m.T,.2);assert.equal(one.p.f,5);
 const two=preset('example2'),d=sample(two.p,two.p.probe,two.t);close(d.theta,5*Math.PI/6);close(d.u*100,-Math.sqrt(3));
 const rows=csvParse(readFileSync(new URL('../events.csv',import.meta.url),'utf8'));
 for(const name of ['explore','example1','example2','left','sine','zero']){const c=preset(name),row=rows.find(r=>r.case===name);close(sample(c.p,c.p.probe,c.t).u,+row.u_m);}
});
test('sine/cosine switching preserves the entire physical field and crest trajectory',()=>{
 for(const direction of [-1,1])for(const phi of [-Math.PI,-.7,0,Math.PI/6,Math.PI]){
  const p=parameters({direction,phi}),s=changeForm(p,'sin'),again=changeForm(s,'cos');
  for(const x of [0,.19,1.3,2])for(const t of [0,.25,1,2]){close(sample(s,x,t).u,sample(p,x,t).u);close(sample(again,x,t).u,sample(p,x,t).u);close(crest(s,t).x,crest(p,t).x);}
 }
});
test('periodicity, translation, direction and material-point coordinates',()=>{
 for(const direction of [-1,1]){const p=parameters({direction}),m=metrics(p);for(const x of [0,.3,1.9])for(const t of [0,.2,.9]){
  const d=sample(p,x,t);close(sample(p,x+p.lambda,t).u,d.u);close(sample(p,x,t+m.T).u,d.u);close(sample(p,x+direction*p.lambda*p.f*t,t).u,sample(p,x,0).u);
 }close(crest(p,m.T/4).x-crest(p,0).x,direction*p.lambda/4);assert.equal(crest(p,2).order,crest(p,0).order);}
 const p=parameters();assert.ok(crest(p,2).x>2,'tracked crest leaves the window rather than wrapping');assert.ok(history(p).every(d=>d.x===p.probe));
 const right=parameters({probe:0}),left=parameters({direction:-1,probe:0});close(sample(right,0,.37).u,sample(left,0,.37).u);
});
test('zero field and amplitude-independent generator parameters',()=>{
 const p=parameters({A:0});assert.equal(crest(p,.5),null);assert.equal(metrics(p).observed,false);assert.ok(snapshot(p,.7).every(d=>d.u===0));
 const doubled=parameters({A:.05});assert.equal(metrics(doubled).T,metrics(p).T);assert.equal(metrics(doubled).k,metrics(p).k);
});
test('validation and SI CSV grid',()=>{
 for(const p of [{lambda:0},{f:-1},{A:.06},{probe:3},{direction:0},{form:'bad'},{phi:NaN}])assert.throws(()=>parameters(p));assert.throws(()=>preset('bad'));assert.throws(()=>changeForm(parameters(),'bad'));
 const rows=csvParse(csv(preset('example2').p));assert.equal(rows.length,4225);assert.equal(+rows.at(-1).x_m,2);assert.equal(+rows.at(-1).t_s,2);assert.equal(+rows[0].A_m,.02);assert.ok(rows.every(r=>Number.isFinite(+r.u_m)));
});
