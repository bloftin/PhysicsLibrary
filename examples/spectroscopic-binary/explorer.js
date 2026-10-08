import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import * as d3 from 'd3';
import {createIcons,Play,Pause,RotateCcw,Eye,Orbit,Download,ArrowUpRight} from 'lucide';
import {DEFAULT,PRESETS,TAU,DEG,C,AU,elements,atAnomaly,state,rvCurve,spectrum,lineShape,velocityDomain,wavelength,infer,csv,wrap} from './model.js';

const $=id=>document.getElementById(id),icons={Play,Pause,RotateCcw,Eye,Orbit,Download,ArrowUpRight};
const colors=['#e2ad40','#21b5d1'],p={...DEFAULT};let playing=false,view='profile',rvPlot,profilePlot,trailPlot,curve=[];
const fmt=(v,n=2)=>Number.isFinite(v)?v.toFixed(n):'Not constrained';
const keys=['m1','q','period','i','e','w','gamma','light','width','resolution'];
const units={m1:' M☉',period:' d',i:'°',w:'°',gamma:' km/s',width:' km/s'};
function syncControls(){
  for(const k of keys){$(k).value=p[k];$(k+'-value').textContent=(k==='resolution'?Math.round(p[k]).toLocaleString():fmt(p[k],['period','w','gamma','width'].includes(k)?0:k==='i'?1:2))+(units[k]||'');}
  $('sb2').setAttribute('aria-pressed',String(p.sb2));$('sb1').setAttribute('aria-pressed',String(!p.sb2));
  $('rv2').hidden=!p.sb2;$('secondary-key').hidden=!p.sb2;$('assumed-label').hidden=p.sb2;
}
function axes(id,xDomain,yDomain,xLabel,yLabel,height){
  const svg=d3.select($(id)),width=$(id).clientWidth;if(width<100)return null;
  svg.selectAll('*').remove();svg.attr('viewBox',`0 0 ${width} ${height}`);
  const margin={left:44,right:14,top:12,bottom:40},x=d3.scaleLinear().domain(xDomain).range([margin.left,width-margin.right]),y=d3.scaleLinear().domain(yDomain).range([height-margin.bottom,margin.top]);
  svg.append('g').attr('class','grid').attr('transform',`translate(${margin.left},0)`).call(d3.axisLeft(y).ticks(4).tickSize(-(width-margin.left-margin.right)).tickFormat(''));
  svg.append('g').attr('class','axis').attr('transform',`translate(0,${height-margin.bottom})`).call(d3.axisBottom(x).ticks(width<400?4:6).tickFormat(xLabel.includes('nm')?d3.format('.2f'):null));
  svg.append('g').attr('class','axis').attr('transform',`translate(${margin.left},0)`).call(d3.axisLeft(y).ticks(4));
  svg.append('text').attr('class','axis-label').attr('x',(width+margin.left)/2).attr('y',height-5).attr('text-anchor','middle').text(xLabel);
  svg.append('text').attr('class','axis-label').attr('transform',`translate(12,${(height-margin.bottom)/2}) rotate(-90)`).attr('text-anchor','middle').text(yLabel);
  return {svg,x,y,width,height,margin};
}
function marker(plot,x,color,dash,label){
  const g=plot.svg.append('g');g.append('line').attr('x1',plot.x(x)).attr('x2',plot.x(x)).attr('y1',plot.margin.top).attr('y2',plot.height-plot.margin.bottom).attr('stroke',color).attr('stroke-dasharray',dash);
  if(label)g.append('text').attr('x',plot.x(x)+3).attr('y',plot.margin.top-3).attr('fill',color).attr('font-size',10).text(label);return g;
}
function path(plot,data,x,y,color,klass){
  return plot.svg.append('path').attr('class',klass||'').attr('fill','none').attr('stroke',color).attr('stroke-width',1.7).attr('d',d3.line().x(v=>plot.x(x(v))).y(v=>plot.y(y(v)))(data));
}
function scrub(plot,id,vertical=false){
  const node=$(id),select=event=>{if(event.pointerType==='mouse'&&event.buttons!==1)return;const pt=d3.pointer(event,node);p.phase=Math.max(0,Math.min(1,(vertical?plot.y:plot.x).invert(pt[vertical?1:0])));pause();updatePhase();};
  node.onpointerdown=e=>{node.setPointerCapture(e.pointerId);select(e);};node.onpointermove=e=>{if(node.hasPointerCapture(e.pointerId))select(e);};
  node.onkeydown=e=>{if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Home','End'].includes(e.key))return;e.preventDefault();pause();p.phase=e.key==='Home'?0:e.key==='End'?1:wrap(p.phase+(['ArrowLeft','ArrowUp'].includes(e.key)?-.005:.005));updatePhase();};
}
function drawRV(){
  const el=elements(p),offset=p.e*Math.cos(p.w*DEG),bounds=[p.gamma+el.k1*(offset-1),p.gamma+el.k1*(offset+1)];
  if(p.sb2)bounds.push(p.gamma-el.k2*(offset-1),p.gamma-el.k2*(offset+1));
  const padding=Math.max(5,(Math.max(...bounds)-Math.min(...bounds))*.12);
  rvPlot=axes('rv-curve',[0,1],[Math.min(...bounds)-padding,Math.max(...bounds)+padding],'Orbital phase','RV (km/s)',$('rv-curve').clientHeight);if(!rvPlot)return;
  rvPlot.svg.append('line').attr('x1',rvPlot.x(0)).attr('x2',rvPlot.x(1)).attr('y1',rvPlot.y(p.gamma)).attr('y2',rvPlot.y(p.gamma)).attr('stroke','#82939b').attr('stroke-dasharray','4 4');
  path(rvPlot,curve,v=>v.phase,v=>v.rv1,'#b47a12','rv1-path');if(p.sb2)path(rvPlot,curve,v=>v.phase,v=>v.rv2,'#087e9b','rv2-path');
  rvPlot.cursor=rvPlot.svg.append('line').attr('class','cursor').attr('y1',12).attr('y2',rvPlot.height-40);
  rvPlot.dots=[rvPlot.svg.append('circle').attr('r',4).attr('fill','#b47a12'),rvPlot.svg.append('circle').attr('r',4).attr('fill','#087e9b').style('display',p.sb2?null:'none')];scrub(rvPlot,'rv-curve');
}
function drawProfile(){
  const domain=velocityDomain(p).map(wavelength);profilePlot=axes('spectrum',domain,[.28,1.02],'Wavelength (nm)','Normalized flux',$('spectrum').clientHeight);if(!profilePlot)return;
  marker(profilePlot,wavelength(0),'#8b989f','2 4','rest');marker(profilePlot,wavelength(p.gamma),'#647c8b','4 3','');
  profilePlot.paths=[profilePlot.svg.append('path').attr('class','combined-line').attr('stroke','#293a44').attr('stroke-width',2.1),profilePlot.svg.append('path').attr('class','primary-line').attr('stroke','#b47a12').attr('stroke-width',1.3),profilePlot.svg.append('path').attr('class','secondary-line').attr('stroke','#087e9b').attr('stroke-width',1.3).style('display',p.sb2?null:'none')];
  for(const line of profilePlot.paths)line.attr('fill','none');
}
function drawTrail(){
  if(view!=='trail')return;const [lo,hi]=velocityDomain(p);trailPlot=axes('trail-axis',[wavelength(lo),wavelength(hi)],[1,0],'Wavelength (nm)','Orbital phase',$('trail-axis').clientHeight);if(!trailPlot)return;
  // The heatmap is recomputed only when parameters or viewport dimensions change.
  const canvas=$('trail'),width=512,height=256;canvas.width=width;canvas.height=height;const context=canvas.getContext('2d'),image=context.createImageData(width,height);
  for(let row=0;row<height;row++){const v=state(p,row/(height-1));for(let col=0;col<width;col++){const flux=spectrum(p,lo+(hi-lo)*col/(width-1),v).combined,j=(row*width+col)*4,shade=Math.round(255-240*(1-flux)/.65);image.data[j]=shade;image.data[j+1]=shade;image.data[j+2]=shade;image.data[j+3]=255;}}
  context.putImageData(image,0,0);trailPlot.svg.select('.grid').remove();marker(trailPlot,wavelength(0),'#8b989f','2 4','');
  trailPlot.cursor=trailPlot.svg.append('line').attr('class','cursor').attr('x1',44).attr('x2',trailPlot.width-14);scrub(trailPlot,'trail-axis',true);
}
let renderer,camera,orbitControls,scene,orbitGroup,star1,star2,arrow1,arrow2,arc,pole;
const vector=a=>new THREE.Vector3(...a);
function label(text,color){const canvas=document.createElement('canvas');canvas.width=512;canvas.height=96;const ctx=canvas.getContext('2d');ctx.fillStyle=color;ctx.font='44px Arial';ctx.textAlign='center';ctx.fillText(text,256,62);const sprite=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(canvas),transparent:true,depthTest:false}));sprite.scale.set(1.2,.3,1);return sprite;}
function resetCamera(mode='reset'){
  if(!camera)return;const i=p.i*DEG;orbitControls.target.set(0,0,.22);
  if(mode==='earth')camera.position.set(0,0,4.2);else if(mode==='top')camera.position.set(0,-4.2*Math.sin(i),4.2*Math.cos(i)+.22);else camera.position.set(1.7,-1.5,2.5);
  if(mode==='top'&&p.i===90)camera.up.set(0,0,1);else camera.up.set(0,1,0);orbitControls.update();fitScene();
}
function fitScene(){if(!renderer)return;const width=$('scene').clientWidth,height=$('scene').clientHeight;renderer.setSize(width,height,false);camera.aspect=width/height;camera.zoom=Math.min(1,camera.aspect/1.55);camera.updateProjectionMatrix();}
function initScene(){
  try{
    renderer=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});renderer.setPixelRatio(Math.min(devicePixelRatio,2));$('scene').append(renderer.domElement);renderer.domElement.setAttribute('aria-label','Three-dimensional binary orbit with Earth direction');
    scene=new THREE.Scene();scene.background=new THREE.Color('#101719');camera=new THREE.PerspectiveCamera(42,1,.01,100);orbitControls=new OrbitControls(camera,renderer.domElement);orbitControls.enableDamping=true;orbitControls.enablePan=false;orbitControls.minDistance=2;orbitControls.maxDistance=8;
    scene.add(new THREE.AmbientLight(0xffffff,2));const light=new THREE.DirectionalLight(0xffffff,3);light.position.set(2,2,3);scene.add(light);
    const plane=new THREE.Mesh(new THREE.PlaneGeometry(2.8,2.8),new THREE.MeshBasicMaterial({color:'#50716e',transparent:true,opacity:.1,side:THREE.DoubleSide,depthWrite:false}));scene.add(plane);
    scene.add(new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(),1.4,0x40cba0,.13,.08));const earthLabel=label('Earth (+Z)','#66dcb4');earthLabel.position.set(.35,0,1.2);scene.add(earthLabel);
    const skyLabel=label('sky X–Y','#91acae');skyLabel.position.set(.9,-.9,0);scene.add(skyLabel);
    const center=new THREE.Mesh(new THREE.SphereGeometry(.025,12,12),new THREE.MeshBasicMaterial({color:0xffffff}));scene.add(center);
    orbitGroup=new THREE.Group();scene.add(orbitGroup);
    star1=new THREE.Mesh(new THREE.SphereGeometry(.085,32,24),new THREE.MeshStandardMaterial({color:colors[0],emissive:colors[0],emissiveIntensity:.4,roughness:.8}));star2=new THREE.Mesh(new THREE.SphereGeometry(.065,32,24),new THREE.MeshStandardMaterial({color:colors[1],emissive:colors[1],emissiveIntensity:.4,roughness:.8}));scene.add(star1,star2);
    arrow1=new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(),.35,0xe2ad40,.07,.04);arrow2=new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(),.35,0x21b5d1,.07,.04);scene.add(arrow1,arrow2);resetCamera();
  }catch{renderer?.dispose();renderer=null;$('scene').querySelector('canvas')?.remove();$('webgl-fallback').hidden=false;for(const id of ['camera-reset','camera-earth','camera-top'])$(id).disabled=true;}
}
function rebuildOrbit(){
  if(!renderer)return;for(const child of [...orbitGroup.children]){orbitGroup.remove(child);child.traverse(part=>{part.geometry?.dispose();part.material?.dispose();});}
  for(let component=0;component<2;component++){const points=[];for(let n=0;n<=512;n++)points.push(vector(atAnomaly(p,TAU*n/512)[component?'r2':'r1']));orbitGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineBasicMaterial({color:colors[component],transparent:true,opacity:.65})));}
  const angle=p.i*DEG,points=[];for(let n=0;n<=64;n++){const t=angle*n/64;points.push(new THREE.Vector3(0,-.55*Math.sin(t),.55*Math.cos(t)));}
  arc=new THREE.Line(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineBasicMaterial({color:0xa5bdc9}));orbitGroup.add(arc);
  pole=new THREE.ArrowHelper(new THREE.Vector3(0,-Math.sin(angle),Math.cos(angle)),new THREE.Vector3(),.8,0xa5bdc9,.08,.05);orbitGroup.add(pole);
}
function masses(){
  const el=elements(p),hyp=+$('hyp-i').value,assumed=+$('assumed-m1').value;let result;
  $('hyp-i-value').textContent=fmt(hyp,1)+'°';$('inferred1-label').innerHTML=p.sb2?'Inferred M<sub>1</sub>':'Assumed M<sub>1</sub>';
  try{result=infer(p,hyp,assumed);}catch{$('inferred1').textContent=$('inferred2').textContent=$('minimum').textContent='Invalid assumed mass';return;}
  const mass=v=>v===null?'Not constrained':fmt(v,3)+' M☉';$('inferred1').textContent=mass(result.m1);$('inferred2').textContent=mass(result.m2);$('minimum').textContent=mass(result.minimum);
  $('measured-q').textContent=result.q===null?'Not constrained':fmt(result.q,3);
  $('k1').textContent=fmt(el.k1,2)+' km/s';$('k2').textContent=p.sb2?fmt(el.k2,2)+' km/s':'Not observed';$('mass-function').textContent=fmt(el.f,4)+' M☉';
  $('m1sin').textContent=p.sb2&&el.signal?mass(el.m1sin):'Not constrained';$('m2sin').textContent=p.sb2&&el.signal?mass(el.m2sin):'Not constrained';
  $('mode-summary').textContent=p.sb2?'Two visible sets of lines':'Only star 1 has absorption lines';
  $('constraint-state').textContent=!el.signal?'Face-on: no orbital velocity modulation. Masses and mass ratio are not constrained by these spectra.':p.sb2?'Two amplitudes give q = K₁/K₂ and minimum masses; a separate inclination is needed for true masses.':'A single amplitude gives a mass function. Companion mass requires both an assumed primary mass and an inclination.';
  $('equation').innerHTML=p.sb2?'q = K<sub>1</sub> / K<sub>2</sub> &nbsp;&middot;&nbsp; M<sub>1</sub> sin&sup3; i = P (K<sub>1</sub> + K<sub>2</sub>)&sup2; K<sub>2</sub> (1 &minus; e&sup2;)<sup>3/2</sup> / (2&pi;G)':'f(M) = P K<sub>1</sub>&sup3; (1 &minus; e&sup2;)<sup>3/2</sup> / (2&pi;G) = M<sub>2</sub>&sup3; sin&sup3; i / (M<sub>1</sub> + M<sub>2</sub>)&sup2;';
}
function updatePhase(){
  const v=state(p);$('phase').value=p.phase;$('phase-value').textContent=fmt(p.phase,3);$('rv1').textContent='Star 1: '+fmt(v.rv1,1)+' km/s';$('rv2').textContent='Star 2: '+fmt(v.rv2,1)+' km/s';
  if(rvPlot){rvPlot.cursor.attr('x1',rvPlot.x(p.phase)).attr('x2',rvPlot.x(p.phase));rvPlot.dots.forEach((dot,n)=>dot.attr('cx',rvPlot.x(p.phase)).attr('cy',rvPlot.y(n?v.rv2:v.rv1)));}
  if(view==='profile'&&profilePlot){const domain=velocityDomain(p),data=Array.from({length:513},(_,n)=>{const velocity=domain[0]+(domain[1]-domain[0])*n/512;return {lambda:wavelength(velocity),...spectrum(p,velocity,v)};});['combined','component1','component2'].forEach((key,n)=>profilePlot.paths[n].attr('d',d3.line().x(d=>profilePlot.x(d.lambda)).y(d=>profilePlot.y(d[key]))(data)));}
  if(view==='trail'&&trailPlot)trailPlot.cursor.attr('y1',trailPlot.y(p.phase)).attr('y2',trailPlot.y(p.phase));
  if(renderer){star1.position.copy(vector(v.r1));star2.position.copy(vector(v.r2));const scale=.45/(v.n*v.a/Math.sqrt(1-p.e*p.e));for(const [arrow,position,velocity] of [[arrow1,v.r1,v.v1],[arrow2,v.r2,v.v2]]){const vel=vector(velocity);arrow.position.copy(vector(position));arrow.setDirection(vel.clone().normalize());arrow.setLength(vel.length()*scale,.07,.04);}}
}
function rebuild(){
  syncControls();curve=rvCurve(p);const el=elements(p);$('true-m2').textContent=fmt(el.m2,2)+' M☉';$('true-a').textContent=fmt(el.a/AU,3)+' AU';
  $('resolution-note').textContent='Instrument FWHM '+fmt(C/p.resolution,1)+' km/s; convolved line '+fmt(lineShape(p).fwhm,1)+' km/s.';
  drawRV();drawProfile();drawTrail();rebuildOrbit();masses();updatePhase();
}
function pause(){playing=false;$('play').innerHTML='<i data-lucide="play"></i>';$('play').setAttribute('aria-label','Play orbit');$('play').title='Play orbit';createIcons({icons});}
for(const k of keys)$(k).addEventListener('input',()=>{p[k]=+$(k).value;$('preset').value='custom';rebuild();});
for(const mode of ['sb1','sb2'])$(mode).onclick=()=>{p.sb2=mode==='sb2';$('preset').value='custom';rebuild();};
$('preset').onchange=()=>{Object.assign(p,PRESETS[$('preset').value]);pause();rebuild();};
$('phase').oninput=()=>{p.phase=+$('phase').value;pause();updatePhase();};
$('play').onclick=()=>{if(playing)pause();else{playing=true;$('play').innerHTML='<i data-lucide="pause"></i>';$('play').title='Pause orbit';$('play').setAttribute('aria-label','Pause orbit');createIcons({icons});}};
for(const id of ['hyp-i','assumed-m1'])$(id).addEventListener('input',masses);
for(const mode of ['reset','earth','top'])$('camera-'+mode).onclick=()=>resetCamera(mode);
function setView(next){view=next;for(const name of ['profile','trail']){$(name+'-panel').hidden=name!==view;$(name+'-tab').setAttribute('aria-selected',String(name===view));$(name+'-tab').tabIndex=name===view?0:-1;}if(view==='trail')drawTrail();else drawProfile();updatePhase();}
for(const name of ['profile','trail']){$(name+'-tab').onclick=()=>setView(name);$(name+'-tab').onkeydown=e=>{if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){e.preventDefault();setView(e.key==='Home'?'profile':e.key==='End'?'trail':view==='profile'?'trail':'profile');$(view+'-tab').focus();}};}
$('export').onclick=()=>{const url=URL.createObjectURL(new Blob([csv(p)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='spectroscopic-binary-rv.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
initScene();rebuild();createIcons({icons});
let resizeTimer;new ResizeObserver(()=>{clearTimeout(resizeTimer);resizeTimer=setTimeout(()=>{fitScene();drawRV();drawProfile();drawTrail();updatePhase();},50);}).observe(document.querySelector('.workspace'));
let previous=performance.now();function animate(now){const dt=Math.min(.1,(now-previous)/1000);previous=now;if(playing){p.phase=wrap(p.phase+dt*+$('speed').value);updatePhase();}if(renderer){orbitControls.update();renderer.render(scene,camera);}requestAnimationFrame(animate);}requestAnimationFrame(animate);
