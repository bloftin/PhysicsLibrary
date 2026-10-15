import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULTS,parameters,at,point,curve,trace,polygon,csv} from '../model.js';
const close=(a,b,tol=2e-10)=>assert.ok(Math.abs(a-b)<=tol*(1+Math.abs(b)),`${a} != ${b}`);

test('533 independent Julia reference samples across 13 cases',()=>{
  const lines=readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split(/\r?\n/),keys=lines.shift().split(',');assert.equal(lines.length,533);
  for(const line of lines){const v=line.split(','),d=Object.fromEntries(keys.map((k,i)=>[k,v[i]])),p={mode:+d.mode,a:+d.a_input,alpha:+d.alpha_input,length:+d.length_input,perimeter:+d.perimeter_input,n:+d.n,ratio:+d.ratio},r=at(p);
    for(const [js,julia] of Object.entries({R:'R',area:'area',efficiency:'fraction'}))close(r.mode===6&&js==='R'?r.poly.R:r[js],+d[julia]);
    if(r.mode===6){close(r.circle,+d.circle);close(r.square,+d.square);close(r.poly.apothem,+d.apothem);}
    else{for(const key of ['a','length','kappa','lambda','residual'])close(r[key],+d[key]);const q=point(p,+d.u);for(const key of ['x','y','tx','ty','nx','ny','kappa'])close(q[key],+d[key]);}
  }
});
test('independent sampled boundary lengths, areas and curvature',()=>{
  for(const mode of [1,3,4])for(const alpha of [15,45,90,...(mode===4?[120,165]:[])]){
    const p={...DEFAULTS,mode,alpha,ratio:-1},r=at(p),rows=curve(p,2001);let length=0,area=0;
    for(let i=1;i<rows.length;i++){const a=rows[i-1],b=rows[i];length+=Math.hypot(b.x-a.x,b.y-a.y);area+=(a.y+b.y)*(b.x-a.x)/2;}
    close(length,r.length,2e-6);close(area,r.area,3e-6);close(r.residual,0);
    for(const u of [-1,0,1]){const q=point(p,u);close(q.tx*q.nx+q.ty*q.ny,0);close(q.tx**2+q.ty**2,1);close(q.kappa,-1/r.R);}
  }
});
test('Dido preserves rope length, peaks at orthogonal contact, and admits major arcs',()=>{
  for(let alpha=15;alpha<=165;alpha++){const r=at({mode:4,alpha});close(r.length,DEFAULTS.length);assert.ok(r.efficiency<=1+1e-12);if(alpha<90)assert.ok(r.slope>0);if(alpha>90)assert.ok(r.slope<0);}
  const r=at({mode:4,alpha:90});close(r.efficiency,1);close(r.R,r.length/Math.PI);close(point({mode:4,alpha:90},1).tx,0);assert.equal(at({mode:4,alpha:120}).graph,false);
});
test('fixed chord family and semicircle endpoint qualification',()=>{
  for(const alpha of [15,30,60,90]){const r=at({alpha});close(r.a,DEFAULTS.a);assert.ok(r.length>2*r.a&&r.length<=Math.PI*r.a+1e-12);}
  const r=at({mode:3,a:2});close(r.area,2*Math.PI);close(r.length,2*Math.PI);close(r.residual,0);close(at({mode:4}).residual,0);close(point({mode:3},-1).tx,0);assert.ok(point({mode:3},-1).ty>.99);
  const rows=trace({mode:3});close(rows.at(-1).x,90);close(rows.at(-1).y,Math.PI/2);for(let i=1;i<rows.length;i++)assert.ok(rows[i].y>rows[i-1].y);
});
test('same perimeter polygons approach circle and agree with closed formulas',()=>{
  for(const P of [4,12,20]){let prev=0;for(let n=3;n<=60;n++){const poly=polygon(P,n);close(poly.perimeter,P);close(poly.area,poly.exactArea);assert.ok(poly.area>prev);assert.ok(poly.area<P*P/(4*Math.PI));prev=poly.area;}
    close(polygon(P,4).area,P*P/16);close(at({mode:6,perimeter:P,n:4}).efficiency,Math.PI/4);
  }
  close(at({mode:6,perimeter:8}).area/at({mode:6,perimeter:4}).area,4);
});
test('invalid inputs and finite numerical exports',()=>{
  for(const p of [{mode:2},{a:0},{alpha:91},{mode:4,alpha:180},{n:3.5},{ratio:Infinity},{probe:-2}])assert.throws(()=>parameters(p));
  assert.throws(()=>point(DEFAULTS,2));assert.throws(()=>point({mode:6},0));assert.throws(()=>curve(DEFAULTS,2));
  for(const mode of [1,3,4,6]){const s=csv({mode});assert.ok(!/NaN|Infinity/.test(s));assert.equal(s.trim().split('\n').length,mode===6?59:242);assert.ok(trace({mode}).length>10);}
});
