import {bisect} from './vendor/bisect.js';

export const DEFAULTS=Object.freeze({shape:'rounded',A:.02,T:2,axis:1,unit:'cm',level:.5,f2:4});
export const PRESETS={return:{params:{A:.02,T:2,unit:'cm'},fraction:.5},four:{params:{A:.003,T:.25,unit:'mm'},fraction:0},twenty:{params:{A:.003,T:.05,unit:'mm'},fraction:0},zero:{params:{A:0},fraction:0}};
export const UNITS={m:{factor:1,label:'m'},cm:{factor:100,label:'cm'},mm:{factor:1000,label:'mm'}};
export const SHAPES={rounded:{label:'Rounded',knots:[0,.25,.5,.75,1],slopes:[6,0,-6,0,6]},triangle:{label:'Triangle',knots:[0,.25,.5,.75,1]},uneven:{label:'Uneven timing',knots:[0,.15,.5,.65,1],slopes:[4,0,-4,0,4]}};
const heights=[0,1,0,-1,0];
export function parameters(raw={}){const p={...DEFAULTS,...raw};if(!Object.hasOwn(SHAPES,p.shape)||!Object.hasOwn(UNITS,p.unit)||![1,-1].includes(p.axis))throw new RangeError('Unknown motion or coordinate choice.');for(const [k,lo,hi] of [['A',0,.05],['T',.05,4],['level',-.9,.9],['f2',.25,20]])if(!Number.isFinite(p[k])||p[k]<lo||p[k]>hi)throw new RangeError('Invalid '+k+'.');return p;}
export function cycle(shape,s){
  if(!Object.hasOwn(SHAPES,shape)||!Number.isFinite(s))throw new RangeError('Invalid repeating coordinate.');
  const def=SHAPES[shape],r=((s%1)+1)%1,k=def.knots;let i=0;while(i<3&&r>=k[i+1])i++;const d=k[i+1]-k[i],z=(r-k[i])/d,a=heights[i],b=heights[i+1];let value,slope;
  if(shape==='triangle'){value=a+(b-a)*z;slope=(b-a)/d;if(Math.abs(r-.25)<1e-11||Math.abs(r-.75)<1e-11)slope=null;}
  else{const m=def.slopes[i]*d,n=def.slopes[i+1]*d,c=3*(b-a)-2*m-n,e=2*(a-b)+m+n;value=a+z*(m+z*(c+z*e));slope=(m+z*(2*c+3*z*e))/d;}
  return {value,slope,leg:i,partial:Math.abs(value-a),r};
}
export function sample(raw={},t=0){
  const p=parameters(raw);if(!Number.isFinite(t)||t<0||t>1e5)throw new RangeError('Time must be finite and nonnegative.');
  const s=t/p.T,c=cycle(p.shape,s),physical=p.A*c.value,u=p.axis*physical,velocity=p.A===0?0:c.slope===null?null:p.axis*p.A*c.slope/p.T;
  const distance=p.A*(4*Math.floor(s)+c.leg+c.partial),cycles=p.A===0?0:Math.floor(s+1e-10),crossings=p.A===0?0:Math.floor(2*s+1e-10);
  return {t,u,physical,velocity,distance,cycles,crossings,f:p.A===0?null:1/p.T,period:p.A===0?null:p.T,progress:p.A===0?0:s,direction:velocity===null?'corner':p.A===0||Math.abs(c.slope)<1e-10?'still':p.axis*c.slope>0?'positive':'negative'};
}
export function history(raw={},count=1201,seconds){const p=parameters(raw);if(!Number.isInteger(count)||count<3||count>20001)throw new RangeError('Invalid sample count.');const end=seconds===undefined?3*p.T:seconds;if(!Number.isFinite(end)||end<=0||end>100)throw new RangeError('Invalid time window.');return Array.from({length:count},(_,i)=>sample(p,end*i/(count-1)));}
export function crossingPair(raw={}){
  const p=parameters(raw);if(p.A===0)return null;const def=SHAPES[p.shape],target=p.axis*p.level,intervals=target>=0?[[0,def.knots[1]],[def.knots[1],.5]]:[[.5,def.knots[3]],[def.knots[3],1]];
  const roots=Math.abs(target)<1e-13?[0,.5]:intervals.map(([a,b])=>bisect(s=>cycle(p.shape,s).value-target,a,b,{tolerance:1e-13,maxIterations:150}));
  const first=sample(p,roots[0]*p.T),second=sample(p,roots[1]*p.T),repeat=sample(p,(roots[0]+1)*p.T);return {first,second,repeat,gap:second.t-first.t};
}
export function frequencyWindow(raw={}){const p=parameters(raw);return {first:sample(p,1),second:sample({...p,T:1/p.f2},1),firstHz:p.A===0?null:1/p.T,secondHz:p.A===0?null:p.f2};}
export function csv(raw={}){const p=parameters(raw);return 'shape,A_m,T_s,coordinate_sign,time_s,displacement_m,physical_coordinate_m,velocity_m_per_s,velocity_defined,distance_m,complete_cycles,equilibrium_crossings,observed_f_Hz\n'+history(p).map(d=>[p.shape,p.A,p.T,p.axis,d.t,d.u,d.physical,d.velocity===null?'':d.velocity,d.velocity===null?0:1,d.distance,d.cycles,d.crossings,d.f===null?'':d.f].join(',')).join('\n')+'\n';}
