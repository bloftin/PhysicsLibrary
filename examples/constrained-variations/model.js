import {create,parseDependencies,derivativeDependencies} from 'mathjs';
const {parse,derivative}=create({...parseDependencies,...derivativeDependencies});
export const DEFAULTS=Object.freeze({mode:'mean',mean:.5,b:.6,norm:1,angle:35,lambda:-6});
export function parameters(raw={}){
  const p={...DEFAULTS,...raw};
  if(!['mean','normalization'].includes(p.mode))throw new Error('Unknown functional');
  for(const [key,min,max] of [['mean',-1,1],['b',-1,1],['norm',.25,2],['angle',0,360],['lambda',-16,16]])
    if(!Number.isFinite(p[key])||p[key]<min||p[key]>max)throw new Error(`Invalid ${key}`);
  return p;
}
const compiled=new Map();
for(const [mode,J,K] of [['mean','6*a^2+18*b^2/5','a'],['normalization','a^2+4*b^2','a^2+b^2']]){
  const j=parse(J),k=parse(K);compiled.set(mode,{J:j.compile(),K:k.compile(),ja:derivative(j,'a',{simplify:false}).compile(),jb:derivative(j,'b',{simplify:false}).compile(),ka:derivative(k,'a',{simplify:false}).compile(),kb:derivative(k,'b',{simplify:false}).compile()});
}
export function objective(mode,a,b){if(!compiled.has(mode))throw new Error('Unknown functional');return compiled.get(mode).J.evaluate({a,b});}
export function at(raw={}){
  const p=parameters(raw),theta=p.angle*Math.PI/180,r=Math.sqrt(p.norm),a=p.mode==='mean'?p.mean:r*Math.cos(theta),b=p.mode==='mean'?p.b:r*Math.sin(theta),f=compiled.get(p.mode),scope={a,b};
  const J=f.J.evaluate(scope),K=f.K.evaluate(scope),gJ=[f.ja.evaluate(scope),f.jb.evaluate(scope)],gK=[f.ka.evaluate(scope),f.kb.evaluate(scope)],t=p.mode==='mean'?[0,1]:[-b/r,a/r];
  const lambdaFit=-(gJ[0]*gK[0]+gJ[1]*gK[1])/(gK[0]**2+gK[1]**2),residual=gJ.map((v,i)=>v+p.lambda*gK[i]),dJ=gJ[0]*t[0]+gJ[1]*t[1],dK=gK[0]*t[0]+gK[1]*t[1];
  const residualL2=p.mode==='mean'?Math.hypot(12*a+p.lambda,Math.sqrt(432)*b):2*Math.hypot((1+p.lambda)*a,(4+p.lambda)*b);
  return {a,b,J,K,gJ,gK,t,lambdaFit,residual,residualNorm:Math.hypot(...residual),residualL2,dJ,dK,length:p.mode==='mean'?1:Math.PI,target:p.mode==='mean'?p.mean:p.norm};
}
export function density(raw={},x){
  const p=parameters(raw),r=at(p);
  if(!Number.isFinite(x)||x<0||x>r.length+1e-12)throw new Error('Invalid x');
  const phi=p.mode==='mean'?[6*x*(1-x),6*x*(1-x)*(2*x-1)]:[Math.sqrt(2/Math.PI)*Math.sin(x),Math.sqrt(2/Math.PI)*Math.sin(2*x)];
  const dp=p.mode==='mean'?[6-12*x,-36*x*x+36*x-6]:[Math.sqrt(2/Math.PI)*Math.cos(x),2*Math.sqrt(2/Math.PI)*Math.cos(2*x)];
  const y=r.a*phi[0]+r.b*phi[1],yp=r.a*dp[0]+r.b*dp[1],eta=r.t[0]*phi[0]+r.t[1]*phi[1],etap=r.t[0]*dp[0]+r.t[1]*dp[1];
  const gJ=p.mode==='mean'?12*r.a+36*r.b*(2*x-1):2*r.a*phi[0]+8*r.b*phi[1],gK=p.mode==='mean'?1:2*y;
  return {x,y,yp,eta,etap,gJ,gK,scaledK:-p.lambda*gK,residual:gJ+p.lambda*gK};
}
export function curve(raw={},count=161){const p=parameters(raw),r=at(p);if(!Number.isInteger(count)||count<21||count>2001)throw new Error('Invalid sample count');return Array.from({length:count},(_,i)=>density(p,r.length*i/(count-1)));}
export function feasible(raw={},parameter){const p=parameters(raw);return at(p.mode==='mean'?{...p,b:parameter}:{...p,angle:parameter});}
export function trace(raw={},count=181){const p=parameters(raw);return Array.from({length:count},(_,i)=>{const q=p.mode==='mean'?-1+2*i/(count-1):360*i/(count-1);return {q,...feasible(p,q)};});}
export function minimizer(raw={}){const p=parameters(raw);p.b=0;p.angle=0;p.lambda=p.mode==='mean'?-12*p.mean:-1;return p;}
export function csv(raw,rows=curve(raw)){
  const p=parameters(raw),r=at(p);
  return '# '+JSON.stringify({...p,J:r.J,K:r.K,a:r.a,b:r.b,deltaJ:r.dJ,deltaK:r.dK,residualL2:r.residualL2})+'\n'+'x,y,y_prime,eta,eta_prime,gJ,gK,minus_lambda_gK,residual\n'+rows.map(row=>[row.x,row.y,row.yp,row.eta,row.etap,row.gJ,row.gK,row.scaledK,row.residual].map(v=>v.toPrecision(15)).join(',')).join('\n')+'\n';
}
