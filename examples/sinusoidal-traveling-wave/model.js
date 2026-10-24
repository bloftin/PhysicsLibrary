export const TAU=2*Math.PI;
export const BOUNDS=Object.freeze({A:[0,.05],lambda:[.25,2],f:[.5,5],phi:[-Math.PI,Math.PI],probe:[0,2]});
export const PRESETS=Object.freeze({explore:'Explore',example1:'Example 1: parameters',example2:'Example 2: one event',left:'Left-moving wave',sine:'Equivalent sine form',zero:'Zero amplitude'});
export function parameters(raw={}) {
  const p={A:.03,lambda:1,f:1,phi:0,direction:1,form:'cos',probe:.65,...raw};
  for(const [key,[lo,hi]] of Object.entries(BOUNDS))if(!Number.isFinite(p[key])||p[key]<lo-1e-12||p[key]>hi+1e-12)throw new RangeError('Invalid '+key+'.');
  if(![1,-1].includes(p.direction)||!['cos','sin'].includes(p.form))throw new RangeError('Unknown wave direction or form.');
  return p;
}
export function preset(id='explore') {
  if(!Object.hasOwn(PRESETS,id))throw new RangeError('Unknown example.');
  let p=parameters(),t=.15;
  if(id==='example1'){p=parameters({lambda:.5,f:5,phi:Math.PI/6,probe:.75});t=0;}
  if(id==='example2'){p=parameters({A:.02,lambda:2,f:1,phi:Math.PI/3,probe:1});t=.25;}
  if(id==='left')p=parameters({direction:-1,phi:Math.PI/6});
  if(id==='sine')p=parameters({form:'sin',phi:Math.PI/2});
  if(id==='zero')p=parameters({A:0});
  return {p,t};
}
export function metrics(p) {return {k:TAU/p.lambda,omega:TAU*p.f,T:1/p.f,lambda:p.lambda,f:p.f,observed:p.A>0};}
export function phase(p,x,t) {return TAU*x/p.lambda-p.direction*TAU*p.f*t+p.phi;}
export function sample(p,x,t) {
  const theta=phase(p,x,t);
  return {x,t,theta,u:p.A*(p.form==='cos'?Math.cos(theta):Math.sin(theta))};
}
export function wrap(angle) {return ((angle+Math.PI)%TAU+TAU)%TAU-Math.PI;}
export function changeForm(p,form) {
  if(!['cos','sin'].includes(form))throw new RangeError('Unknown wave form.');
  if(form===p.form)return {...p};
  return parameters({...p,form,phi:wrap(p.phi+(form==='sin'?Math.PI/2:-Math.PI/2))});
}
export function crest(p,t) {
  if(p.A===0)return null;
  const {k,omega}=metrics(p), base=p.form==='cos'?0:Math.PI/2;
  // Fix a single phase branch near x=1 at t=0; never wrap it back into view.
  const order=Math.round((k+p.phi-base)/TAU), theta=base+TAU*order;
  return {order,theta,x:(theta+p.direction*omega*t-p.phi)/k};
}
export function snapshot(p,t,count=801) {return Array.from({length:count},(_,i)=>sample(p,2*i/(count-1),t));}
export function history(p,count=801) {return Array.from({length:count},(_,i)=>sample(p,p.probe,2*i/(count-1)));}
export function csv(raw) {
  const p=parameters(raw), m=metrics(p), header='A_m,lambda_m,f_Hz,phi_rad,direction,form,x_m,t_s,u_m,phase_rad,tracked_crest_x_m\n',rows=[];
  for(let j=0;j<=64;j++)for(let i=0;i<=64;i++){
    const t=2*j/64,d=sample(p,2*i/64,t),c=crest(p,t);
    rows.push([p.A,p.lambda,p.f,p.phi,p.direction,p.form,d.x,d.t,d.u,d.theta,c?.x??''].join(','));
  }
  return header+rows.join('\n')+'\n';
}
