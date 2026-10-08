import {Vector3} from 'three';
export const C=299792458,TAU=2*Math.PI,DEG=Math.PI/180;
export const DEFAULT={amplitude:5,frequency:100,theta:0,phi:0,beta:0,phase:0,x:0,y:0,z:0,spacing:.25,slice:0,time:0};
export const PRESETS={
  article:{...DEFAULT},
  reverse:{...DEFAULT,theta:180,beta:180},
  oblique:{...DEFAULT,theta:55,phi:35,beta:25,x:.2,y:-.2,z:.1},
  rotated:{...DEFAULT,beta:90},
  gps:{...DEFAULT,frequency:1575.42},
  zero:{...DEFAULT,amplitude:0}
};
export function validate(p){
  for(const key of Object.keys(DEFAULT))if(!Number.isFinite(p[key]))throw new RangeError(key+' must be finite');
  if(p.amplitude<0||p.amplitude>10||p.frequency<10||p.frequency>2000||p.theta<0||p.theta>180||p.spacing<0||p.spacing>1||Math.max(Math.abs(p.x),Math.abs(p.y),Math.abs(p.z))>.5||Math.abs(p.slice)>1.1)throw new RangeError('Invalid wave parameters');
  return p;
}
export function basis(p){
  const theta=p.theta*DEG,phi=p.phi*DEG,beta=p.beta*DEG;
  const n=new Vector3(Math.sin(theta)*Math.cos(phi),Math.sin(theta)*Math.sin(phi),Math.cos(theta));
  const u=new Vector3(Math.cos(theta)*Math.cos(phi),Math.cos(theta)*Math.sin(phi),-Math.sin(theta)),v=new Vector3(-Math.sin(phi),Math.cos(phi),0);
  const e=u.multiplyScalar(Math.cos(beta)).addScaledVector(v,Math.sin(beta));
  return {n:n.toArray(),e:e.toArray()};
}
export const dot=(a,b)=>new Vector3(...a).dot(new Vector3(...b));
export function scales(p){validate(p);const f=p.frequency*1e6,lambda=C/f,period=1/f;return {f,lambda,period,k:TAU/lambda,omega:TAU*f};}
export function sampler(p){
  const {n,e}=basis(p),offset=p.phase*DEG;
  return {n,e,at(r,time=p.time){const argument=TAU*(n[0]*r[0]+n[1]*r[1]+n[2]*r[2]-time)+offset,psi=p.amplitude*Math.cos(argument);return {psi,E:e.map(v=>v*psi),magnitude:Math.abs(psi),argument};}};
}
export function evaluate(p,r,time=p.time){return sampler(p).at(r,time);}
export function physical(p,rMetres,timeSeconds){const {lambda,period}=scales(p);return evaluate(p,rMetres.map(v=>v/lambda),timeSeconds/period);}
export function probes(p){const a=[p.x,p.y,p.z],{n}=basis(p);return {a,b:a.map((v,i)=>v+p.spacing*n[i])};}
export function moveProbe(p,projectedPosition){
  if(!Number.isFinite(projectedPosition))throw new RangeError('Probe coordinate must be finite');
  const {n}=basis(p),r=[p.x,p.y,p.z],s0=dot(n,r),perp=r.map((v,j)=>v-s0*n[j]);let lo=-Infinity,hi=Infinity;
  for(let j=0;j<3;j++)if(Math.abs(n[j])>1e-12){const a=(-.5-perp[j])/n[j],b=(.5-perp[j])/n[j];lo=Math.max(lo,Math.min(a,b));hi=Math.min(hi,Math.max(a,b));}
  const s=Math.max(lo,Math.min(hi,projectedPosition));return perp.map((v,j)=>Math.max(-.5,Math.min(.5,v+s*n[j])));
}
export function quantity(v,key){if(key==='psi')return v.psi;if(key==='magnitude')return v.magnitude;const index={ex:0,ey:1,ez:2}[key];if(index===undefined)throw new RangeError('Unknown field quantity');return v.E[index];}
export function snapshot(p,count=512){const {n}=basis(p);return Array.from({length:count+1},(_,j)=>{const s=-2+4*j/count;return {s,...evaluate(p,n.map(v=>v*s))};});}
export function history(p,key='psi',count=512){const {a,b}=probes(p);return Array.from({length:count+1},(_,j)=>{const time=2*j/count;return {time,a:quantity(evaluate(p,a,time),key),b:quantity(evaluate(p,b,time),key)};});}
export function csv(p){
  const {a,b}=probes(p),{lambda,period}=scales(p),rows=['probe,t_over_T,time_s,x_m,y_m,z_m,psi_V_m,Ex_V_m,Ey_V_m,Ez_V_m,magnitude_V_m,frequency_MHz,amplitude_V_m,theta_deg,phi_deg,beta_deg,phase_deg'];
  for(let j=0;j<=512;j++)for(const [name,r] of [['A',a],['B',b]]){const time=2*j/512,v=evaluate(p,r,time);rows.push([name,time,time*period,...r.map(x=>x*lambda),v.psi,...v.E,v.magnitude,p.frequency,p.amplitude,p.theta,p.phi,p.beta,p.phase].join(','));}
  return rows.join('\n')+'\n';
}
