import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { csvParse } from 'd3';
import { preset, validate, inner, analyze, terms, curves, errorAt, normalizeTarget, csv, polynomialLabel } from '../model.js';
const near = (actual, expected, tolerance = 2e-10) => assert.ok(Math.abs(actual - expected) <= tolerance * Math.max(1, Math.abs(expected)), `${actual} != ${expected}`);
const references = csvParse(readFileSync(new URL('../reference.csv', import.meta.url), 'utf8'));
function fromRow(row) {
  const count = row.mode === 'vectors' ? 2 : 4;
  return validate({ mode: row.mode, u: Array.from({length:count},(_,i)=>+row['u'+i]), v: Array.from({length:count},(_,i)=>+row['v'+i]), a:+row.a,b:+row.b,weight:row.weight,n:16,fit:false,c:+row.trial_c });
}
test('153 independent exact-rational Julia geometry references', () => {
  assert.equal(references.length,153);
  for(const row of references) {
    const d=analyze(fromRow(row));
    for(const [key,column] of [['uv','uv'],['uu','uu'],['vv','vv'],['c','trial_c'],['rv','residual_inner_v'],['error2','error_squared']]) near(d[key],+row[column]);
    if(row.optimal_c==='')assert.equal(d.optimal,null);else near(d.optimal,+row.optimal_c);
    if(row.angle_deg==='')assert.equal(d.angle,null);else near(d.angle,+row.angle_deg,2e-6);
  }
});
test('520 independent Julia function values, integrands, projections and residuals', () => {
  const rows=csvParse(readFileSync(new URL('../samples.csv',import.meta.url),'utf8'));assert.equal(rows.length,520);
  for(const row of rows) {
    const ref=references.find(r=>r.case===row.case),p={...fromRow(ref),fit:true};
    const index=Math.round((+row.x-p.a)/(p.b-p.a)*64),d=curves(p,analyze(p),65)[index];
    for(const [key,column]of [['u','u'],['v','v'],['projection','optimal_projection'],['residual','residual'],['product','product']])near(d[key],+row[column]);
  }
});
test('article projection, norm, interval and weighting examples', () => {
  near(analyze(preset('functions','square')).optimal,1/3);near(analyze(preset('functions','cubic')).optimal,3/5);
  near(analyze(preset('functions','weighted')).optimal,2/3);near(analyze(preset('functions','norm')).nu,Math.sqrt(2/3));
  near(analyze(preset('functions','cancel')).uv,0);near(analyze(preset('functions','interval')).uv,.5);
  const p=preset('functions','weighted');near(analyze({...p,weight:'uniform'}).optimal,.5);
  near(analyze(preset('matrices','trace')).optimal,2);near(analyze(preset('matrices','symmetric')).uv,0);
});
test('symmetry, bilinearity, positivity, Cauchy-Schwarz, projection and Pythagoras', () => {
  for(const p of [preset(),preset('functions','quadratic'),preset('functions','cubic'),preset('matrices','general')]) {
    const d=analyze(p);near(inner(p,p.u,p.v),inner(p,p.v,p.u));assert.ok(d.uv*d.uv<=d.uu*d.vv+1e-10);
    near(inner(p,p.u.map((u,i)=>2*u+3*p.v[i]),p.v),2*d.uv+3*d.vv);
    near(d.rv,0);near(d.uu,d.c*d.c*d.vv+d.error2);
    for(const c of [-2,0,.25,1,3]) {
      const trial=analyze({...p,fit:false,c});near(trial.error2,d.error2+d.vv*(c-d.optimal)**2);
      near(d.uu,c*c*d.vv+trial.error2+2*c*trial.rv);
      near(errorAt(p,c),trial.error2);
    }
    const normalized=normalizeTarget(p),nd=analyze(normalized);near(nd.nv,1);near(nd.uv,nd.optimal);
    d.projection.forEach((value,i)=>near(nd.projection[i],value));
    const manual={...p,fit:false,c:.75},nm=normalizeTarget(manual);analyze(manual).projection.forEach((value,i)=>near(analyze(nm).projection[i],value));
  }
});
test('midpoint convergence and signed cancellation are distinct from analytic geometry', () => {
  const p=preset('functions','square'),exact=analyze(p).uv;
  const approx=n=>terms({...p,n}).reduce((s,d)=>s+d.value,0);
  assert.ok(Math.abs(approx(128)-exact)<Math.abs(approx(4)-exact)/100);
  for(const n of [4,16,128])near(analyze({...p,n}).optimal,1/3);
  const cancel=preset('functions','cancel'),q=terms(cancel);
  near(q.reduce((s,d)=>s+d.value,0),0);assert.ok(q.some(d=>d.value>0)&&q.some(d=>d.value<0));
  const best=analyze(p),residualSum=terms(p,best,best.residual).reduce((s,d)=>s+d.value,0);
  near(best.rv,0);assert.ok(Math.abs(residualSum)>1e-5,'finite sample residual sum is not falsely identified with exact orthogonality');
});
test('zero objects, finite CSV, validation and readable polynomial labels', () => {
  for(const mode of ['vectors','matrices']) {
    const p=preset(mode,'zero'),d=analyze(p);assert.equal(d.optimal,null);assert.equal(d.angle,null);assert.throws(()=>normalizeTarget(p));
    near(errorAt(p,0),errorAt(p,100));assert.ok(d.projection.every(x=>x===0));
  }
  const p=preset('functions','cubic'),data=csvParse(csv(p));assert.equal(data.length,16);near(+data[0].optimal_c,.6);
  assert.ok(!/NaN|Infinity|undefined/.test(csv(preset('matrices','zero'))));
  assert.equal(polynomialLabel([0,0,0,0]),'0');assert.equal(polynomialLabel([1,-1,0,1]),'1 − x + x³');
  for(const change of [{u:[NaN,1]},{n:3},{c:Infinity},{weight:'bad'},{a:1},{v:[1]}])assert.throws(()=>validate({...preset(),...change}));
});
