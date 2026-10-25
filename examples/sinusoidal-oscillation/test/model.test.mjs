import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { csvParse } from 'd3';
import { TAU, parameters, preset, metrics, fromRate, sample, changeForm, comparison, history, landmarks, arc, csv } from '../model.js';
const near = (actual, expected, tolerance = 2e-12) => assert.ok(Math.abs(actual-expected) < tolerance, `${actual} != ${expected}`);

test('1449 independent Julia complex-exponential references', () => {
  const rows=csvParse(readFileSync(new URL('../reference.csv',import.meta.url),'utf8'));
  assert.equal(rows.length,1449);
  for(const r of rows) {
    const p=parameters({ A:+r.A_m,f:+r.f_Hz,phi:+r.phi_rad,form:r.form }),d=sample(p,+r.t_s);
    near(d.theta,+r.phase_rad); near(d.c,+r.cos_phase); near(d.s,+r.sin_phase);
    near(d.u,+r.u_m); near(d.slope,+r.du_dt_m_per_s);
  }
});
test('both article examples, units and quarter-cycle events', () => {
  const one=preset('example1').p,two=preset('example2').p;
  near(metrics(one).omega,4*Math.PI);near(metrics(one).T,.5);near(one.A*100,4);
  const values=landmarks(one).map(d=>d.u);
  [.04,0,-.04,0,.04].forEach((u,i)=>near(values[i],u));
  near(two.A*1000,6);near(metrics(two).omega,5*Math.PI);near(metrics(two).T,.4);
  near(sample(two,0).u,0);assert.ok(sample(two,0).slope<0);
  for(const r of csvParse(readFileSync(new URL('../events.csv',import.meta.url),'utf8'))) {
    if(['fast_negative','slow_sine'].includes(r.case)) continue;
    const d=sample(preset(r.case).p,+r.t_s);near(d.u,+r.u_m);near(d.theta,+r.phase_rad);
  }
});
test('rate entry conversions and doubled frequency retain physical seconds', () => {
  for(const f of [.25,.5,1,2.5,4]) {
    near(fromRate('frequency',f),f);near(fromRate('period',1/f),f);near(fromRate('angular',TAU*f),f);
    const p=parameters({f}),q=comparison(p,'double');near(metrics(q).T,1/(2*f));
    near(metrics(q).omega,2*metrics(p).omega);near(q.A,p.A);
    for(const t of [0,.1,.5,2]) near(sample(q,t).u,sample(p,2*t).u);
  }
  for(const value of [0,-1,NaN,Infinity]) assert.throws(()=>fromRate('period',value));
});
test('equivalent sine/cosine preserves values and motion through phase wrapping', () => {
  for(const phi of [-Math.PI,-Math.PI/2,0,Math.PI/2,Math.PI]) for(const form of ['sin','cos']) {
    const p=parameters({phi,form}),q=changeForm(p,form==='sin'?'cos':'sin');
    for(const t of [0,.125,.5,1,3.9]) {near(sample(q,t).u,sample(p,t).u);near(sample(q,t).slope,sample(p,t).slope);}
  }
  const rise=sample(preset('rising').p,0),fall=sample(preset('falling').p,0);
  near(rise.u,fall.u);assert.ok(rise.slope>0&&fall.slope<0);
});
test('periodicity, phase shift, circle projection and radians', () => {
  for(const phi of [-Math.PI,-.1,0,Math.PI/3,Math.PI]) {
    const p=parameters({phi,f:2.5});
    for(const t of [0,.1,1,4]) {
      const d=sample(p,t);near(d.u,sample(p,t+metrics(p).T).u);
      near(d.u,p.A*d.c);near(sample(p,t).u,sample(parameters({...p,phi:0}),t+phi/metrics(p).omega).u);
      near(d.c*d.c+d.s*d.s,1);
      for(const radius of [.5,1,1.5]) {const a=arc(d.theta,radius);near(a.length/a.radius,a.angle);}
    }
  }
  near(arc(1,1.5).length,1.5);near(arc(-Math.PI/2,1).angle,3*Math.PI/2);
  const p=parameters(),q=comparison(p,'phase');near(q.phi,0);assert.equal(comparison(p,'off'),null);
});
test('zero amplitude, fixed-domain samples, validation and SI CSV', () => {
  const p=preset('zero').p;
  assert.equal(metrics(p).observed,false);assert.ok(history(p).every(d=>d.u===0&&d.slope===0));
  assert.equal(history(p).at(-1).t,4);
  const rows=csvParse(csv(parameters({A:.006,f:2.5}),'double'));
  assert.equal(rows.length,1601);near(+rows[0].A_m,.006);near(+rows.at(-1).t_s,4);
  near(+rows[33].comparison_u_m,sample(comparison(parameters({A:.006,f:2.5}),'double'),+rows[33].t_s).u);
  assert.equal(csvParse(csv(p))[0].comparison_u_m,'');
  for(const raw of [{A:-1},{A:1},{f:0},{f:5},{phi:4},{form:'tan'},{A:NaN}])assert.throws(()=>parameters(raw));
  assert.throws(()=>comparison(p,'bad'));assert.throws(()=>preset('bad'));assert.throws(()=>arc(1,0));
});
