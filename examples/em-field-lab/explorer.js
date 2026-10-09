import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import * as d3 from 'd3';
import {createIcons,Play,Pause,SkipBack,RotateCcw,Scan,Eye,Download,ArrowUpRight} from 'lucide';
import {DEFAULT,PRESETS,DEG,scales,sampler,probes,moveProbe,snapshot,history,quantity,dot,csv,validate} from './model.js';
const $=id=>document.getElementById(id),icons={Play,Pause,SkipBack,RotateCcw,Scan,Eye,Download,ArrowUpRight};
const p={...DEFAULT},keys=['amplitude','phase','theta','phi','beta','x','y','z','spacing','slice'];
let playing=false,mode='vector',field=sampler(p),shot,trace,series=[],planeDirty=true,sceneDirty=true;
const fmt=(x,n=2)=>Math.abs(x)<.5*10**-n?(0).toFixed(n):x.toFixed(n),vec=(a,n=2)=>'('+a.map(v=>fmt(v,n)).join(', ')+')';
function sync(){
  for(const k of keys){$(k).value=p[k];$(k+'-value').textContent=fmt(p[k],['phase','theta','phi','beta'].includes(k)?0:k==='amplitude'?1:2)+(['phase','theta','phi','beta'].includes(k)?'\u00b0':k==='amplitude'?' V/m':'');}
  $('frequency').value=p.frequency;$('frequency-log').value=Math.log10(p.frequency);$('n-vector').textContent=vec(field.n,3);$('e-vector').textContent=vec(field.e,3);
  const s=scales(p);$('frequency-readout').textContent=fmt(p.frequency,2)+' MHz';$('wavelength-readout').textContent=fmt(s.lambda,s.lambda<1?4:3)+' m';$('period-readout').textContent=fmt(s.period*1e9,3)+' ns';
  $('slice-note').textContent=Math.abs(Math.sin(p.theta*DEG))<1e-8?'This X-Y slice is perpendicular to propagation: its value is spatially uniform.':'Contours connect equal scalar values in the selected X-Y slice.';
}
function axes(id,xDomain,yDomain,xLabel){
  const svg=d3.select($(id)),width=$(id).clientWidth,height=$(id).clientHeight;if(width<100)return null;svg.selectAll('*').remove();svg.attr('viewBox',`0 0 ${width} ${height}`);
  const margin={left:38,right:12,top:12,bottom:38},x=d3.scaleLinear().domain(xDomain).range([38,width-12]),y=d3.scaleLinear().domain(yDomain).range([height-38,12]);
  svg.append('g').attr('class','grid').attr('transform','translate(38,0)').call(d3.axisLeft(y).ticks(4).tickSize(-(width-50)).tickFormat(''));
  svg.append('g').attr('class','axis').attr('transform',`translate(0,${height-38})`).call(d3.axisBottom(x).ticks(width<350?4:6));svg.append('g').attr('class','axis').attr('transform','translate(38,0)').call(d3.axisLeft(y).ticks(4));
  svg.append('text').attr('class','axis-label').attr('x',(width+26)/2).attr('y',height-5).attr('text-anchor','middle').text(xLabel);svg.append('text').attr('class','axis-label').attr('transform',`translate(11,${(height-38)/2}) rotate(-90)`).attr('text-anchor','middle').text('V/m');
  return {svg,x,y,width,height,margin};
}
function line(plot,data,x,y,color,klass){return plot.svg.append('path').attr('class',klass).attr('fill','none').attr('stroke',color).attr('stroke-width',1.8).attr('d',d3.line().x(v=>plot.x(x(v))).y(v=>plot.y(y(v)))(data));}
function drawPlots(){
  shot=axes('snapshot',[-2,2],[-10.5,10.5],'Position along n / \u03bb');if(shot){shot.path=line(shot,[],d=>d.s,d=>d.psi,'#a06f19','snapshot-path');shot.markers=['#148462','#be4c58'].map(color=>shot.svg.append('circle').attr('r',4).attr('fill',color));}
  series=history(p,$('quantity').value);trace=axes('history',[0,2],$('quantity').value==='magnitude'?[0,10.5]:[-10.5,10.5],'Time t / T');if(trace){line(trace,series,d=>d.time,d=>d.a,'#148462','history-a');line(trace,series,d=>d.time,d=>d.b,'#be4c58','history-b');trace.cursor=trace.svg.append('line').attr('class','cursor').attr('y1',12).attr('y2',trace.height-38);trace.dots=['#148462','#be4c58'].map(color=>trace.svg.append('circle').attr('r',4).attr('fill',color));}
  $('quantity-note').textContent=$('quantity').value==='magnitude'?'Magnitude: always nonnegative':'Signed component or coefficient';
  if(trace){const node=$('history');const select=e=>{const [x]=d3.pointer(e,node);p.time=Math.max(0,Math.min(2,trace.x.invert(x)));pause();update();};node.onpointerdown=e=>{node.setPointerCapture(e.pointerId);select(e);};node.onpointermove=e=>{if(node.hasPointerCapture(e.pointerId))select(e);};node.onkeydown=e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;e.preventDefault();pause();p.time=e.key==='Home'?0:e.key==='End'?2:Math.max(0,Math.min(2,p.time+(e.key==='ArrowLeft'?-.01:.01)));update();};}
  if(shot){const node=$('snapshot'),move=s=>{[p.x,p.y,p.z]=moveProbe(p,s);$('preset').value='custom';rebuild();},select=e=>move(shot.x.invert(d3.pointer(e,node)[0]));node.onpointerdown=e=>{node.setPointerCapture(e.pointerId);select(e);};node.onpointermove=e=>{if(node.hasPointerCapture(e.pointerId))select(e);};node.onkeydown=e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;e.preventDefault();move(e.key==='Home'?-2:e.key==='End'?2:dot(field.n,[p.x,p.y,p.z])+(e.key==='ArrowLeft'?-.01:.01));};}
}
let renderer,scene,camera,controls,rods,heads,scalarPoints,plane,texture,contourLines,crestGroup,propagation,propLabel,probeA,probeB,labelA,labelB;
const locations=[];for(let x=-1;x<=1.001;x+=.5)for(let y=-1;y<=1.001;y+=.5)for(let j=0;j<=6;j++)locations.push([x,y,-1+j/3]);
const object=new THREE.Object3D(),direction=new THREE.Vector3(),up=new THREE.Vector3(0,1,0),color=new THREE.Color();
const ramp=d3.scaleLinear().domain([-10,0,10]).range(['#0990b6','#eff5f3','#eda93f']);
const palette=Array.from({length:201},(_,j)=>d3.rgb(ramp((j-100)/10)));
function sprite(text,fill){const canvas=document.createElement('canvas');canvas.width=64;canvas.height=64;const ctx=canvas.getContext('2d');ctx.fillStyle=fill;ctx.font='36px Arial';ctx.textAlign='center';ctx.fillText(text,32,45);const result=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(canvas),transparent:true,depthTest:false}));result.scale.set(.32,.32,1);return result;}
function fit(){if(!renderer)return;const width=$('scene').clientWidth,height=$('scene').clientHeight;renderer.setSize(width,height,false);camera.aspect=width/height;camera.zoom=1.15*Math.min(1,camera.aspect/1.1);camera.updateProjectionMatrix();sceneDirty=true;}
function cameraView(view='reset'){
  if(!renderer)return;controls.target.set(0,0,0);camera.up.set(0,1,0);
  if(view==='xy')camera.position.set(0,0,6.8);else if(view==='wave'){camera.position.copy(new THREE.Vector3(...field.n).multiplyScalar(6.8));camera.up.copy(new THREE.Vector3(...field.e));}else camera.position.set(4,2.8,4.5);
  controls.update();fit();
}
function initScene(){
  try{
    renderer=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});renderer.setPixelRatio(Math.min(devicePixelRatio,2));$('scene').append(renderer.domElement);renderer.domElement.setAttribute('aria-label','Three-dimensional field sampled at fixed locations');scene=new THREE.Scene();scene.background=new THREE.Color('#11191c');camera=new THREE.PerspectiveCamera(42,1,.01,100);controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=true;controls.enablePan=false;controls.minDistance=4;controls.maxDistance=12;
    const box=new THREE.EdgesGeometry(new THREE.BoxGeometry(2.4,2.4,2.4));scene.add(new THREE.LineSegments(box,new THREE.LineBasicMaterial({color:0x42585c,transparent:true,opacity:.6})));
    const bases=new THREE.BufferGeometry().setFromPoints(locations.map(r=>new THREE.Vector3(...r)));scene.add(new THREE.Points(bases,new THREE.PointsMaterial({color:0x779392,size:.024})));
    rods=new THREE.InstancedMesh(new THREE.CylinderGeometry(.01,.01,1,6),new THREE.MeshBasicMaterial(),locations.length);heads=new THREE.InstancedMesh(new THREE.ConeGeometry(.04,1,8),new THREE.MeshBasicMaterial(),locations.length);scalarPoints=new THREE.InstancedMesh(new THREE.SphereGeometry(.04,10,8),new THREE.MeshBasicMaterial(),locations.length);for(const mesh of [rods,heads,scalarPoints]){mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);mesh.frustumCulled=false;scene.add(mesh);}scalarPoints.visible=false;
    const canvas=document.createElement('canvas');canvas.width=64;canvas.height=64;texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;plane=new THREE.Mesh(new THREE.PlaneGeometry(2.2,2.2),new THREE.MeshBasicMaterial({map:texture,side:THREE.DoubleSide,transparent:true,opacity:.82,depthWrite:false}));plane.visible=false;scene.add(plane);contourLines=new THREE.Group();contourLines.visible=false;scene.add(contourLines);
    for(let axis=0;axis<3;axis++){const dir=new THREE.Vector3();dir.setComponent(axis,1);scene.add(new THREE.ArrowHelper(dir,new THREE.Vector3(-1.3,-1.3,-1.3),.65,[0xdb6b68,0x75c693,0x7ab9d1][axis],.065,.035));const label=sprite(['x','y','z'][axis],['#db6b68','#75c693','#7ab9d1'][axis]);label.position.set(-1.3,-1.3,-1.3);label.position.addScaledVector(dir,.82);scene.add(label);}
    propagation=new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(),2.4,0xd2e6da,.12,.055);propLabel=sprite('n','#d2e6da');scene.add(propagation,propLabel);
    crestGroup=new THREE.Group();for(let j=0;j<5;j++){const sheet=new THREE.Mesh(new THREE.PlaneGeometry(2.6,2.6),new THREE.MeshBasicMaterial({color:0x87b2a0,transparent:true,opacity:.045,side:THREE.DoubleSide,depthWrite:false}));crestGroup.add(sheet);}scene.add(crestGroup);
    probeA=new THREE.Mesh(new THREE.SphereGeometry(.065,20,16),new THREE.MeshBasicMaterial({color:0x2bd49c,depthTest:false}));probeB=new THREE.Mesh(new THREE.SphereGeometry(.065,20,16),new THREE.MeshBasicMaterial({color:0xff6c7a,depthTest:false}));probeA.renderOrder=10;probeB.renderOrder=10;labelA=sprite('A','#6befb9');labelB=sprite('B','#ff929c');scene.add(probeA,probeB,labelA,labelB);cameraView();
  }catch{renderer?.dispose();renderer=null;$('scene').querySelector('canvas')?.remove();$('webgl-fallback').hidden=false;for(const id of ['camera-reset','camera-xy','camera-wave'])$(id).disabled=true;}
}
function drawScalarPlane(){
  if(!renderer||mode!=='scalar')return;const canvas=texture.image,ctx=canvas.getContext('2d'),image=ctx.createImageData(64,64),values=[];
  for(let y=0;y<64;y++)for(let x=0;x<64;x++){const value=field.at([-1.1+2.2*x/63,1.1-2.2*y/63,p.slice],p.time).psi;values.push(value);const col=palette[Math.max(0,Math.min(200,Math.round(100+10*value)))],j=4*(y*64+x);image.data[j]=col.r;image.data[j+1]=col.g;image.data[j+2]=col.b;image.data[j+3]=255;}
  ctx.putImageData(image,0,0);texture.needsUpdate=true;plane.position.z=p.slice;
  for(const child of [...contourLines.children]){contourLines.remove(child);child.geometry.dispose();child.material.dispose();}
  // Discard the contour generator's domain boundary: it is not an isoline.
  const points=[],interior=v=>v[0]>.5&&v[0]<63.5&&v[1]>.5&&v[1]<63.5;
  for(const contour of d3.contours().size([64,64]).thresholds([-8,-4,0,4,8])(values))for(const polygon of contour.coordinates)for(const ring of polygon)for(let j=1;j<ring.length;j++){if(!interior(ring[j-1])||!interior(ring[j]))continue;for(const vertex of [ring[j-1],ring[j]])points.push(-1.1+2.2*(vertex[0]-.5)/63,1.1-2.2*(vertex[1]-.5)/63,p.slice+.004);}
  if(points.length){const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(points,3));contourLines.add(new THREE.LineSegments(geometry,new THREE.LineBasicMaterial({color:0x344e57,transparent:true,opacity:.5})));}
  planeDirty=false;
}
function updateGlyphs(){
  if(!renderer)return;
  sceneDirty=true;
  const points=probes(p);probeA.position.set(...points.a);probeB.position.set(...points.b);labelA.position.copy(probeA.position).add(new THREE.Vector3(.09,.15,0));labelB.position.copy(probeB.position).add(new THREE.Vector3(.09,-.15,0));
  for(let j=0;j<locations.length;j++){
    const r=locations[j],value=field.at(r,p.time).psi,length=.04*Math.abs(value),head=Math.min(.09,length*.35);color.set(value<0?'#16b4d8':'#ebb247');direction.set(...field.e).multiplyScalar(value<0?-1:1);object.quaternion.setFromUnitVectors(up,direction);
    object.position.set(...r).addScaledVector(direction,(length-head)/2);object.scale.set(length<1e-9?0:1,Math.max(0,length-head),length<1e-9?0:1);object.updateMatrix();rods.setMatrixAt(j,object.matrix);rods.setColorAt(j,color);
    object.position.set(...r).addScaledVector(direction,length-head/2);object.scale.set(head/.09,head,head/.09);object.updateMatrix();heads.setMatrixAt(j,object.matrix);heads.setColorAt(j,color);
    const col=palette[Math.max(0,Math.min(200,Math.round(100+10*value)))];color.setRGB(col.r/255,col.g/255,col.b/255,THREE.SRGBColorSpace);object.position.set(...r);object.quaternion.identity();object.scale.set(1,1,1);object.updateMatrix();scalarPoints.setMatrixAt(j,object.matrix);scalarPoints.setColorAt(j,color);
  }
  for(const mesh of [rods,heads,scalarPoints]){mesh.instanceMatrix.needsUpdate=true;mesh.instanceColor.needsUpdate=true;}
  const n=new THREE.Vector3(...field.n),e=new THREE.Vector3(...field.e),side=new THREE.Vector3().crossVectors(n,e);propagation.setDirection(n);propagation.position.copy(n).multiplyScalar(-1.2).addScaledVector(side,-1.35);propLabel.position.copy(propagation.position).addScaledVector(n,2.5).addScaledVector(e,.12);
  crestGroup.visible=$('crests').checked&&p.amplitude>0;const offset=((p.time-p.phase/360)%1+1)%1;for(let j=0;j<5;j++){const s=offset+j-2,mesh=crestGroup.children[j];mesh.visible=Math.abs(s)<1.35;mesh.position.copy(n).multiplyScalar(s);mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),n);}
  if(planeDirty)drawScalarPlane();
}
function update(){
  $('time').value=p.time;$('time-value').textContent=fmt(p.time,3);const s=scales(p),positions=probes(p),a=field.at(positions.a,p.time),b=field.at(positions.b,p.time);$('physical-time').textContent=fmt(p.time*s.period*1e9,3)+' ns';
  for(const [name,r,v] of [['a',positions.a,a],['b',positions.b,b]]){$(name+'-position').textContent=vec(r,3);$(name+'-metres').textContent=vec(r.map(x=>x*s.lambda),4);$(name+'-psi').textContent=fmt(v.psi,3);$(name+'-vector').textContent=vec(v.E,3);$(name+'-magnitude').textContent=fmt(v.magnitude,3);}
  $('delay-readout').textContent='B is '+fmt(p.spacing,2)+'\u03bb downstream: geometric delay '+fmt(p.spacing*s.period*1e9,3)+' ns ('+fmt(p.spacing,2)+'T), phase lag '+fmt((360*p.spacing)%360,1)+'\u00b0 modulo 360\u00b0.';
  if(shot){shot.path.attr('d',d3.line().x(v=>shot.x(v.s)).y(v=>shot.y(v.psi))(snapshot(p)));shot.markers.forEach((mark,j)=>mark.attr('cx',shot.x(dot(field.n,j?positions.b:positions.a))).attr('cy',shot.y(j?b.psi:a.psi)));}
  if(trace){trace.cursor.attr('x1',trace.x(p.time)).attr('x2',trace.x(p.time));trace.dots.forEach((mark,j)=>mark.attr('cx',trace.x(p.time)).attr('cy',trace.y(quantity(j?b:a,$('quantity').value))));}
  planeDirty=true;updateGlyphs();
}
function rebuild(){validate(p);field=sampler(p);sync();drawPlots();update();}
function pause(){playing=false;$('play').innerHTML='<i data-lucide="play"></i>';$('play').title='Play field';$('play').setAttribute('aria-label','Play field');createIcons({icons});}
function setMode(next){mode=next;sceneDirty=true;for(const name of ['scalar','vector']){$(name+'-tab').setAttribute('aria-selected',String(name===mode));$(name+'-tab').tabIndex=name===mode?0:-1;}$('scene').setAttribute('aria-labelledby',mode+'-tab');$('scene-title').textContent=mode==='vector'?'E(r, t): vectors at fixed positions':'\u03c8(r, t): signed scalar values';$('slice-control').hidden=$('slice-note').hidden=mode!=='scalar';if(renderer){rods.visible=heads.visible=mode==='vector';scalarPoints.visible=plane.visible=contourLines.visible=mode==='scalar';}drawScalarPlane();}
for(const k of keys)$(k).addEventListener('input',()=>{p[k]=+$(k).value;$('preset').value='custom';rebuild();});
$('frequency-log').oninput=()=>{p.frequency=Math.min(2000,Math.max(10,10**+$('frequency-log').value));$('preset').value='custom';$('input-error').hidden=true;rebuild();};
$('frequency').oninput=()=>{const value=+$('frequency').value;if(!Number.isFinite(value)||value<10||value>2000){$('input-error').hidden=false;$('input-error').textContent='Frequency must be between 10 and 2000 MHz.';return;}p.frequency=value;$('preset').value='custom';$('input-error').hidden=true;rebuild();};
$('preset').onchange=()=>{Object.assign(p,PRESETS[$('preset').value]);pause();$('input-error').hidden=true;rebuild();};
$('time').oninput=()=>{p.time=+$('time').value;pause();update();};$('reset-time').onclick=()=>{p.time=0;pause();update();};
$('play').onclick=()=>{if(playing)pause();else{playing=true;$('play').innerHTML='<i data-lucide="pause"></i>';$('play').title='Pause field';$('play').setAttribute('aria-label','Pause field');createIcons({icons});}};
$('quantity').onchange=()=>{drawPlots();update();};$('crests').onchange=updateGlyphs;
for(const name of ['scalar','vector']){$(name+'-tab').onclick=()=>setMode(name);$(name+'-tab').onkeydown=e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;e.preventDefault();setMode(e.key==='Home'?'scalar':e.key==='End'?'vector':mode==='scalar'?'vector':'scalar');$(mode+'-tab').focus();};}
for(const view of ['reset','xy','wave'])$('camera-'+view).onclick=()=>cameraView(view);
$('export').onclick=()=>{const url=URL.createObjectURL(new Blob([csv(p)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='em-field-probe-histories.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
initScene();rebuild();createIcons({icons});let timer;new ResizeObserver(()=>{clearTimeout(timer);timer=setTimeout(()=>{fit();drawPlots();update();},50);}).observe(document.querySelector('.workspace'));
let last=performance.now(),lastUpdate=last;function animate(now){const dt=Math.min(.1,(now-last)/1000);last=now;if(playing&&!document.hidden){p.time=(p.time+dt*+$('speed').value)%2;if(now-lastUpdate>33){update();lastUpdate=now;}}if(renderer&&!document.hidden){const changed=controls.update();if(changed||sceneDirty){renderer.render(scene,camera);sceneDirty=false;}}requestAnimationFrame(animate);}requestAnimationFrame(animate);
