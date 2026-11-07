import {contours,geoPath,geoIdentity,scaleLinear,line,extent,format} from 'd3';
import {createIcons,RotateCcw,Download,ArrowLeftRight,Play,Pause} from 'lucide';
import {E_CHARGE,MASK,PRESETS,preset,validate,meterScale,environment,accessible,endpoints,vertices,safePath,pathPoint,samples,battery,transfer,csv,distance} from './model.js';
import {integrate} from './integral.js';
const $=id=>document.getElementById(id),icons=()=>createIcons({icons:{RotateCcw,Download,ArrowLeftRight,Play,Pause}});
const units={nC:1e-9,uC:1e-6,e:E_CHARGE};
const fmt=(x,unit='')=>{if(!Number.isFinite(x))return 'Unavailable';if(Math.abs(x)<1e-30)x=0;return (x===0?'0':format('.5~g')(x).replace(/\u2212/g,'-'))+(unit?' '+unit:'');};
const energy=x=>p.unit==='e'?fmt(x/E_CHARGE,'eV'):Math.abs(x)>=1e-6?fmt(x/1e-6,'\u03bcJ'):fmt(x/1e-9,'nJ'),volts=x=>fmt(x,'V');
let p=preset(),route='direct',fraction=0,selected='a',source=0,swapped=false,running=false,lastTime=0,frame=0,cacheKey='',cache,integralKey='',integrals;
let plotSamples=[],mapTransform;
for(const [id,title]of Object.entries(PRESETS))$('example').add(new Option(title,id));
function stop(){running=false;lastTime=0;cancelAnimationFrame(frame);$('play').innerHTML='<i data-lucide="play"></i>';$('play').title=$('play').ariaLabel='Play prescribed path traversal';icons();}
function sync(){
  $('example').value=p.id;$('uniform-inputs').hidden=p.kind!=='uniform';$('source-inputs').hidden=p.kind!=='points'||!p.sources.length;
  for(const key of ['voltage','gap','offset'])$(key).value=p[key];
  $('charge').value=p.q/units[p.unit];$('charge-unit').value=p.unit;$('charge').min=-10e-6/units[p.unit];$('charge').max=10e-6/units[p.unit];
  $('source').replaceChildren(...p.sources.map((s,i)=>new Option('Q'+(i+1),i)));$('source').value=source;
  if(p.sources[source])for(const [id,key,mul]of [['source-q','q',1e9],['source-x','x',1],['source-y','y',1]])$(id).value=p.sources[source][key]*mul;
  $('marker').value=selected;$('x').value=p[selected].x;$('y').value=p[selected].y;
  $('x-label').textContent=p.kind==='uniform'?'x (d/2 units)':'x (m)';$('y-label').textContent=p.kind==='uniform'?'y (d/2 units)':'y (m)';
  $('scene-units').textContent=p.kind==='uniform'?'1 map unit = '+fmt(meterScale(p),'m'):'Coordinates in meters';
  $('map-caption').textContent=p.kind==='uniform'?'Uniform-field patch; rails mark a spacing d. Colors and contour levels use V - C; saturated colors clip at the scale limits.':'Fixed point sources in vacuum. Colors and contours use V - C; white disks exclude r < 0.16 m. Saturated colors clip at the scale limits.';
  $('route').value=route;$('progress').value=fraction;$('progress-label').textContent=Math.round(100*fraction)+'%';
  $('error').hidden=true;
}
function edit(fn){stop();try{const next=structuredClone(p);fn(next);p=validate(next);fraction=0;sync();render();}catch(e){$('error').textContent=e.message+' The diagram retains the last valid values.';$('error').hidden=false;}}
function canvas(id){const c=$(id),r=c.getBoundingClientRect(),d=Math.min(devicePixelRatio||1,2);if(c.width!==Math.round(r.width*d)||c.height!==Math.round(r.height*d)){c.width=Math.round(r.width*d);c.height=Math.round(r.height*d);}const ctx=c.getContext('2d');ctx.setTransform(d,0,0,d,0,0);ctx.clearRect(0,0,r.width,r.height);return{c,ctx,w:r.width,h:r.height};}
function arrow(ctx,x,y,dx,dy,length,color){const n=Math.hypot(dx,dy);if(n<1e-12)return;const ux=dx/n,uy=dy/n,ex=x+ux*length,ey=y+uy*length;ctx.strokeStyle=color;ctx.fillStyle=color;ctx.lineWidth=1.6;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(ex,ey);ctx.stroke();ctx.beginPath();ctx.moveTo(ex,ey);ctx.lineTo(ex-ux*6-uy*3,ey-uy*6+ux*3);ctx.lineTo(ex-ux*6+uy*3,ey-uy*6-ux*3);ctx.closePath();ctx.fill();}
function text(ctx,s,x,y,color='#26383b',size=11,align='center'){ctx.font=size+'px Arial';ctx.fillStyle=color;ctx.textAlign=align;ctx.fillText(s,x,y);}
function mapData(){
  const span=+$('span').value,key=JSON.stringify([p.kind,p.voltage,p.gap,p.sources,span]);if(key===cacheKey)return cache;
  const n=120,values=[],pixels=document.createElement('canvas');pixels.width=pixels.height=n;const c=pixels.getContext('2d'),image=c.createImageData(n,n),base={...p,offset:0};
  for(let j=0;j<n;j++)for(let i=0;i<n;i++){
    const point={x:-2.5+(i+.5)*5/n,y:2.5-(j+.5)*5/n},e=environment(base,point),v=e?.v??0;values.push(v);
    const t=Math.min(1,Math.abs(v)/span),end=v<0?[39,125,155]:[197,78,76],bg=[248,250,249],at=4*(j*n+i);
    for(let k=0;k<3;k++)image.data[at+k]=bg[k]+(end[k]-bg[k])*t*.68;image.data[at+3]=255;
  }
  c.putImageData(image,0,0);cache={pixels,n,levels:contours().size([n,n]).thresholds([-span*2/3,-span/3,0,span/3,span*2/3])(values)};cacheKey=key;return cache;
}
function scene(){
  const {ctx,w,h}=canvas('scene'),side=Math.min(w-54,h-48),left=(w-side)/2,top=15,scale=side/5;
  const xy=point=>[left+(point.x+2.5)*scale,top+(2.5-point.y)*scale];mapTransform={left,top,scale,xy};const data=mapData();
  ctx.drawImage(data.pixels,left,top,side,side);ctx.save();ctx.beginPath();ctx.rect(left,top,side,side);ctx.clip();
  if($('contours').checked){const path=geoPath(geoIdentity().scale(side/data.n).translate([left,top]),ctx);for(const level of data.levels){ctx.beginPath();path(level);ctx.strokeStyle=level.value===0?'#495e63':'#6f888b';ctx.lineWidth=level.value===0?1.2:.55;ctx.stroke();}}
  if($('arrows').checked)for(let y=-2.15;y<2.3;y+=.55)for(let x=-2.15;x<2.3;x+=.55){const point={x,y};if(!accessible(p,point))continue;const e=environment(p,point),[px,py]=xy(point);arrow(ctx,px,py,e.ex,-e.ey,Math.min(17,scale*.3),'#19777d');}
  if(p.kind==='uniform')for(const x of [-1,1]){const [sx]=xy({x,y:0});ctx.strokeStyle=x===-1?(p.voltage<=0?'#b94c4f':'#187c9a'):(p.voltage<=0?'#187c9a':'#b94c4f');ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(sx,top+10);ctx.lineTo(sx,top+side-10);ctx.stroke();}
  for(const other of ['direct','bent']){const vs=vertices(p,other);ctx.beginPath();vs.forEach((v,i)=>{const [x,y]=xy(v);i?ctx.lineTo(x,y):ctx.moveTo(x,y);});ctx.strokeStyle=other===route?'#3c344e':'#8f8397';ctx.lineWidth=other===route?2.7:1.2;ctx.setLineDash(other===route?[]:[5,5]);ctx.stroke();ctx.setLineDash([]);}
  for(const [i,s]of p.sources.entries()){const [x,y]=xy(s);if(s.q!==0){ctx.fillStyle='#fafafa';ctx.beginPath();ctx.arc(x,y,MASK*scale,0,2*Math.PI);ctx.fill();}ctx.fillStyle=s.q>0?'#ba4548':s.q<0?'#187c9a':'#708286';ctx.beginPath();ctx.arc(x,y,10,0,Math.PI*2);ctx.fill();text(ctx,s.q>0?'+':s.q<0?'-':'0',x,y+4,'white',15);text(ctx,'Q'+(i+1),x,y-17);}
  for(const key of ['h','b','a']){const [x,y]=xy(p[key]);ctx.fillStyle=key==='h'?'#796586':(key==='a')!==swapped?'#bb454a':'#26383b';ctx.strokeStyle='white';ctx.lineWidth=2;ctx.beginPath();ctx.arc(x,y,key==='h'?6:8,0,2*Math.PI);ctx.fill();ctx.stroke();text(ctx,key.toUpperCase(),x+14,y-10,ctx.fillStyle,12,'left');}
  if(safePath(p,route)){const point=pathPoint(p,route,fraction),[x,y]=xy(point),e=environment(p,point);ctx.fillStyle='#b38421';ctx.strokeStyle='white';ctx.lineWidth=2;ctx.beginPath();ctx.arc(x,y,5,0,2*Math.PI);ctx.fill();ctx.stroke();text(ctx,'P',x-13,y+17,'#89640e',12);arrow(ctx,x,y,e.ex,-e.ey,28,'#087c83');if(p.q!==0)arrow(ctx,x+3,y+3,Math.sign(p.q)*e.ex,-Math.sign(p.q)*e.ey,38,'#987015');}
  ctx.restore();ctx.strokeStyle='#a9bec2';ctx.lineWidth=1;ctx.strokeRect(left,top,side,side);
  for(let i=-2;i<=2;i++){const [x,y]=xy({x:i,y:i});text(ctx,String(i),x,top+side+16);text(ctx,String(i),left-9,y+4,'#5b7277',10,'right');}
  const span=+$('span').value;$('low-color').textContent='-'+span;$('high-color').textContent='+'+span;
}
function results(){
  const end=endpoints(p),safe=safePath(p,route);$('download').disabled=!safe;$('play').disabled=!safe;$('progress').disabled=!safe;
  if(!safe&&running)stop();
  $('red-name').textContent=swapped?'B':'A';$('black-name').textContent=swapped?'A':'B';
  for(const id of ['va','vb','meter','dv','du','work'])$(id).textContent='Excluded';
  if(end){$('va').textContent=volts(end.a.v);$('vb').textContent=volts(end.b.v);$('meter').textContent=volts(swapped?end.dv:end.meter);$('dv').textContent=volts(end.dv);$('du').textContent=energy(end.du);$('work').textContent=energy(end.work);}
  $('meter-equation').textContent=swapped?'V(B) - V(A)':'V(A) - V(B)';
  $('interpretation').textContent=!end?'A or B is inside a source display-exclusion disk. Move it outside to compare finite potentials.':p.q===0?'q = 0: the field and voltage remain, but this neutral marker has no electric force, energy change or electric work.':Math.abs(end.du)<1e-26?'The endpoints are equipotential: zero net energy change and electric work, not necessarily zero field along the path.':end.du>0?'The charge gains potential energy. The electric field does negative work; quasistatic transport requires positive external work.':'The charge loses potential energy. The electric field does positive work; a quasistatic external agent removes that energy.';
  const key=JSON.stringify(p);if(key!==integralKey){integrals={};for(const name of ['direct','bent'])try{integrals[name]=integrate(p,name);}catch{integrals[name]={failed:true};}integralKey=key;}
  $('path-results').replaceChildren();for(const name of ['direct','bent']){const r=integrals[name],row=document.createElement('tr'),length=pathPoint(p,name,1).length;for(const value of [name==='direct'?'Straight':'Via H',fmt(length,'m'),!r?'Excluded path':r.failed?'Solver unavailable':volts(r.volts),!r?'Withheld':r.failed?'Withheld':energy(r.work),end?energy(end.work):'Excluded endpoint']){const td=document.createElement('td');td.textContent=value;row.append(td);}$('path-results').append(row);}
  const residual=end?Math.max(0,...Object.values(integrals).filter(r=>r&&!r.failed).map(r=>Math.abs(r.volts+end.dv))):0;
  $('path-status').textContent=!safe?'Selected path enters a 0.16 m source exclusion disk. Traversal, plot and CSV are withheld. The endpoint result, when finite, remains meaningful.':Object.values(integrals).some(r=>r?.failed)?'A numerical integral did not converge; endpoint energy is still analytic.':'Independent ODEX field integrals; largest endpoint discrepancy: '+volts(residual)+'. Small residuals are numerical error. A positive integral means potential drops from A to B.';
  $('charge-count').textContent='Main test charge: '+fmt(p.q,'C')+' = '+fmt(p.q/E_CHARGE)+' elementary charges (signed).';
  $('energy-ev').textContent=end?'For this A to B transfer: '+fmt(end.du/E_CHARGE,'eV')+' of potential-energy change. An electron crossing this same voltage would have '+fmt(-end.dv,'eV')+' of potential-energy change.':'Endpoint energy is withheld inside a source exclusion disk.';
}
function profile(){
  const {ctx,w,h}=canvas('profile'),quantity=$('plot-quantity').value;plotSamples=samples(p,route);
  if(!plotSamples.length){text(ctx,'Path excluded near a source',w/2,h/2,'#9d3328',14);for(const id of ['local-position','local-v','local-u','local-work'])$(id).textContent='Withheld';return;}
  const factor=quantity==='v'?1:1e9,ys=plotSamples.map(s=>s[quantity]*factor),range=extent(ys),padding=Math.max((range[1]-range[0])*.12,quantity==='v'?.5:Math.max(Math.abs(range[0])*.1,1e-12));
  const x=scaleLinear().domain([0,1]).range([66,w-18]),y=scaleLinear().domain([range[0]-padding,range[1]+padding]).nice().range([h-38,25]);
  ctx.lineWidth=1;for(const v of y.ticks(4)){ctx.strokeStyle='#dce6e8';ctx.beginPath();ctx.moveTo(66,y(v));ctx.lineTo(w-18,y(v));ctx.stroke();text(ctx,fmt(v),58,y(v)+4,'#5b7277',10,'right');}
  for(const f of [0,.25,.5,.75,1])text(ctx,String(f),x(f),h-20,'#5b7277',10);text(ctx,'Fraction of path length',w/2,h-3,'#5b7277',11);text(ctx,quantity==='v'?'V (volts)':'U (nJ)',66,12,'#5b7277',11,'left');
  ctx.strokeStyle=quantity==='v'?'#087c83':'#987015';ctx.lineWidth=2.4;ctx.beginPath();line().x(s=>x(s.f)).y(s=>y(s[quantity]*factor)).context(ctx)(plotSamples);ctx.stroke();
  const point=pathPoint(p,route,fraction),e=environment(p,point),u=p.q*e.v,work=p.q*(environment(p,p.a).v-e.v),yy=y((quantity==='v'?e.v:u)*factor);
  ctx.strokeStyle='#796586';ctx.setLineDash([4,4]);ctx.beginPath();ctx.moveTo(x(fraction),25);ctx.lineTo(x(fraction),h-38);ctx.stroke();ctx.setLineDash([]);ctx.fillStyle='#b38421';ctx.beginPath();ctx.arc(x(fraction),yy,4.5,0,2*Math.PI);ctx.fill();
  $('local-position').textContent='P: '+fmt(fraction*point.length,'m')+' from A';$('local-v').textContent='V(P) = '+volts(e.v);$('local-u').textContent='U(P) = '+energy(u);$('local-work').textContent='W(A to P) = '+energy(work);
}
function drawCharge(){
  const n=+$('electrons').value,t=transfer(n),{ctx,w,h}=canvas('charge-scene'),cx=[w*.22,w*.78],cy=h*.48,r=Math.min(58,w*.17);
  cx.forEach((x,i)=>{ctx.fillStyle=i===0?(n>=0?'#f8e7e6':'#e2f0f5'):(n>=0?'#e2f0f5':'#f8e7e6');ctx.strokeStyle='#a6bdc3';ctx.beginPath();ctx.arc(x,cy,r,0,Math.PI*2);ctx.fill();ctx.stroke();text(ctx,i?'Right':'Left',x,h-15,'#26383b',12);const charge=i?-n:n;text(ctx,(charge>0?'+':'')+charge+' e',x,cy+5,charge>0?'#ba4548':charge<0?'#187c9a':'#26383b',18);});
  const arrowX=n>=0?cx[0]+r+6:cx[1]-r-6;arrow(ctx,arrowX,cy-17,n>=0?1:-1,0,Math.max(12,cx[1]-cx[0]-2*r-12),'#187c9a');text(ctx,Math.abs(n)+' electrons',w/2,cy-30,'#187c9a',11);
  $('transfer-title').textContent=n===0?'No net transfer':Math.abs(n)+' electrons moved '+(n>0?'left to right':'right to left');$('transfer-left').textContent='Left: '+fmt(t.left,'C');$('transfer-right').textContent='Right: '+fmt(t.right,'C');
}
function drawBattery(){
  let b;try{b=battery(+$('emf').value,+$('internal-r').value,+$('load-r').value,+$('meter-r').value);$('battery-error').hidden=true;}catch(e){$('battery-error').textContent=e.message;$('battery-error').hidden=false;return;}
  const {ctx,w,h}=canvas('battery-scene'),left=35,right=w-35,top=50,bottom=h-42,middle=(top+bottom)/2,load=left+(right-left)*.62,sourceX=left+(right-left)*.27;
  ctx.lineWidth=1.7;ctx.strokeStyle='#425e65';ctx.beginPath();ctx.moveTo(left,middle-14);ctx.lineTo(left,top);ctx.lineTo(sourceX-22,top);ctx.moveTo(sourceX+22,top);ctx.lineTo(right,top);ctx.lineTo(right,middle-17);ctx.moveTo(right,middle+17);ctx.lineTo(right,bottom);ctx.lineTo(left,bottom);ctx.lineTo(left,middle+14);ctx.moveTo(load,top);ctx.lineTo(load,middle-24);ctx.moveTo(load,middle+24);ctx.lineTo(load,bottom);ctx.stroke();
  ctx.strokeStyle='#26383b';ctx.strokeRect(sourceX-22,top-8,44,16);ctx.strokeRect(load-8,middle-24,16,48);
  ctx.beginPath();ctx.moveTo(left-14,middle-9);ctx.lineTo(left+14,middle-9);ctx.moveTo(left-8,middle+6);ctx.lineTo(left+8,middle+6);ctx.stroke();text(ctx,'+',left+21,middle-5,'#ba4548',13);text(ctx,'EMF',left,middle+38,'#26383b',11);
  ctx.beginPath();ctx.arc(right,middle,17,0,2*Math.PI);ctx.stroke();text(ctx,'V',right,middle+5,'#26383b',14);text(ctx,'r',sourceX,top-16,'#26383b',12);text(ctx,'R',load-21,middle+4,'#26383b',13);
  text(ctx,'+'+volts(b.terminal),right,top-18,'#ba4548',12,'right');text(ctx,'0 V reference',right,bottom+24,'#26383b',11,'right');text(ctx,'Rm',right,middle+35,'#5b7277',11);
  $('terminal').textContent=volts(b.terminal);$('current').textContent=fmt(b.current*1000,'mA');$('unloaded').textContent=volts(b.unloaded);
  $('battery-detail').textContent='Meter draws '+fmt(b.meterCurrent*1e6,'uA')+'. Internal heating: '+fmt(b.internalPower,'W')+'. Source power '+fmt(b.sourcePower,'W')+' = internal + load + meter power. Changing r or the load changes terminal voltage; EMF is energy per charge, not force.';
}
function render(){results();scene();profile();drawCharge();drawBattery();}
function animate(time){if(!running)return;if(lastTime)fraction=Math.min(1,fraction+(time-lastTime)/8000);lastTime=time;$('progress').value=fraction;$('progress-label').textContent=Math.round(100*fraction)+'%';scene();profile();if(fraction===1)stop();else frame=requestAnimationFrame(animate);}
$('example').onchange=()=>{stop();p=preset($('example').value);selected='a';source=0;fraction=0;swapped=false;sync();render();};
$('reset').onclick=()=>{stop();p=preset(p.id);selected='a';source=0;fraction=0;swapped=false;sync();render();};
for(const id of ['voltage','gap','offset'])$(id).onchange=()=>edit(next=>next[id]=Number($(id).value||NaN));
$('charge').onchange=()=>edit(next=>next.q=Number($('charge').value||NaN)*units[p.unit]);
$('charge-unit').onchange=()=>{p.unit=$('charge-unit').value;sync();};
$('source').onchange=()=>{source=+$('source').value;sync();};
for(const [id,key,mul]of [['source-q','q',1e-9],['source-x','x',1],['source-y','y',1]])$(id).onchange=()=>edit(next=>next.sources[source][key]=Number($(id).value||NaN)*mul);
$('marker').onchange=()=>{selected=$('marker').value;sync();};
for(const key of ['x','y'])$(key).onchange=()=>edit(next=>next[selected][key]=Number($(key).value||NaN));
$('route').onchange=()=>{stop();route=$('route').value;fraction=0;sync();render();};
for(const id of ['span','arrows','contours'])$(id).onchange=()=>scene();
$('swap').onclick=()=>{swapped=!swapped;results();scene();};
$('plot-quantity').onchange=profile;
$('progress').oninput=()=>{stop();fraction=+$('progress').value;$('progress-label').textContent=Math.round(100*fraction)+'%';scene();profile();};
$('play').onclick=()=>{if(running){stop();return;}if(fraction===1)fraction=0;running=true;lastTime=0;$('play').innerHTML='<i data-lucide="pause"></i>';$('play').title=$('play').ariaLabel='Pause prescribed path traversal';icons();frame=requestAnimationFrame(animate);};
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
$('electrons').oninput=drawCharge;for(const id of ['emf','internal-r','load-r','meter-r'])$(id).onchange=drawBattery;
$('download').onclick=()=>{const url=URL.createObjectURL(new Blob([csv(p,route)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='potential-work-path.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),500);};
let dragging=null;
function pointerPoint(event){const rect=$('scene').getBoundingClientRect(),m=mapTransform;return{x:Math.max(-2.3,Math.min(2.3,(event.clientX-rect.left-m.left)/m.scale-2.5)),y:Math.max(-2.3,Math.min(2.3,2.5-(event.clientY-rect.top-m.top)/m.scale))};}
$('scene').onpointerdown=event=>{stop();const point=pointerPoint(event),candidates=[...['a','b','h'].map(key=>({key,point:p[key]})),...p.sources.map((s,i)=>({key:'source',i,point:s}))].sort((a,b)=>distance(a.point,point)-distance(b.point,point));const closest=candidates[0];dragging=distance(closest.point,point)*mapTransform.scale<24?closest:{key:selected};if(dragging.key==='source')source=dragging.i;else selected=dragging.key;$('scene').setPointerCapture(event.pointerId);sync();};
$('scene').onpointermove=event=>{if(!dragging)return;const point=pointerPoint(event);edit(next=>Object.assign(dragging.key==='source'?next.sources[dragging.i]:next[dragging.key],point));};
$('scene').onpointerup=$('scene').onpointercancel=()=>{dragging=null;};
let resizeFrame;new ResizeObserver(()=>{cancelAnimationFrame(resizeFrame);resizeFrame=requestAnimationFrame(render);}).observe(document.querySelector('.experiment'));
icons();sync();render();
