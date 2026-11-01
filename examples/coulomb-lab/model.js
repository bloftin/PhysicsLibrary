export const EPSILON_0 = 8.8541878188e-12;
export const K = 1 / (4 * Math.PI * EPSILON_0);
export const BOUND = 2.5, VIEW = 3, MIN_SEPARATION = .3, MASK = .12;
export const PRESETS = { dipole:'Dipole', like:'Like charges', unequal:'Unequal opposite charges', triangle:'Three-charge triangle', quadrupole:'Quadrupole', balance:'Three-charge balance', positive:'One positive source', negative:'One negative source', six:'Six charges', zero:'Zero source charges' };
const charge = (x, y, microC) => ({ x, y, q: microC * 1e-6 });
export function preset(id = 'dipole') {
  if (!Object.hasOwn(PRESETS, id)) throw new RangeError('Unknown configuration.');
  let charges = [charge(-1,0,1),charge(1,0,-1)];
  if (id === 'like') charges[1].q = 1e-6;
  if (id === 'unequal') charges[1].q = -2e-6;
  if (id === 'triangle') charges = [charge(-1,-.7,1),charge(1,-.7,1),charge(0,1,-1)];
  if (id === 'quadrupole') charges = [charge(-1,-1,1),charge(1,-1,-1),charge(1,1,1),charge(-1,1,-1)];
  if (id === 'balance') charges = [charge(-1,0,1),charge(0,0,.5),charge(1,0,1)];
  if (id === 'positive' || id === 'negative') charges = [charge(0,0,id === 'positive' ? 1 : -1),charge(2,0,0)];
  if (id === 'six') charges = Array.from({length:6},(_,i)=>charge(1.5*Math.cos(i*Math.PI/3),1.5*Math.sin(i*Math.PI/3),i%2?-1:1));
  if (id === 'zero') charges = [charge(-1,0,0),charge(1,0,0)];
  return validate({ charges, selected:id==='balance'?1:0, probe:{x:0,y:1.7},testQ:1e-6 });
}
export function validate(raw) {
  const p = { ...raw, charges:raw.charges.map(c=>({...c})),probe:{...raw.probe} };
  if (p.charges.length<2||p.charges.length>6||!Number.isInteger(p.selected)||p.selected<0||p.selected>=p.charges.length) throw new RangeError('Select two to six charges.');
  for (const c of p.charges) if (![c.x,c.y,c.q].every(Number.isFinite)||Math.abs(c.x)>BOUND+1e-12||Math.abs(c.y)>BOUND+1e-12||Math.abs(c.q)>5e-6+1e-15) throw new RangeError('Charge positions must be within ±2.5 m and charges within ±5 μC.');
  for (let i=0;i<p.charges.length;i++) for (let j=i+1;j<p.charges.length;j++) if (distance(p.charges[i],p.charges[j])<MIN_SEPARATION-1e-10) throw new RangeError('Keep charge centers at least 0.30 m apart. No force softening is used.');
  if (![p.probe.x,p.probe.y,p.testQ].every(Number.isFinite)||Math.abs(p.probe.x)>2.8||Math.abs(p.probe.y)>2.8||Math.abs(p.testQ)>2e-6+1e-15) throw new RangeError('Probe must remain within ±2.8 m; test charge range is ±2 μC.');
  return p;
}
export const distance = (a,b) => Math.hypot(a.x-b.x,a.y-b.y);
export function fieldAt(charges,point,omit=-1) {
  let x=0,y=0,scale=0;
  for (const [i,c] of charges.entries()) {
    if (i===omit||c.q===0) continue;
    const dx=point.x-c.x,dy=point.y-c.y,r=Math.hypot(dx,dy);
    if (r===0) return null;
    const strength=K*c.q/(r*r); x+=strength*dx/r; y+=strength*dy/r; scale+=Math.abs(strength);
  }
  return {x,y,magnitude:Math.hypot(x,y),scale};
}
export function pairForce(charges,i,j) {
  if (i===j) return {x:0,y:0,magnitude:0};
  const a=charges[i],b=charges[j],r=distance(a,b);
  if (!(r>0)) return null;
  const scalar=K*a.q*b.q/(r*r);
  const x=scalar*(a.x-b.x)/r,y=scalar*(a.y-b.y)/r;
  return {x,y,magnitude:Math.abs(scalar),r};
}
export function forces(charges) {
  const result=charges.map(()=>({x:0,y:0}));
  // Compute each pair once so its reaction is exactly the negative contribution.
  for(let i=0;i<charges.length;i++)for(let j=i+1;j<charges.length;j++){
    const f=pairForce(charges,i,j);if(!f)throw new RangeError('Coincident source positions.');
    result[i].x+=f.x;result[i].y+=f.y;result[j].x-=f.x;result[j].y-=f.y;
  }
  return result.map(f=>({...f,magnitude:Math.hypot(f.x,f.y)}));
}
export function probeResult(p) {
  const closest = Math.min(...p.charges.filter(c=>c.q!==0).map(c=>distance(c,p.probe)),Infinity);
  if(closest<MASK)return {status:closest===0?'singular':'masked',field:null,force:null};
  const field=fieldAt(p.charges,p.probe);
  return {status:'ready',field,force:{x:p.testQ*field.x,y:p.testQ*field.y,magnitude:Math.abs(p.testQ)*field.magnitude}};
}
export function resizeCharges(raw,count) {
  if(!Number.isInteger(count)||count<2||count>6)throw new RangeError('Select two to six charges.');
  const p=validate(raw);p.charges=p.charges.slice(0,count);
  const candidates=[];for(const y of [1.5,-1.5,.75,-.75,0,2.25,-2.25])for(const x of [0,1.5,-1.5,.75,-.75,2.25,-2.25])candidates.push({x,y});
  while(p.charges.length<count){const spot=candidates.find(s=>p.charges.every(c=>distance(s,c)>=.6));if(!spot)throw new RangeError('No room for another charge.');p.charges.push({...spot,q:p.charges.length%2?-1e-6:1e-6});}
  p.selected=Math.min(p.selected,count-1);return validate(p);
}
export function separationRange(p) {
  const [a,b]=p.charges,r=distance(a,b),ux=(b.x-a.x)/r,uy=(b.y-a.y)/r,mx=(a.x+b.x)/2,my=(a.y+b.y)/2;
  const max=2*Math.min(Math.abs(ux)>1e-12?(BOUND-Math.abs(mx))/Math.abs(ux):Infinity,Math.abs(uy)>1e-12?(BOUND-Math.abs(my))/Math.abs(uy):Infinity);
  return {min:MIN_SEPARATION,max,r,ux,uy,mx,my};
}
export function setSeparation(raw,r) {
  const p=validate(raw);if(p.charges.length!==2)throw new RangeError('Separation control is for two charges.');
  const s=separationRange(p);if(!Number.isFinite(r)||r<s.min-1e-10||r>s.max+1e-10)throw new RangeError('Requested separation does not fit inside the position limits.');
  for(let i=0;i<2;i++){const sign=i?1:-1;p.charges[i].x=s.mx+sign*r*s.ux/2;p.charges[i].y=s.my+sign*r*s.uy/2;}return validate(p);
}
export function inverseSquare(p,count=181) {
  const product=Math.abs(p.charges[0].q*p.charges[1].q),end=Math.max(5,distance(p.charges[0],p.charges[1]));
  return Array.from({length:count},(_,i)=>{const r=.3+(end-.3)*i/(count-1);return {r,force:K*product/(r*r)};});
}
export function csv(raw) {
  const p=validate(raw), fs=forces(p.charges), rows=['index,q_C,x_m,y_m,Fx_N,Fy_N,F_N,E_external_x_N_per_C,E_external_y_N_per_C'];
  p.charges.forEach((c,i)=>{const e=fieldAt(p.charges,c,i);rows.push([i+1,c.q,c.x,c.y,fs[i].x,fs[i].y,fs[i].magnitude,e.x,e.y].join(','));});
  return rows.join('\n')+'\n';
}
