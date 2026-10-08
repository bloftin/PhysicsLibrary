import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULT,PRESETS,TAU,DEG,DAY,C,REST,state,elements,atAnomaly,phaseAt,lineShape,spectrum,wavelength,opticalVelocity,companionMass,infer,rvCurve,csv,validate} from '../model.js';
const close=(a,b,tolerance=1e-9)=>assert.ok(Math.abs(a-b)<=tolerance*Math.max(1,Math.abs(b)),`${a} != ${b}`);
const table=name=>{const [header,...rows]=readFileSync(new URL('../'+name,import.meta.url),'utf8').trim().split(/\r?\n/);return rows.map(row=>Object.fromEntries(row.split(',').map((value,i)=>[header.split(',')[i],i?+value:value])));};
const configs={};
test('all states agree with independent Julia bisection and eccentric-anomaly velocities',()=>{
  for(const row of table('reference.csv')){
    const p={...DEFAULT,...Object.fromEntries(['m1','q','period','i','e','w','gamma','light','width','resolution'].map(k=>[k,row[k]])),sb2:!!row.sb2};configs[row.case]=p;
    const v=state(p,row.phase);for(const key of ['k1','k2','f','m1sin','m2sin','a','rv1','rv2'])close(v[key],row[key]);
    for(const key of ['r1','r2','v1','v2'])v[key].forEach((value,n)=>close(value,row[key+'xyz'[n]]));
  }
});
test('Gaussian convolution and Doppler shifts agree with Julia reference spectra',()=>{
  for(const row of table('spectrum-reference.csv')){
    const s=spectrum(configs[row.case],row.velocity,state(configs[row.case],row.phase));
    for(const key of ['combined','component1','component2'])close(s[key],row[key],2e-12);
    close(wavelength(row.velocity),row.lambda,2e-12);
  }
});
test('barycentric conservation, velocity derivatives and positive recession sign',()=>{
  for(const p of Object.values(configs))for(let n=0;n<100;n++){
    const phase=n/100,v=state(p,phase),h=1e-6,left=state(p,phase-h),right=state(p,phase+h);
    for(let axis=0;axis<3;axis++){close(v.r1[axis]+p.q*v.r2[axis],0);close(v.v1[axis]+p.q*v.v2[axis],0);close((right.r1[axis]-left.r1[axis])*v.a/(2*h*p.period*DAY),v.v1[axis],2e-7);}
    close(v.rv1,p.gamma-v.v1[2]);close(v.rv2,p.gamma-v.v2[2]);
    const r=v.r2.map((x,j)=>(x-v.r1[j])*v.a),vel=v.v2.map((x,j)=>x-v.v1[j]);close(vel.reduce((s,x)=>s+x*x,0)/2-1.3271244e11*(p.m1+v.m2)/Math.hypot(...r),-1.3271244e11*(p.m1+v.m2)/(2*v.a));
  }
});
test('K amplitudes, mass function, minimum masses and eccentric extrema',()=>{
  for(const p of Object.values(configs)){
    const el=elements(p);close(el.k1,p.q*el.k2);close(el.m1sin,p.m1*Math.sin(p.i*DEG)**3);close(el.m2sin,el.m2*Math.sin(p.i*DEG)**3);close(el.f,el.m2**3*Math.sin(p.i*DEG)**3/(p.m1+el.m2)**2);
    const max=atAnomaly(p,-p.w*DEG),min=atAnomaly(p,Math.PI-p.w*DEG);close(max.rv1,p.gamma+el.k1*(1+p.e*Math.cos(p.w*DEG)));close(min.rv1,p.gamma+el.k1*(-1+p.e*Math.cos(p.w*DEG)));
    if(el.signal){const result=infer(p,p.i,p.m1);close(result.m1,p.m1);close(result.m2,el.m2);assert.ok(result.minimum<=el.m2+1e-10);}
  }
});
test('gamma is a TIME average, not the eccentric curve extrema midpoint',()=>{
  const p=PRESETS.eccentric;let mean=0;const count=20000;for(let n=0;n<count;n++)mean+=state(p,n/count).rv1/count;close(mean,p.gamma,1e-8);
  const el=elements(p);assert.ok(Math.abs(el.k1*p.e*Math.cos(p.w*DEG))>1);
});
test('face-on spectra cannot measure mass ratio; separate hypotheses do not mutate observations',()=>{
  const p={...PRESETS.faceon};assert.deepEqual(infer(p,65,1.2),{q:null,m1:null,m2:null,minimum:null});for(let n=0;n<10;n++)close(state(p,n/10).rv1,p.gamma);
  const model={...DEFAULT},before=csv(model),a=infer(model,90,1.2),b=infer(model,30,1.2);close(b.m1/a.m1,8);assert.equal(csv(model),before);
  assert.equal(infer(PRESETS.sb1,60,1.2).q,null);close(companionMass(elements(PRESETS.sb1).f,1.2,60),.72);
});
test('positive RV redshifts, instrumental convolution preserves Gaussian equivalent width',()=>{
  assert.ok(wavelength(100)>REST);assert.ok(wavelength(-100)<REST);close(opticalVelocity(wavelength(100)),100);
  const sharp=lineShape({...DEFAULT,resolution:150000}),blurry=lineShape({...DEFAULT,resolution:3000});assert.ok(blurry.sigma>sharp.sigma);assert.ok(blurry.depth<sharp.depth);close(blurry.sigma*blurry.depth,sharp.sigma*sharp.depth);
  const p={...PRESETS.sb1};for(let phase=0;phase<=1;phase+=.1)for(let velocity=-300;velocity<300;velocity+=3){const s=spectrum(p,velocity,state(p,phase));close(s.component2,1);close(s.combined,s.component1);assert.ok(s.combined>=.35&&s.combined<=1);}
  const zero=spectrum({...DEFAULT,light:0},state(DEFAULT).rv2);close(zero.combined,zero.component1);
});
test('phase inversion, orbit closure, CSV shape and guards',()=>{
  for(const p of Object.values(PRESETS)){for(let n=0;n<64;n++){const nu=n*TAU/64,v=state(p,phaseAt(p,nu)),a=atAnomaly(p,nu);close(v.rv1,a.rv1);}close(state(p,0).rv1,state(p,1).rv1);const curve=rvCurve(p);assert.equal(curve[0].phase,0);assert.equal(curve.at(-1).phase,1);}
  const rows=csv(PRESETS.sb1).trim().split('\n');assert.match(rows[0],/rv2_model_km_s/);assert.ok(rows.slice(1).every(row=>row.split(',')[6]==='0'));
  for(const values of [{e:1},{m1:0},{i:100},{q:NaN},{resolution:0}])assert.throws(()=>validate({...DEFAULT,...values}),RangeError);
  assert.throws(()=>companionMass(.1,1,0),RangeError);assert.throws(()=>companionMass(-1,1),RangeError);close(companionMass(0,1),0);
});
