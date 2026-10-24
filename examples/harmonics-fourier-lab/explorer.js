import {scaleLinear,extent} from 'd3';
import {createIcons,Play,Pause,StepForward,RotateCcw,RotateCw,Download,Volume2,VolumeX,AudioLines,Eraser} from 'lucide';
import {MAX_N,TAU,preset,validate,value,polar,setPolar,metrics,phasors,target,csv,wav,audioCoefficients} from './model.js';
import {Synth} from './audio.js';

const $=id=>document.getElementById(id), icons={Play,Pause,StepForward,RotateCcw,RotateCw,Download,Volume2,VolumeX,AudioLines,Eraser};
const ink='#203033', muted='#657a7c', grid='#dce6e5', teal='#087f78', coral='#ce5143', palette=[teal,coral,'#a47316','#576bac'];
let state=preset(), selected=1, q=.12, running=false, last=0, frameId=null, volume=.15, mode='mix';
const fmt=(x,d=3)=>Math.abs(x)<1e-10?'0':Number(x.toPrecision(d)).toString();
const milliseconds=t=>fmt(t*1000,4)+' ms';
function icon(button,name,label) {button.replaceChildren(); const i=document.createElement('i');i.dataset.lucide=name;button.append(i);if(label){const span=document.createElement('span');span.textContent=label;button.append(span);}createIcons({icons});}
function alert(message='') {$('error').textContent=message; $('error').hidden=!message;}
function selectedAudio() {return mode==='selected'?selected:0;}
const synth=new Synth(on=>{$('listen').setAttribute('aria-pressed',String(on));icon($('listen'),on?'volume-x':'volume-2',on?'Stop sound':'Listen');soundStatus();});
function soundStatus() {
  const c=audioCoefficients(state,synth.context?.sampleRate||48000,selectedAudio());
  $('audio-status').textContent=!synth.on?'Sound is off.':c.bound===0?'Silent: no retained AC component.':`${mode==='selected'?'Harmonic '+selected:'Mixture'} at ${fmt(state.f0)} Hz base; DC removed.${c.omitted?' '+c.omitted+' high components omitted from sound.':''}`;
}
function audioUpdate() {synth.update(state,volume,selectedAudio());soundStatus();}
function change(callback,{custom=false}={}) {
  try {callback(); validate(state);if(custom) state.preset='custom';alert();sync();audioUpdate();}catch(e){alert(e.message);}
}
function stopAnimation() {running=false;if(frameId!==null){cancelAnimationFrame(frameId);frameId=null;}$('play').setAttribute('aria-pressed','false');$('play').setAttribute('aria-label','Play slow-motion clock');$('play').title='Play slow-motion clock';icon($('play'),'play');}
function sync() {
  $('preset').value=state.preset;
  $('count').value=state.N;$('count-value').value=state.N;
  $('frequency').value=state.f0;$('frequency-range').value=state.f0;
  $('dc').value=state.dc;$('dc-value').value=fmt(state.dc);
  const p=polar(state,selected), m=metrics(state);
  $('amplitude').value=p.amplitude;$('amplitude-value').value=fmt(p.amplitude);
  $('phase').value=p.phase;$('phase-value').value=fmt(p.phase,4)+'°';
  $('selected-title').textContent='Harmonic '+selected;
  $('selected-frequency').textContent=`${fmt(selected*state.f0)} Hz · T${selected} = ${milliseconds(1/(selected*state.f0))}`;
  $('coefficients').textContent=`A${selected} = ${fmt(state.a[selected])}, B${selected} = ${fmt(state.b[selected])}`;
  $('selected-note').textContent=selected>state.N?`n = ${selected} is excluded because it exceeds N = ${state.N}. Its saved coefficients are retained, but it contributes neither to the sum nor to sound.`:p.amplitude<1e-10?`n = ${selected} has zero amplitude. Its phase is undefined; no vector or sound component is present.`:`R${selected} cos(${selected}ω₀t − δ${selected}), with δ${selected} = ${fmt(p.phase,4)}°. Positive 90° is a sine, not a time advance.`;
  $('base-period').textContent=milliseconds(1/state.f0);
  $('omega').textContent=fmt(TAU*state.f0,5)+' rad/s';
  $('fundamental').textContent=m.period?milliseconds(m.period):'No smallest period';
  $('active-count').textContent=`${m.ns.length} nonzero component${m.ns.length===1?'':'s'} retained`;
  $('period-note').textContent=!m.divisor?'A constant repeats after every positive interval; no fundamental oscillation frequency can be inferred.':m.divisor>1?`The nonzero harmonic numbers have greatest common divisor ${m.divisor}. This sum repeats every T₀ / ${m.divisor}, at ${fmt(m.frequency)} Hz.`:m.ns.includes(1)?'The first harmonic is present. All components return after T₀, which is the smallest period of this sum.':'The first harmonic is absent, but the remaining harmonic numbers have greatest common divisor 1. T₀ is still the smallest period.';
  $('formula').textContent='S'+state.N+'(t) = '+fmt(state.dc)+m.ns.flatMap(n=>[[state.a[n],'cos'],[state.b[n],'sin']].filter(([coefficient])=>Math.abs(coefficient)>1e-10).map(([coefficient,basis])=>` ${coefficient<0?'−':'+'} ${fmt(Math.abs(coefficient))} ${basis}(${n===1?'':n}ω₀t)`)).join('');
  const short=m.ns.length>4;
  if(short) $('formula').textContent=`S${state.N}(t) = A₀ + Σₙ₌₁…${state.N} [Aₙ cos(nω₀t) + Bₙ sin(nω₀t)]`;
  for (const button of $('bank').children) {
    const n=Number(button.dataset.n), r=polar(state,n).amplitude;
    button.setAttribute('aria-pressed',String(n===selected));button.classList.toggle('excluded',n>state.N);
    button.style.setProperty('--height',Math.max(2,52*r/2.5)+'px');
    button.setAttribute('aria-label',`Harmonic ${n}, amplitude ${fmt(r)}${n>state.N?', excluded by N':''}`);
    button.title=`n = ${n}: ${fmt(n*state.f0)} Hz, R = ${fmt(r)}${n>state.N?' (not retained)':''}`;
  }
  draw();
}
for(let n=1;n<=MAX_N;n++) {
  const button=document.createElement('button');button.type='button';button.dataset.n=n;
  const bar=document.createElement('span');bar.className='bar';bar.setAttribute('aria-hidden','true');
  const label=document.createElement('span');label.textContent=n;button.append(bar,label);
  button.addEventListener('click',()=>{selected=n;sync();audioUpdate();});$('bank').append(button);
}
function canvas(id) {
  const c=$(id), box=c.getBoundingClientRect(), w=box.width, h=box.height, dpr=Math.min(devicePixelRatio||1,2);
  if(c.width!==Math.round(w*dpr)||c.height!==Math.round(h*dpr)){c.width=Math.round(w*dpr);c.height=Math.round(h*dpr);}
  const ctx=c.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);ctx.font='12px Arial';ctx.lineCap='round';return {ctx,w,h};
}
function line(ctx,x1,y1,x2,y2,color,width=1,dash=[]) {ctx.beginPath();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.setLineDash([]);}
function circle(ctx,x,y,r,color,fill=false,width=1) {ctx.beginPath();ctx.arc(x,y,Math.max(0,r),0,TAU);ctx.lineWidth=width;ctx.strokeStyle=color;ctx.fillStyle=color;fill?ctx.fill():ctx.stroke();}
function text(ctx,str,x,y,{color=muted,align='left',size=12}={}) {ctx.font=`${size}px Arial`;ctx.fillStyle=color;ctx.textAlign=align;ctx.fillText(str,x,y);}
function path(ctx,points,x,y,color,width=2,dash=[]) {ctx.beginPath();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);let pen=false;for(const p of points){if(p.y===null){pen=false;continue;}if(pen)ctx.lineTo(x(p.x),y(p.y));else{ctx.moveTo(x(p.x),y(p.y));pen=true;}}ctx.stroke();ctx.setLineDash([]);}
function drawWheel() {
  const {ctx,w,h}=canvas('wheel'), m=metrics(state), scale=(Math.min(w,h)-65)/(2*Math.max(1,m.bound)), cx=w/2, cy=h/2;
  line(ctx,20,cy,w-20,cy,grid);line(ctx,cx,35,cx,h-35,grid);
  text(ctx,'Component phases',14,21,{color:ink});
  const chain=phasors(state,q);
  for(const p of chain){const x0=cx+p.start.x*scale,y0=cy-p.start.y*scale,x=cx+p.x*scale,y=cy-p.y*scale,color=p.n===selected?coral:teal;circle(ctx,x0,y0,p.radius*scale,p.n===selected?'#d79589':'#bdcfcc');line(ctx,x0,y0,x,y,color,p.n===selected?2.6:1.7);circle(ctx,x,y,p.n===selected?3.6:2.5,color,true);}
  const tip=chain.at(-1)||{x:0,y:0}, tx=cx+tip.x*scale,ty=cy-tip.y*scale;
  line(ctx,tx,ty,w-12,ty,teal,1,[4,4]);circle(ctx,tx,ty,4,teal,true);
  text(ctx,'S'+state.N+' − A₀ = '+fmt(tip.y,4),w/2,h-13,{align:'center',color:teal,size:13});
  if(!chain.length) text(ctx,'No oscillating components',w/2,cy+28,{align:'center'});
}
function drawWave() {
  const {ctx,w,h}=canvas('wave'), pad={l:48,r:12,t:30,b:43}, samples=Array.from({length:1201},(_,i)=>({x:2*i/1200,y:value(state,2*i/1200)})), overlay=$('show-target').checked&&['square','triangle','sawtooth'].includes(state.preset);
  const domain=extent(samples,d=>d.y);if(overlay){domain[0]=Math.min(domain[0],-1);domain[1]=Math.max(domain[1],1);}const span=Math.max(.5,domain[1]-domain[0]);
  const x=scaleLinear().domain([0,2]).range([pad.l,w-pad.r]), y=scaleLinear().domain([domain[0]-.12*span,domain[1]+.12*span]).range([h-pad.b,pad.t]);
  for(const v of y.ticks(4)){line(ctx,pad.l,y(v),w-pad.r,y(v),grid);text(ctx,fmt(v),pad.l-8,y(v)+4,{align:'right'});}
  for(const t of [0,.5,1,1.5,2]){line(ctx,x(t),pad.t,x(t),h-pad.b,grid,1,t===1?[4,4]:[]);text(ctx,String(t),x(t),h-pad.b+18,{align:t===2?'right':t===0?'left':'center'});}
  text(ctx,'S_N (arbitrary units)',pad.l,15,{color:ink,size:11});text(ctx,'t / T₀  (base cycles)',(pad.l+w-pad.r)/2,h-5,{align:'center',size:11});
  ctx.save();ctx.beginPath();ctx.rect(pad.l,pad.t,w-pad.l-pad.r,h-pad.t-pad.b);ctx.clip();
  if(overlay){const points=samples.map(p=>{const v=target(state.preset,p.x), jump=state.preset==='square'&&Math.abs(Math.sin(TAU*p.x))<1e-10||state.preset==='sawtooth'&&Math.abs((p.x+.5)%1)<1e-10;return {x:p.x,y:jump?null:v};});path(ctx,points,x,y,'#879a9a',1.5,[5,4]);for(let i=0;i<=4;i++){const t=i/2;if(state.preset==='square'||state.preset==='sawtooth'&&i%2)circle(ctx,x(t),y(0),2.5,'#879a9a',true);}}
  path(ctx,samples,x,y,teal,2.5);line(ctx,x(q),pad.t,x(q),h-pad.b,coral,1.2);circle(ctx,x(q),y(value(state,q)),4,coral,true);ctx.restore();
  if(overlay) text(ctx,'Dashed: ideal reference',w-pad.r,pad.t+12,{align:'right',size:11});
}
function drawStack() {
  const {ctx,w,h}=canvas('stack'), x0=w<500?125:165, right=w-15, top=27, bottom=h-35, row=(bottom-top)/4, x=scaleLinear().domain([0,1]).range([x0,right]), phase=q%1;
  for(const t of [0,.5,1]){line(ctx,x(t),top-3,x(t),bottom+3,grid,1,t===1?[4,4]:[]);text(ctx,String(t),x(t),h-19,{align:t===1?'right':'center'});}
  text(ctx,'t / T₀',(x0+right)/2,h-3,{align:'center',size:11});
  for(let n=1;n<=4;n++) {
    const cy=top+(n-.5)*row, r=Math.min(18,row*.3), color=palette[n-1], cx=x0-35;
    text(ctx,'n = '+n,4,cy-5,{color:ink});text(ctx,milliseconds(1/(n*state.f0)),4,cy+12,{size:11});circle(ctx,cx,cy,r,grid);
    const angle=TAU*n*phase;line(ctx,cx,cy,cx+r*Math.sin(angle),cy-r*Math.cos(angle),color,2);circle(ctx,cx+r*Math.sin(angle),cy-r*Math.cos(angle),2.5,color,true);
    line(ctx,x0,cy,right,cy,grid);const points=Array.from({length:401},(_,i)=>({x:i/400,y:Math.cos(TAU*n*i/400)}));path(ctx,points,x,v=>cy-r*v,color,1.8);circle(ctx,x(phase),cy-r*Math.cos(angle),3,color,true);
  }
  line(ctx,x(phase),top-3,x(phase),bottom+3,coral,1,[2,4]);
}
function draw(){$('clock').value=q;$('clock-value').value=fmt(q,4)+' T₀';$('instant').textContent=`S${state.N} = ${fmt(value(state,q),4)} · t = ${milliseconds(q/state.f0)}`;drawWheel();drawWave();drawStack();}
$('preset').addEventListener('change',()=>change(()=>{const f=state.f0;state=preset($('preset').value);state.f0=f;selected=1;q=.12;}));
for(const id of ['frequency','frequency-range']) $(id).addEventListener(id==='frequency'?'change':'input',()=>{const v=Number($(id).value);if(!Number.isFinite(v)||v<55||v>440){alert('Base frequency must be between 55 and 440 Hz.');return;}change(()=>state.f0=v);});
$('count').addEventListener('input',()=>change(()=>state.N=Number($('count').value)));
$('dc').addEventListener('input',()=>change(()=>state.dc=Number($('dc').value),{custom:true}));
$('amplitude').addEventListener('input',()=>change(()=>setPolar(state,selected,Number($('amplitude').value),polar(state,selected).phase)));
$('phase').addEventListener('input',()=>change(()=>setPolar(state,selected,polar(state,selected).amplitude,Number($('phase').value))));
$('cosine').addEventListener('click',()=>change(()=>setPolar(state,selected,polar(state,selected).amplitude||1,0)));
$('sine').addEventListener('click',()=>change(()=>setPolar(state,selected,polar(state,selected).amplitude||1,90)));
$('remove').addEventListener('click',()=>change(()=>setPolar(state,selected,0,0)));
$('show-target').addEventListener('change',draw);
$('clock').addEventListener('input',()=>{stopAnimation();q=Number($('clock').value);draw();});
$('step').addEventListener('click',()=>{stopAnimation();q=q+.125>2?0:q+.125;draw();});
$('play').addEventListener('click',()=>{if(running)stopAnimation();else{running=true;last=performance.now();$('play').setAttribute('aria-pressed','true');$('play').setAttribute('aria-label','Pause clock');$('play').title='Pause clock';icon($('play'),'pause');frameId=requestAnimationFrame(frame);}});
function frame(now){if(!running)return;q=(q+Math.min(.05,(now-last)/1000)*.2)%2;last=now;draw();frameId=requestAnimationFrame(frame);}
$('reset').addEventListener('click',()=>{stopAnimation();synth.stop();state=preset();q=.12;selected=1;mode='mix';volume=.15;$('audio-mode').value=mode;$('volume').value=volume;$('volume-value').value='15%';$('show-target').checked=true;alert();sync();soundStatus();});
$('listen').addEventListener('click',async()=>{try{if(synth.on)synth.stop();else await synth.start(state,volume,selectedAudio());alert();}catch(e){synth.stop();alert(e.message);}});
$('audio-mode').addEventListener('change',()=>{mode=$('audio-mode').value;audioUpdate();});
$('volume').addEventListener('input',()=>{volume=Number($('volume').value);$('volume-value').value=Math.round(volume*100)+'%';audioUpdate();});
function download(data,type,name){const url=URL.createObjectURL(new Blob([data],{type})), a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
$('download').addEventListener('click',()=>download(csv(state),'text/csv','harmonics-fourier.csv'));
$('wav').addEventListener('click',()=>download(wav(state,{volume,selected:selectedAudio()}),'audio/wav','harmonics-'+mode+'.wav'));
document.addEventListener('visibilitychange',()=>{if(document.hidden){synth.stop();stopAnimation();}});
window.addEventListener('pagehide',()=>{synth.stop();stopAnimation();});
const resize=new ResizeObserver(draw);for(const id of ['wheel','wave','stack'])resize.observe($(id));
createIcons({icons});sync();
