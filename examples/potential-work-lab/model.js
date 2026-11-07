export const E_CHARGE = 1.602176634e-19;
export const K = 1 / (4 * Math.PI * 8.8541878188e-12);
export const MASK = .16;
export const PRESETS = {
  plates:'E01: parallel plates', sign:'E01: +5 V, either sign', worked:'E01: negative-charge example',
  electron:'E01: electron gains 3 eV', positive:'Positive point source', negative:'Negative point source',
  dipole:'Dipole: zero V is not zero E', like:'Like sources: zero E is not zero V', zero:'No source field'
};
export function preset(id='plates') {
  if (!Object.hasOwn(PRESETS,id)) throw new RangeError('Unknown example.');
  let p={id,kind:'uniform',voltage:-10,gap:.05,sources:[],q:2e-9,unit:'nC',a:{x:-1,y:0},b:{x:1,y:0},h:{x:0,y:1.15},offset:0};
  if(id==='sign')Object.assign(p,{voltage:5,q:2e-6,unit:'uC'});
  if(id==='worked')Object.assign(p,{voltage:-3,q:-4e-6,unit:'uC',offset:5});
  if(id==='electron')Object.assign(p,{voltage:3,q:-E_CHARGE,unit:'e'});
  if(['positive','negative','dipole','like','zero'].includes(id)){
    Object.assign(p,{kind:'points',q:1e-9,unit:'nC',a:{x:-1.7,y:-1.1},b:{x:1.7,y:-1.1},h:{x:0,y:.6}});
    p.sources=id==='positive'||id==='negative'?[{x:0,y:0,q:(id==='positive'?1:-1)*1e-9}]:id==='zero'?[]:[{x:-1,y:0,q:1e-9},{x:1,y:0,q:(id==='like'?1:-1)*1e-9}];
    if(id==='positive'||id==='negative'){p.a={x:.6,y:0};p.b={x:2,y:0};p.h={x:1.1,y:1.5};}
  }
  return validate(p);
}
export function validate(raw){
  const p=structuredClone(raw);
  if(!['uniform','points'].includes(p.kind)||![p.q,p.offset,p.voltage,p.gap].every(Number.isFinite)||Math.abs(p.q)>10e-6+1e-15||Math.abs(p.offset)>1000||Math.abs(p.voltage)>100||p.gap<.01||p.gap>.2)throw new RangeError('Check charge, voltage, gap and reference limits.');
  for(const point of [p.a,p.b,p.h,...p.sources])if(![point.x,point.y].every(Number.isFinite)||Math.abs(point.x)>2.3||Math.abs(point.y)>2.3)throw new RangeError('Positions must be within -2.3 to +2.3 map units.');
  for(const s of p.sources)if(!Number.isFinite(s.q)||Math.abs(s.q)>5e-9+1e-20)throw new RangeError('Source range is -5 to +5 nC.');
  for(let i=0;i<p.sources.length;i++)for(let j=i+1;j<p.sources.length;j++)if(distance(p.sources[i],p.sources[j])<.4)throw new RangeError('Keep source centers at least 0.40 m apart.');
  return p;
}
export const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
// Uniform-field map units are d/2 meters; point-source map units are meters.
export const meterScale=p=>p.kind==='uniform'?p.gap/2:1;
export function environment(p,point){
  let v=0,ex=0,ey=0;
  if(p.kind==='uniform'){v=p.voltage*(point.x+1)/2;ex=-p.voltage/p.gap;}
  else for(const s of p.sources){
    if(s.q===0)continue;
    const dx=point.x-s.x,dy=point.y-s.y,r=Math.hypot(dx,dy);
    if(r===0)return null;
    v+=K*s.q/r;ex+=K*s.q*dx/(r*r*r);ey+=K*s.q*dy/(r*r*r);
  }
  return {v:v+p.offset,ex,ey,e:Math.hypot(ex,ey)};
}
export function accessible(p,point){return p.kind==='uniform'||p.sources.every(s=>s.q===0||distance(point,s)>=MASK);}
export function vertices(p,route='direct'){
  if(!['direct','bent'].includes(route))throw new RangeError('Unknown path.');
  return route==='bent'?[p.a,p.h,p.b]:[p.a,p.b];
}
export function segmentDistance(p,a,b){
  const dx=b.x-a.x,dy=b.y-a.y,l2=dx*dx+dy*dy,t=l2?Math.max(0,Math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/l2)):0;
  return Math.hypot(p.x-a.x-t*dx,p.y-a.y-t*dy);
}
export function safePath(p,route){
  const vs=vertices(p,route);
  return p.kind==='uniform'||p.sources.every(s=>s.q===0||vs.slice(1).every((b,i)=>segmentDistance(s,vs[i],b)>=MASK));
}
export function pathPoint(p,route,fraction){
  if(!Number.isFinite(fraction)||fraction<0||fraction>1)throw new RangeError('Path fraction must be between 0 and 1.');
  const vs=vertices(p,route),lengths=vs.slice(1).map((b,i)=>distance(vs[i],b)),total=lengths.reduce((a,b)=>a+b,0);
  let remaining=total*fraction;
  for(let i=0;i<lengths.length;i++)if(remaining<=lengths[i]||i===lengths.length-1){const t=lengths[i]?remaining/lengths[i]:0;return{x:vs[i].x+t*(vs[i+1].x-vs[i].x),y:vs[i].y+t*(vs[i+1].y-vs[i].y),length:total*meterScale(p)};}else remaining-=lengths[i];
}
export function endpoints(p){
  if(!accessible(p,p.a)||!accessible(p,p.b))return null;
  const a=environment(p,p.a),b=environment(p,p.b),dv=b.v-a.v,du=p.q*dv;
  return {a,b,dv,du,work:-du,external:du,meter:-dv};
}
export function samples(p,route='direct',count=161){
  if(!safePath(p,route))return [];
  const a=environment(p,p.a);
  return Array.from({length:count},(_,i)=>{const f=i/(count-1),point=pathPoint(p,route,f),e=environment(p,point);return{f,x:point.x,y:point.y,s:f*point.length,v:e.v,u:p.q*e.v,work:p.q*(a.v-e.v),ex:e.ex,ey:e.ey};});
}
export function battery(emf,r,load,rm=1e7){
  if(![emf,r,load,rm].every(Number.isFinite)||emf<0||emf>24||r<0||r>1000||load<1||load>1e6||rm<1||rm>1e10)throw new RangeError('Battery/load values outside supported limits.');
  const parallel=1/(1/load+1/rm),current=emf/(r+parallel),terminal=current*parallel;
  return {current,terminal,loadCurrent:terminal/load,meterCurrent:terminal/rm,internalPower:current*current*r,loadPower:terminal*terminal/load,meterPower:terminal*terminal/rm,sourcePower:emf*current,unloaded:emf*load/(r+load)};
}
export function transfer(n){
  if(!Number.isInteger(n)||Math.abs(n)>20)throw new RangeError('Transfer an integer from -20 to +20 electrons.');
  return {left:n*E_CHARGE,right:-n*E_CHARGE,total:0};
}
export function csv(p,route){
  const rows=['fraction,x_map,y_map,path_m,V_V,U_J,W_electric_J,Ex_V_per_m,Ey_V_per_m'];
  for(const s of samples(p,route))rows.push([s.f,s.x,s.y,s.s,s.v,s.u,s.work,s.ex,s.ey].join(','));
  return rows.join('\n')+'\n';
}
