import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {csvParse} from 'd3';
import {MAX_N,TAU,preset,validate,value,polar,setPolar,metrics,phasors,target,audioCoefficients,soundSamples,wav,csv} from '../model.js';
const close=(a,b,tol=2e-11)=>assert.ok(Math.abs(a-b)<tol,`${a} != ${b}`);
test('1806 independent Julia samples, RMS and gcd periods',()=>{
  const coefficients=csvParse(readFileSync(new URL('../coefficients.csv',import.meta.url),'utf8'));
  const reference=csvParse(readFileSync(new URL('../reference.csv',import.meta.url),'utf8'));
  assert.equal(reference.length,1806);
  for(const row of reference){
    const s=preset('constant');s.N=Number(row.N);s.f0=Number(row.f0_Hz);s.dc=Number(row.A0);
    for(const c of coefficients.filter(c=>c.case===row.case)){s.a[Number(c.n)]=Number(c.A_n);s.b[Number(c.n)]=Number(c.B_n);}
    close(value(s,Number(row.cycle)),Number(row.value));
    const m=metrics(s);close(m.acRms,Number(row.ac_rms));
    if(row.period_s==='')assert.equal(m.period,null);else close(m.period,Number(row.period_s));
  }
  for(const name of ['article','square','triangle','sawtooth','single','missing','even','constant']) {
    const s=preset(name);
    for(const c of coefficients.filter(c=>c.case===name)){close(s.a[Number(c.n)],Number(c.A_n));close(s.b[Number(c.n)],Number(c.B_n));}
  }
});
test('phasor endpoint, phase convention, DC and time translation',()=>{
  const s=preset();
  close(value(s,.25),1);
  for(const q of [0,.13,.25,.57,1.2])close(phasors(s,q).at(-1).y,value(s,q)-s.dc);
  const cosine=preset('single');setPolar(cosine,1,1,90);close(value(cosine,.25),1);close(value(cosine,0),0);
  setPolar(cosine,1,0,180);assert.equal(polar(cosine,1).phase,0);
  setPolar(cosine,1,2.5,0);for(let phase=-180;phase<=180;phase++){setPolar(cosine,1,polar(cosine,1).amplitude,phase);close(polar(cosine,1).amplitude,2.5);}
  const phase=.4, shifted=structuredClone(s);
  for(let n=1;n<=MAX_N;n++){shifted.a[n]=s.a[n]*Math.cos(n*phase)-s.b[n]*Math.sin(n*phase);shifted.b[n]=s.a[n]*Math.sin(n*phase)+s.b[n]*Math.cos(n*phase);}
  close(value(shifted,.37),value(s,.37-phase/TAU));
});
test('shortest period is not always base period or the lowest retained harmonic',()=>{
  assert.equal(metrics(preset('even')).divisor,2);assert.equal(metrics(preset('missing')).divisor,1);
  assert.equal(metrics(preset('constant')).period,null);
  const s=preset('single');s.N=0;assert.equal(value(s,.37),0);assert.equal(metrics(s).period,null);
  assert.deepEqual(phasors(s,.1),[]);
});
test('square, triangle and sawtooth targets and convergence away from jumps',()=>{
  for(const name of ['square','triangle','sawtooth']){const s=preset(name);s.N=24;for(const q of [.13,.27,.7])assert.ok(Math.abs(value(s,q)-target(name,q))<.12);}
  assert.equal(target('square',.5),0);assert.equal(target('sawtooth',.5),0);
  const square=preset('square');square.N=23;let max=-Infinity;for(let i=0;i<2000;i++)max=Math.max(max,value(square,i/2000));assert.ok(max>1.1&&max<1.25,'Gibbs overshoot retained, not clipped');
});
test('audio excludes DC, respects cutoff, solo and conservative gain',()=>{
  const s=preset(), c=audioCoefficients(s);assert.equal(c.real[0],0);assert.equal(c.imag[0],0);
  const solo=audioCoefficients(s,48000,2);assert.equal(solo.real[1],0);close(solo.imag[2],-.75);
  const cutoff=preset('sawtooth');cutoff.N=24;cutoff.f0=440;const high=audioCoefficients(cutoff,8000);assert.ok(high.omitted>0);assert.equal(high.real[24],0);assert.equal(high.imag[24],0);
  assert.ok(soundSamples(preset('constant'),{seconds:.1}).every(x=>x===0));
  for(const name of ['article','square','triangle','sawtooth']){const samples=soundSamples(preset(name),{seconds:.1,volume:.3});assert.ok(samples.every(x=>Math.abs(x)<=.300001));close(samples[0],0);close(samples.at(-1),0);}
});
test('browser WAV agrees with independent Julia 16-bit PCM',()=>{
  const original=readFileSync(new URL('../julia-square.wav',import.meta.url));
  const generated=Buffer.from(wav(preset('square')));
  assert.equal(generated.length,192044);assert.equal(generated.readUInt32LE(24),48000);assert.equal(generated.readUInt16LE(22),1);assert.equal(generated.readUInt16LE(34),16);
  assert.deepEqual(generated.subarray(0,44),original.subarray(0,44));
  for(let offset=44;offset<generated.length;offset+=2)assert.ok(Math.abs(generated.readInt16LE(offset)-original.readInt16LE(offset))<=2);
});
test('validation and exported data preserve coefficients and physical seconds',()=>{
  assert.throws(()=>preset('bad'));assert.throws(()=>validate({...preset(),N:25}));assert.throws(()=>validate({...preset(),f0:0}));assert.throws(()=>setPolar(preset(),2,3,0));assert.throws(()=>audioCoefficients(preset(),0));assert.throws(()=>soundSamples(preset(),{volume:1}));
  const rows=csvParse(csv(preset()));assert.equal(rows.length,1025);assert.equal(Number(rows[0].A1),2);assert.equal(Number(rows[0].B2),-.75);close(Number(rows.at(-1).time_s),2/110);
});
