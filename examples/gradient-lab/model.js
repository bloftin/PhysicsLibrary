import {create,parseDependencies,derivativeDependencies,expDependencies,sinDependencies,cosDependencies} from 'mathjs';
const {parse,derivative}=create({...parseDependencies,...derivativeDependencies,...expDependencies,...sinDependencies,...cosDependencies});
export const DOMAIN=2.5;
export const FIELDS=Object.freeze({
  plane:{label:'Tilted plane',expression:'a*(x+b*y)',formula:'\u03b1(x + \u03b2y)'},
  bowl:{label:'Elliptic bowl',expression:'a*(x^2+b*y^2)/2',formula:'\u03b1(x\u00b2 + \u03b2y\u00b2)/2'},
  saddle:{label:'Saddle',expression:'a*(x^2-b*y^2)/2',formula:'\u03b1(x\u00b2 \u2212 \u03b2y\u00b2)/2'},
  gaussian:{label:'Gaussian hill',expression:'a*exp(-b*(x^2+y^2))',formula:'\u03b1 exp[\u2212\u03b2(x\u00b2 + y\u00b2)]'},
  waves:{label:'Waves',expression:'a*sin(b*x)*cos(b*y)',formula:'\u03b1 sin(\u03b2x) cos(\u03b2y)'},
  wells:{label:'Double well',expression:'a*(x^4/4-x^2/2+b*y^2/2)',formula:'\u03b1(x\u2074/4 \u2212 x\u00b2/2 + \u03b2y\u00b2/2)'}
});
export const DEFAULTS=Object.freeze({field:'bowl',a:1,b:1.3,x:-.9,y:.6,angle:25});
const compiled=new Map();
export function parameters(raw={}) {
  const p={...DEFAULTS,...raw};
  if(!Object.hasOwn(FIELDS,p.field))throw new Error('Unknown scalar field');
  for(const [key,min,max] of [['a',.25,2],['b',.25,2],['x',-DOMAIN,DOMAIN],['y',-DOMAIN,DOMAIN],['angle',-180,180]])
    if(!Number.isFinite(p[key])||p[key]<min||p[key]>max)throw new Error(`Invalid ${key}`);
  return p;
}
function functions(field){
  if(!compiled.has(field)){
    const f=parse(FIELDS[field].expression);
    compiled.set(field,{f:f.compile(),fx:derivative(f,'x',{simplify:false}).compile(),fy:derivative(f,'y',{simplify:false}).compile()});
  }
  return compiled.get(field);
}
export function sample(raw={},x,y){
  const p=parameters(raw);x??=p.x;y??=p.y;
  if(!Number.isFinite(x)||!Number.isFinite(y)||Math.abs(x)>DOMAIN+1e-10||Math.abs(y)>DOMAIN+1e-10)throw new Error('Point outside domain');
  const f=functions(p.field),scope={a:p.a,b:p.b,x,y},value=f.f.evaluate(scope),fx=f.fx.evaluate(scope),fy=f.fy.evaluate(scope);
  const magnitude=Math.hypot(fx,fy),theta=p.angle*Math.PI/180,ux=Math.cos(theta),uy=Math.sin(theta);
  return {x,y,value,fx,fy,magnitude,ux,uy,directional:fx*ux+fy*uy};
}
export function grid(raw={},count=65){
  const p=parameters(raw);
  if(!Number.isInteger(count)||count<9||count>161)throw new Error('Invalid grid resolution');
  const rows=[];
  for(let j=0;j<count;j++)for(let i=0;i<count;i++)rows.push(sample(p,-DOMAIN+2*DOMAIN*i/(count-1),-DOMAIN+2*DOMAIN*j/(count-1)));
  return rows;
}
export function section(raw={},count=161){
  const p=parameters(raw),point=sample(p),bounds=[-Infinity,Infinity];
  for(const [origin,direction] of [[p.x,point.ux],[p.y,point.uy]])if(Math.abs(direction)>1e-12){const ends=[(-DOMAIN-origin)/direction,(DOMAIN-origin)/direction].sort((a,b)=>a-b);bounds[0]=Math.max(bounds[0],ends[0]);bounds[1]=Math.min(bounds[1],ends[1]);}
  const rows=[];
  for(let i=0;i<count;i++){const t=bounds[0]+(bounds[1]-bounds[0])*i/(count-1),x=Math.max(-DOMAIN,Math.min(DOMAIN,p.x+t*point.ux)),y=Math.max(-DOMAIN,Math.min(DOMAIN,p.y+t*point.uy));rows.push({t,...sample(p,x,y),linear:point.value+t*point.directional});}
  return rows;
}
export function gradientStep(raw={},sign=1){
  const p=parameters(raw),r=sample(p);
  if(![1,-1].includes(sign))throw new Error('Invalid step direction');
  if(r.magnitude<1e-7)return {point:r,reason:'Stationary within tolerance'};
  const dx=sign*r.fx/r.magnitude,dy=sign*r.fy/r.magnitude;
  let h=.16;
  for(const [coordinate,direction] of [[p.x,dx],[p.y,dy]])if(Math.abs(direction)>1e-12)h=Math.min(h,(Math.sign(direction)*DOMAIN-coordinate)/direction);
  if(h<1e-8)return {point:r,reason:'Domain boundary'};
  // Armijo backtracking gives finite monotone steps, not a physical trajectory.
  for(let attempt=0;attempt<28;attempt++,h*=.5){
    const next=sample(p,Math.max(-DOMAIN,Math.min(DOMAIN,p.x+h*dx)),Math.max(-DOMAIN,Math.min(DOMAIN,p.y+h*dy)));
    if(sign*(next.value-r.value)>=.1*h*r.magnitude)return {point:next,reason:null};
  }
  return {point:r,reason:'Step below tolerance'};
}
export function csv(raw,rows){
  return '# '+JSON.stringify(parameters(raw))+'\n'+'x,y,f,df_dx,df_dy,gradient_magnitude,directional_derivative\n'+rows.map(r=>[r.x,r.y,r.value,r.fx,r.fy,r.magnitude,r.directional].map(v=>v.toPrecision(15)).join(',')).join('\n')+'\n';
}
