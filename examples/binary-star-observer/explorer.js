import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { createIcons,Play,Pause,RotateCcw,Eye,Orbit,Download,ArrowUpRight,Circle,Sparkle } from 'lucide';
import * as d3 from 'd3';
import { DEFAULT,PRESETS,TAU,DEG,wrap,valid,radii,state,atAnomaly,flux,outcome,probability,totalCoverageProbability,events,curve,orientationCount,pole } from './model.js';

const $=id=>document.getElementById(id);
const icons={Play,Pause,RotateCcw,Eye,Orbit,Download,ArrowUpRight,Circle,Sparkle};
const p={...DEFAULT};
let mode='observer',unresolved=false,playing=false,last=0,adjusted='',samples=[],eventList=[];
let renderer,scene,camera,orbitControls,system=new THREE.Group(),star1,star2,selectedPole;
let xScale,yScale,cursor,fluxDot;
const percent=x=>(100*x).toFixed(1)+'%';
const fmt=(x,n=3)=>x.toFixed(n);
function refreshIcons(){createIcons({icons});}
function setPlay(value){playing=value;$('play').innerHTML=`<i data-lucide="${value?'pause':'play'}"></i>`;$('play').setAttribute('aria-label',value?'Pause orbit':'Play orbit');$('play').title=value?'Pause orbit':'Play orbit';refreshIcons();}

function initializeScene(){
  try{
    renderer=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});
    renderer.setPixelRatio(Math.min(devicePixelRatio,2));
    renderer.setClearColor('#132723');$('scene').append(renderer.domElement);
    renderer.domElement.setAttribute('aria-label','Binary orbit with fixed Earth sightline, or random orbital poles');
    scene=new THREE.Scene();scene.add(system);
    camera=new THREE.PerspectiveCamera(40,1,.01,100);
    orbitControls=new OrbitControls(camera,renderer.domElement);
    orbitControls.enableDamping=true;orbitControls.dampingFactor=.08;
    orbitControls.minDistance=2.5;orbitControls.maxDistance=10;orbitControls.enablePan=false;
    scene.add(new THREE.AmbientLight(0xffffff,2));
    const light=new THREE.DirectionalLight(0xffffff,2.4);light.position.set(-2,3,5);scene.add(light);
    resetCamera();
  }catch{
    renderer?.dispose();renderer=undefined;$('scene').querySelector('canvas')?.remove();$('webgl-fallback').hidden=false;
  }
}
function resetCamera(){
  if(!camera)return;
  camera.up.set(0,1,0);camera.position.set(mode==='observer'?1.8:2.1,mode==='observer'?1.55:1.8,mode==='observer'?2.45:2.5);
  orbitControls.target.set(0,0,mode==='observer'?.30:0);orbitControls.update();
}
function line(points,color,opacity=1){
  const geometry=new THREE.BufferGeometry().setFromPoints(points.map(v=>new THREE.Vector3(...v)));
  const obj=new THREE.Line(geometry,new THREE.LineBasicMaterial({color,transparent:opacity<1,opacity}));system.add(obj);return obj;
}
function sphere(radius,color,position=[0,0,0]){
  const mesh=new THREE.Mesh(new THREE.SphereGeometry(radius,40,24),new THREE.MeshStandardMaterial({color,roughness:.85,emissive:color,emissiveIntensity:.4}));
  mesh.position.set(...position);system.add(mesh);return mesh;
}
function arrow(vector,length,color){
  const v=new THREE.Vector3(...vector).normalize();
  const obj=new THREE.ArrowHelper(v,new THREE.Vector3(),length,color,.10,.055);system.add(obj);return obj;
}
function label(text,position,color='#d8eee2'){
  const canvas=document.createElement('canvas');canvas.width=256;canvas.height=64;
  const c=canvas.getContext('2d');c.font='26px Arial';c.fillStyle=color;c.textAlign='center';c.fillText(text,128,40);
  const texture=new THREE.CanvasTexture(canvas),obj=new THREE.Sprite(new THREE.SpriteMaterial({map:texture,transparent:true,depthTest:false}));
  obj.position.set(...position);obj.scale.set(.80,.20,1);system.add(obj);
}
function clearSystem(){
  system.traverse(obj=>{obj.geometry?.dispose();const mats=Array.isArray(obj.material)?obj.material:[obj.material];for(const m of mats){m?.map?.dispose();m?.dispose();}});
  system.clear();star1=star2=selectedPole=undefined;
}
function drawOrbitScene(){
  clearSystem();
  const {r1,r2}=radii(p),path1=[],path2=[];
  for(let n=0;n<=256;n++){const v=atAnomaly(p,TAU*n/256);path1.push(v.star1);path2.push(v.star2);}
  line(path1,'#d2a343',.8);line(path2,'#68bdd5',.8);
  const peak=Math.max(1,p.j);
  const color1=new THREE.Color('#ffc55e').multiplyScalar(1/peak),color2=new THREE.Color('#79d4f0').multiplyScalar(p.j/peak);
  star1=sphere(r1,color1);star2=sphere(r2,color2);
  sphere(.014,'#f5f5e3');
  const sky=new THREE.Mesh(new THREE.PlaneGeometry(2.1,2.1),new THREE.MeshBasicMaterial({color:'#578b79',transparent:true,opacity:.07,side:THREE.DoubleSide,depthWrite:false}));system.add(sky);
  line([[-1.05,0,0],[1.05,0,0]],'#3f6d5b',.5);line([[0,-1.05,0],[0,1.05,0]],'#3f6d5b',.5);
  label('Sky plane',[.65,.95,0],'#89af9d');
  arrow([0,0,1],1.6,'#83e0a6');sphere(.055,'#62bc94',[0,0,1.65]);label('Earth (+Z)',[0,.15,1.75],'#98e5af');
  arrow(pole(p),1.0,'#dfb5f3');label('Pole',pole(p).map(v=>v*1.13),'#dfb5f3');
  // The orbit-normal angle, not the free inspection camera, sets physical inclination.
  const arc=[];for(let n=0;n<=64;n++){const t=p.i*DEG*n/64;arc.push([0,-.43*Math.sin(t),.43*Math.cos(t)]);}
  line(arc,'#f4e7cf');label(`i = ${p.i.toFixed(1)} deg`,[.22,-.27,.42],'#e3d6b5');
}
function drawProbabilityScene(){
  clearSystem();
  const pr=probability(p),positions=[],colors=[],color=new THREE.Color();
  for(let n=0;n<2400;n++){
    const mu=1-2*(n+.5)/2400,angle=n*Math.PI*(3-Math.sqrt(5)),r=Math.sqrt(1-mu*mu);
    positions.push(r*Math.cos(angle),r*Math.sin(angle),mu);
    color.set(Math.abs(mu)<pr.both?'#77dfad':Math.abs(mu)<pr.any?'#e6b455':'#70897c');colors.push(color.r,color.g,color.b);
  }
  const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));geometry.setAttribute('color',new THREE.Float32BufferAttribute(colors,3));
  system.add(new THREE.Points(geometry,new THREE.PointsMaterial({size:.017,vertexColors:true,sizeAttenuation:true})));
  function band(muLow,muHigh,color){
    if(muHigh-muLow<1e-10)return;
    for(const sign of [-1,1]){
      const top=Math.acos(sign===1?muHigh:-muLow),bottom=Math.acos(sign===1?muLow:-muHigh);
      const belt=new THREE.Mesh(new THREE.SphereGeometry(1.005,96,16,0,TAU,top,bottom-top),new THREE.MeshBasicMaterial({color,transparent:true,opacity:.15,side:THREE.DoubleSide,depthWrite:false}));
      belt.rotation.x=Math.PI/2;system.add(belt);
    }
  }
  band(0,pr.both,'#64dba2');band(pr.both,pr.any,'#e6ae43');
  for(const mu of [-pr.any,-pr.both,0,pr.both,pr.any]){
    const r=Math.sqrt(1-mu*mu),points=[];for(let n=0;n<=160;n++)points.push([r*Math.cos(TAU*n/160),r*Math.sin(TAU*n/160),mu]);
    line(points,Math.abs(mu)===pr.any?'#ebbc6b':'#7dbca0',mu===0?.3:.7);
  }
  line([[0,0,-1.15],[0,0,1.6]],'#7ab998',.7);arrow([0,0,1],1.5,'#83e0a6');label('Earth (+Z)',[0,.28,1.25],'#98e5af');
  selectedPole=sphere(.045,'#dfb5f3',pole(p).map(v=>v*1.025));arrow(pole(p),1.02,'#dfb5f3');label('Selected pole',pole(p).map(v=>v*1.2),'#dfb5f3');
  label('Eclipsing orientations',[0,0,-1.33],'#edc97b');
}

function disk(c,x,y,r,color){
  const grad=c.createRadialGradient(x-r*.15,y-r*.18,0,x,y,r);
  const edge=p.limb?.35:.92;
  grad.addColorStop(0,color);grad.addColorStop(.7,color);grad.addColorStop(1,d3.color(color).darker(-Math.log2(edge)).formatHex());
  c.fillStyle=grad;c.beginPath();c.arc(x,y,r,0,TAU);c.fill();
}
function drawEarth(){
  const canvas=$('earth-canvas'),rect=canvas.getBoundingClientRect(),dpr=Math.min(devicePixelRatio,2);
  if(!rect.width)return;
  canvas.width=Math.round(rect.width*dpr);canvas.height=Math.round(rect.height*dpr);
  const c=canvas.getContext('2d');c.scale(dpr,dpr);const W=rect.width,H=rect.height;
  c.fillStyle='#f9fbfa';c.fillRect(0,0,W,H);
  const v=state(p),F=flux(p,v),{r1,r2}=radii(p);
  if(unresolved){
    c.fillStyle='#172c25';c.fillRect(0,0,W,H);
    const r=4,halo=c.createRadialGradient(W/2,H/2,0,W/2,H/2,20);
    halo.addColorStop(0,`rgba(245,231,187,${F})`);halo.addColorStop(.25,`rgba(245,231,187,${F*.5})`);halo.addColorStop(1,'rgba(245,231,187,0)');
    c.fillStyle=halo;c.fillRect(W/2-20,H/2-20,40,40);c.fillStyle=`rgba(255,246,212,${F})`;c.beginPath();c.arc(W/2,H/2,r,0,TAU);c.fill();
  }else{
    const span=Math.max(.65,(1+p.e)*Math.max(p.q,1)/(1+p.q)+Math.max(r1,r2)),scale=Math.min(W-38,H-44)/(2*span);
    const X=x=>W/2+x*scale,Y=y=>H/2-y*scale;
    c.strokeStyle='#dce6e0';c.lineWidth=1;c.beginPath();c.moveTo(18,H/2);c.lineTo(W-18,H/2);c.moveTo(W/2,18);c.lineTo(W/2,H-18);c.stroke();
    c.setLineDash([3,4]);
    for(const [key,color] of [['star1','#d3ba84'],['star2','#96c1cd']]){
      c.strokeStyle=color;c.beginPath();for(let n=0;n<=200;n++){const xy=atAnomaly(p,TAU*n/200)[key];if(n===0)c.moveTo(X(xy[0]),Y(xy[1]));else c.lineTo(X(xy[0]),Y(xy[1]));}c.stroke();
    }
    c.setLineDash([]);
    const peak=Math.max(1,p.j),c1=d3.rgb('#efb044'),c2=d3.rgb('#60bdda');
    for(const key of ['r','g','b']){c1[key]/=peak;c2[key]*=p.j/peak;}
    const stars=[{xy:v.star1,r:r1,color:c1.formatHex(),n:1},{xy:v.star2,r:r2,color:c2.formatHex(),n:2}].sort((a,b)=>a.xy[2]-b.xy[2]);
    for(const star of stars)disk(c,X(star.xy[0]),Y(star.xy[1]),Math.max(.5,star.r*scale),star.color);
    c.font='11px Arial';c.fillStyle='#72867a';c.textAlign='left';c.fillText('X',W-23,H/2-6);c.fillText('Y',W/2+6,22);
    c.strokeStyle='#718e7c';c.beginPath();c.moveTo(20,H-22);c.lineTo(20+.2*scale,H-22);c.stroke();c.fillText('0.2 a',20,H-7);
  }
  $('eclipse-state').textContent=outcome(p,v);
}
function drawPlot(){
  samples=curve(p);eventList=events(p);
  const svg=d3.select('#light-curve');svg.selectAll('*').remove();
  const W=$('light-curve').getBoundingClientRect().width,H=205,m={left:47,right:20,top:19,bottom:35};
  if(W<100)return;
  svg.attr('viewBox',`0 0 ${W} ${H}`);
  xScale=d3.scaleLinear().domain([0,1]).range([m.left,W-m.right]);
  const low=Math.max(0,Math.min(...samples.map(v=>v.flux))-.035);
  yScale=d3.scaleLinear().domain([low,1.035]).range([H-m.bottom,m.top]);
  svg.append('g').attr('class','axis').attr('transform',`translate(0,${H-m.bottom})`).call(d3.axisBottom(xScale).ticks(W<500?5:10).tickFormat(d3.format('.1f')));
  svg.append('g').attr('class','axis').attr('transform',`translate(${m.left},0)`).call(d3.axisLeft(yScale).ticks(4).tickFormat(d3.format('.2f')));
  for(const ev of eventList){
    const ranges=ev.end<ev.start?[[ev.start,1],[0,ev.end]]:[[ev.start,ev.end]];
    for(const [a,b] of ranges)svg.append('rect').attr('x',xScale(a)).attr('y',m.top).attr('width',xScale(b)-xScale(a)).attr('height',H-m.bottom-m.top).attr('fill',ev.behind===1?'#fbf2dd':'#e8f5f8');
  }
  svg.append('path').datum(samples).attr('d',d3.line().x(v=>xScale(v.phase)).y(v=>yScale(v.flux))).attr('fill','none').attr('stroke','#236f57').attr('stroke-width',2);
  cursor=svg.append('line').attr('y1',m.top).attr('y2',H-m.bottom).attr('stroke','#a68038').attr('stroke-width',1).attr('stroke-dasharray','3,3');
  fluxDot=svg.append('circle').attr('r',4).attr('fill','#c89b42').attr('stroke','#fff').attr('stroke-width',1.5);
  svg.append('text').attr('x',W-m.right).attr('y',H-5).attr('text-anchor','end').attr('font-size',11).attr('fill','#6f8177').text('Orbital phase');
  $('event-summary').replaceChildren();
  for(const behind of [1,2]){
    const ev=eventList.find(v=>v.behind===behind),div=document.createElement('div');div.className='event';
    const title=document.createElement('strong');title.textContent=`Eclipse ${behind===1?'A':'B'}: star ${behind} behind`;div.append(title,document.createElement('br'));
    const span=document.createElement('span');span.textContent=ev?`Midpoint ${fmt(ev.phase)} | duration ${percent(ev.duration)} of P`: 'No eclipse at this inclination';div.append(span);
    if(ev){div.append(document.createElement('br'));const depth=document.createElement('span');depth.textContent=`Depth ${percent(ev.depth)}`;div.append(depth);}
    $('event-summary').append(div);
  }
}
function updateProbability(){
  const pr=probability(p),total=totalCoverageProbability(p),counts=orientationCount(p),mu=Math.cos(p.i*DEG);
  for(const [id,value] of [['p-any',pr.any],['p-both',pr.both],['p-only',pr.any-pr.both],['p-none',1-pr.any],['p-a',pr.a],['p-b',pr.b],['p-total',total]])$(id).textContent=percent(value);
  $('i-critical').textContent=(Math.acos(pr.any)/DEG).toFixed(2)+' deg';
  $('selected-outcome').textContent=`${p.i.toFixed(1)} deg: ${mu<pr.both?'both':mu<pr.any?'one':'neither'}`;
  $('ensemble-bar').replaceChildren();
  for(const [count,color] of [[counts.both,'#3ba174'],[counts.only,'#d8a448'],[counts.none,'#b4c1b8']]){
    const span=document.createElement('span');span.style.width=percent(count/counts.n);span.style.background=color;$('ensemble-bar').append(span);
  }
  $('ensemble-count').textContent=`${counts.both} both / ${counts.only} one / ${counts.none} neither`;
}
function updateInstant(){
  const v=state(p),F=flux(p,v);
  if(star1){star1.position.set(...v.star1);star2.position.set(...v.star2);}
  if(cursor){cursor.attr('x1',xScale(p.phase)).attr('x2',xScale(p.phase));fluxDot.attr('cx',xScale(p.phase)).attr('cy',yScale(F));}
  $('phase').value=p.phase;$('phase-value').textContent=fmt(p.phase);
  $('flux-readout').textContent=fmt(F,4);
  if(mode==='observer')drawEarth();
}
function recompute(){
  if(!valid(p))throw new Error('Invalid detached binary parameters');
  for(const id of ['i','w','s','k','j','e','q']){
    $(id).value=p[id];$(id+'-value').textContent=fmt(p[id],['i','w'].includes(id)?1:id==='s'?3:2)+(['i','w'].includes(id)?' deg':'');
  }
  $('limb').checked=p.limb;const {r1,r2}=radii(p);$('r1').textContent=fmt(r1);$('r2').textContent=fmt(r2);
  $('detached').textContent=adjusted||`Detached: radius sum ${fmt(p.s)} < periastron separation ${fmt(1-p.e)} a`;
  $('detached').classList.toggle('adjusted',Boolean(adjusted));
  drawPlot();updateProbability();
  if(renderer){if(mode==='observer')drawOrbitScene();else drawProbabilityScene();}
  updateInstant();
}
function switchMode(next){
  mode=next;setPlay(false);document.body.classList.toggle('probability-mode',mode==='probability');
  $('observer-panel').hidden=mode!=='observer';$('probability-panel').hidden=mode!=='probability';$('earth-panel').hidden=mode!=='observer';
  for(const name of ['observer','probability']){const tab=$(name+'-tab');tab.setAttribute('aria-selected',String(name===mode));tab.tabIndex=name===mode?0:-1;}
  $('scene-title').textContent=mode==='observer'?'Orbit & Earth line of sight':'Orbital poles on the orientation sphere';
  $('camera-top').disabled=mode==='probability';recompute();resetCamera();resize();
}
function resize(){
  if(renderer){const box=$('scene').getBoundingClientRect();renderer.setSize(box.width,box.height,false);camera.aspect=box.width/box.height;camera.zoom=Math.min(1,camera.aspect/(mode==='observer'?1.7:1.4));camera.updateProjectionMatrix();}
  if(mode==='observer'){drawPlot();updateInstant();}
}
for(const id of ['i','w','s','k','j','e','q'])$(id).addEventListener('input',()=>{
  p[id]=Number($(id).value);adjusted='';
  if(p.s>=1-p.e){
    if(id==='e'){p.s=Math.floor((1-p.e-.005)*1000)/1000;adjusted='Radius sum reduced to keep both stars detached at periastron.';}
    else{p.e=Math.max(0,Math.floor((1-p.s-.005)*100)/100);adjusted='Eccentricity reduced to keep both stars detached at periastron.';}
  }
  $('preset').selectedIndex=-1;recompute();
});
$('limb').addEventListener('change',()=>{p.limb=$('limb').checked;recompute();});
$('preset').addEventListener('change',()=>{Object.assign(p,PRESETS[$('preset').value]);adjusted='';setPlay(false);const ev=events(p);if(ev.length)p.phase=ev[0].phase;recompute();});
$('phase').addEventListener('input',()=>{setPlay(false);p.phase=Number($('phase').value);updateInstant();});
$('play').addEventListener('click',()=>setPlay(!playing));
$('observer-tab').addEventListener('click',()=>switchMode('observer'));
$('probability-tab').addEventListener('click',()=>switchMode('probability'));
document.querySelector('.modes').addEventListener('keydown',event=>{
  if(['ArrowLeft','ArrowRight','Home','End'].includes(event.key)){
    event.preventDefault();switchMode(event.key==='Home'?'observer':event.key==='End'?'probability':mode==='observer'?'probability':'observer');$(mode+'-tab').focus();
  }
});
for(const [id,value] of [['disk-view',false],['point-view',true]])$(id).addEventListener('click',()=>{
  unresolved=value;$('disk-view').setAttribute('aria-pressed',String(!value));$('point-view').setAttribute('aria-pressed',String(value));
  $('projection-label').textContent=value?'Unresolved source | combined photometric light':'Magnified disks | sky plane X-Y';drawEarth();
});
$('camera-reset').addEventListener('click',resetCamera);
$('camera-earth').addEventListener('click',()=>{if(camera){camera.up.set(0,1,0);camera.position.set(0,0,4.5);orbitControls.target.set(0,0,0);orbitControls.update();}});
$('camera-top').addEventListener('click',()=>{if(camera){camera.up.set(1,0,0);camera.position.set(...pole(p).map(v=>v*4.5));orbitControls.target.set(0,0,0);orbitControls.update();}});
function scrub(event){
  if(!xScale)return;const box=$('light-curve').getBoundingClientRect(),W=xScale.range()[1]+20;
  p.phase=Math.max(0,Math.min(1,xScale.invert((event.clientX-box.left)*W/box.width)));setPlay(false);updateInstant();
}
let dragging=false;
$('light-curve').addEventListener('pointerdown',event=>{dragging=true;$('light-curve').setPointerCapture(event.pointerId);scrub(event);});
$('light-curve').addEventListener('pointermove',event=>{if(dragging)scrub(event);});
$('light-curve').addEventListener('pointerup',()=>{dragging=false;});
$('light-curve').addEventListener('pointercancel',()=>{dragging=false;});
$('light-curve').addEventListener('keydown',event=>{if(['ArrowLeft','ArrowRight'].includes(event.key)){event.preventDefault();setPlay(false);p.phase=wrap(p.phase+(event.key==='ArrowRight'?.005:-.005));updateInstant();}});
$('export').addEventListener('click',()=>{
  const rows=['phase,normalized_flux,inclination,radius_sum,radius_ratio,brightness_ratio,eccentricity,omega,mass_ratio,limb_darkening'];
  for(const v of samples)rows.push([v.phase,v.flux,p.i,p.s,p.k,p.j,p.e,p.w,p.q,p.limb?1:0].join(','));
  const url=URL.createObjectURL(new Blob([rows.join('\n')+'\n'],{type:'text/csv'}));const a=document.createElement('a');a.href=url;a.download='binary-light-curve.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
});
document.addEventListener('visibilitychange',()=>{last=0;});
function frame(time){
  if(!document.hidden){
    const dt=last?Math.min(.05,(time-last)/1000):0;
    if(playing&&mode==='observer'){p.phase=wrap(p.phase+dt*Number($('speed').value));updateInstant();}
    if(renderer){orbitControls.update();renderer.render(scene,camera);}
  }
  last=time;requestAnimationFrame(frame);
}
initializeScene();refreshIcons();recompute();
new ResizeObserver(resize).observe($('scene'));window.addEventListener('resize',resize);resize();requestAnimationFrame(frame);
