export const MAX_N = 24;
export const TAU = 2 * Math.PI;
export const PRESETS = Object.freeze({
  article: 'FS01: the article\'s three harmonics',
  square: 'Square wave: odd sine harmonics',
  triangle: 'Triangle wave: rapidly fading harmonics',
  sawtooth: 'Sawtooth: all sine harmonics',
  single: 'A single cosine',
  missing: 'No first harmonic: n = 2 and 3',
  even: 'Only n = 2 and 4: a shorter period',
  constant: 'DC only: no oscillation',
});
export function preset(id = 'article') {
  if (!Object.hasOwn(PRESETS, id)) throw new RangeError('Unknown waveform.');
  const s = {preset:id, N:3, f0:110, dc:0, a:Array(MAX_N+1).fill(0), b:Array(MAX_N+1).fill(0)};
  if (id === 'article') {s.dc=1; s.a[1]=2; s.b[2]=-.75; s.a[3]=.4;}
  if (id === 'single') {s.N=1; s.a[1]=1;}
  if (id === 'missing') {s.N=3; s.a[2]=1; s.b[3]=1;}
  if (id === 'even') {s.N=4; s.a[2]=1; s.b[4]=.5;}
  if (id === 'constant') {s.N=0; s.dc=1;}
  if (['square','triangle','sawtooth'].includes(id)) {
    s.N=9;
    for (let n=1; n<=MAX_N; n++) {
      if (id==='square' && n%2) s.b[n]=4/(Math.PI*n);
      if (id==='triangle' && n%2) s.b[n]=8*(-1)**((n-1)/2)/(Math.PI*n)**2;
      if (id==='sawtooth') s.b[n]=2*(-1)**(n+1)/(Math.PI*n);
    }
  }
  return s;
}
export function validate(s) {
  if (!s || !Number.isInteger(s.N) || s.N<0 || s.N>MAX_N || !Number.isFinite(s.f0) || s.f0<55 || s.f0>440 || !Number.isFinite(s.dc) || Math.abs(s.dc)>2) throw new RangeError('Invalid period, harmonic count or DC offset.');
  for (const row of [s.a,s.b]) if (!Array.isArray(row) || row.length!==MAX_N+1 || row.some(x=>!Number.isFinite(x) || Math.abs(x)>2.5)) throw new RangeError('Invalid harmonic coefficients.');
  return s;
}
export function component(s,n,q) {return s.a[n]*Math.cos(TAU*n*q)+s.b[n]*Math.sin(TAU*n*q);}
export function value(s,q) {let y=s.dc; for(let n=1;n<=s.N;n++) y+=component(s,n,q); return y;}
export function polar(s,n) {const amplitude=Math.hypot(s.a[n],s.b[n]); return {amplitude, phase:amplitude<1e-12?0:Math.atan2(s.b[n],s.a[n])*180/Math.PI};}
export function setPolar(s,n,amplitude,phase) {
  if (!Number.isInteger(n)||n<1||n>MAX_N||!Number.isFinite(amplitude)||amplitude<0||amplitude>2.5+1e-12||!Number.isFinite(phase)||Math.abs(phase)>180) throw new RangeError('Invalid amplitude or phase.');
  amplitude=Math.min(2.5,amplitude);
  s.a[n]=amplitude*Math.cos(phase*Math.PI/180); s.b[n]=amplitude*Math.sin(phase*Math.PI/180); s.preset='custom'; return s;
}
export function active(s) {return Array.from({length:s.N},(_,i)=>i+1).filter(n=>Math.hypot(s.a[n],s.b[n])>1e-10);}
const gcd = (a,b) => b ? gcd(b,a%b) : a;
export function metrics(s) {
  const ns=active(s), divisor=ns.reduce(gcd,0), acEnergy=ns.reduce((sum,n)=>sum+(s.a[n]**2+s.b[n]**2)/2,0);
  return {ns, divisor, period:divisor?1/(s.f0*divisor):null, frequency:divisor?s.f0*divisor:null,
    acRms:Math.sqrt(acEnergy), rms:Math.sqrt(s.dc**2+acEnergy), bound:ns.reduce((sum,n)=>sum+polar(s,n).amplitude,0)};
}
export function phasors(s,q) {
  let x=0, y=0;
  return active(s).map(n=>{const start={x,y}; const real=component(s,n,q), imaginary=s.a[n]*Math.sin(TAU*n*q)-s.b[n]*Math.cos(TAU*n*q); x+=imaginary; y+=real; return {n,start,x,y,radius:polar(s,n).amplitude};});
}
export function target(id,q) {
  const sine=Math.sin(TAU*q);
  if (id==='square') return Math.abs(sine)<1e-12?0:Math.sign(sine);
  if (id==='triangle') return 2*Math.asin(sine)/Math.PI;
  if (id==='sawtooth') {const r=((q+.5)%1+1)%1; return Math.abs(r)<1e-12?0:2*(r-.5);}
  return null;
}
export function audioCoefficients(s,sampleRate=48000,selected=0) {
  validate(s);
  if (!Number.isInteger(sampleRate)||sampleRate<8000||sampleRate>192000||!Number.isInteger(selected)||selected<0||selected>MAX_N) throw new RangeError('Invalid audio configuration.');
  const real=new Float32Array(MAX_N+1), imag=new Float32Array(MAX_N+1); let bound=0, omitted=0;
  for (const n of active(s)) {
    if (selected && n!==selected) continue;
    if (n*s.f0>=sampleRate*.45) {omitted++; continue;}
    real[n]=s.a[n]; imag[n]=s.b[n]; bound+=Math.hypot(real[n],imag[n]);
  }
  return {real,imag,bound,omitted};
}
export function soundSamples(s,{sampleRate=48000,seconds=2,volume=.15,selected=0}={}) {
  if (!Number.isFinite(seconds)||seconds<.1||seconds>10||!Number.isFinite(volume)||volume<0||volume>.3) throw new RangeError('Invalid audio duration or gain.');
  const coeff=audioCoefficients(s,sampleRate,selected), count=Math.round(sampleRate*seconds), samples=new Float32Array(count), gain=coeff.bound?volume/coeff.bound:0;
  for (let i=0;i<count;i++) {
    const t=i/sampleRate, envelope=Math.max(0,Math.min(1,t/.025,(count-1-i)/sampleRate/.025)); let y=0;
    for (let n=1;n<=s.N;n++) y+=coeff.real[n]*Math.cos(TAU*n*s.f0*t)+coeff.imag[n]*Math.sin(TAU*n*s.f0*t);
    samples[i]=y*gain*envelope;
  }
  return samples;
}
export function wav(s,options={}) {
  const rate=options.sampleRate??48000, samples=soundSamples(s,options), bytes=new ArrayBuffer(44+samples.length*2), view=new DataView(bytes);
  const text=(offset,str)=>[...str].forEach((c,i)=>view.setUint8(offset+i,c.charCodeAt(0)));
  text(0,'RIFF'); view.setUint32(4,bytes.byteLength-8,true); text(8,'WAVEfmt '); view.setUint32(16,16,true); view.setUint16(20,1,true); view.setUint16(22,1,true); view.setUint32(24,rate,true); view.setUint32(28,2*rate,true); view.setUint16(32,2,true); view.setUint16(34,16,true); text(36,'data'); view.setUint32(40,samples.length*2,true);
  samples.forEach((x,i)=>view.setInt16(44+i*2,Math.round(x*32767),true)); return bytes;
}
export function csv(s) {
  validate(s);
  const coefficients=Array.from({length:MAX_N},(_,i)=>[s.a[i+1],s.b[i+1]]).flat().join(',');
  return 'f0_Hz,N,A0,'+Array.from({length:MAX_N},(_,i)=>`A${i+1},B${i+1}`).join(',')+',time_s,cycle,S_N\n'+Array.from({length:1025},(_,i)=>{const q=2*i/1024; return [s.f0,s.N,s.dc,coefficients,q/s.f0,q,value(s,q)].join(',');}).join('\n')+'\n';
}
