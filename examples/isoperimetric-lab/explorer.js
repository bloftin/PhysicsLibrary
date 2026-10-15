import {scaleLinear,range} from 'd3';
import {createIcons,Play,Pause,RotateCcw,Download} from 'lucide';
import {DEFAULTS,parameters,at,point,curve,trace,csv} from './model.js';
import {GUIDES} from './explanations.js';

const $=id=>document.getElementById(id),fmt=v=>Math.abs(v)<1e-10?'0':v.toFixed(3);
const C={ink:'#29494e',muted:'#587279',grid:'#dce9e8',teal:'#087f7e',fill:'#d6efea',coral:'#c24c39',blue:'#216aba',square:'#707d8d'};
let p={...DEFAULTS},playing=false,last=0,phase=0;
const keys=['a','alpha','length','perimeter','n','ratio','probe'];
function icons(){createIcons({icons:{Play,Pause,RotateCcw,Download},attrs:{'aria-hidden':'true'}});}
function setText(id,value){$(id).textContent=value;}
function canvas(id){const c=$(id),rect=c.getBoundingClientRect(),dpr=Math.min(devicePixelRatio||1,2);c.width=Math.round(rect.width*dpr);c.height=Math.round(rect.height*dpr);const ctx=c.getContext('2d');ctx.scale(dpr,dpr);ctx.font='12px Arial';ctx.lineJoin='round';return {ctx,w:rect.width,h:rect.height};}
function path(ctx,points,X,Y,{fill=null,stroke=C.teal,width=2,dash=[],close=false}={}){ctx.beginPath();for(let i=0;i<points.length;i++){const [x,y]=points[i];if(i)ctx.lineTo(X(x),Y(y));else ctx.moveTo(X(x),Y(y));}if(close)ctx.closePath();if(fill){ctx.fillStyle=fill;ctx.fill();}if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=width;ctx.setLineDash(dash);ctx.stroke();ctx.setLineDash([]);}}
function label(ctx,text,x,y,color=C.ink,align='left'){ctx.fillStyle=color;ctx.textAlign=align;ctx.fillText(text,x,y);ctx.textAlign='left';}
function dot(ctx,x,y,color=C.coral,r=4){ctx.beginPath();ctx.arc(x,y,r,0,2*Math.PI);ctx.fillStyle=color;ctx.fill();}
function arrow(ctx,x,y,dx,dy,color){const t=Math.atan2(dy,dx),len=Math.hypot(dx,dy);if(len<1)return;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+dx,y+dy);ctx.strokeStyle=color;ctx.lineWidth=2;ctx.stroke();ctx.beginPath();ctx.moveTo(x+dx,y+dy);ctx.lineTo(x+dx-8*Math.cos(t-.4),y+dy-8*Math.sin(t-.4));ctx.lineTo(x+dx-8*Math.cos(t+.4),y+dy-8*Math.sin(t+.4));ctx.closePath();ctx.fillStyle=color;ctx.fill();}
function grid(ctx,w,h,X,Y){for(const x of X.ticks(10))path(ctx,[[x,Y.invert(20)],[x,Y.invert(h-24)]],X,Y,{stroke:C.grid,width:1});for(const y of Y.ticks(8))path(ctx,[[X.invert(24),y],[X.invert(w-24),y]],X,Y,{stroke:C.grid,width:1});}
function drawGeometry(r){
  const {ctx,w,h}=canvas('geometry');
  if(r.mode===6){
    const rad=r.P/(2*Math.PI),span=rad*4.25,scale=Math.min((w-50)/(span*2),(h-110)/(r.poly.R*2.3)),Y=y=>h*.47-y*scale,x=v=>w/2+v*scale;
    const offsets=[-2.9*rad,0,2.9*rad],titles=['Circle','Square',`${r.n}-gon`],areas=[r.circle,r.square,r.area];
    const circle=range(0,241).map(i=>[rad*Math.cos(i*Math.PI/120),rad*Math.sin(i*Math.PI/120)]),side=r.P/4,square=[[-side/2,-side/2],[side/2,-side/2],[side/2,side/2],[-side/2,side/2]];
    [circle,square,r.poly.vertices].forEach((vertices,i)=>{const xx=v=>x(v+offsets[i]);path(ctx,vertices,xx,Y,{fill:i===2?'#fae4dc':C.fill,stroke:[C.teal,C.square,C.coral][i],close:true});label(ctx,titles[i],xx(0),h-55,C.ink,'center');label(ctx,`${(areas[i]/r.circle*100).toFixed(1)}%`,xx(0),h-34,C.muted,'center');});
    const [v0,v1]=r.poly.vertices,mid=[(v0[0]+v1[0])/2,(v0[1]+v1[1])/2],xx=v=>x(v+offsets[2]);path(ctx,[[0,0],v0,v1],xx,Y,{fill:'#c7ddf0',stroke:C.blue,close:true,width:1});path(ctx,[[0,0],mid],xx,Y,{stroke:C.blue,width:2});dot(ctx,xx(0),Y(0),C.blue,3);
    label(ctx,`Same closed perimeter P = ${fmt(r.P)}`,w/2,24,C.ink,'center');
    $('geometry').setAttribute('aria-label',`Equal perimeter ${r.P}: circle area ${fmt(r.circle)}, square ${fmt(r.square)}, regular ${r.n}-gon ${fmt(r.area)}. Same length scale.`);
    return;
  }
  const samples=curve(p),arc=samples.map(d=>[d.x,d.y]),reflected=$('reflection').checked&&r.mode===4,full=$('circle').checked;
  let xmin=Math.min(-r.a,...arc.map(d=>d[0])),xmax=-xmin,ymin=reflected?-r.height:0,ymax=r.height;
  if(full){xmin=-r.R;xmax=r.R;ymin=Math.min(ymin,-r.R*(1+Math.cos(r.alpha)));ymax=Math.max(ymax,r.R*(1-Math.cos(r.alpha)));}
  const span=Math.max(xmax-xmin,(ymax-ymin)*1.2,.1),scale=Math.min((w-80)/span,(h-95)/(ymax-ymin+span*.2)),centerY=(ymin+ymax)/2;
  const X=v=>w/2+v*scale,Y=v=>h*.49-(v-centerY)*scale;
  grid(ctx,w,h,scaleLinear([-w/(2*scale),w/(2*scale)],[0,w]),scaleLinear([centerY+h*.49/scale,centerY-(h-h*.49)/scale],[0,h]));
  if(full)path(ctx,range(0,241).map(i=>[r.R*Math.sin(i*Math.PI/120),r.R*(Math.cos(i*Math.PI/120)-Math.cos(r.alpha))]),X,Y,{stroke:'#9eb6bb',dash:[5,5],width:1});
  path(ctx,arc,X,Y,{fill:C.fill,stroke:null,close:true});
  if(reflected)path(ctx,arc.map(([x,y])=>[x,-y]),X,Y,{fill:'#e8f3f0',stroke:C.teal,dash:[6,5],close:true,width:1.5});
  path(ctx,[[(25-w/2)/scale,0],[(w-25-w/2)/scale,0]],X,Y,{stroke:'#7b989a',width:1.5});
  path(ctx,arc,X,Y,{stroke:C.teal,width:3});
  const isSemi=Math.abs(r.alpha-Math.PI/2)<1e-8;
  for(const sign of [-1,1]){const x=sign*r.a,dx=sign*28;dot(ctx,X(x),Y(0),C.ink);label(ctx,sign<0?'A':'B',X(x)+sign*10,Y(0)+21,C.ink,sign<0?'right':'left');if(r.mode===4){arrow(ctx,X(x)-dx*.4,Y(0)+35,dx,0,C.muted);arrow(ctx,X(x)+dx*.4,Y(0)+35,-dx,0,C.muted);}if(isSemi){path(ctx,[[x-sign*12/scale,0],[x-sign*12/scale,12/scale],[x,12/scale]],X,Y,{stroke:C.blue,width:1.5});}}
  const q=point(p,p.probe);dot(ctx,X(q.x),Y(q.y),C.coral,5);
  if($('vectors').checked){const len=Math.min(45,w*.11);arrow(ctx,X(q.x),Y(q.y),q.tx*len,-q.ty*len,C.coral);arrow(ctx,X(q.x),Y(q.y),q.nx*len,-q.ny*len,C.blue);const safe=(v,hi)=>Math.max(12,Math.min(hi-12,v));label(ctx,'T',safe(X(q.x)+q.tx*(len+12),w),safe(Y(q.y)-q.ty*(len+12),h),C.coral,'center');label(ctx,'n',safe(X(q.x)+q.nx*(len+12),w),safe(Y(q.y)-q.ny*(len+12),h),C.blue,'center');}
  label(ctx,r.mode===4?'Straight shore: zero rope cost':'Fixed chord: 2a',w/2,h-14,C.muted,'center');
  $('geometry').setAttribute('aria-label',`${r.mode===4?'Sliding':'Fixed'} endpoints, circular ${r.graph?'graph':'overhanging parametric'} arc. Area ${fmt(r.area)}, curved length ${fmt(r.length)}, signed curvature ${fmt(r.kappa)}. Tangent and normal at t/alpha ${p.probe}.`);
}
function drawTrace(r){
  const {ctx,w,h}=canvas('trace'),data=trace(p),margin={l:48,r:20,t:25,b:42};
  const X=scaleLinear().domain(r.mode===1?[0,1]:r.mode===6?[3,60]:r.mode===3?[15,90]:[15,165]).range([margin.l,w-margin.r]);
  const Y=scaleLinear().domain(r.mode===1?[Math.min(-1.1,p.ratio*-1-.2),2.2]:r.mode===3?[1,1.7]:[0,1.08]).range([h-margin.b,margin.t]);
  for(const y of Y.ticks(4)){path(ctx,[[X.domain()[0],y],[X.domain()[1],y]],X,Y,{stroke:C.grid,width:1});label(ctx,y.toFixed(1),margin.l-8,Y(y)+4,C.muted,'right');}
  const target=r.mode===3?Math.PI/2:1;
  path(ctx,[[X.domain()[0],target],[X.domain()[1],target]],X,Y,{stroke:C.blue,dash:[5,4],width:1.5});
  for(const x of X.ticks(w<450?4:7))label(ctx,String(x),X(x),h-margin.b+20,C.muted,'center');
  path(ctx,data.map(d=>[d.x,d.y]),X,Y,{stroke:C.teal,width:2.5});
  const selected=r.mode===1?{x:(p.probe+1)/2,y:-p.ratio}:r.mode===6?{x:p.n,y:r.efficiency}:r.mode===3?{x:90,y:Math.PI/2}:{x:r.alpha*180/Math.PI,y:r.efficiency};
  dot(ctx,X(selected.x),Y(selected.y),C.coral,5);
  label(ctx,r.mode===1?'1 (required)':r.mode===6?'Circle = 1':r.mode===3?'L/(2a) = pi/2':'Semicircle bound = 1',w-margin.r,Y(target)-8,C.blue,'right');
  if(r.mode===1)label(ctx,'lambda * kappa',margin.l+8,Y(-p.ratio)+18,C.teal);
  label(ctx,r.mode===1?'Normalized arc length s/L':r.mode===6?'Number of sides n':'Half-angle alpha (degrees)',w/2,h-4,C.muted,'center');
  $('trace').setAttribute('aria-label',r.mode===1?`Lambda times signed curvature ${fmt(-p.ratio)}, required 1, residual ${fmt(r.residual)} at every arc point.`:r.mode===3?'At fixed chord, the circular length-to-chord ratio increases to pi/2 at 90 degrees.':`Area as a fraction of the ${r.mode===6?'circle':'shoreline semicircle'} bound: ${fmt(r.efficiency)}.`);
}
function updateContent(r){
  const titles={1:'A circular graph between fixed endpoints',3:'A semicircle with fixed chord and L = pi*a',4:"A fixed rope, two sliding endpoints",6:'Three shapes, one perimeter'};
  setText('figure-title',titles[r.mode]);setText('family-label',r.mode===6?'Equal scale / equal perimeter':r.graph?'Minor arc / graph':'Major arc / overhang');
  setText('controls-title',r.mode===4?'Free endpoints':r.mode===6?'Closed boundaries':'Fixed endpoints');
  setText('budget',r.mode===4?'Curved length L stays fixed as the half-angle changes.':r.mode===6?'All three closed boundaries use the same P.':r.mode===3?'Both chord and prescribed length scale with a.':'The chord stays fixed; the half-angle sets the corresponding length budget.');
  const metricLabels=r.mode===6?['Polygon area','Closed perimeter P','Circle area','Area / circle']:['Area A','Curved length L','Radius R',r.mode===1?'EL: 1 - lambda*kappa':'Area / bound'];
  const values=r.mode===6?[r.area,r.P,r.circle,100*r.efficiency]:[r.area,r.length,r.R,r.mode===1?r.residual:100*r.efficiency];
  values.forEach((value,i)=>{setText('metric'+(i+1),fmt(value)+(i===3&&r.mode!==1?'%':''));setText('metric'+(i+1)+'-label',metricLabels[i]);});
  setText('geometry-caption',r.mode===6?'Teal circle, grey square, coral polygon. Each boundary has the same perimeter; the blue triangle exposes the polygon apothem.':r.mode===4?`Area is enclosed by the teal arc and free shoreline. Endpoint separation = ${fmt(2*r.a)}; closed perimeter of the upper region = ${fmt(r.length+2*r.a)}. ${r.graph?'':'This major arc overhangs; it cannot be written as a single graph y(x).'}`:`Filled area lies between the arch and chord. The coral tangent follows left-to-right traversal; blue is the left unit normal. Signed curvature = ${fmt(r.kappa)} everywhere.`);
  setText('plot-title',r.mode===1?'Interior EL balance along the whole arc':r.mode===6?'Regular polygons approach the circle':r.mode===3?'The length-to-chord condition':'Equal-length circular arches');
  setText('plot-caption',r.mode===1?`lambda = ${fmt(r.lambda)}; kappa = ${fmt(r.kappa)}. Both curves coincide only when lambda/R = -1. Moving the probe does not change the constant curvature.`:r.mode===6?'The vertical coordinate is A_n / A_circle, at fixed closed perimeter P. The square is the n = 4 point.':r.mode===3?'The vertical coordinate is L/(2a) = alpha/sin(alpha), at fixed chord. The special budget L = pi*a selects 90 degrees. Other chart points have different lengths; they are not feasible alternatives at that same budget.':`Every chart point has curved length L = ${fmt(r.length)}. Area is divided by L^2/(2*pi), so the maximum value is 1. The coral point is the displayed arch.`);
  let title,body;
  if(r.mode===1){title=Math.abs(r.residual)<1e-9?'The multiplier matches the circular curvature':'Circular geometry, but the multiplier is not matched';body=`The arc has constant signed curvature ${fmt(r.kappa)}. With H = y + lambda*sqrt(1+y'^2), the required product is lambda*kappa = 1; it is currently ${fmt(1-r.residual)}. Choosing lambda = -R = ${fmt(-r.R)} removes the interior EL residual. This is a stationary candidate for the displayed length ${fmt(r.length)}, not a numerical proof of a global maximum.`;}
  else if(r.mode===3){title='The endpoints have vertical tangents, not singular geometry';body=`Here a = R = ${fmt(r.R)}, L = pi*a = ${fmt(r.length)}, and A = pi*a^2/2 = ${fmt(r.area)}. The angle-based tangent remains finite even at A and B, where y'(x) is infinite. Reflection gives a full circle, explaining why this semicircle attains the area bound for this length budget.`;}
  else if(r.mode===4){const err=Math.abs(Math.cos(r.alpha));title=err<1e-9?'Orthogonal contact selects the semicircle':'The interior is circular; the endpoint condition is missing';body=`At fixed rope length ${fmt(r.length)}, this arch encloses ${fmt(100*r.efficiency)}% of the shoreline bound. The magnitude of each endpoint tangent's horizontal component is |cos(alpha)| = ${fmt(err)}. It must vanish at a free-endpoint stationary solution. At alpha = 90 degrees, R = L/pi and A = L^2/(2*pi). The shoreline is free; counting its width as rope would solve a different problem.`;}
  else{title=`The ${r.n}-gon encloses ${fmt(100*r.efficiency)}% of the circle's area`;body=`All three shapes have perimeter ${fmt(r.P)}. Their areas are ${fmt(r.circle)} (circle), ${fmt(r.square)} (square) and ${fmt(r.area)} (regular ${r.n}-gon). The square's fraction is always pi/4, about 78.54%. Changing P scales the areas together; changing n changes how efficiently a regular polygon uses its perimeter.`;}
  setText('interpretation-title',title);setText('interpretation',body);
}
function render(){const r=at(p);updateContent(r);drawGeometry(r);drawTrace(r);}
function sync(){
  document.querySelectorAll('[data-modes]').forEach(el=>el.hidden=!el.dataset.modes.split(' ').includes(String(p.mode)));
  for(const key of keys){$(key).value=p[key];if(document.activeElement!==$(key+'-number'))$(key+'-number').value=p[key];setText(key+'-value',key==='alpha'?`${p[key].toFixed(1)} deg`:key==='n'?p[key]:p[key].toFixed(2));}
  for(const id of ['alpha','alpha-number'])$(id).max=p.mode===1?90:165;
  $('exercise').value=p.mode;if($('guide-body').dataset.mode!==String(p.mode)){$('guide-title').textContent=GUIDES[p.mode].title;$('guide-body').innerHTML=GUIDES[p.mode].body;$('guide-body').dataset.mode=p.mode;}
  render();
}
function stop(){playing=false;$('play').setAttribute('aria-pressed','false');$('play').innerHTML='<i data-lucide="play"></i>';icons();}
for(const key of keys)for(const id of [key,key+'-number'])$(id).addEventListener('input',()=>{stop();try{const raw=$(id).value;if(raw.trim()==='')throw new Error('Enter a value for '+key);const next=parameters({...p,[key]:Number(raw)});p=next;$('error').hidden=true;sync();}catch(e){$('error').textContent=e.message;$('error').hidden=false;}});
$('exercise').addEventListener('change',()=>{stop();p={...DEFAULTS,mode:Number($('exercise').value),alpha:Number($('exercise').value)===4?55:60};$('error').hidden=true;sync();});
$('reset').addEventListener('click',()=>{stop();p={...DEFAULTS,mode:p.mode,alpha:p.mode===4?55:60};for(const id of ['circle','reflection'])$(id).checked=false;$('vectors').checked=true;$('error').hidden=true;sync();});
$('match').addEventListener('click',()=>{p.ratio=-1;sync();});$('semicircle').addEventListener('click',()=>{stop();p.alpha=90;sync();});
for(const id of ['circle','vectors','reflection'])$(id).addEventListener('change',render);
$('play').addEventListener('click',()=>{if(playing){stop();return;}playing=true;last=0;phase=p.mode===6?Math.asin((p.n-3)/28.5-1):Math.asin(p.probe);$('play').setAttribute('aria-pressed','true');$('play').innerHTML='<i data-lucide="pause"></i>';icons();});
$('download').addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([csv(p)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download=`cv09e1-example-${p.mode}.csv`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
new ResizeObserver(()=>render()).observe($('geometry'));
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
function animate(time){requestAnimationFrame(animate);if(!playing||time-last<100)return;const dt=last?Math.min((time-last)/1000,.2):.1;last=time;phase+=dt*.65;if(p.mode===6)p.n=3+Math.floor((Math.sin(phase)+1)*28.5);else p.probe=Math.sin(phase);sync();}
icons();sync();requestAnimationFrame(animate);
