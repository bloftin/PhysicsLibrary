import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {FIELDS,DEFAULTS,parameters,sample,grid,section,gradientStep,csv} from '../model.js';
const close=(a,b,tol=2e-10)=>assert.ok(Math.abs(a-b)<tol*(1+Math.abs(b)),`${a} != ${b}`);
test('all 2178 Julia reference points match symbolic differentiation',()=>{
  const lines=readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split(/\r?\n/);lines.shift();assert.equal(lines.length,2178);
  for(const row of lines){const [field,...numbers]=row.split(','),[a,b,angle,x,y,f,fx,fy,mag,du]=numbers.map(Number),r=sample({field,a,b,angle,x,y});for(const [actual,expected] of [[r.value,f],[r.fx,fx],[r.fy,fy],[r.magnitude,mag],[r.directional,du]])close(actual,expected);}
});
test('directions: maximal uphill, tangent to level set, and downhill',()=>{
  for(const field of Object.keys(FIELDS)){
    const p={...DEFAULTS,field},r=sample(p),angle=Math.atan2(r.fy,r.fx)*180/Math.PI;
    close(sample({...p,angle}).directional,r.magnitude);
    close(sample({...p,angle:(angle+90+540)%360-180}).directional,0);
    close(sample({...p,angle:(angle+180+540)%360-180}).directional,-r.magnitude);
  }
});
test('Armijo paths are finite, monotone, and bounded for both directions',()=>{
  for(const field of Object.keys(FIELDS))for(const sign of [-1,1]){
    let p={...DEFAULTS,field},last=sample(p);
    for(let i=0;i<300;i++){const {point,reason}=gradientStep(p,sign);if(reason)break;assert.ok(sign*(point.value-last.value)>=-1e-12);assert.ok(Math.abs(point.x)<=2.5&&Math.abs(point.y)<=2.5);p={...p,x:point.x,y:point.y};last=point;}
  }
  assert.equal(gradientStep({...DEFAULTS,x:0,y:0}).reason,'Stationary within tolerance');
  assert.equal(gradientStep({...DEFAULTS,field:'plane',x:2.5,y:2.5}).reason,'Domain boundary');
});
test('section tangent derivative agrees with central differences',()=>{
  for(const field of Object.keys(FIELDS)){
    const p={...DEFAULTS,field},r=sample(p),h=1e-5;
    const diff=(sample(p,p.x+h*r.ux,p.y+h*r.uy).value-sample(p,p.x-h*r.ux,p.y-h*r.uy).value)/(2*h);close(diff,r.directional,1e-7);
    const cut=section(p);assert.equal(cut.length,161);assert.ok(cut[0].t<=0&&cut.at(-1).t>=0);for(const point of cut)assert.ok(Number.isFinite(point.value));
  }
});
test('grid, zero-gradient cases, export, and invalid inputs',()=>{
  assert.equal(grid(DEFAULTS,9).length,81);
  assert.equal(csv(DEFAULTS,grid(DEFAULTS,9)).trim().split('\n').length,83);
  for(const field of ['bowl','saddle','gaussian','wells'])assert.equal(sample({...DEFAULTS,field,x:0,y:0}).magnitude,0);
  for(const raw of [{field:'bad'},{field:'__proto__'},{a:0},{b:Infinity},{x:3},{angle:200}])assert.throws(()=>parameters(raw));
  assert.throws(()=>grid(DEFAULTS,1));assert.throws(()=>gradientStep(DEFAULTS,0));assert.throws(()=>sample(DEFAULTS,NaN,0));
});
