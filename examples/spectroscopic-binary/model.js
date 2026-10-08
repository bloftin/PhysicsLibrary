import {kepler3} from 'astronomia/kepler';
import {binaryRoot} from 'astronomia/iterate';

export const TAU=2*Math.PI,DEG=Math.PI/180,DAY=86400,AU=149597870.7,MU_SUN=1.3271244e11,C=299792.458,REST=500;
export const GAUSSIAN_FWHM=2*Math.sqrt(2*Math.log(2));
export const DEFAULT={m1:1.2,q:.7,period:12,i:65,e:.15,w:45,gamma:20,light:.55,width:12,resolution:60000,sb2:true,phase:0};
export const PRESETS={
  unequal:{...DEFAULT},
  twins:{...DEFAULT,m1:1,q:1,period:12,i:80,e:0,w:0,gamma:0,light:1},
  eccentric:{...DEFAULT,q:.55,period:35,i:70,e:.65,w:45,light:.45},
  faceon:{...DEFAULT,i:0,e:.3},
  sb1:{...DEFAULT,q:.6,period:20,i:60,e:.3,w:120,gamma:-15,light:.15,sb2:false},
  blended:{...DEFAULT,q:1,e:0,w:0,gamma:0,light:1,resolution:3000,phase:.17}
};
export const wrap=x=>((x%1)+1)%1;
export function validate(p){
  for(const key of ['m1','q','period','i','e','w','gamma','light','width','resolution','phase'])if(!Number.isFinite(p[key]))throw new RangeError(key+' must be finite');
  if(p.m1<=0||p.q<=0||p.period<=0||p.i<0||p.i>90||p.e<0||p.e>.8||p.light<0||p.width<=0||p.resolution<1000||typeof p.sb2!=='boolean')throw new RangeError('Invalid binary or spectrum parameters');
  return p;
}
export function elements(p){
  validate(p);
  const m2=p.m1*p.q,period=p.period*DAY,n=TAU/period,a=Math.cbrt(MU_SUN*(p.m1+m2)/n**2),a1=a*p.q/(1+p.q),a2=a/(1+p.q);
  const factor=n/Math.sqrt(1-p.e*p.e),sin=Math.sin(p.i*DEG),k1=a1*factor*sin,k2=a2*factor*sin;
  const c=period*(1-p.e*p.e)**1.5/(TAU*MU_SUN);
  return {m2,n,a,a1,a2,k1,k2,f:c*k1**3,m1sin:c*(k1+k2)**2*k2,m2sin:c*(k1+k2)**2*k1,asin:(k1+k2)/factor,signal:sin>1e-10};
}
export function atAnomaly(p,nu){
  const el=elements(p),w=p.w*DEG,i=p.i*DEG,r=(1-p.e*p.e)/(1+p.e*Math.cos(nu));
  const x=r*Math.cos(nu),y=r*Math.sin(nu),factor=el.n*el.a/Math.sqrt(1-p.e*p.e);
  const vx=-factor*Math.sin(nu),vy=factor*(p.e+Math.cos(nu));
  const rotate=(x,y)=>[x*Math.cos(w)-y*Math.sin(w),(x*Math.sin(w)+y*Math.cos(w))*Math.cos(i),(x*Math.sin(w)+y*Math.cos(w))*Math.sin(i)];
  const relative=rotate(x,y),velocity=rotate(vx,vy),f1=-p.q/(1+p.q),f2=1/(1+p.q);
  const r1=relative.map(v=>v*f1),r2=relative.map(v=>v*f2),v1=velocity.map(v=>v*f1),v2=velocity.map(v=>v*f2);
  // Earth is on +Z: positive barycentric vZ approaches Earth, hence negative RV.
  return {...el,nu,relative,r1,r2,v1,v2,rv1:p.gamma-v1[2],rv2:p.gamma-v2[2]};
}
export function state(p,phase=p.phase){
  const E=kepler3(p.e,TAU*wrap(phase)),nu=2*Math.atan2(Math.sqrt(1+p.e)*Math.sin(E/2),Math.sqrt(1-p.e)*Math.cos(E/2));
  return atAnomaly(p,nu);
}
export function phaseAt(p,nu){
  const E=2*Math.atan2(Math.sqrt(1-p.e)*Math.sin(nu/2),Math.sqrt(1+p.e)*Math.cos(nu/2));return wrap((E-p.e*Math.sin(E))/TAU);
}
export const wavelength=rv=>REST*(1+rv/C);
export const opticalVelocity=lambda=>C*(lambda/REST-1);
export function lineShape(p){
  const intrinsic=p.width/GAUSSIAN_FWHM,instrument=C/(p.resolution*GAUSSIAN_FWHM),sigma=Math.hypot(intrinsic,instrument);
  return {sigma,depth:.65*intrinsic/sigma,fwhm:GAUSSIAN_FWHM*sigma};
}
export function spectrum(p,velocity,v=state(p)){
  const {sigma,depth}=lineShape(p),weight1=1/(1+p.light),weight2=p.light/(1+p.light);
  const a=depth*weight1*Math.exp(-.5*((velocity-v.rv1)/sigma)**2);
  const b=p.sb2?depth*weight2*Math.exp(-.5*((velocity-v.rv2)/sigma)**2):0;
  return {combined:1-a-b,component1:1-a,component2:1-b};
}
export function velocityDomain(p){
  const el=elements(p),offset=p.e*Math.cos(p.w*DEG),padding=4*lineShape(p).sigma;
  const extrema=[p.gamma,p.gamma+el.k1*(offset-1),p.gamma+el.k1*(offset+1)];
  if(p.sb2)extrema.push(p.gamma-el.k2*(offset-1),p.gamma-el.k2*(offset+1));
  const span=Math.max(25,(Math.max(...extrema)-Math.min(...extrema))/2+padding),center=(Math.max(...extrema)+Math.min(...extrema))/2;
  return [Math.min(0,center-span)-5,Math.max(0,center+span)+5];
}
export function rvCurve(p,count=512){
  const phases=new Set([0,1]);for(let n=0;n<count;n++)phases.add(n/count);
  // Extra true-anomaly samples retain rapid periastron structure at high e.
  for(let n=0;n<512;n++)phases.add(phaseAt(p,n*TAU/512));
  return [...phases].sort((a,b)=>a-b).map(phase=>({phase,...state(p,phase)}));
}
export function companionMass(f,m1,i=90){
  if(!Number.isFinite(f)||f<0||!Number.isFinite(m1)||m1<=0||!Number.isFinite(i)||i<=0||i>90)throw new RangeError('Mass inversion requires f >= 0, M1 > 0 and 0 < i <= 90');
  if(f===0)return 0;
  const sin3=Math.sin(i*DEG)**3,fn=m2=>m2**3*sin3/(m1+m2)**2-f;
  let high=Math.max(m1,2*f/sin3);while(fn(high)<0)high*=2;
  return binaryRoot(fn,0,high);
}
export function infer(p,inclination,assumedPrimary){
  const el=elements(p);if(!el.signal)return {q:null,m1:null,m2:null,minimum:null};
  if(!Number.isFinite(inclination)||inclination<=0||inclination>90)throw new RangeError('Inclination hypothesis must be positive');
  if(p.sb2){const sin3=Math.sin(inclination*DEG)**3;return {q:el.k1/el.k2,m1:el.m1sin/sin3,m2:el.m2sin/sin3,minimum:el.m2sin};}
  return {q:null,m1:assumedPrimary,m2:companionMass(el.f,assumedPrimary,inclination),minimum:companionMass(el.f,assumedPrimary)};
}
export function csv(p){
  const rows=['phase,time_day,rv1_km_s,rv2_model_km_s,lambda1_nm,lambda2_model_nm,secondary_lines,m1_solar,q,period_day,inclination_deg,eccentricity,omega_deg,gamma_km_s'];
  for(const v of rvCurve(p))rows.push([v.phase,v.phase*p.period,v.rv1,v.rv2,wavelength(v.rv1),wavelength(v.rv2),p.sb2?1:0,p.m1,p.q,p.period,p.i,p.e,p.w,p.gamma].join(','));
  return rows.join('\n')+'\n';
}
