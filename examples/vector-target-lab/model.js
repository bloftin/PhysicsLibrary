import {bisect} from './vendor/bisect.js';

export const DEFAULTS=Object.freeze({mode:'plane',ax:-3.4,ay:-2.2,az:3.8,T:2,tilt:28,yaw:15,offset:0,radius:1.5,rx:1.8,ry:1.1,rz:1.5,u:.8,v:.6,lon:30,lat:25,bend:0,psi:20});
export const FIELDS=[
  ['ax','Start x',-5,5,.01,'start'],['ay','Start y',-5,5,.01,'start'],['az','Start z',-5,5,.01,'start'],['T','Fixed duration T',.5,4,.01,'start'],
  ['tilt','Tilt (degrees)',0,75,.1,'target'],['yaw','Azimuth (degrees)',-180,180,.1,'target'],['offset','Center offset',-1.5,1.5,.01,'target'],
  ['radius','Sphere radius',.5,2.5,.01,'target'],['rx','Ellipsoid a',.5,2.5,.01,'target'],['ry','Ellipsoid b',.5,2.5,.01,'target'],['rz','Ellipsoid c',.5,2.5,.01,'target'],
  ['u','Plane coordinate u',-10,10,.01,'endpoint'],['v','Plane coordinate v',-10,10,.01,'endpoint'],['lon','Longitude (degrees)',-180,180,.1,'endpoint'],['lat','Latitude (degrees)',-90,90,.1,'endpoint'],
  ['bend','Vertical bend h',-1,1,.01,'endpoint'],['psi','Variation angle (degrees)',-180,180,.1,'endpoint']];
export const add=(a,b)=>a.map((v,i)=>v+b[i]),sub=(a,b)=>a.map((v,i)=>v-b[i]),mul=(a,s)=>a.map(v=>v*s),dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0),norm=a=>Math.hypot(...a);
export const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]],unit=a=>mul(a,1/norm(a));
const rad=d=>d*Math.PI/180;
export function frame(p){const b=rad(p.tilt),a=rad(p.yaw),e1=[Math.cos(b)*Math.cos(a),Math.cos(b)*Math.sin(a),-Math.sin(b)],e2=[-Math.sin(a),Math.cos(a),0],n=[Math.sin(b)*Math.cos(a),Math.sin(b)*Math.sin(a),Math.cos(b)];return {e1,e2,n,C:mul(n,p.offset)};}
export function world(f,v){return add(add(mul(f.e1,v[0]),mul(f.e2,v[1])),mul(f.n,v[2]));}
export function local(f,v){return [dot(v,f.e1),dot(v,f.e2),dot(v,f.n)];}
export function parameters(raw={}){
  const p={...DEFAULTS,...raw};if(!['plane','sphere','ellipsoid'].includes(p.mode))throw new RangeError('Unknown target');
  for(const [k,,lo,hi] of FIELDS)if(!Number.isFinite(p[k])||p[k]<lo||p[k]>hi)throw new RangeError('Invalid '+k);
  if(p.mode!=='plane'){const f=frame(p),a=local(f,sub([p.ax,p.ay,p.az],f.C)),axes=p.mode==='sphere'?[p.radius,p.radius,p.radius]:[p.rx,p.ry,p.rz];if(a.reduce((s,v,i)=>s+(v/axes[i])**2,0)<=1+1e-8)throw new RangeError('The start must stay outside the curved target.');}
  return p;
}
export function surface(p,x,y){const f=frame(p);if(p.mode==='plane')return add(f.C,world(f,[x,y,0]));const axes=p.mode==='sphere'?[p.radius,p.radius,p.radius]:[p.rx,p.ry,p.rz],a=rad(x),b=rad(y);return add(f.C,world(f,[axes[0]*Math.cos(b)*Math.cos(a),axes[1]*Math.cos(b)*Math.sin(a),axes[2]*Math.sin(b)]));}
export function closest(raw={}){
  const p=parameters(raw),f=frame(p),A=[p.ax,p.ay,p.az],a=local(f,sub(A,f.C));
  if(p.mode==='plane')return add(f.C,world(f,[a[0],a[1],0]));
  if(p.mode==='sphere')return add(f.C,world(f,mul(a,p.radius/norm(a))));
  const d=[p.rx**2,p.ry**2,p.rz**2],equation=l=>a.reduce((s,v,i)=>s+d[i]*v*v/(d[i]+l)**2,0)-1;
  const l=bisect(equation,0,Math.max(p.rx,p.ry,p.rz)*norm(a),{maxIterations:200,tolerance:1e-12});
  return add(f.C,world(f,a.map((v,i)=>d[i]*v/(d[i]+l))));
}
export function at(raw={}){
  const p=parameters(raw),f=frame(p),A=[p.ax,p.ay,p.az],B=surface(p,p.mode==='plane'?p.u:p.lon,p.mode==='plane'?p.v:p.lat),star=closest(p),delta=sub(B,A),axes=p.mode==='sphere'?[p.radius,p.radius,p.radius]:[p.rx,p.ry,p.rz],b=local(f,sub(B,f.C));
  const grad=p.mode==='plane'?f.n:world(f,b.map((v,i)=>2*v/axes[i]**2)),n=unit(grad);
  const t1=p.mode==='plane'?f.e1:unit(cross(Math.abs(n[2])<.9?[0,0,1]:[1,0,0],n)),t2=cross(n,t1),eta=add(mul(t1,Math.cos(rad(p.psi))),mul(t2,Math.sin(rad(p.psi))));
  const momentum=sub(mul(delta,1/p.T),[0,0,Math.PI*p.bend/p.T]),pn=mul(n,dot(momentum,n)),pt=sub(momentum,pn),lambda=dot(momentum,grad)/dot(grad,grad);
  const straight=dot(delta,delta)/(2*p.T),bendCost=Math.PI**2*p.bend**2/(4*p.T),J=straight+bendCost,Jmin=dot(sub(star,A),sub(star,A))/(2*p.T),boundary=dot(momentum,eta),interior=Math.PI*p.bend*eta[2]/p.T,total=dot(delta,eta)/p.T;
  const residual=Math.PI**2*Math.abs(p.bend)/(Math.sqrt(2)*p.T**2),tangent=norm(pt),stationary=residual<1e-8&&tangent<1e-7,minimum=stationary&&Math.abs(J-Jmin)<1e-7;
  return {...p,...f,A,B,star,n,t1,t2,eta,grad,momentum,pn,pt,lambda,J,Jmin,gap:Math.max(0,J-Jmin),straight,bendCost,boundary,interior,total,residual,tangent,stationary,minimum,coordinates:local(f,sub(B,f.C))};
}
function sampleAt(r,s){const delta=sub(r.B,r.A),q=add(add(r.A,mul(delta,s)),[0,0,r.bend*Math.sin(Math.PI*s)]),velocity=add(mul(delta,1/r.T),[0,0,Math.PI*r.bend/r.T*Math.cos(Math.PI*s)]),acceleration=[0,0,-(Math.PI**2)*r.bend/r.T**2*Math.sin(Math.PI*s)],qstar=add(r.A,mul(sub(r.star,r.A),s));return {s,time:s*r.T,q,velocity,acceleration,qstar};}
export function sample(raw,s){if(!Number.isFinite(s)||s<0||s>1)throw new RangeError('Invalid path position');return sampleAt(at(raw),s);}
export function curve(raw,count=121){if(!Number.isInteger(count)||count<3||count>10001)throw new RangeError('Invalid sample count');const r=at(raw);return Array.from({length:count},(_,i)=>sampleAt(r,i/(count-1)));}
export function minimizer(raw){const p=parameters(raw),f=frame(p),b=local(f,sub(closest(p),f.C));if(p.mode==='plane')return {...p,u:b[0],v:b[1],bend:0};const axes=p.mode==='sphere'?[p.radius,p.radius,p.radius]:[p.rx,p.ry,p.rz],v=b.map((x,i)=>x/axes[i]);return {...p,lon:Math.atan2(v[1],v[0])*180/Math.PI,lat:Math.asin(Math.max(-1,Math.min(1,v[2])))*180/Math.PI,bend:0};}
export function variation(raw,angle){const r=at({...raw,psi:angle});return {angle,boundary:r.boundary,interior:r.interior,total:r.total};}
export function csv(raw){const r=at(raw);return 'target,s,time,x,y,z,vx,vy,vz,ax,ay,az,minimum_x,minimum_y,minimum_z,J,J_min,tangential_momentum,interior_RMS,endpoint_boundary_variation,interior_variation,total_variation\n'+curve(raw).map(d=>[r.mode,d.s,d.time,...d.q,...d.velocity,...d.acceleration,...d.qstar,r.J,r.Jmin,r.tangent,r.residual,r.boundary,r.interior,r.total].join(',')).join('\n')+'\n';}
