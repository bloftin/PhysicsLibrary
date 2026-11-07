import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {E_CHARGE,K,MASK,PRESETS,preset,validate,environment,accessible,endpoints,pathPoint,safePath,segmentDistance,samples,battery,transfer,csv} from '../model.js';
import {integrate} from '../integral.js';
const near=(a,b,scale=1)=>assert.ok(Math.abs(a-b)<=3e-10*Math.max(Math.abs(a),Math.abs(b),scale),`${a} versus ${b}`);
const rows=name=>{const [head,...lines]=readFileSync(new URL('../'+name,import.meta.url),'utf8').trim().split('\n');const keys=head.split(',');return lines.map(l=>Object.fromEntries(l.split(',').map((v,i)=>[keys[i],i<2&&name==='reference.csv'||i===0?v:Number(v)])));};
test('1170 independent Julia path, field, potential, energy and work samples',()=>{
 for(const r of rows('reference.csv')){const p=preset(r.case),pt=pathPoint(p,r.route,r.f),e=environment(p,pt),a=environment(p,p.a);near(pt.x,r.x_map);near(pt.y,r.y_map);near(pt.length*r.f,r.path_m);near(e.v,r.V_V);near(e.ex,r.Ex_V_per_m);near(e.ey,r.Ey_V_per_m);near(p.q*e.v,r.U_J,1e-28);near(p.q*(a.v-e.v),r.W_electric_J,1e-28);}
 for(const r of rows('events.csv')){const e=endpoints(preset(r.case));near(e.dv,r.dV_V);near(e.du,r.dU_J,1e-28);near(e.work,r.W_electric_J,1e-28);near(e.meter,r.meter_A_minus_B_V);}
});
test('article worked values, charge sign/scaling, gauge and meter polarity',()=>{
 let p=preset('plates'),e=endpoints(p);near(e.dv,-10);near(e.du,-20e-9,1e-28);near(e.work,20e-9,1e-28);near(environment(p,p.a).ex,200);
 p=preset('worked');e=endpoints(p);near(e.du,12e-6,1e-28);near(e.work,-12e-6,1e-28);
 p=preset('electron');near(endpoints(p).du/E_CHARGE,-3);
 for(const id of Object.keys(PRESETS)){p=preset(id);const before=endpoints(p),field=environment(p,p.a);p.offset+=177;const after=endpoints(p);near(after.dv,before.dv);near(after.du,before.du,1e-25);near(environment(p,p.a).ex,field.ex);p.q*=-2;near(endpoints(p).du,-2*before.du,1e-25);p.q=0;near(endpoints(p).du,0);}
});
test('conservative field integrals, bent paths, repeated points and closed loops',()=>{
 for(const id of Object.keys(PRESETS)){let p=preset(id);for(const route of ['direct','bent']){assert.ok(safePath(p,route));const integral=integrate(p,route),end=endpoints(p);near(integral.volts,-end.dv);assert.ok(Math.abs(integral.work-end.work)<=Math.abs(p.q)*3e-10*Math.max(1,Math.abs(end.dv)));}p.b={...p.a};for(const route of ['direct','bent'])near(integrate(p,route).volts,0);p.h={...p.a};near(integrate(p,'bent').volts,0);}
});
test('field is negative spatial gradient; zero V differs from zero E',()=>{
 for(const id of ['positive','negative','dipole','like','plates']){const p=preset(id),x=.4,y=.7,h=1e-5,scale=p.kind==='uniform'?p.gap/2:1,e=environment(p,{x,y});const dx=(environment(p,{x:x+h,y}).v-environment(p,{x:x-h,y}).v)/(2*h*scale),dy=(environment(p,{x,y:y+h}).v-environment(p,{x,y:y-h}).v)/(2*h*scale);assert.ok(Math.abs(dx+e.ex)<1e-6);assert.ok(Math.abs(dy+e.ey)<1e-6);}
 const dip=environment(preset('dipole'),{x:0,y:0}),like=environment(preset('like'),{x:0,y:0});assert.equal(dip.v,0);assert.ok(dip.e>0);assert.equal(like.e,0);assert.ok(like.v>0);
});
test('singular/masked/neutral sources and exact segment exclusion',()=>{
 const p=preset('positive');assert.equal(environment(p,{x:0,y:0}),null);assert.equal(accessible(p,{x:.1,y:0}),false);assert.notEqual(environment(p,{x:.1,y:0}),null);p.a={x:-1,y:.159};p.b={x:1,y:.159};assert.equal(safePath(p,'direct'),false);assert.equal(integrate(p,'direct'),null);assert.deepEqual(samples(p),[]);p.a.y=p.b.y=MASK+.001;assert.ok(safePath(p,'direct'));p.sources[0].q=0;assert.equal(environment(p,{x:0,y:0}).v,0);assert.ok(accessible(p,{x:0,y:0}));p.a={x:0,y:0};assert.ok(endpoints(p));near(segmentDistance({x:1,y:1},{x:0,y:0},{x:0,y:0}),Math.sqrt(2));
});
test('battery loading, ideal limit and full power balance',()=>{
 const ordinary=battery(9,10,100,1e7),loaded=battery(9,10,100,100);assert.ok(loaded.terminal<ordinary.terminal);near(battery(9,0,100,100).terminal,9);assert.equal(battery(0,10,100).terminal,0);
 for(const r of [0,10,1000])for(const load of [1,100,1e6])for(const rm of [100,1e7]){const b=battery(9,r,load,rm);near(b.sourcePower,b.internalPower+b.loadPower+b.meterPower);near(b.current,b.loadCurrent+b.meterCurrent);near(b.terminal,9-b.current*r);}
 assert.throws(()=>battery(9,-1,100));assert.throws(()=>battery(9,10,0));
});
test('integer electron conservation, limits, validation and SI export',()=>{
 for(let n=-20;n<=20;n++){const t=transfer(n);assert.equal(t.left+t.right,0);near(t.left,n*E_CHARGE,1e-28);}assert.throws(()=>transfer(.1));assert.throws(()=>transfer(21));assert.throws(()=>validate({...preset(),q:NaN}));assert.throws(()=>validate({...preset(),a:{x:3,y:0}}));assert.throws(()=>pathPoint(preset(),'direct',1.1));const data=csv(preset(),'bent');assert.equal(data.trim().split('\n').length,162);assert.ok(!/NaN|Infinity|undefined/.test(data));assert.ok(K>8.98e9&&K<9e9);
});
