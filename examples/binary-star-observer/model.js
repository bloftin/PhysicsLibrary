import { kepler3 } from 'astronomia/kepler';
import venn from 'venn.js';
import fmin from 'fmin';
import grid from './limb-grid.json' with {type:'json'};

export const TAU=2*Math.PI, DEG=Math.PI/180;
export const DEFAULT={i:87,s:.28,k:.55,j:.35,e:0,w:0,q:.65,phase:.25,limb:false};
export const PRESETS={
  twins:{i:90,s:.24,k:1,j:1,e:0,w:0,q:1,phase:.25},
  unequal:{...DEFAULT},
  grazing:{i:78,s:.24,k:.65,j:.55,e:0,w:0,q:.75,phase:.25},
  missed:{i:65,s:.24,k:1,j:1,e:0,w:0,q:1,phase:.25},
  eccentric:{i:79,s:.16,k:.7,j:.45,e:.5,w:60,q:.7,phase:.031},
  article:{i:85,s:.186019,k:1,j:.7,e:0,w:0,q:1,phase:.25}
};
export const wrap=x=>((x%1)+1)%1;
const clamp=(x,lo,hi)=>Math.max(lo,Math.min(hi,x));
const root=(f,a,b)=>fmin.bisect(f,a,b,{tolerance:1e-12,maxIterations:100});
export function valid(p){return Object.values(p).every(v=>typeof v!=='number'||Number.isFinite(v)) && p.s>0 && p.s<1-p.e && p.e>=0&&p.e<=.8&&p.i>=0&&p.i<=90&&p.k>=.25&&p.k<=4&&p.j>0&&p.q>0;}
export function radii(p){return {r1:p.s/(1+p.k),r2:p.s*p.k/(1+p.k)};}
export function atAnomaly(p,nu){
  const r=(1-p.e*p.e)/(1+p.e*Math.cos(nu)),u=nu+p.w*DEG;
  const relative=[r*Math.cos(u),r*Math.sin(u)*Math.cos(p.i*DEG),r*Math.sin(u)*Math.sin(p.i*DEG)];
  return {relative,star1:relative.map(v=>-p.q*v/(1+p.q)),star2:relative.map(v=>v/(1+p.q)),d:Math.hypot(relative[0],relative[1]),nu};
}
export function phaseAt(p,nu){
  const E=2*Math.atan2(Math.sqrt(1-p.e)*Math.sin(nu/2),Math.sqrt(1+p.e)*Math.cos(nu/2));
  return wrap((E-p.e*Math.sin(E))/TAU);
}
export function state(p,phase=p.phase){
  const E=kepler3(p.e,TAU*wrap(phase));
  const nu=2*Math.atan2(Math.sqrt(1+p.e)*Math.sin(E/2),Math.sqrt(1-p.e)*Math.cos(E/2));
  return atAnomaly(p,nu);
}
export function limbSurvival(k,x){
  if(x>=1)return 1;
  if(k>=1 && x*(1+k)<=k-1)return 0;
  const a=clamp(Math.log(k/grid.kmin)/Math.log(grid.kmax/grid.kmin)*(grid.nk-1),0,grid.nk-1);
  const impact=clamp(x,0,1)*(1+k),inner=Math.abs(1-k);
  const contactCoordinate=impact<inner ? .5*impact/inner : .5+(impact-inner)/(4*Math.min(1,k));
  const b=contactCoordinate*(grid.nx-1),i=Math.min(Math.floor(a),grid.nk-2),j=Math.min(Math.floor(b),grid.nx-2),t=a-i,v=b-j;
  const ix=i*grid.nx+j;
  return (1-t)*((1-v)*grid.values[ix]+v*grid.values[ix+1])+t*((1-v)*grid.values[ix+grid.nx]+v*grid.values[ix+grid.nx+1]);
}
export function flux(p,v=state(p)){
  const {r1,r2}=radii(p),f1=r1*r1,f2=p.j*r2*r2;
  if(v.d>=p.s)return 1;
  if(p.limb){
    return v.relative[2]>=0 ? (f1*limbSurvival(p.k,v.d/p.s)+f2)/(f1+f2) : (f1+f2*limbSurvival(1/p.k,v.d/p.s))/(f1+f2);
  }
  const area=venn.circleOverlap(r1,r2,v.d);
  return clamp(1-area*(v.relative[2]>=0?1:p.j)/(Math.PI*(f1+f2)),0,1);
}
export function outcome(p,v=state(p)){
  if(v.d>=p.s)return 'No eclipse';
  const {r1,r2}=radii(p),behind=v.relative[2]>=0?1:2,rb=behind===1?r1:r2,rf=behind===1?r2:r1;
  return `${v.d+rb<=rf?'Total eclipse':v.d+rf<=rb?'Full transit':'Partial eclipse'}: star ${behind} behind`;
}

// Maximize the allowed cos^2(i) over each line-of-sight half-orbit.
// Detached stars give opposite derivative signs at the half-orbit endpoints.
export function probability(p,radius=p.s){
  if(radius===0)return {a:0,b:0,any:0,both:0,ua:Math.PI/2,ub:3*Math.PI/2};
  const w=p.w*DEG,S=radius/(1-p.e*p.e);
  const f=u=>Math.cos(u)-S*S*(1+p.e*Math.cos(u-w))*(Math.cos(u)+p.e*Math.cos(w));
  const ua=root(f,0,Math.PI),ub=root(f,Math.PI,TAU);
  const limit=u=>{
    const r=(1-p.e*p.e)/(1+p.e*Math.cos(u-w));
    return Math.sqrt(clamp(((radius/r)**2-Math.cos(u)**2)/Math.sin(u)**2,0,1));
  };
  const a=limit(ua),b=limit(ub);
  return {a,b,any:Math.max(a,b),both:Math.min(a,b),ua,ub};
}
export function events(p){
  const pr=probability(p),mu=Math.cos(p.i*DEG),w=p.w*DEG;
  return [[0,Math.PI,pr.ua,pr.a,1],[Math.PI,TAU,pr.ub,pr.b,2]].flatMap(([lo,hi,uc,limit,behind])=>{
    if(mu>=limit-1e-12)return [];
    const separation=u=>atAnomaly(p,u-w).d-p.s;
    const left=root(separation,lo,uc),right=root(separation,uc,hi);
    const si2=Math.sin(p.i*DEG)**2;
    const derivative=u=>p.e*Math.sin(u-w)*(1-si2*Math.sin(u)**2)-(1+p.e*Math.cos(u-w))*si2*Math.sin(u)*Math.cos(u);
    const mid=root(derivative,left,right);
    const start=phaseAt(p,left-w),end=phaseAt(p,right-w),phase=phaseAt(p,mid-w);
    return [{behind,start,end,phase,duration:wrap(end-start),depth:1-flux(p,atAnomaly(p,mid-w)),left,right,mid}];
  });
}
export function totalCoverageProbability(p){
  const {r1,r2}=radii(p),pr=probability(p,Math.abs(r1-r2));
  return r2>r1?pr.a:r1>r2?pr.b:0;
}
export function curve(p){
  const phases=new Set([0,1]);
  for(let n=0;n<512;n++)phases.add(n/512);
  // Sampling within contacts catches brief periastron eclipses that uniform time samples miss.
  for(const ev of events(p)){
    for(let n=0;n<=100;n++)phases.add(wrap(ev.start+ev.duration*n/100));
    phases.add(ev.phase);
  }
  return [...phases].sort((a,b)=>a-b).map(phase=>({phase,flux:flux(p,state(p,phase))}));
}
export function orientationCount(p,n=2400){
  const pr=probability(p);let both=0,only=0;
  for(let j=0;j<n;j++){
    const mu=Math.abs(1-2*(j+.5)/n);
    if(mu<pr.both)both++;else if(mu<pr.any)only++;
  }
  return {both,only,none:n-both-only,n};
}
export function pole(p){return [0,-Math.sin(p.i*DEG),Math.cos(p.i*DEG)];}
