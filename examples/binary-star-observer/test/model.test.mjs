import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULT,PRESETS,TAU,DEG,valid,radii,state,atAnomaly,flux,probability,totalCoverageProbability,events,curve,limbSurvival,orientationCount} from '../model.js';
const near=(a,b,tol=1e-9)=>assert.ok(Math.abs(a-b)<=tol,`${a} != ${b} (tol ${tol})`);
function csv(name){const lines=readFileSync(new URL('../'+name,import.meta.url),'utf8').trim().split('\n');const keys=lines.shift().split(',');return lines.map(line=>Object.fromEntries(line.split(',').map((v,i)=>[keys[i],Number.isNaN(Number(v))?v:Number(v)])));}

test('Julia library reference states, two luminous stars and both limb modes',()=>{
  let largest=0;
  for(const row of csv('reference.csv')){
    const p={i:row.inclination,s:row.radius_sum,k:row.radius_ratio,j:row.brightness_ratio,e:row.eccentricity,w:row.omega,q:row.mass_ratio,phase:row.phase};
    const v=state(p);v.relative.forEach((x,i)=>near(x,row[['x','y','z'][i]],1e-10));near(v.d,row.separation,1e-10);
    near(flux(p,v),row.uniform_flux,2e-10);
    const error=Math.abs(flux({...p,limb:true},v)-row.limb_flux);largest=Math.max(largest,error);near(flux({...p,limb:true},v),row.limb_flux,3e-4);
    const pr=probability(p);near(pr.a,row.p_a,1e-10);near(pr.b,row.p_b,1e-10);
  }
  console.log('Largest reference light-curve interpolation error:',largest);
});
test('2,000 off-grid Transits samples bound limb interpolation error',()=>{
  let largest=0;
  for(const row of csv('limb-check.csv')){const actual=limbSurvival(row.k,row.x);largest=Math.max(largest,Math.abs(actual-row.flux));near(actual,row.flux,3e-4);assert.ok(actual>=0&&actual<=1);}
  console.log('Largest off-grid kernel error:',largest);
});
test('central equal stars, unequal transit, foreground versus background, grazing and missed',()=>{
  const p={...PRESETS.twins,limb:false};near(flux(p,state(p,.25)),.5);near(flux(p,state(p,.75)),.5);near(flux(p,state(p,0)),1);
  const unequal={...p,k:.5,j:.25};near(flux(unequal,state(unequal,.25)),1-.25/1.0625);near(flux(unequal,state(unequal,.75)),1-.0625/1.0625);
  assert.equal(events(PRESETS.grazing).length,2);assert.equal(events(PRESETS.missed).length,0);
  assert.equal(events(PRESETS.eccentric).length,1);
  near(limbSurvival(1,0),0);near(limbSurvival(4,0),0);near(limbSurvival(.25,1),1);
});
test('circular geometric probability and isotropic orientation ensemble',()=>{
  const p=PRESETS.article,pr=probability(p);near(pr.any,p.s);near(pr.both,p.s);near(Math.acos(pr.any)/DEG,79.27945189,1e-7);
  const counts=orientationCount(p);near(counts.both/counts.n,p.s,.001);assert.equal(counts.only,0);
  near(probability({...p,i:10}).any,pr.any);near(probability({...p,j:2,q:4,k:.25}).any,pr.any);
  near(probability(p,0).any,0);
});
test('eccentric probability boundaries agree with independent angular scan',()=>{
  for(const e of [0,.3,.6,.8])for(const w of [0,30,60,90,170,270,330])for(const s of [.02,Math.min(.35,(1-e)*.95)]){
    const p={...DEFAULT,e,w,s},pr=probability(p);
    for(const [lo,expected] of [[0,pr.a],[Math.PI,pr.b]]){
      let max=0;for(let n=1;n<10000;n++){const u=lo+Math.PI*n/10000,r=(1-e*e)/(1+e*Math.cos(u-w*DEG));max=Math.max(max,((s/r)**2-Math.cos(u)**2)/Math.sin(u)**2);}
      near(expected,Math.sqrt(max),2e-5);
    }
    assert.ok(pr.both<=pr.any);assert.ok(pr.any<1);
  }
});
test('total coverage requires a larger foreground star, not just internal disk contact',()=>{
  const p={...PRESETS.eccentric,k:.5},r=radii(p),pr=probability(p,r.r1-r.r2);
  near(totalCoverageProbability(p),pr.b);assert.ok(pr.b<pr.a);
  const reverse={...p,k:2};near(totalCoverageProbability(reverse),pr.a);
  near(totalCoverageProbability({...p,k:1}),0);
  near(totalCoverageProbability({...p,e:0}),p.s*Math.abs(1-p.k)/(1+p.k));
});
test('barycenter, Kepler timing, orbit closure, face-on and physical guards',()=>{
  for(const p of Object.values(PRESETS))for(const phase of [0,.05,.25,.75,1]){
    const v=state(p,phase);v.relative.forEach((x,i)=>near(v.star1[i]+p.q*v.star2[i],0));
    near(Math.hypot(...v.relative),(1-p.e*p.e)/(1+p.e*Math.cos(v.nu)));
    assert.ok(valid(p));assert.ok(flux(p,v)>=0&&flux(p,v)<=1);
  }
  const face={...DEFAULT,i:0,e:.8,s:.1};for(let n=0;n<100;n++)near(flux(face,state(face,n/100)),1);
  assert.equal(valid({...DEFAULT,e:.8,s:.28}),false);assert.equal(valid({...DEFAULT,k:0}),false);assert.equal(valid({...DEFAULT,e:NaN}),false);
  near(state(PRESETS.eccentric,0).relative[0],state(PRESETS.eccentric,1).relative[0]);
});
test('contact roots, duration, adaptive curve and eccentric timing',()=>{
  for(const base of Object.values(PRESETS))for(const limb of [false,true]){
    const p={...base,limb};
    for(const ev of events(p)){
      near(atAnomaly(p,ev.left-p.w*DEG).d,p.s,1e-9);near(atAnomaly(p,ev.right-p.w*DEG).d,p.s,1e-9);
      assert.ok(ev.duration>0&&ev.duration<.5);assert.ok(ev.depth>0);assert.ok(ev.phase>=0&&ev.phase<1);
    }
    const data=curve(p);assert.equal(data[0].phase,0);assert.equal(data.at(-1).phase,1);assert.ok(data.every(row=>Number.isFinite(row.flux)));
  }
  const edge={...DEFAULT,i:90,e:.8,s:.02,w:90};assert.equal(events(edge).length,2);assert.ok(events(edge).some(ev=>ev.duration<.003));assert.ok(curve(edge).some(v=>v.flux<.99));
  const ecc={...DEFAULT,i:90,e:.5,s:.16,w:30};const ev=events(ecc);assert.ok(Math.abs(Math.abs(ev[1].phase-ev[0].phase)-.5)>.1);assert.ok(Math.abs(ev[0].duration-ev[1].duration)>.005);
});
test('grazing boundary and randomized detached configurations remain finite',()=>{
  let seed=91;const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/2**32;};
  for(let n=0;n<600;n++){
    const e=.8*random(),s=.02+random()*(Math.min(.5,(1-e)*.97)-.02),w=360*random();
    const base={...DEFAULT,e,s,w,k:.25+3.75*random(),j:.05+1.95*random(),q:.25+3.75*random(),limb:n%2===0},pr=probability(base);
    for(const delta of [-.00001,.00001,.01]){
      const p={...base,i:Math.min(90,Math.acos(pr.any)/DEG+delta)};assert.ok(valid(p));
      const evs=events(p);if(delta<0)assert.equal(evs.length,0);else assert.ok(evs.length>=1);
      for(const ev of evs){assert.ok(Number.isFinite(ev.depth)&&ev.depth>=0);assert.ok(ev.duration>0);}
    }
  }
});
