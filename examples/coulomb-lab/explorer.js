import {scaleLinear,scaleLog,interpolateRgbBasis,rgb} from 'd3';
import {createIcons,RotateCcw,Download,MoveUpRight,Spline,Minimize2,Maximize2} from 'lucide';
import {K,BOUND,VIEW,MASK,MIN_SEPARATION,PRESETS,preset,validate,fieldAt,pairForce,forces,probeResult,resizeCharges,separationRange,setSeparation,inverseSquare,csv,distance} from './model.js';
import {fieldLines} from './lines.js';
const $=id=>document.getElementById(id),icons={RotateCcw,Download,MoveUpRight,Spline,Minimize2,Maximize2};
const C={positive:'#c64e45',negative:'#147da2',net:'#986e13',field:'#087d86',pair:'#7168a6',ink:'#29383d',muted:'#5c7279',grid:'#dce6e8'};
const heatColor=interpolateRgbBasis(['#f3f7f8','#d5e7e6','#67adae','#e2cb73','#dd8272']);
const fmt=(x,n=5)=>Math.abs(x)<1e-10?'0':String(Number(x.toPrecision(n)));
const forceText=f=>Math.abs(f)<1e-15?'0 N':Math.abs(f)<1?fmt(f*1e3)+' mN':fmt(f)+' N';
let p=preset(),example='dipole',mode='force',drag=null,view=null,lineTimer=null,linesKey='',lines=[],lineFailure='';
let shadeKey='',shadeImage=null;
const key=()=>JSON.stringify([p.charges,Number($('density').value)]);
function error(message=''){$('error').textContent=message;$('error').hidden=!message;}
function change(fn,source=true){
  try{p=validate(fn({...p,charges:p.charges.map(c=>({...c})),probe:{...p.probe}}));if(source)example='custom';error();sync();}
  catch(e){error(e.message);}
}
function sync(){
  $('example').replaceChildren(...Object.entries({...PRESETS,custom:'Custom configuration'}).map(([id,name])=>{const option=new Option(name,id);option.disabled=id==='custom';return option;}));$('example').value=example;
  $('count').value=p.charges.length;
  $('selected').replaceChildren(...p.charges.map((c,i)=>new Option(`q${i+1}: ${fmt(c.q*1e6)} μC`,i)));$('selected').value=p.selected;
  const q=p.charges[p.selected];$('charge').value=Number((q.q*1e6).toPrecision(6));$('charge-range').value=q.q*1e6;$('x').value=Number(q.x.toPrecision(6));$('y').value=Number(q.y.toPrecision(6));
  $('probe-x').value=Number(p.probe.x.toPrecision(6));$('probe-y').value=Number(p.probe.y.toPrecision(6));$('test-charge').value=Number((p.testQ*1e6).toPrecision(6));
  $('pair-controls').hidden=p.charges.length!==2;$('pair-band').hidden=p.charges.length!==2;
  if(p.charges.length===2){const range=separationRange(p);for(const id of ['distance','distance-range']){$(id).min=MIN_SEPARATION;$(id).max=range.max;$(id).value=id==='distance'?Number(range.r.toPrecision(6)):range.r;}$('halve').disabled=range.r/2<MIN_SEPARATION;$('double').disabled=range.r*2>range.max+1e-10;}
  $('mode-force').setAttribute('aria-pressed',String(mode==='force'));$('mode-field').setAttribute('aria-pressed',String(mode==='field'));
  $('force-controls').hidden=mode!=='force';$('field-controls').hidden=mode!=='field';$('vector-scale').hidden=mode!=='force';
  $('density').disabled=$('field-style').value!=='lines';
  $('force-key').hidden=mode!=='force';$('pair-key').hidden=mode!=='force'||!$('components').checked;$('field-key').hidden=mode!=='field';
  $('probe-key').hidden=!$('probe-visible').checked;
  $('color-key').hidden=mode!=='field'||!$('shading').checked;
  $('view-title').textContent=mode==='force'?'Forces on held charges':'Electric field of the sources';
  $('formula').textContent=mode==='force'?'Fᵢ = k Σⱼ≠ᵢ qᵢqⱼ (rᵢ − rⱼ) / |rᵢ − rⱼ|³':'E(P) = k Σⱼ qⱼ (P − rⱼ) / |P − rⱼ|³';
  draw();
}
function canvas(id){const c=$(id),b=c.getBoundingClientRect(),w=b.width,h=b.height,dpr=Math.min(devicePixelRatio||1,2);if(c.width!==Math.round(w*dpr)||c.height!==Math.round(h*dpr)){c.width=Math.round(w*dpr);c.height=Math.round(h*dpr);}const ctx=c.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);ctx.lineCap='round';return{ctx,w,h};}
function text(ctx,value,x,y,color=C.muted,align='left',size=11){ctx.font=`${size}px Arial`;ctx.fillStyle=color;ctx.textAlign=align;ctx.fillText(value,x,y);}
function line(ctx,x1,y1,x2,y2,color,width=1,dash=[]){ctx.beginPath();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.setLineDash([]);}
function dot(ctx,x,y,r,fill,stroke=fill){ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();ctx.strokeStyle=stroke;ctx.lineWidth=1.5;ctx.stroke();}
function arrow(ctx,x1,y1,x2,y2,color,width=2,dash=[],head=7){
  const length=Math.hypot(x2-x1,y2-y1);if(length<1)return;
  line(ctx,x1,y1,x2,y2,color,width,dash);const angle=Math.atan2(y2-y1,x2-x1),size=Math.min(head,length*.6);
  ctx.beginPath();ctx.moveTo(x2,y2);ctx.lineTo(x2-size*Math.cos(angle-.45),y2-size*Math.sin(angle-.45));ctx.lineTo(x2-size*Math.cos(angle+.45),y2-size*Math.sin(angle+.45));ctx.closePath();ctx.fillStyle=color;ctx.fill();
}
function sceneFrame(){
  const c=canvas('scene'),{ctx,w,h}=c,s=Math.min(w-70,h-78)/(2*VIEW),cx=w/2,cy=(h-25)/2,x=v=>cx+s*v,y=v=>cy-s*v;
  return{...c,s,cx,cy,x,y,left:x(-VIEW),right:x(VIEW),top:y(VIEW),bottom:y(-VIEW)};
}
function drawGrid(v){const{ctx,x,y,left,right,top,bottom,w,h}=v;
  for(let i=-3;i<=3;i++){line(ctx,x(i),top,x(i),bottom,C.grid);line(ctx,left,y(i),right,y(i),C.grid);text(ctx,String(i),x(i),bottom+17,C.muted,i===-3?'left':i===3?'right':'center');if(i!==0)text(ctx,String(i),left-7,y(i)+4,C.muted,'right');}
  line(ctx,left,y(0),right,y(0),'#aebfc3');line(ctx,x(0),top,x(0),bottom,'#aebfc3');text(ctx,'x (m)',(left+right)/2,h-7,C.ink,'center');text(ctx,'y (m)',left,Math.max(12,top-9),C.ink);
}
function clip(v,fn){v.ctx.save();v.ctx.beginPath();v.ctx.rect(v.left,v.top,v.right-v.left,v.bottom-v.top);v.ctx.clip();fn();v.ctx.restore();}
function shade(){
  const cache=JSON.stringify(p.charges);if(shadeKey===cache)return shadeImage;shadeKey=cache;
  const image=document.createElement('canvas');image.width=image.height=130;const ctx=image.getContext('2d'),data=ctx.createImageData(130,130);
  for(let j=0;j<130;j++)for(let i=0;i<130;i++){
    const point={x:-VIEW+2*VIEW*i/129,y:VIEW-2*VIEW*j/129},masked=p.charges.some(c=>c.q!==0&&distance(c,point)<MASK),e=masked?null:fieldAt(p.charges,point);
    const t=e?Math.max(0,Math.min(1,(Math.log10(Math.max(e.magnitude,100))-2)/4)):0,color=rgb(heatColor(t)),offset=4*(j*130+i);
    data.data[offset]=color.r;data.data[offset+1]=color.g;data.data[offset+2]=color.b;data.data[offset+3]=255;
  }
  ctx.putImageData(data,0,0);shadeImage=image;return image;
}
function fieldArrows(v){const{ctx,x,y,s}=v,length=Math.min(17,s*.32);
  for(let j=0;j<11;j++)for(let i=0;i<11;i++){
    const point={x:-2.7+.54*i,y:-2.7+.54*j};if(p.charges.some(c=>c.q!==0&&distance(c,point)<.23))continue;
    const e=fieldAt(p.charges,point);if(!e||e.magnitude<1e-10||e.magnitude<1e-8*e.scale)continue;
    const dx=length*e.x/e.magnitude/2,dy=-length*e.y/e.magnitude/2;arrow(ctx,x(point.x)-dx,y(point.y)-dy,x(point.x)+dx,y(point.y)+dy,C.field,1.1,[],4);
  }
}
function queueLines(){
  clearTimeout(lineTimer);if(drag)return;
  const cache=key(),charges=p.charges.map(c=>({...c})),density=Number($('density').value);
  lineTimer=setTimeout(()=>{try{const result=fieldLines(charges,density);if(key()===cache){lines=result;linesKey=cache;lineFailure='';}}catch(e){linesKey=cache;lines=[];lineFailure='Line tracing unavailable; field arrows shown.';}draw();},100);
}
function tracedLines(v){const{ctx,x,y}=v;
  for(const curve of lines){ctx.beginPath();ctx.strokeStyle=C.field;ctx.lineWidth=1.35;curve.points.forEach((q,i)=>i?ctx.lineTo(x(q.x),y(q.y)):ctx.moveTo(x(q.x),y(q.y)));ctx.stroke();let length=0;for(let i=1;i<curve.points.length;i++){const a=curve.points[i-1],b=curve.points[i];length+=v.s*distance(a,b);if(length>65){const tail=curve.points[Math.max(0,i-3)];arrow(ctx,x(tail.x),y(tail.y),x(b.x),y(b.y),C.field,1.35,[],5);length=0;}}}
}
function forceVectors(v,fs){const{ctx,x,y,left,right,top,bottom}=v,items=fs.map((f,i)=>({origin:p.charges[i],f,color:C.net,width:i===p.selected?3:2}));
  if($('components').checked)for(let j=0;j<p.charges.length;j++)if(j!==p.selected)items.unshift({origin:p.charges[p.selected],f:pairForce(p.charges,p.selected,j),color:C.pair,width:1.6,dash:[4,4]});
  let scale=Math.min(95,(right-left)*.25)/Math.max(...items.map(d=>d.f.magnitude),1e-30);
  for(const{origin,f}of items){const px=x(origin.x),py=y(origin.y);if(f.x>0)scale=Math.min(scale,(right-5-px)/f.x);if(f.x<0)scale=Math.min(scale,(left+5-px)/f.x);if(f.y>0)scale=Math.min(scale,(py-top-5)/f.y);if(f.y<0)scale=Math.min(scale,(py-bottom+5)/f.y);}
  for(const{origin,f,color,width,dash}of items)if(f.magnitude>1e-20)arrow(ctx,x(origin.x),y(origin.y),x(origin.x)+scale*f.x,y(origin.y)-scale*f.y,color,width,dash);
  $('force-scale').textContent=items.every(d=>d.f.magnitude===0)?'All force vectors are zero':forceText(40/scale)+' (common linear scale)';
}
function labels(v,radius){const{ctx,x,y,w,h}=v,placed=[];
  for(const[i,c]of p.charges.entries()){
    const label='q'+(i+1),width=ctx.measureText(label).width+5,px=x(c.x),py=y(c.y),offset=radius+5;
    const candidates=[[px+offset,py-offset],[px+offset,py+offset+10],[px-offset-width,py-offset],[px-offset-width,py+offset+10]];
    let chosen=candidates.find(([lx,ly])=>lx>v.left+1&&lx+width<v.right-1&&ly-11>v.top+1&&ly<v.bottom-1&&!placed.some(b=>lx<b.x+b.w&&lx+width>b.x&&ly-11<b.y+b.h&&ly>b.y)&&!p.charges.some(q=>Math.abs(lx+width/2-x(q.x))<width/2+radius&&Math.abs(ly-5-y(q.y))<radius+6))||candidates[0];
    placed.push({x:chosen[0],y:chosen[1]-11,w:width,h:15});text(ctx,label,chosen[0],chosen[1],C.ink,'left',11);
  }
}
function drawCharges(v){const{ctx,x,y,s}=v,radius=Math.min(13,Math.max(5,s*MIN_SEPARATION*.43));
  for(const[i,c]of p.charges.entries()){
    const color=c.q>0?C.positive:c.q<0?C.negative:'#77878d';if(i===p.selected)dot(ctx,x(c.x),y(c.y),radius+3,'white',C.ink);
    dot(ctx,x(c.x),y(c.y),radius,color);text(ctx,c.q>0?'+':c.q<0?'−':'0',x(c.x),y(c.y)+Math.max(3,radius*.35),'white','center',Math.max(9,Math.min(16,radius*1.4)));
  }
  labels(v,radius);
}
function drawProbe(v,result){if(!$('probe-visible').checked)return;const{ctx,x,y}=v,px=x(p.probe.x),py=y(p.probe.y);
  if(mode==='field'&&result.field&&result.field.magnitude>1e-10){const e=result.field,length=27,ux=e.x/e.magnitude,uy=-e.y/e.magnitude;arrow(ctx,px,py,px+length*ux,py+length*uy,C.ink,2.5);if(p.testQ!==0)arrow(ctx,px,py,px+Math.sign(p.testQ)*17*ux,py+Math.sign(p.testQ)*17*uy,C.pair,1.5,[3,3],5);}
  dot(ctx,px,py,5,'white',C.ink);line(ctx,px-8,py,px+8,py,C.ink);line(ctx,px,py-8,px,py+8,C.ink);text(ctx,'P',px>v.right-25?px-10:px+10,py<v.top+22?py+18:py-9,C.ink,px>v.right-25?'right':'left',12);
}
function drawScene(fs,probe){const v=sceneFrame();view=v;
  const field=mode==='field',wantLines=field&&$('field-style').value==='lines',ready=linesKey===key();
  if(field&&$('shading').checked&&!drag)v.ctx.drawImage(shade(),v.left,v.top,v.right-v.left,v.bottom-v.top);
  drawGrid(v);clip(v,()=>{
    if(field){if(wantLines&&ready&&!lineFailure&&!drag)tracedLines(v);else fieldArrows(v);}
    else forceVectors(v,fs);
    drawCharges(v);drawProbe(v,probe);
  });
  if(wantLines&&!ready&&!drag)queueLines();
  $('view-status').textContent=field?(drag?'Live direction arrows while dragging':wantLines?(ready?(lineFailure||`${lines.length} illustrative field curves`):'Updating curves · live field arrows'):'Direction-only field arrows'):'Shared linear force-arrow scale';
  $('scene-note').textContent=field?'Field directions run from positive toward negative sources or the view boundary. Grid and probe arrows show direction, not calibrated lengths. Shading uses a fixed logarithmic 10²–10⁶ N/C scale. The purple probe arrow follows the force on the virtual test charge.':'Gold arrows are net forces; dashed purple arrows are pair contributions on the selected charge. Every force arrow uses the same current linear scale. Positions are held; arrows are not charge motion. Select or drag a source; the selected marker has a dark ring.';
  if(p.charges.every(c=>c.q===0))$('scene-note').textContent='Every source charge is zero: all fields and forces vanish. There are no field curves or directions to draw.';
}
function drawInverse(){if(p.charges.length!==2)return;
  const{ctx,w,h}=canvas('inverse'),left=58,right=w-18,top=30,bottom=h-40,data=inverseSquare(p),nonzero=data[0].force>0;
  const x=scaleLinear().domain([.3,data.at(-1).r]).range([left,right]),y=nonzero?scaleLog().domain([data.at(-1).force*.8,data[0].force*1.2]).range([bottom,top]):scaleLinear().domain([0,1]).range([bottom,top]);
  for(const value of x.ticks(5)){line(ctx,x(value),top,x(value),bottom,C.grid);text(ctx,value,x(value),bottom+17,C.muted,'center');}
  const ticks=nonzero?y.ticks().filter(v=>{const power=Math.floor(Math.log10(v));return Math.abs(v/10**power-1)<1e-8;}):[0,.5,1];
  for(const value of ticks){line(ctx,left,y(value),right,y(value),C.grid);text(ctx,fmt(value*1e3,3),left-7,y(value)+4,C.muted,'right');}
  text(ctx,nonzero?'|F| (mN), log scale':'|F| (mN)',left,14,C.ink);text(ctx,'separation r (m)',(left+right)/2,h-5,C.muted,'center');
  ctx.beginPath();ctx.strokeStyle=C.field;ctx.lineWidth=2.3;data.forEach((d,i)=>i?ctx.lineTo(x(d.r),y(d.force)):ctx.moveTo(x(d.r),y(d.force)));ctx.stroke();
  const r=distance(...p.charges),f=pairForce(p.charges,0,1).magnitude;dot(ctx,x(r),y(f),5,C.net);
  $('pair-r').textContent=fmt(r)+' m';$('pair-f').textContent=forceText(f);$('pair-quarter').textContent=forceText(f/4);$('pair-four').textContent=forceText(f*4);
}
function contributions(probe){const field=mode==='field',point=field?p.probe:p.charges[p.selected],rows=[];
  $('sum-title').textContent=field?'Field superposition at probe P':'Force superposition on q'+(p.selected+1);
  $('sum-note').textContent=field?'All source charges included':'Selected source excluded from its own external field';
  $('column-x').textContent=field?'Eₓ (N/C)':'Fₓ (mN)';$('column-y').textContent=field?'Eᵧ (N/C)':'Fᵧ (mN)';$('column-mag').textContent=field?'|E| (N/C)':'|F| (mN)';
  let tx=0,ty=0;
  for(const[j,c]of p.charges.entries()){
    if(!field&&j===p.selected)continue;
    const value=field?(probe.status==='ready'?fieldAt([c],point):null):pairForce(p.charges,p.selected,j),factor=field?1:1e3;
    if(value){tx+=value.x*factor;ty+=value.y*factor;}
    const tr=document.createElement('tr');for(const textValue of ['q'+(j+1),fmt(c.q*1e6),fmt(distance(c,point)),value?fmt(value.x*factor):'—',value?fmt(value.y*factor):'—',value?fmt(value.magnitude*factor):'—']){const td=document.createElement('td');td.textContent=textValue;tr.append(td);}rows.push(tr);
  }
  $('contributions').replaceChildren(...rows);const tr=document.createElement('tr');
  for(const value of ['Vector sum','','',field&&probe.status!=='ready'?'—':fmt(tx),field&&probe.status!=='ready'?'—':fmt(ty),field&&probe.status!=='ready'?'—':fmt(Math.hypot(tx,ty))]){const td=document.createElement('td');td.textContent=value;tr.append(td);}$('total-row').replaceChildren(tr);
  $('table-note').textContent=field?'Components add as vectors. The magnitude of the sum is not the sum of magnitudes. Probe displays are withheld inside the source exclusion disks.':'Each row is the force on the selected charge due to one other source. Its reaction acts on that other source. Net forces in a many-charge system are not generally an equal-and-opposite pair.';
}
function draw(){const fs=forces(p.charges),selected=fs[p.selected],external=fieldAt(p.charges,p.charges[p.selected],p.selected),probe=probeResult(p);
  $('selected-title').textContent=mode==='field'?'Field magnitude at P':'Net force on q'+(p.selected+1);
  $('main-components-title').textContent=mode==='field'?'Eₓ / Eᵧ (N/C)':'Fₓ / Fᵧ (mN)';$('main-third-title').textContent=mode==='field'?'Virtual test force at P':'External |E| at selected charge';
  if(mode==='field'){$('force-mag').textContent=probe.field?fmt(probe.field.magnitude)+' N/C':probe.status==='singular'?'Undefined at source':'Display exclusion';$('force-components').textContent=probe.field?fmt(probe.field.x)+' / '+fmt(probe.field.y):'—';$('external-field').textContent=probe.force?forceText(probe.force.magnitude):'—';}
  else{$('force-mag').textContent=forceText(selected.magnitude);$('force-components').textContent=fmt(selected.x*1e3)+' / '+fmt(selected.y*1e3);$('external-field').textContent=fmt(external.magnitude)+' N/C';}
  if(probe.status==='ready'){$('probe-field').textContent=fmt(probe.field.magnitude)+' N/C';$('probe-components').textContent=fmt(probe.field.x)+' / '+fmt(probe.field.y);$('test-force').textContent=forceText(probe.force.magnitude);$('probe-note').textContent='Ftest = qtest E(P). The test charge is virtual and does not alter E. '+(p.testQ<0?'A negative test charge reverses the force direction.':p.testQ===0?'With qtest = 0, force vanishes without erasing the field.':'A positive test charge feels force along E.');}
  else{$('probe-field').textContent=probe.status==='singular'?'Undefined at source':'Display exclusion';$('probe-components').textContent='—';$('test-force').textContent='—';$('probe-note').textContent=probe.status==='singular'?'The field of a nonzero point source is undefined at its own position. Move P away from the source.':'P is within 0.12 m of a nonzero source. This display withholds the probe values there; the underlying Coulomb formula is not softened.';}
  drawScene(fs,probe);drawInverse();contributions(probe);
}
for(const[id,value]of [['mode-force','force'],['mode-field','field']])$(id).addEventListener('click',()=>{mode=value;sync();});
$('example').addEventListener('change',()=>{example=$('example').value;p=preset(example);error();sync();});
$('count').addEventListener('change',()=>change(q=>resizeCharges(q,Number($('count').value))));
$('selected').addEventListener('change',()=>{p.selected=Number($('selected').value);sync();});
for(const id of ['charge','x','y'])$(id).addEventListener('change',()=>change(q=>{q.charges[q.selected][id==='charge'?'q':id]=$(id).valueAsNumber*(id==='charge'?1e-6:1);return q;}));
$('charge-range').addEventListener('input',()=>change(q=>{q.charges[q.selected].q=Number($('charge-range').value)*1e-6;return q;}));
for(const id of ['distance','distance-range'])$(id).addEventListener(id==='distance'?'change':'input',()=>change(q=>setSeparation(q,$(id).valueAsNumber)));
for(const[id,factor]of [['halve',.5],['double',2]])$(id).addEventListener('click',()=>change(q=>setSeparation(q,distance(...q.charges)*factor)));
for(const id of ['components','field-style','density','shading','probe-visible'])$(id).addEventListener('change',sync);
for(const[id,keyName]of [['probe-x','x'],['probe-y','y']])$(id).addEventListener('change',()=>change(q=>{q.probe[keyName]=$(id).valueAsNumber;return q;},false));
$('test-charge').addEventListener('change',()=>change(q=>({...q,testQ:$('test-charge').valueAsNumber*1e-6}),false));
$('reset').addEventListener('click',()=>{clearTimeout(lineTimer);p=preset();example='dipole';$('components').checked=true;$('shading').checked=true;$('probe-visible').checked=true;$('field-style').value='lines';$('density').value='10';$('snap').checked=false;error();sync();});
$('download').addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([csv(p)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='coulomb-sources-forces.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
function pointerPoint(event){const b=$('scene').getBoundingClientRect();let x=(event.clientX-b.left-view.cx)/view.s,y=(view.cy-event.clientY+b.top)/view.s;if($('snap').checked){x=Math.round(x*10)/10;y=Math.round(y*10)/10;}return{x,y};}
$('scene').addEventListener('pointerdown',event=>{const point=pointerPoint(event),radius=22/view.s;const nearest=p.charges.map((c,i)=>({i,d:distance(c,point)})).sort((a,b)=>a.d-b.d)[0],probeDistance=$('probe-visible').checked?distance(p.probe,point):Infinity;
  if(probeDistance<radius&&probeDistance<nearest.d)drag={kind:'probe'};
  else if(nearest.d<radius){p.selected=nearest.i;drag={kind:'charge'};}
  else if($('probe-visible').checked)drag={kind:'probe'};
  if(drag){clearTimeout(lineTimer);$('scene').setPointerCapture(event.pointerId);if(drag.kind==='probe')movePointer(point);else sync();}
});
function movePointer(point){const kind=drag.kind,bound=kind==='charge'?BOUND:2.8,position={x:Math.max(-bound,Math.min(bound,point.x)),y:Math.max(-bound,Math.min(bound,point.y))};change(q=>{if(kind==='charge')Object.assign(q.charges[q.selected],position);else q.probe=position;return q;},kind==='charge');}
$('scene').addEventListener('pointermove',event=>{if(drag)movePointer(pointerPoint(event));});
for(const event of ['pointerup','pointercancel','lostpointercapture'])$('scene').addEventListener(event,()=>{if(drag){drag=null;draw();}});
window.addEventListener('pagehide',()=>clearTimeout(lineTimer));
const observer=new ResizeObserver(()=>{if($('scene').getBoundingClientRect().width>0)draw();});observer.observe($('scene'));observer.observe($('inverse'));createIcons({icons});sync();
