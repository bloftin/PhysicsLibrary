import {create,parseDependencies,derivativeDependencies,sinDependencies,cosDependencies} from 'mathjs';
import {polygonArea, polygonLength} from 'd3';
const {derivative}=create({...parseDependencies,...derivativeDependencies,...sinDependencies,...cosDependencies});

export const DEFAULTS = {mode:1,a:1.5,alpha:60,length:8,perimeter:12,n:6,ratio:-.6,probe:.25};
const bounds = {a:[.5,3],alpha:[15,165],length:[2,16],perimeter:[4,20],n:[3,60],ratio:[-2,1],probe:[-1,1]};
// Differentiate the parametric circle, not y(x): endpoint tangents stay finite.
const expressions = ['R*sin(t)','R*(cos(t)-cos(alpha))'];
const firstNodes = expressions.map(e=>derivative(e,'t',{simplify:false}));
const first = firstNodes.map(node=>node.compile());
const second = firstNodes.map(node=>derivative(node,'t',{simplify:false}).compile());
const areaSlope = derivative('(alpha-sin(alpha)*cos(alpha))/(4*alpha^2)','alpha',{simplify:false}).compile();

export function parameters(raw={}) {
  const p={...DEFAULTS,...raw};
  if(![1,3,4,6].includes(p.mode))throw new RangeError('Unknown exercise');
  for(const [k,[lo,hi]] of Object.entries(bounds))if(!Number.isFinite(p[k])||p[k]<lo||p[k]>hi)throw new RangeError('Invalid '+k);
  if(!Number.isInteger(p.n))throw new RangeError('Sides must be an integer');
  if(p.mode===1&&p.alpha>90)throw new RangeError('The graph arc needs alpha <= 90 degrees');
  return p;
}
export function polygon(P,n) {
  const R=P/(2*n*Math.sin(Math.PI/n)),apothem=P/(2*n*Math.tan(Math.PI/n));
  const vertices=Array.from({length:n},(_,i)=>{const t=2*Math.PI*i/n-Math.PI/2-Math.PI/n;return [R*Math.cos(t),R*Math.sin(t)];});
  return {R,apothem,vertices,area:Math.abs(polygonArea(vertices)),perimeter:polygonLength(vertices),exactArea:P*P/(4*n*Math.tan(Math.PI/n))};
}
export function at(raw={}) {
  const p=parameters(raw);
  if(p.mode===6){const P=p.perimeter,circle=P*P/(4*Math.PI),square=P*P/16,poly=polygon(P,p.n);return {...p,P,circle,square,poly,area:poly.area,efficiency:poly.area/circle};}
  const alpha=(p.mode===3?90:p.alpha)*Math.PI/180;
  const R=p.mode===4?p.length/(2*alpha):p.a/Math.sin(alpha);
  const a=R*Math.sin(alpha),length=2*R*alpha,area=R*R*(alpha-Math.sin(alpha)*Math.cos(alpha));
  const lambda=(p.mode===1?p.ratio:-1)*R,kappa=-1/R,residual=1-lambda*kappa;
  return {...p,alpha,R,a,length,area,lambda,kappa,residual,height:R*(1-Math.cos(alpha)),bound:length*length/(2*Math.PI),efficiency:area/(length*length/(2*Math.PI)),slope:areaSlope.evaluate({alpha}),graph:alpha<=Math.PI/2+1e-12};
}
export function point(raw,u) {
  if(!Number.isFinite(u)||Math.abs(u)>1)throw new RangeError('Invalid probe');
  const r=at(raw);if(r.mode===6)throw new RangeError('No smooth polygon curvature');
  const t=r.alpha*u,scope={R:r.R,alpha:r.alpha,t},[dx,dy]=first.map(f=>f.evaluate(scope)),[ddx,ddy]=second.map(f=>f.evaluate(scope));
  const speed=Math.hypot(dx,dy);
  return {x:r.R*Math.sin(t),y:r.R*(Math.cos(t)-Math.cos(r.alpha)),tx:dx/speed,ty:dy/speed,nx:-dy/speed,ny:dx/speed,kappa:(dx*ddy-dy*ddx)/speed**3};
}
export function curve(raw,count=241) {
  if(!Number.isInteger(count)||count<3||count>10001)throw new RangeError('Invalid sample count');
  return Array.from({length:count},(_,i)=>{const u=-1+2*i/(count-1);return {u,...point(raw,u)};});
}
export function trace(raw,count=151) {
  const p=parameters(raw);
  if(p.mode===6)return Array.from({length:58},(_,i)=>({x:i+3,y:Math.PI/((i+3)*Math.tan(Math.PI/(i+3)))}));
  if(p.mode===1)return Array.from({length:count},(_,i)=>({x:i/(count-1),y:at(p).lambda*at(p).kappa}));
  if(p.mode===3)return Array.from({length:count},(_,i)=>{const degrees=15+75*i/(count-1),alpha=degrees*Math.PI/180;return {x:degrees,y:alpha/Math.sin(alpha)};});
  return Array.from({length:count},(_,i)=>{const alpha=15+150*i/(count-1),r=at({...p,mode:4,alpha});return {x:alpha,y:r.efficiency};});
}
export function csv(raw) {
  const r=at(raw);
  if(r.mode===6)return 'sides,perimeter,area,circle_area,area_fraction\n'+trace(raw).map(d=>`${d.x},${r.P},${polygon(r.P,d.x).area},${r.circle},${d.y}`).join('\n')+'\n';
  return 'exercise,u,x,y,tangent_x,tangent_y,normal_x,normal_y,signed_curvature,radius,curved_length,area,lambda,EL_residual\n'+curve(raw).map(d=>[r.mode,d.u,d.x,d.y,d.tx,d.ty,d.nx,d.ny,d.kappa,r.R,r.length,r.area,r.lambda,r.residual].join(',')).join('\n')+'\n';
}
