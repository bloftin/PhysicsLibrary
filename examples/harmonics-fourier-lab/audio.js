import {audioCoefficients} from './model.js';

export class Synth {
  constructor(onState) {this.onState=onState; this.context=null; this.oscillator=null; this.gain=null; this.on=false; this.generation=0;}
  async start(s,volume,selected=0) {
    const generation=++this.generation;
    const Context=globalThis.AudioContext||globalThis.webkitAudioContext;
    if(!Context) throw new Error('Live sound is unavailable in this browser. WAV export still works.');
    this.context ||= new Context();
    await this.context.resume();
    if(generation!==this.generation) {if(!this.on) await this.context.suspend(); return;}
    this.on=true; this.update(s,volume,selected); this.onState(true);
  }
  update(s,volume,selected=0) {
    if(!this.on) return;
    const ctx=this.context, c=audioCoefficients(s,ctx.sampleRate,selected), now=ctx.currentTime;
    if(!this.oscillator) {
      this.oscillator=ctx.createOscillator(); this.gain=ctx.createGain();
      this.gain.gain.setValueAtTime(0,now); this.oscillator.connect(this.gain); this.gain.connect(ctx.destination);
      this.oscillator.start();
    }
    this.oscillator.setPeriodicWave(ctx.createPeriodicWave(c.real,c.imag,{disableNormalization:true}));
    this.oscillator.frequency.setTargetAtTime(s.f0,now,.02);
    this.gain.gain.cancelScheduledValues(now);
    this.gain.gain.setTargetAtTime(c.bound?Math.max(0,Math.min(.3,volume))/c.bound:0,now,.02);
    return c;
  }
  stop() {
    ++this.generation; this.on=false;
    const ctx=this.context, osc=this.oscillator, gain=this.gain;
    this.oscillator=null; this.gain=null;
    if(osc) {
      const now=ctx.currentTime;
      gain.gain.cancelScheduledValues(now); gain.gain.setTargetAtTime(0,now,.008);
      osc.stop(now+.06); osc.onended=()=>{osc.disconnect(); gain.disconnect(); if(!this.on) ctx.suspend().catch(()=>{});};
    } else if(ctx) ctx.suspend().catch(()=>{});
    this.onState(false);
  }
}
