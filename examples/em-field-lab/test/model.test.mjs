import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULT,PRESETS,C,TAU,basis,scales,evaluate,physical,probes,moveProbe,snapshot,history,quantity,dot,csv,validate,sampler} from '../model.js';
const close=(a,b,tolerance=1e-11)=>assert.ok(Math.abs(a-b)<=tolerance*Math.max(1,Math.abs(b)),`${a} != ${b}`);
test('all 1820 independent Julia samples, frames and physical scales agree',()=>{
  const [head,...lines]=readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split(/\r?\n/),keys=head.split(',');assert.equal(lines.length,1820);
  for(const line of lines){const row=Object.fromEntries(line.split(',').map((v,i)=>[keys[i],i<2?v:+v])),p={...DEFAULT,...Object.fromEntries(Object.keys(DEFAULT).filter(k=>k!=='time').map(k=>[k,row[k]]))};
    const r=[row.rx,row.ry,row.rz],v=evaluate(p,r,row.time),frame=basis(p),s=scales(p);close(v.psi,row.psi);close(v.magnitude,row.magnitude);v.E.forEach((x,i)=>close(x,[row.ex,row.ey,row.ez][i]));frame.n.forEach((x,i)=>close(x,[row.nx,row.ny,row.nz][i]));frame.e.forEach((x,i)=>close(x,[row.ux,row.uy,row.uz][i]));close(s.lambda,row.lambda);close(s.period,row.period);sampler(p).at(r,row.time).E.forEach((x,i)=>close(x,v.E[i]));
  }
});
test('unit orthogonal frames for every polar angle, azimuth and transverse rotation',()=>{
  for(const theta of [0,25,55,90,132,180])for(const phi of [0,35,90,300,360])for(const beta of [0,25,90,175,180]){const p={...DEFAULT,theta,phi,beta},f=basis(p);close(dot(f.n,f.n),1);close(dot(f.e,f.e),1);close(dot(f.n,f.e),0);const v=evaluate(p,[.3,-.4,.7],.37);close(dot(v.E,f.n),0);close(Math.hypot(...v.E),v.magnitude);}
});
test('article example, sign reversal, rotated and reverse propagation examples',()=>{
  const v=evaluate(DEFAULT,[0,0,0],.5);close(v.psi,-5);assert.deepEqual(v.E,[-5,-0,-0]);close(v.magnitude,5);close(evaluate(DEFAULT,[0,0,.25],0).psi,0);
  close(evaluate(PRESETS.rotated,[0,0,0],0).E[1],5);close(evaluate(PRESETS.reverse,[0,0,0],0).E[0],5);
  const time=.12;close(evaluate(DEFAULT,[0,0,time],time).psi,5);close(evaluate(PRESETS.reverse,[0,0,-time],time).psi,5);
});
test('fixed-probe delayed histories and whole-wavelength phase ambiguity',()=>{
  for(const model of Object.values(PRESETS))for(const spacing of [0,.25,.5,1]){const p={...model,spacing},r=probes(p);const before=JSON.stringify(r);for(let time=0;time<=2;time+=.013){close(evaluate(p,r.b,time).psi,evaluate(p,r.a,time-spacing).psi);if(spacing===1)close(evaluate(p,r.b,time).psi,evaluate(p,r.a,time).psi);}assert.equal(JSON.stringify(probes(p)),before);}
});
test('pattern advection, transverse uniformity and normalized wave equation',()=>{
  const p=PRESETS.oblique,f=basis(p),r=[.12,.23,.31],time=.27,h=1e-4;
  for(let j=0;j<30;j++){const d=j/29;close(evaluate(p,r.map((x,i)=>x+d*f.n[i]),time+d).psi,evaluate(p,r,time).psi);close(evaluate(p,r.map((x,i)=>x+d*f.e[i]),time).psi,evaluate(p,r,time).psi);}
  const value=evaluate(p,r,time).psi,dtt=(evaluate(p,r,time+h).psi-2*value+evaluate(p,r,time-h).psi)/h**2;
  const dss=(evaluate(p,r.map((x,i)=>x+h*f.n[i]),time).psi-2*value+evaluate(p,r.map((x,i)=>x-h*f.n[i]),time).psi)/h**2;close(dtt,dss,1e-7);close(dtt,-(TAU**2)*value,1e-7);
});
test('frequency rescales metres and seconds without altering normalized fields',()=>{
  for(const frequency of [10,100,1575.42,2000]){const p={...PRESETS.oblique,frequency},s=scales(p),r=[.1,.2,.3],time=.71,v=evaluate(p,r,time);close(s.lambda*s.f,C);close(s.period*s.f,1);physical(p,r.map(x=>x*s.lambda),time*s.period).E.forEach((x,i)=>close(x,v.E[i]));}
});
test('zero field, histories, snapshot and export remain finite and signed',()=>{
  for(const row of history(PRESETS.zero))assert.ok(row.a===0&&row.b===0);
  const p=PRESETS.oblique;for(const key of ['psi','ex','ey','ez','magnitude'])for(const row of history(p,key)){assert.ok(Number.isFinite(row.a));if(key==='magnitude')assert.ok(row.a>=0);}
  assert.equal(snapshot(p)[0].s,-2);assert.equal(snapshot(p).at(-1).s,2);assert.throws(()=>quantity(evaluate(p,[0,0,0]),'unknown'),RangeError);
  const rows=csv(p).trim().split('\n');assert.equal(rows.length,1027);const size=rows[0].split(',').length;assert.ok(rows.every(row=>row.split(',').length===size));assert.match(rows[0],/time_s,x_m,y_m,z_m/);
});
test('input guards',()=>{
  for(const change of [{frequency:0},{frequency:2001},{theta:181},{amplitude:-1},{x:1},{spacing:2},{slice:2},{phase:NaN},{time:Infinity}])assert.throws(()=>validate({...DEFAULT,...change}),RangeError);
});
test('snapshot probe selection is bounded along propagation and preserves transverse offset',()=>{
  for(const p of Object.values(PRESETS)){const {n}=basis(p),r=probes(p).a,s=dot(n,r),before=r.map((v,j)=>v-s*n[j]);for(const target of [-2,-.4,0,.1,2]){const next=moveProbe(p,target),projection=dot(n,next);assert.ok(next.every(v=>Math.abs(v)<=.5));next.forEach((v,j)=>close(v-projection*n[j],before[j]));}}
  assert.throws(()=>moveProbe(DEFAULT,NaN),RangeError);
});
