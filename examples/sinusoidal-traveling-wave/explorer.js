import {scaleLinear} from 'd3';
import {createIcons,Play,Pause,StepBack,StepForward,RotateCcw,Download,ArrowLeft,ArrowRight} from 'lucide';
import {TAU,parameters,preset,metrics,phase,sample,wrap,changeForm,crest,snapshot,history,csv} from './model.js';
const $=id=>document.getElementById(id), icons={Play,Pause,StepBack,StepForward,RotateCcw,Download,ArrowLeft,ArrowRight};
const teal='#087d86',coral='#c74e46',gold='#9b7212',ink='#26383c',muted='#627b80',grid='#dce6e8';
let {p,t}=preset(),example='explore',running=false,last=0,raf=null,speed=.25;
let fieldKey='',fieldImage=null;
const fmt=(x,d=4)=>Math.abs(x)<1e-10?'0':String(Number(x.toPrecision(d)));
function error(message=''){$('error').textContent=message;$('error').hidden=!message;}
function setPlayIcon(name){$('play').innerHTML=`<i data-lucide="${name}"></i>`;createIcons({icons});}
function stop(){running=false;if(raf!==null){cancelAnimationFrame(raf);raf=null;}$('play').setAttribute('aria-pressed','false');$('play').setAttribute('aria-label','Play clock');$('play').title='Play clock';setPlayIcon('play');}
function change(fn,custom=true){try{const candidate=parameters(fn({...p}));p=candidate;if(custom)example='custom';error();sync();}catch(e){error(e.message);}}
function sync(){
  const m=metrics(p);$('example').value=example;$('amplitude').value=p.A*100;$('amplitude-value').value=fmt(p.A*100);$('wavelength').value=p.lambda;$('frequency').value=p.f;
  $('wavenumber').value=m.k;$('omega').value=m.omega;$('phase').value=p.phi*180/Math.PI;$('phase-value').value=fmt(p.phi*180/Math.PI)+'°';$('probe').value=Number(p.probe.toFixed(5));$('probe-range').value=p.probe;$('form').value=p.form;
  $('left').setAttribute('aria-pressed',String(p.direction===-1));$('right').setAttribute('aria-pressed',String(p.direction===1));
  $('equation').textContent=`u(x, t) = A ${p.form}(kx ${p.direction===1?'−':'+'} ωt + φ)`;
  $('lambda-readout').textContent=fmt(p.lambda)+' m';$('period-readout').textContent=fmt(m.T)+' s';
  $('lambda-title').textContent=(p.A?'':'Nominal ')+'wavelength λ';$('period-title').textContent=(p.A?'':'Nominal ')+'period T';
  $('wave-note').textContent=p.A?`f = ${fmt(p.f)} Hz. A spatial pattern translates ${p.direction===1?'right':'left'} while each material marker keeps its horizontal position. The two plots use fixed windows, so changing λ or f changes the number of visible cycles.`:'Zero amplitude: a flat field has no observed wavelength, period, moving crest or observable phase. The positive λ and f settings are nominal.';
  $('history-position').textContent=`x₀ = ${fmt(p.probe)} m`;
  $('form-note').textContent=p.form==='sin'?'Equivalent sine convention: its phase constant is 90° ahead of the cosine convention for the same physical wave.':'Cosine convention. Its equivalent sine form adds 90° to the phase constant without changing the field.';
  draw();
}
function canvas(id){const c=$(id),b=c.getBoundingClientRect(),w=b.width,h=b.height,dpr=Math.min(devicePixelRatio||1,2);if(c.width!==Math.round(w*dpr)||c.height!==Math.round(h*dpr)){c.width=Math.round(w*dpr);c.height=Math.round(h*dpr);}const ctx=c.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);ctx.lineCap='round';ctx.font='12px Arial';return{ctx,w,h};}
function text(ctx,str,x,y,{color=muted,align='left',size=12}={}){ctx.font=`${size}px Arial`;ctx.fillStyle=color;ctx.textAlign=align;ctx.fillText(str,x,y);}
function line(ctx,x1,y1,x2,y2,color,width=1,dash=[]){ctx.beginPath();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.setLineDash([]);}
function dot(ctx,x,y,r,color,hollow=false){ctx.beginPath();ctx.arc(x,y,r,0,TAU);ctx.fillStyle=hollow?'#fff':color;ctx.fill();ctx.strokeStyle=color;ctx.lineWidth=1.5;ctx.stroke();}
function diamond(ctx,x,y,r,color){ctx.beginPath();ctx.moveTo(x,y-r);ctx.lineTo(x+r,y);ctx.lineTo(x,y+r);ctx.lineTo(x-r,y);ctx.closePath();ctx.fillStyle=color;ctx.fill();}
function trace(ctx,points,x,y,color,width=2,dash=[]){ctx.beginPath();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);points.forEach((d,i)=>i?ctx.lineTo(x(d.x),y(d.y)):ctx.moveTo(x(d.x),y(d.y)));ctx.stroke();ctx.setLineDash([]);}
function frame(id,xlabel){const c=canvas(id),{ctx,w,h}=c,pad={l:48,r:15,t:52,b:42},x=scaleLinear().domain([0,2]).range([pad.l,w-pad.r]),y=scaleLinear().domain([-.06,.06]).range([h-pad.b,pad.t]);
  for(const v of [-.05,0,.05]){line(ctx,pad.l,y(v),w-pad.r,y(v),grid);text(ctx,fmt(v*100),pad.l-8,y(v)+4,{align:'right'});}
  const ticks=w<450?[0,1,2]:[0,.5,1,1.5,2];for(const v of ticks){line(ctx,x(v),pad.t,x(v),h-pad.b,grid);text(ctx,fmt(v),x(v),h-pad.b+18,{align:v===0?'left':v===2?'right':'center'});}
  text(ctx,'u (cm)',pad.l,14,{color:ink,size:11});text(ctx,xlabel,(pad.l+w-pad.r)/2,h-5,{align:'center',size:11});
  return{...c,pad,x,y};
}
function clipped(c,fn){const{ctx,pad,w,h}=c;ctx.save();ctx.beginPath();ctx.rect(pad.l,pad.t,w-pad.l-pad.r,h-pad.t-pad.b);ctx.clip();fn();ctx.restore();}
function bracket(ctx,x1,x2,y,label,color=muted){line(ctx,x1,y,x2,y,color);line(ctx,x1,y-3,x1,y+3,color);line(ctx,x2,y-3,x2,y+3,color);text(ctx,label,(x1+x2)/2,y-6,{align:'center',color,size:11});}
function drawSnapshot(){const c=frame('snapshot','position x (m)'),{ctx,x,y,w,pad}=c,crestNow=crest(p,t),initial=crest(p,0);
  clipped(c,()=>{
    if($('initial').checked)trace(ctx,snapshot(p,0).map(d=>({x:d.x,y:d.u})),x,y,'#b1c3ca',1.5,[5,4]);
    if($('guides').checked&&p.A>0){for(const a of [-p.A,p.A])line(ctx,pad.l,y(a),w-pad.r,y(a),'#b8cbd0',1,[3,5]);}
    trace(ctx,snapshot(p,t).map(d=>({x:d.x,y:d.u})),x,y,teal,2.5);
    if($('particles').checked)for(let i=0;i<=40;i++){const position=2*i/40;dot(ctx,x(position),y(sample(p,position,t).u),2.3,teal,true);}
    if(initial&&$('initial').checked&&initial.x>=0&&initial.x<=2)dot(ctx,x(initial.x),y(p.A),4,gold,true);
    if(crestNow&&crestNow.x>=0&&crestNow.x<=2)diamond(ctx,x(crestNow.x),y(p.A),5,gold);
    line(ctx,x(p.probe),pad.t,x(p.probe),c.h-pad.b,coral,1,[4,4]);
    dot(ctx,x(p.probe),y(sample(p,p.probe,t).u),5,coral);
  });
  if($('guides').checked&&p.A>0)bracket(ctx,x(0),x(p.lambda),40,'λ = '+fmt(p.lambda)+' m');
  $('crest-note').textContent=crestNow?`Gold crest: x = ${fmt(crestNow.x)} m${crestNow.x<0||crestNow.x>2?' (outside this window)':''}. A quarter-period step changes its position by ${fmt(p.lambda/4)} m toward ${p.direction===1?'+x':'−x'}.`:'No crest is distinguished in a zero-amplitude field.';
}
function drawHistory(){const c=frame('history','time t (s)'),{ctx,x,y,pad,w,h}=c;
  clipped(c,()=>{trace(ctx,history(p).map(d=>({x:d.t,y:d.u})),x,y,coral,2.3);line(ctx,x(t),pad.t,x(t),h-pad.b,teal,1.3,[4,4]);dot(ctx,x(t),y(sample(p,p.probe,t).u),5,coral);});
  if($('guides').checked&&p.A>0)bracket(ctx,x(0),x(metrics(p).T),40,'T = '+fmt(metrics(p).T)+' s');
}
function heatmap(){const key=JSON.stringify([p.A,p.lambda,p.f,p.phi,p.direction,p.form]);if(fieldKey===key)return fieldImage;fieldKey=key;
  const image=document.createElement('canvas');image.width=300;image.height=200;const ctx=image.getContext('2d'),data=ctx.createImageData(image.width,image.height);
  for(let j=0;j<image.height;j++)for(let i=0;i<image.width;i++){
    const u=sample(p,2*i/(image.width-1),2*(1-j/(image.height-1))).u,v=Math.min(1,Math.abs(u)/.05),color=u>=0?[71,150,173]:[204,119,101],offset=4*(j*image.width+i);
    for(let k=0;k<3;k++)data.data[offset+k]=Math.round(255+(color[k]-255)*v);data.data[offset+3]=255;
  }
  ctx.putImageData(data,0,0);fieldImage=image;return image;
}
function drawSpacetime(){const{ctx,w,h}=canvas('spacetime'),pad={l:48,r:15,t:20,b:42},x=scaleLinear().domain([0,2]).range([pad.l,w-pad.r]),y=scaleLinear().domain([0,2]).range([h-pad.b,pad.t]);
  ctx.drawImage(heatmap(),pad.l,pad.t,w-pad.l-pad.r,h-pad.t-pad.b);
  const ticks=w<450?[0,1,2]:[0,.5,1,1.5,2];for(const v of ticks){text(ctx,fmt(v),x(v),h-pad.b+18,{align:v===0?'left':v===2?'right':'center'});text(ctx,fmt(v),pad.l-9,y(v)+4,{align:'right'});}
  text(ctx,'t (s)',pad.l-8,11,{align:'right',size:11,color:ink});text(ctx,'position x (m)',(pad.l+w-pad.r)/2,h-5,{align:'center',size:11,color:ink});
  const shape={ctx,w,h,pad};clipped(shape,()=>{if(p.A>0){const a=crest(p,0),b=crest(p,2);line(ctx,x(a.x),y(0),x(b.x),y(2),gold,2.8);const c=crest(p,t);if(c.x>=0&&c.x<=2)diamond(ctx,x(c.x),y(t),4.5,gold);}line(ctx,x(p.probe),pad.t,x(p.probe),h-pad.b,coral,1.7,[5,4]);line(ctx,pad.l,y(t),w-pad.r,y(t),teal,1.7,[5,4]);dot(ctx,x(p.probe),y(t),4,ink,true);});
}
function draw(){const m=metrics(p),d=sample(p,p.probe,t),temporal=-p.direction*m.omega*t;
  $('time').value=t;$('time-value').value=fmt(t)+' s';$('snapshot-time').textContent='t = '+fmt(t)+' s';$('displacement').textContent=fmt(d.u*100,5)+' cm';$('back').disabled=t<=0;$('next').disabled=t>=2;
  $('space-phase').textContent=fmt(m.k*p.probe,6)+' rad';$('time-phase-title').textContent='Temporal contribution '+(p.direction===1?'−':'＋')+'ωt';$('time-phase').textContent=fmt(temporal,6)+' rad';$('offset-phase').textContent=fmt(p.phi,6)+' rad';$('total-phase').textContent=fmt(d.theta,6)+' rad';$('wrapped-phase').textContent=fmt(wrap(d.theta),6)+' rad';$('rates').textContent=fmt(m.k,5)+' rad/m; '+fmt(m.omega,5)+' rad/s';$('event-result').textContent=`u = ${fmt(p.A*100)} ${p.form}(${fmt(d.theta,5)}) = ${fmt(d.u*100,5)} cm`;
  drawSnapshot();drawHistory();drawSpacetime();
}
$('example').addEventListener('change',()=>{stop();const c=preset($('example').value);p=c.p;t=c.t;example=$('example').value;error();sync();});
$('amplitude').addEventListener('input',()=>change(q=>({...q,A:Number($('amplitude').value)/100})));
for(const [id,key,convert] of [['wavelength','lambda',x=>x],['frequency','f',x=>x],['wavenumber','lambda',x=>TAU/x],['omega','f',x=>x/TAU],['probe','probe',x=>x]])$(id).addEventListener('change',()=>change(q=>({...q,[key]:convert($(id).valueAsNumber)})));
$('parameter-mode').addEventListener('change',()=>{const ordinary=$('parameter-mode').value==='ordinary';$('ordinary').hidden=!ordinary;$('angular').hidden=ordinary;});
$('probe-range').addEventListener('input',()=>change(q=>({...q,probe:Number($('probe-range').value)})));
$('phase').addEventListener('input',()=>change(q=>({...q,phi:Number($('phase').value)*Math.PI/180})));
$('form').addEventListener('change',()=>change(q=>changeForm(q,$('form').value)));
$('left').addEventListener('click',()=>change(q=>({...q,direction:-1})));$('right').addEventListener('click',()=>change(q=>({...q,direction:1})));
for(const id of ['particles','initial','guides'])$(id).addEventListener('change',draw);
$('time').addEventListener('input',()=>{stop();t=Number($('time').value);draw();});
$('speed').addEventListener('change',()=>speed=Number($('speed').value));
for(const [id,direction] of [['back',-1],['next',1]])$(id).addEventListener('click',()=>{stop();t=Math.max(0,Math.min(2,t+direction*metrics(p).T/4));draw();});
$('play').addEventListener('click',()=>{if(running){stop();return;}if(t>=2)t=0;running=true;last=performance.now();$('play').setAttribute('aria-pressed','true');$('play').setAttribute('aria-label','Pause clock');$('play').title='Pause clock';setPlayIcon('pause');raf=requestAnimationFrame(animate);});
function animate(now){if(!running)return;t=Math.min(2,t+Math.min(.1,(now-last)/1000)*speed);last=now;draw();if(t>=2)stop();else raf=requestAnimationFrame(animate);}
$('reset').addEventListener('click',()=>{stop();({p,t}=preset());example='explore';speed=.25;$('speed').value='.25';$('parameter-mode').value='ordinary';$('ordinary').hidden=false;$('angular').hidden=true;for(const id of ['particles','initial','guides'])$(id).checked=true;error();sync();});
function pick(id,event){const c=$(id),box=c.getBoundingClientRect(),left=48,right=box.width-15,top=id==='spacetime'?20:52,bottom=box.height-42,x=event.clientX-box.left,y=event.clientY-box.top;if(x<left||x>right||y<top||y>bottom)return;stop();if(id==='history'){t=2*(x-left)/(right-left);draw();}else{if(id==='spacetime')t=2*(bottom-y)/(bottom-top);change(q=>({...q,probe:2*(x-left)/(right-left)}));}}
for(const id of ['snapshot','history','spacetime'])$(id).addEventListener('click',e=>pick(id,e));
$('download').addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([csv(p)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='sinusoidal-traveling-wave.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});window.addEventListener('pagehide',stop);
const observer=new ResizeObserver(draw);for(const id of ['snapshot','history','spacetime'])observer.observe($(id));createIcons({icons});sync();
