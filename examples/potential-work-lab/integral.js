import { Solver } from 'odex';
import { environment, meterScale, safePath, vertices } from './model.js';
// Integrate E dot dr in volts, then multiply by q. This retains accuracy for electron-scale work.
export function integrate(p,route){
  if(!safePath(p,route))return null;
  let volts=0;
  const vs=vertices(p,route);
  for(let i=1;i<vs.length;i++){
    const a=vs[i-1],b=vs[i],dx=b.x-a.x,dy=b.y-a.y;
    if(dx===0&&dy===0)continue;
    const solver=new Solver(1);solver.absoluteTolerance=solver.relativeTolerance=1e-12;solver.maxStepSize=.05;
    const result=solver.solve(t=>{const e=environment(p,{x:a.x+t*dx,y:a.y+t*dy});return[(e.ex*dx+e.ey*dy)*meterScale(p)];},0,[0],1);
    if(result.outcome!==0||!Number.isFinite(result.y[0]))throw new Error('Work integration did not converge.');
    volts+=result.y[0];
  }
  return {volts,work:p.q*volts};
}
