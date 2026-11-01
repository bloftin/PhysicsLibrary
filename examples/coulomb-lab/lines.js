import { Solver } from 'odex';
import { fieldAt, distance, MASK, VIEW } from './model.js';
const LIMIT = Symbol('trace limit');
export function traceLine(charges, seed, direction = 1) {
  const points=[{...seed}], solver=new Solver(2);
  solver.absoluteTolerance=solver.relativeTolerance=2e-6;
  solver.initialStepSize=.008;solver.maxStepSize=.045;solver.maxSteps=1600;
  let reason='length',hit=null;
  function check(point) {
    if(Math.abs(point.x)>VIEW+.04||Math.abs(point.y)>VIEW+.04){reason='boundary';throw LIMIT;}
    for(const [i,c] of charges.entries())if(c.q!==0&&distance(c,point)<MASK){reason='charge';hit=i;throw LIMIT;}
    const e=fieldAt(charges,point);
    if(!e||e.magnitude<1e-8||e.magnitude<.002*e.scale){reason='null';throw LIMIT;}
    return e;
  }
  try {
    solver.solve((_s,y)=>{const e=check({x:y[0],y:y[1]});return [direction*e.x/e.magnitude,direction*e.y/e.magnitude];},0,[seed.x,seed.y],18,(_n,_a,_b,y)=>{
      const point={x:y[0],y:y[1]};check(point);if(distance(point,points.at(-1))>.004)points.push(point);
    });
  } catch(e) { if(e!==LIMIT)throw e; }
  if(direction<0)points.reverse();
  return {points,reason,hit};
}
export function fieldLines(charges,density=10) {
  const total=charges.reduce((s,c)=>s+Math.abs(c.q)*1e6,0),factor=Math.min(1,140/Math.max(1,total*density)),lines=[];
  const positive=charges.some(c=>c.q>0);
  for(const c of charges) {
    if(c.q===0)continue;
    const n=Math.max(2,Math.round(Math.abs(c.q)*1e6*density*factor));
    for(let i=0;i<n;i++) {
      const angle=2*Math.PI*i/n,seed={x:c.x+(MASK+.025)*Math.cos(angle),y:c.y+(MASK+.025)*Math.sin(angle)};
      const line=traceLine(charges,seed,c.q>0?1:-1);
      // Positive seeds already represent connections to negative sinks. Reverse-seeded
      // negative lines add incoming boundary branches, not duplicate internal connections.
      if(c.q<0&&positive&&line.reason==='charge'&&charges[line.hit]?.q>0)continue;
      if(line.points.length>2)lines.push(line);
    }
  }
  return lines;
}
