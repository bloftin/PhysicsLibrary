import {create,expmDependencies,multiplyDependencies} from 'mathjs';
const {expm,multiply}=create({...expmDependencies,...multiplyDependencies});

export const DEFAULTS = Object.freeze({mode:'harmonic',m:1,k:4,zeta:0.12,force:0.8,ratio:1,phase:0,x0:1,v0:0,cycles:8});
export const PRESETS = Object.freeze({
  release: {label:'Free release',mode:'harmonic',x0:1,v0:0},
  kick: {label:'Velocity kick',mode:'harmonic',x0:0,v0:2},
  damped: {label:'Weak damping',mode:'damped',zeta:0.12},
  critical: {label:'Critical return',mode:'damped',zeta:1},
  overdamped: {label:'Overdamped return',mode:'damped',zeta:1.6},
  resonance: {label:'Driven resonance',mode:'driven',zeta:0.12,x0:0,force:0.8,ratio:1},
  undamped: {label:'Undamped resonance',mode:'driven',zeta:0,x0:0,force:0.8,ratio:1},
  beats: {label:'Driven transient',mode:'driven',zeta:0.03,force:0.4,ratio:0.85}
});
export function parameters(raw={}) {
  const p={...DEFAULTS,...raw};
  if (!['harmonic','damped','driven'].includes(p.mode)) throw new Error('Unknown oscillator mode');
  const bounds={m:[0.25,5],k:[1,40],zeta:[0,2],force:[0,4],ratio:[0.1,3],phase:[-180,180],x0:[-1.5,1.5],v0:[-3,3],cycles:[2,12]};
  for (const [key,[min,max]] of Object.entries(bounds)) {
    if (!Number.isFinite(p[key]) || p[key]<min || p[key]>max) throw new Error(`Invalid ${key}`);
  }
  return p;
}
export function scales(raw) {
  const p=parameters(raw), omega0=Math.sqrt(p.k/p.m), period=2*Math.PI/omega0;
  const zeta=p.mode==='harmonic'?0:p.zeta;
  return {omega0,period,f0:1/period,zeta,c:2*zeta*Math.sqrt(p.m*p.k),
    omega:p.ratio*omega0,force:p.mode==='driven'?p.force:0,duration:p.cycles*period};
}
export function classification(raw) {
  const s=scales(raw);
  return s.zeta===0?'Undamped':s.zeta<1?'Underdamped':s.zeta===1?'Critically damped':'Overdamped';
}
export function response(raw={},ratio) {
  const p=parameters(raw),s=scales(p),omega=(ratio??p.ratio)*s.omega0;
  const denominator=Math.hypot(p.k-p.m*omega*omega,s.c*omega);
  return denominator<1e-12*p.k&&s.force>0?Infinity:s.force===0?0:s.force/denominator;
}
export function generator(raw) {
  const p=parameters(raw),s=scales(p);
  const a=[[0,1,0,0],[-p.k/p.m,-s.c/p.m,s.force/p.m,0],[0,0,0,-s.omega],[0,0,s.omega,0]];
  const g=Array.from({length:22},()=>Array(22).fill(0));
  for(let i=0;i<4;i++)for(let j=0;j<4;j++)g[i][j]=a[i][j];
  // Lift z_i*z_j into a linear system so work and heat integrate exactly too.
  for(let i=0;i<4;i++)for(let j=0;j<4;j++)for(let b=0;b<4;b++) {
    g[4+4*i+j][4+4*b+j]+=a[i][b];
    g[4+4*i+j][4+4*i+b]+=a[j][b];
  }
  g[20][4+4+1]=s.c;
  g[21][4+4+2]=s.force;
  return g;
}
export function initial(raw) {
  const p=parameters(raw),phi=p.phase*Math.PI/180,z=[p.x0,p.v0,Math.cos(phi),Math.sin(phi)];
  return [...z,...z.flatMap(a=>z.map(b=>a*b)),0,0];
}
function unpack(p,s,z,t) {
  const [x,v,cos]=z,K=0.5*p.m*v*v,U=0.5*p.k*x*x,E=K+U,Q=z[20],W=z[21],F=s.force*cos;
  return {t,x,v,a:(F-s.c*v-p.k*x)/p.m,K,U,E,Q,W,F,balance:E+Q-W-(0.5*p.m*p.v0**2+0.5*p.k*p.x0**2)};
}
export function evaluate(raw,t) {
  const p=parameters(raw),s=scales(p);
  if(!Number.isFinite(t)||t<0||t>s.duration+1e-8)throw new Error('Invalid time');
  const transition=expm(generator(p).map(row=>row.map(value=>value*t))).toArray();
  return unpack(p,s,multiply(transition,initial(p)),t);
}
export function trajectory(raw,count=1200) {
  const p=parameters(raw),s=scales(p);
  if(!Number.isInteger(count)||count<20||count>4000)throw new Error('Invalid sample count');
  const dt=s.duration/count,transition=expm(generator(p).map(row=>row.map(value=>value*dt))).toArray();
  let z=initial(p);
  const rows=[unpack(p,s,z,0)];
  for(let i=1;i<=count;i++) {z=multiply(transition,z);rows.push(unpack(p,s,z,i*dt));}
  return rows;
}
export function csv(p,rows) {
  return '# '+JSON.stringify(parameters(p))+'\n'+'time_s,x_m,v_m_s,a_m_s2,kinetic_J,potential_J,mechanical_J,dissipated_J,drive_work_J,drive_force_N,balance_error_J\n'+
    rows.map(r=>[r.t,r.x,r.v,r.a,r.K,r.U,r.E,r.Q,r.W,r.F,r.balance].map(v=>v.toPrecision(15)).join(',')).join('\n')+'\n';
}
