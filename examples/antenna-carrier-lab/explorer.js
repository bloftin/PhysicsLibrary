import {createIcons,RotateCcw,Download,Play,Pause,SkipBack,Scan,Orbit,RadioReceiver,RadioTower,Focus} from 'lucide';
import {format,scaleLinear,line,max,extent} from 'd3';
import {PRESETS,preset,validate,parameters,state,farField,tuneAndMatch,sweep,csv} from './model.js';
import {createScene} from './scene.js';
const $=id=>document.getElementById(id),icons=()=>createIcons({icons:{RotateCcw,Download,Play,Pause,SkipBack,Scan,Orbit,RadioReceiver,RadioTower,Focus}});
const number=x=>x===0?'0':format('.5~g')(x).replace(/\u2212/g,'-'),unit=(x,u)=>x===0?'0 '+u:format('.4~s')(x).replace(/\u2212/g,'-')+u;
let p=preset(),time=.125,view='close',running=false,previous=0,frame,historyData=[],sweepData=[];
let scene=createScene($('scene'));$('webgl-fallback').hidden=!!scene;
for(const [id,title]of Object.entries(PRESETS))$('preset').add(new Option(title,id));
function stop(){running=false;cancelAnimationFrame(frame);previous=0;$('play').innerHTML='<i data-lucide="play"></i>';$('play').ariaLabel=$('play').title='Play slowed oscillation';icons();}
function sync(){
 $('preset').value=p.id;for(const id of ['fMHz','f0MHz','length','E0','voltage','load','source','theta','psi','loss'])$(id).value=p[id];$('tuning').checked=p.tuning;$('f0MHz').disabled=!p.tuning;
 $('rx-inputs').hidden=p.mode!=='receive';$('tx-inputs').hidden=p.mode!=='transmit';for(const mode of ['receive','transmit'])$(mode).setAttribute('aria-pressed',p.mode===mode);
 $('theta-value').textContent=p.theta+' degrees';$('psi-value').textContent=p.psi+' degrees';$('time').value=time;$('time-value').textContent=time.toFixed(3);$('error').hidden=true;
 $('close-view').setAttribute('aria-pressed',view==='close');$('wave-view').setAttribute('aria-pressed',view==='wave');
}
function edit(fn){stop();try{const next={...p};fn(next);p=validate(next);sync();recalculate();}catch(e){$('error').textContent=e.message+' Last valid state retained.';$('error').hidden=false;}}
function canvas(id){const c=$(id),r=c.getBoundingClientRect(),d=Math.min(devicePixelRatio||1,2);if(c.width!==Math.round(r.width*d)||c.height!==Math.round(r.height*d)){c.width=Math.round(r.width*d);c.height=Math.round(r.height*d);}const ctx=c.getContext('2d');ctx.setTransform(d,0,0,d,0,0);ctx.clearRect(0,0,r.width,r.height);return{ctx,w:r.width,h:r.height};}
function text(ctx,s,x,y,color='#587278',size=11,align='center'){ctx.font=size+'px Arial';ctx.textAlign=align;ctx.fillStyle=color;ctx.fillText(s,x,y);}
function lines(ctx,data,x,y,color,accessor){ctx.strokeStyle=color;ctx.lineWidth=2.1;ctx.beginPath();line().x(d=>x(d.x)).y(d=>y(accessor(d))).context(ctx)(data);ctx.stroke();}
function history(){
 const {ctx,w,h}=canvas('history'),x=scaleLinear().domain([0,2]).range([44,w-17]),y=scaleLinear().domain([-1.2,1.2]).range([h-35,20]);
 for(const v of [-1,0,1]){ctx.strokeStyle='#d6e3e6';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(44,y(v));ctx.lineTo(w-17,y(v));ctx.stroke();text(ctx,String(v),32,y(v)+4);}
 for(const t of [0,.5,1,1.5,2])text(ctx,String(t),x(t),h-17);text(ctx,'t / T',w/2,h-2);
 lines(ctx,historyData,x,y,'#087c88',d=>d.drive);lines(ctx,historyData,x,y,'#9c771a',d=>d.current);lines(ctx,historyData,x,y,'#bf4e55',d=>d.charge);
 ctx.setLineDash([4,4]);ctx.strokeStyle='#799399';ctx.beginPath();ctx.moveTo(x(time),20);ctx.lineTo(x(time),h-35);ctx.stroke();ctx.setLineDash([]);
}
function power(){
 const m=parameters(p),{ctx,w}=canvas('power'),total=m.supplied,segments=[{name:p.mode==='receive'?'Load':'Source R',v:m.terminationPower,c:'#218b86'},{name:'Antenna heat',v:m.heat,c:'#bf4e55'},{name:p.mode==='receive'?'Re-radiated':'Radiated',v:m.radiated,c:'#ad8524'}];
 let left=0;for(const seg of segments){const width=total?seg.v/total*w:0;ctx.fillStyle=seg.c;ctx.fillRect(left,8,width,28);if(width>60)text(ctx,number(seg.v/total*100)+'%',left+width/2,27,'white',11);left+=width;}
 if(total===0){ctx.fillStyle='#edf3f4';ctx.fillRect(0,8,w,28);text(ctx,'No average power transfer',w/2,27);}
 text(ctx,'Input = load/source R + heat + radiation',0,64,'#587278',11,'left');
 $('power-in').textContent=unit(total,'W');$('power-termination').textContent=unit(m.terminationPower,'W');$('power-heat').textContent=unit(m.heat,'W');$('power-rad').textContent=unit(m.radiated,'W');
}
function response(){
 const {ctx,w,h}=canvas('response'),[lo,hi]=extent(sweepData,d=>d.fMHz),x=scaleLinear().domain([lo,hi]).range([65,w-17]),peak=max(sweepData,d=>d.power)||1,y=scaleLinear().domain([0,peak*1.12]).range([h-38,25]);
 for(const v of [0,.5,1]){ctx.strokeStyle='#d6e3e6';ctx.beginPath();ctx.moveTo(65,y(v*peak));ctx.lineTo(w-17,y(v*peak));ctx.stroke();text(ctx,unit(v*peak,'W'),57,y(v*peak)+4,'#587278',10,'right');}
 for(const f of x.ticks(4))text(ctx,number(f),x(f),h-20,'#587278',10);text(ctx,'Frequency (MHz)',w/2,h-3);
 ctx.strokeStyle='#087c88';ctx.lineWidth=2.3;ctx.beginPath();line().x(d=>x(d.fMHz)).y(d=>y(d.power)).context(ctx)(sweepData);ctx.stroke();
 if(p.fMHz>=lo&&p.fMHz<=hi){ctx.strokeStyle='#9c771a';ctx.setLineDash([4,4]);ctx.beginPath();ctx.moveTo(x(p.fMHz),25);ctx.lineTo(x(p.fMHz),h-38);ctx.stroke();ctx.setLineDash([]);}
 $('sweep-note').textContent=p.fMHz<lo||p.fMHz>hi?'Operating f is outside this window':'Gold line: current operating frequency';
 $('response-caption').textContent=(p.mode==='receive'?'Load power':'Radiated power')+' with all other circuit and illumination settings held fixed. '+(p.tuning?'Window spans about five loaded bandwidths on either side of f0.':'Without the coil this simplified circuit is capacitive; no LC resonance is shown.');
}
function pattern(){
 const {ctx,w,h}=canvas('pattern'),r=Math.min(w*.37,h*.38),cx=w/2,cy=h/2;
 ctx.strokeStyle='#d5e2e4';ctx.lineWidth=1;for(const f of [.5,1]){ctx.beginPath();ctx.arc(cx,cy,r*f,0,Math.PI*2);ctx.stroke();}ctx.beginPath();ctx.moveTo(cx-r-8,cy);ctx.lineTo(cx+r+8,cy);ctx.moveTo(cx,cy-r-8);ctx.lineTo(cx,cy+r+8);ctx.stroke();
 ctx.strokeStyle='#ad8524';ctx.lineWidth=2.8;ctx.beginPath();for(let i=0;i<=360;i++){const t=i*Math.PI/180,rho=r*Math.sin(t)**2,x=cx+rho*Math.sin(t),y=cy-rho*Math.cos(t);i?ctx.lineTo(x,y):ctx.moveTo(x,y);}ctx.stroke();
 text(ctx,'Wire axis / null',cx,cy-r-15);text(ctx,'Broadside',cx+r*.85,cy+r*.65);text(ctx,'1',cx+r+13,cy+4);
}
function readings(){
 const m=parameters(p),s=state(p,time),rx=p.mode==='receive';
 $('story-title').textContent=rx?'Wave field drives local charge motion':'Local charge motion launches a wave';
 $('story').textContent=rx?'A transverse incident E field couples to the wire axis. The driven charge/current mode and external load exchange energy with that field.':'A generator drives alternating current. Electrons oscillate locally while radiation transports energy away from the antenna.';
 $('scale-note').textContent='L / lambda = '+number(p.length/m.lambda)+'; T = '+unit(1/m.f,'s');
 $('scene-note').textContent=view==='close'?'Zoomed, schematic wire cross-section. Fixed gray lattice, cyan mobile electrons, red/blue incremental arm charge. Axial drive is an applied-field/EMF cue, not a solved total field inside metal.':rx?'Incoming plane wave: E (teal), B (purple), and energy propagation (gold). Coordinates are wavelengths; central marker denotes the antenna location, not its drawn physical size. E and cB use equal normalized arrow scales.':'Outgoing radiation-zone samples from 2 to 4 wavelengths at quarter-wavelength steps. E and cB share a scale normalized to the current broadside peak at 3 wavelengths. The interior is intentionally not filled with a false far-field solution.';
 $('current-peak').textContent=unit(m.peak,'A');$('charge-peak').textContent=unit(m.qPeak,'C');$('output-label').textContent=rx?'Power in load, average':'Radiated power, average';$('output-power').textContent=unit(rx?m.terminationPower:m.radiated,'W');
 const gain=m.excursion?.11*p.length/2.4/m.excursion:0;
 $('carrier-scale').textContent='Actual center drift excursion: '+unit(m.excursion,'m')+'; peak drift speed: '+unit(m.driftPeak,'m/s')+'. '+(gain?'Marker displacement magnified by '+number(gain)+' (adaptive between settings).':'No driven carrier motion.')+' Assumed n = 8.5e28 /m3 and effective area = 1 mm2.';
 $('instant-i').textContent='I(t) = '+unit(s.current,'A');$('instant-q').textContent='q upper/lower = '+unit(s.charge,'C')+' / '+unit(-s.charge,'C');$('instant-v').textContent=(rx?'Load voltage':'Source-R voltage')+' = '+unit(s.terminal,'V');$('instant-u').textContent='Equivalent LC energy = '+unit(s.uC+s.uL,'J');
 $('power-title').textContent=rx?'Received power is shared, not created':'Generator energy becomes heat and radiation';$('input-title').textContent=rx?'Extracted by driven mode':'Generator power';$('termination-title').textContent=rx?'Delivered to load':'Generator-R heating';$('rad-title').textContent=rx?'Mode re-radiation':'Radiated to space';
 $('power-note').textContent=rx?'Incident average flux: '+unit(m.flux,'W/m2')+'. Available conjugate-matched power: '+unit(m.available,'W')+'. Coupled effective aperture: '+unit(m.aperture,'m2')+'. Radiation is the current-associated scattering term; full structural scattering is not solved.':'Generator average power = source-resistance heating + antenna heating + outgoing radiation. Antenna radiation efficiency excludes generator-resistance loss. Radiation resistance is not a heater.';
 for(const [id,value]of [['wavelength',unit(m.lambda,'m')],['electrical-length',number(p.length/m.lambda)],['radiation-r',unit(m.rad,'ohm')],['reactance',unit(m.X,'ohm')],['efficiency',number(m.efficiency*100)+'%'],['phase',m.peak?number(-Math.atan2(m.X,m.R)*180/Math.PI)+' degrees':'No driven phase']])$(id).textContent=value;
}
function moving(){readings();history();scene?.update(p,time,view);$('time').value=time;$('time-value').textContent=time.toFixed(3);}
function recalculate(){const m=parameters(p);historyData=Array.from({length:241},(_,i)=>{const x=i/120,s=state(p,x);return{x,drive:m.drive?s.drive/Math.abs(m.drive):0,current:m.peak?s.current/m.peak:0,charge:m.qPeak?s.charge/m.qPeak:0};});sweepData=sweep(p);moving();power();response();pattern();}
function animate(t){if(!running)return;if(previous)time=(time+(t-previous)/1000*+$('speed').value)%2;previous=t;moving();frame=requestAnimationFrame(animate);}
$('play').onclick=()=>{if(running){stop();return;}running=true;previous=0;$('play').innerHTML='<i data-lucide="pause"></i>';$('play').ariaLabel=$('play').title='Pause slowed oscillation';icons();frame=requestAnimationFrame(animate);};
$('time').oninput=()=>{stop();time=+$('time').value;moving();};$('time-reset').onclick=()=>{stop();time=0;moving();};
$('preset').onchange=()=>{stop();p=preset($('preset').value);time=.125;sync();recalculate();};$('reset').onclick=()=>{stop();p=preset(p.id);time=.125;sync();recalculate();scene?.reset();};
for(const mode of ['receive','transmit'])$(mode).onclick=()=>edit(next=>next.mode=mode);
for(const id of ['fMHz','f0MHz','length','E0','voltage','load','source','loss'])$(id).onchange=()=>edit(next=>next[id]=Number($(id).value||NaN));
for(const id of ['theta','psi'])$(id).oninput=()=>edit(next=>next[id]=+$(id).value);
$('tuning').onchange=()=>edit(next=>next.tuning=$('tuning').checked);$('match').onclick=()=>edit(next=>Object.assign(next,tuneAndMatch(next)));
for(const [id,value]of [['close-view','close'],['wave-view','wave']])$(id).onclick=()=>{view=value;sync();moving();};
$('camera-reset').onclick=()=>scene?.reset();$('camera-front').onclick=()=>scene?.front();
$('download').onclick=()=>{const url=URL.createObjectURL(new Blob([csv(p)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='antenna-carrier-cycles.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),500);};
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
let resizeFrame;new ResizeObserver(()=>{cancelAnimationFrame(resizeFrame);resizeFrame=requestAnimationFrame(()=>{history();power();response();pattern();});}).observe(document.querySelector('.experiment'));
icons();sync();recalculate();
