import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULTS,parameters,at,density,curve,trace,minimizer,csv} from '../model.js';
const close=(a,b,tol=2e-10)=>assert.ok(Math.abs(a-b)<=tol*(1+Math.abs(b)),`${a} != ${b}`);
test('574 independently generated Julia reference rows',()=>{
  const lines=readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split(/\r?\n/),keys=lines.shift().split(',');assert.equal(lines.length,574);
  for(const line of lines){const values=line.split(','),row=Object.fromEntries(keys.map((k,i)=>[k,values[i]])),p={mode:row.mode,mean:+row.mean,b:+row.b_input,norm:+row.norm,angle:+row.angle,lambda:+row.lambda},r=at(p),d=density(p,+row.x);
    for(const [key,col] of Object.entries({x:'x',y:'y',yp:'y_prime',eta:'eta',etap:'eta_prime',gJ:'gJ',gK:'gK',scaledK:'minus_lambda_gK',residual:'residual'}))close(d[key],+row[col]);
    for(const [key,col] of Object.entries({a:'a',b:'b',J:'J',K:'K',lambdaFit:'lambda_fit',residualL2:'residual_L2',dJ:'deltaJ',dK:'deltaK'}))close(r[key],+row[col]);
    for(const [vec,cols] of [[r.gJ,['ja','jb']],[r.gK,['ka','kb']],[r.t,['ta','tb']]])for(let i=0;i<2;i++)close(vec[i],+row[cols[i]]);
  }
});
test('normal fitting cannot remove tangential first variation away from stationarity',()=>{
  for(const mode of ['mean','normalization']){const p={...DEFAULTS,mode},r=at(p),fitted=at({...p,lambda:r.lambdaFit});close(fitted.gK[0]*fitted.residual[0]+fitted.gK[1]*fitted.residual[1],0);assert.ok(Math.abs(fitted.dJ)>.1);assert.ok(fitted.residualNorm>.1);close(fitted.dK,0);}
});
test('exact article minimizers, multiplier signs, and energy gaps',()=>{
  for(const mean of [-1,-.5,0,.5,1]){const p=minimizer({...DEFAULTS,mean}),r=at(p);close(r.J,6*mean**2);close(r.lambdaFit,-12*mean);close(r.residualL2,0);for(const d of curve(p))close(d.y,6*mean*d.x*(1-d.x));for(const b of [-1,-.3,.4,1])close(at({...p,b}).J-r.J,18*b*b/5);}
  for(const norm of [.25,1,2])for(const angle of [0,90,180,270,360]){const lambda=angle===90||angle===270?-4:-1,r=at({...DEFAULTS,mode:'normalization',norm,angle,lambda});close(r.residualL2,0);close(r.dJ,0);close(r.K,norm);close(r.J,angle===90||angle===270?4*norm:norm);}
});
test('feasible family and linearized tangent are distinct for normalization',()=>{
  for(const mode of ['mean','normalization']){const p={...DEFAULTS,mode},r=at(p);for(const row of trace(p))close(row.K,r.target);close(r.gK[0]*r.t[0]+r.gK[1]*r.t[1],0);const eps=.01,a=r.a+eps*r.t[0],b=r.b+eps*r.t[1];if(mode==='normalization')close(a*a+b*b-r.K,eps*eps);else close(a,p.mean);}
});
test('sampled first-variation integrals and residual L2 norm',()=>{
  for(const mode of ['mean','normalization']){const p={...DEFAULTS,mode},r=at(p),rows=curve(p,2001),h=r.length/2000;const integrate=fn=>rows.reduce((sum,d,i)=>sum+fn(d)*(i===0||i===2000?.5:1),0)*h;close(integrate(d=>d.gJ*d.eta),r.dJ,2e-5);close(integrate(d=>d.gK*d.eta),0,2e-5);close(Math.sqrt(integrate(d=>d.residual**2)),r.residualL2,2e-5);}
});
test('invalid parameters, endpoint conditions, and export',()=>{
  for(const raw of [{mode:'bad'},{norm:0},{lambda:Infinity},{mean:2},{angle:-1}])assert.throws(()=>parameters(raw));assert.throws(()=>density(DEFAULTS,-1));assert.throws(()=>curve(DEFAULTS,2));for(const mode of ['mean','normalization']){const p={...DEFAULTS,mode};close(density(p,0).y,0);close(density(p,at(p).length).y,0);}
  assert.equal(csv(DEFAULTS).trim().split('\n').length,163);
});
