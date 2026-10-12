import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {contours,geoPath,geoTransform,scaleLinear,extent,line,format,interpolateRgbBasis,rgb} from 'd3';
import {createIcons,Play,Pause,RotateCcw,RotateCw,StepForward,Scan,Download,ArrowUpRight} from 'lucide';
import {DOMAIN,FIELDS,DEFAULTS,parameters,sample,grid,section,gradientStep,csv} from './model.js';

const $=id=>document.getElementById(id),palette=interpolateRgbBasis(['#2768a3','#3baa9d','#f0d876','#d87954']);
const controls=[['a','Amplitude \u03b1',.25,2,.05],['b','Shape \u03b2',.25,2,.05],['x','Probe x',-DOMAIN,DOMAIN,.01],['y','Probe y',-DOMAIN,DOMAIN,.01],['angle','Direction (\u00b0)',-180,180,1]];
let p={...DEFAULTS},samples=[],limits=[0,1],levelLines=[],raster,trail=[],view,mapScales,running=false,sign=-1,lastStep=0,timer,fieldDirty=false;
const num=(n,d=3)=>Math.abs(n)<1e-10?'0':Math.abs(n)<.001?n.toExponential(2):n.toFixed(d);
function icons(){createIcons({icons:{Play,Pause,RotateCcw,RotateCw,StepForward,Scan,Download,ArrowUpRight}});}
function run(value){running=value;const label=value?'Pause gradient steps':'Run gradient steps';$('play').innerHTML=`<i data-lucide="${value?'pause':'play'}"></i>`;$('play').title=label;$('play').setAttribute('aria-label',label);icons();}
function sync(){for(const [key] of controls){$(key).value=p[key];$(key+'-number').value=Number(p[key].toFixed(4));$(key+'-number').removeAttribute('aria-invalid');}}
for(const [key,label,min,max,step] of controls){const div=document.createElement('div');div.className='field';div.innerHTML=`<div class="field-head"><label for="${key}-number">${label}</label><input id="${key}-number" type="number" min="${min}" max="${max}" step="${step}"></div><input id="${key}" aria-label="${label}" type="range" min="${min}" max="${max}" step="${step}">`;$('fields').append(div);
  for(const id of [key,key+'-number'])$(id).addEventListener('input',()=>{run(false);const value=Number($(id).value);if($(id).value.trim()===''||!Number.isFinite(value)||value<min||value>max){$(id).setAttribute('aria-invalid','true');$('error').textContent=`${label}: enter a value from ${min} to ${max}.`;$('error').hidden=false;return;}p[key]=value;$(key).value=value;$(key+'-number').value=value;if(['a','b'].includes(key))fieldDirty=true;clearTimeout(timer);timer=setTimeout(()=>{if(fieldDirty)rebuild();else{if(key!=='angle'){trail=[sample(p)];$('status').textContent='Ready';}display();}},40);});
}
$('field').addEventListener('change',()=>{p.field=$('field').value;rebuild();});
function wrapAngle(angle){return (angle+540)%360-180;}
$('align').addEventListener('click',()=>{const r=sample(p);p.angle=wrapAngle(Math.atan2(r.fy,r.fx)*180/Math.PI);display();});
$('tangent').addEventListener('click',()=>{const r=sample(p);p.angle=wrapAngle(Math.atan2(r.fy,r.fx)*180/Math.PI+90);display();});
$('vectors').addEventListener('change',drawMap);$('plane').addEventListener('change',()=>view?.update(sample(p),section(p)));
document.querySelectorAll('[data-sign]').forEach(b=>b.addEventListener('click',()=>{run(false);sign=Number(b.dataset.sign);document.querySelectorAll('[data-sign]').forEach(t=>t.setAttribute('aria-pressed',String(t===b)));$('status').textContent='Ready';}));
$('play').addEventListener('click',()=>{lastStep=0;run(!running);});$('step').addEventListener('click',()=>{run(false);advance();});
$('reset').addEventListener('click',()=>{run(false);p.x=DEFAULTS.x;p.y=DEFAULTS.y;trail=[sample(p)];$('status').textContent='Ready';display();});
$('camera').addEventListener('click',()=>view?.reset());
$('download').addEventListener('click',()=>{const blob=new Blob([csv(p,grid(p,65))],{type:'text/csv'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='gradient-field.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
function advance(){try{if(trail.length>=401){$('status').textContent='400-step limit';run(false);return;}const result=gradientStep(p,sign);if(result.reason){$('status').textContent=result.reason;run(false);return;}p.x=result.point.x;p.y=result.point.y;trail.push(result.point);$('status').textContent=sign===1?'Increasing f':'Decreasing f';display();}catch(error){showError(error);}}
function showError(error){run(false);$('error').textContent=error.message;$('error').hidden=false;}
function rebuild(){try{clearTimeout(timer);run(false);p=parameters(p);samples=grid(p,65);limits=extent(samples,r=>r.value);levelLines=contours().size([65,65]).thresholds(scaleLinear().domain(limits).ticks(12))(samples.map(r=>r.value));
  raster=document.createElement('canvas');raster.width=raster.height=65;const ctx=raster.getContext('2d'),image=ctx.createImageData(65,65);
  for(let j=0;j<65;j++)for(let i=0;i<65;i++){const r=samples[i+(64-j)*65],color=rgb(colorValue(r.value)),offset=(j*65+i)*4;image.data.set([color.r,color.g,color.b,40],offset);}ctx.putImageData(image,0,0);
  fieldDirty=false;trail=[sample(p)];$('formula').textContent=FIELDS[p.field].formula;$('status').textContent='Ready';view?.build();display();
}catch(error){showError(error);}}
function colorValue(value){return palette((value-limits[0])/(limits[1]-limits[0]||1));}
function display(){try{const r=sample(p),cut=section(p);sync();$('error').hidden=true;
  $('value').textContent=num(r.value);$('gradient').textContent=`(${num(r.fx)}, ${num(r.fy)})`;$('magnitude').textContent=num(r.magnitude);$('directional').textContent=num(r.directional);
  $('point-label').textContent=`p = (${num(p.x,2)}, ${num(p.y,2)})`;$('step-count').textContent=trail.length-1+' steps';
  const stationary=r.magnitude<1e-7;$('align').disabled=$('tangent').disabled=stationary;
  $('direction-state').textContent=stationary?'Stationary within tolerance':Math.abs(r.directional)<1e-7?'u tangent to the local level set':r.directional>0?'f increases along u':'f decreases along u';
  $('range').textContent=`Sampled f range: ${num(limits[0],2)} to ${num(limits[1],2)}`;
  drawMap();drawChart('section',cut,'t',['value','linear'],['#258a82','#b1851e'],{x:0,y:r.value},'t');
  const directional=Array.from({length:181},(_,i)=>{const angle=-180+2*i,theta=angle*Math.PI/180;return {angle,slope:r.fx*Math.cos(theta)+r.fy*Math.sin(theta)};});drawChart('direction-plot',directional,'angle',['slope'],['#d6524a'],{x:p.angle,y:r.directional},'\u00b0');
  view?.update(r,cut);
}catch(error){showError(error);}}
function setupCanvas(canvas){const dpr=Math.min(devicePixelRatio||1,2),w=canvas.clientWidth,h=canvas.clientHeight;canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);const ctx=canvas.getContext('2d');ctx.scale(dpr,dpr);return {ctx,w,h};}
function arrow(ctx,x,y,dx,dy,color,width=1.4){const len=Math.hypot(dx,dy);if(len<.1)return;const ux=dx/len,uy=dy/len,head=Math.min(7,len*.3);ctx.strokeStyle=ctx.fillStyle=color;ctx.lineWidth=width;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+dx,y+dy);ctx.stroke();ctx.beginPath();ctx.moveTo(x+dx,y+dy);ctx.lineTo(x+dx-head*ux+head*.5*uy,y+dy-head*uy-head*.5*ux);ctx.lineTo(x+dx-head*ux-head*.5*uy,y+dy-head*uy+head*.5*ux);ctx.closePath();ctx.fill();}
function drawMap(){if(!samples.length)return;const {ctx,w,h}=setupCanvas($('contours')),size=Math.min(w-55,h-36),left=(w-size)/2+9,top=10,X=scaleLinear().domain([-DOMAIN,DOMAIN]).range([left,left+size]),Y=scaleLinear().domain([-DOMAIN,DOMAIN]).range([top+size,top]);mapScales={X,Y};
  ctx.drawImage(raster,left,top,size,size);ctx.save();ctx.beginPath();ctx.rect(left,top,size,size);ctx.clip();
  const projection=geoTransform({point(x,y){this.stream.point(X(-DOMAIN+(x-.5)*5/64),Y(-DOMAIN+(y-.5)*5/64));}}),path=geoPath(projection,ctx);
  for(const level of levelLines){ctx.beginPath();path(level);ctx.strokeStyle=colorValue(level.value);ctx.lineWidth=1;ctx.stroke();}
  const r=sample(p);if(r.value>limits[0]+1e-7&&r.value<limits[1]-1e-7){ctx.beginPath();path(contours().size([65,65]).thresholds([r.value])(samples.map(t=>t.value))[0]);ctx.strokeStyle='#267f76';ctx.lineWidth=2;ctx.stroke();}
  if($('vectors').checked)for(let y=-2.25;y<=2.25;y+=.5)for(let x=-2.25;x<=2.25;x+=.5){const g=sample(p,x,y);if(g.magnitude>1e-7)arrow(ctx,X(x),Y(y),g.fx/g.magnitude*size*.036,-g.fy/g.magnitude*size*.036,'#70877a',.8);}
  const cut=section(p);ctx.strokeStyle='#b1851e';ctx.lineWidth=1;ctx.setLineDash([4,4]);ctx.beginPath();ctx.moveTo(X(cut[0].x),Y(cut[0].y));ctx.lineTo(X(cut.at(-1).x),Y(cut.at(-1).y));ctx.stroke();ctx.setLineDash([]);
  ctx.strokeStyle='#293c40';ctx.lineWidth=2;ctx.beginPath();line().x(t=>X(t.x)).y(t=>Y(t.y)).context(ctx)(trail);ctx.stroke();
  const len=Math.min(size*.16,48);if(r.magnitude>1e-7)arrow(ctx,X(p.x),Y(p.y),r.fx/r.magnitude*len,-r.fy/r.magnitude*len,'#d6524a',2.5);arrow(ctx,X(p.x),Y(p.y),r.ux*len,-r.uy*len,'#b1851e',2.3);
  ctx.beginPath();ctx.arc(X(p.x),Y(p.y),4.5,0,Math.PI*2);ctx.fillStyle='#293c40';ctx.fill();ctx.strokeStyle='white';ctx.lineWidth=1.5;ctx.stroke();ctx.restore();
  ctx.strokeStyle='#c1d3cc';ctx.lineWidth=1;ctx.strokeRect(left,top,size,size);ctx.font='10px system-ui';ctx.fillStyle='#718780';ctx.textAlign='center';ctx.textBaseline='middle';
  for(const x of [-2,-1,0,1,2])ctx.fillText(x,X(x),top+size+12);ctx.textAlign='right';for(const y of [-2,-1,0,1,2])ctx.fillText(y,left-7,Y(y));ctx.textAlign='left';ctx.fillText('x',left+size+6,top+size);ctx.fillText('y',left-13,top+5);
}
function setPoint(x,y){run(false);p.x=Math.max(-DOMAIN,Math.min(DOMAIN,x));p.y=Math.max(-DOMAIN,Math.min(DOMAIN,y));trail=[sample(p)];$('status').textContent='Ready';display();}
let mapDragging=false;$('contours').addEventListener('pointerdown',e=>{mapDragging=true;$('contours').setPointerCapture(e.pointerId);movePoint(e);});$('contours').addEventListener('pointermove',e=>{if(mapDragging)movePoint(e);});for(const type of ['pointerup','pointercancel','lostpointercapture'])$('contours').addEventListener(type,()=>{mapDragging=false;});
function movePoint(e){const rect=$('contours').getBoundingClientRect();if(mapScales)setPoint(mapScales.X.invert(e.clientX-rect.left),mapScales.Y.invert(e.clientY-rect.top));}
$('contours').addEventListener('keydown',e=>{const delta={ArrowLeft:[-.05,0],ArrowRight:[.05,0],ArrowUp:[0,.05],ArrowDown:[0,-.05]}[e.key];if(delta){e.preventDefault();setPoint(p.x+delta[0],p.y+delta[1]);}});
function expand(values){const [lo,hi]=extent(values),pad=Math.max((hi-lo)*.08,.04);return [lo-pad,hi+pad];}
function drawChart(id,rows,xKey,keys,colors,marker,unit){const {ctx,w,h}=setupCanvas($(id)),X=scaleLinear().domain(extent(rows,r=>r[xKey])).range([42,w-12]),Y=scaleLinear().domain(expand(rows.flatMap(r=>keys.map(k=>r[k])))).range([h-29,9]);ctx.font='10px system-ui';ctx.fillStyle='#758881';ctx.strokeStyle='#e4ece8';ctx.lineWidth=1;ctx.textBaseline='middle';ctx.textAlign='right';
  for(const y of Y.ticks(4)){ctx.beginPath();ctx.moveTo(42,Y(y));ctx.lineTo(w-12,Y(y));ctx.stroke();ctx.fillText(format('.2~g')(y),36,Y(y));}ctx.textAlign='center';for(const x of xKey==='angle'?[-180,-90,0,90,180]:X.ticks(Math.max(3,Math.floor(w/70))))ctx.fillText(format('.3~g')(x),X(x),h-12);ctx.textAlign='right';ctx.fillText(unit,w-1,h-12);
  ctx.save();ctx.beginPath();ctx.rect(42,9,Math.max(0,w-54),h-38);ctx.clip();for(let i=0;i<keys.length;i++){ctx.strokeStyle=colors[i];ctx.lineWidth=1.7;ctx.setLineDash(i===1?[4,3]:[]);ctx.beginPath();line().x(r=>X(r[xKey])).y(r=>Y(r[keys[i]])).context(ctx)(rows);ctx.stroke();}ctx.setLineDash([]);ctx.fillStyle='#293c40';ctx.beginPath();ctx.arc(X(marker.x),Y(marker.y),3.7,0,Math.PI*2);ctx.fill();ctx.restore();}
function makeScene(){const host=$('scene'),renderer=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});renderer.setPixelRatio(Math.min(devicePixelRatio||1,2));renderer.setClearColor('#eff5f4');host.prepend(renderer.domElement);renderer.domElement.setAttribute('role','img');renderer.domElement.setAttribute('aria-label','Scalar field surface, movable probe, tangent plane and directional section');
  const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(38,1,.1,100),orbit=new OrbitControls(camera,renderer.domElement);camera.position.set(6.2,5.5,7.6);orbit.target.set(0,0,0);orbit.enableDamping=true;orbit.enablePan=false;orbit.minDistance=8;orbit.maxDistance=18;orbit.maxPolarAngle=Math.PI*.49;orbit.update();orbit.saveState();
  scene.add(new THREE.HemisphereLight('#ffffff','#94b3aa',2.2));const light=new THREE.DirectionalLight('#ffffff',2.5);light.position.set(-3,7,5);scene.add(light);
  const floor=new THREE.Mesh(new THREE.PlaneGeometry(5.4,5.4),new THREE.MeshBasicMaterial({color:'#dce7e3',side:THREE.DoubleSide}));floor.rotation.x=-Math.PI/2;floor.position.y=-2.4;scene.add(floor);
  const gridLines=new THREE.GridHelper(5,10,'#8ca99e','#b8cec5');gridLines.position.y=-2.39;scene.add(gridLines);
  const point=new THREE.Mesh(new THREE.SphereGeometry(.08,18,12),new THREE.MeshStandardMaterial({color:'#253b40'}));scene.add(point);
  const surface=new THREE.Mesh(new THREE.BufferGeometry(),new THREE.MeshStandardMaterial({vertexColors:true,side:THREE.DoubleSide,roughness:.8}));scene.add(surface);
  const tangent=new THREE.Mesh(new THREE.BufferGeometry(),new THREE.MeshBasicMaterial({color:'#f1d78a',transparent:true,opacity:.38,side:THREE.DoubleSide,depthWrite:false}));scene.add(tangent);
  const ascent=new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(),.8,'#d6524a',.13,.09),direction=new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(),.8,'#b1851e',.13,.09);scene.add(ascent,direction);for(const arrow of [ascent,direction]){arrow.line.material.depthTest=false;arrow.cone.material.depthTest=false;arrow.line.renderOrder=12;arrow.cone.renderOrder=12;}
  const cutLine=new THREE.Line(new THREE.BufferGeometry(),new THREE.LineBasicMaterial({color:'#b1851e',depthTest:false})),pathLine=new THREE.Line(new THREE.BufferGeometry(),new THREE.LineBasicMaterial({color:'#263d3d',depthTest:false}));cutLine.renderOrder=9;pathLine.renderOrder=10;scene.add(cutLine,pathLine);
  function label(text,position){const canvas=document.createElement('canvas');canvas.width=canvas.height=64;const ctx=canvas.getContext('2d');ctx.fillStyle='#45685b';ctx.font='32px system-ui';ctx.textAlign='center';ctx.fillText(text,32,42);const sprite=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(canvas),depthTest:false}));sprite.position.copy(position);sprite.scale.set(.4,.4,.4);scene.add(sprite);}
  label('x',new THREE.Vector3(2.85,-2.3,0));label('y',new THREE.Vector3(0,-2.3,-2.85));
  let height=1;
  function replace(object,geometry){object.geometry.dispose();object.geometry=geometry;}
  function build(){height=1/Math.max(.25,Math.abs(limits[0])/p.a,Math.abs(limits[1])/p.a);$('height-scale').textContent='Height \u00d7 '+num(height,2);
    const vertices=[],colors=[],indices=[];for(const r of samples){vertices.push(r.x,height*r.value,-r.y);const color=new THREE.Color(colorValue(r.value));colors.push(color.r,color.g,color.b);}for(let j=0;j<64;j++)for(let i=0;i<64;i++){const a=i+j*65;indices.push(a,a+1,a+65,a+1,a+66,a+65);}const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(vertices,3));geometry.setAttribute('color',new THREE.Float32BufferAttribute(colors,3));geometry.setIndex(indices);geometry.computeVertexNormals();replace(surface,geometry);
  }
  function update(r,cut){point.position.set(r.x,height*r.value+.065,-r.y);ascent.visible=r.magnitude>1e-7;ascent.position.copy(point.position);direction.position.copy(point.position);
    if(ascent.visible)ascent.setDirection(new THREE.Vector3(r.fx,height*r.magnitude*r.magnitude,-r.fy).normalize());direction.setDirection(new THREE.Vector3(r.ux,height*r.directional,-r.uy).normalize());
    const patch=[];for(const [dx,dy] of [[-.5,-.5],[.5,-.5],[.5,.5],[-.5,.5]])patch.push(r.x+dx,height*(r.value+dx*r.fx+dy*r.fy)+.03,-r.y-dy);const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.Float32BufferAttribute(patch,3));geo.setIndex([0,1,2,0,2,3]);replace(tangent,geo);tangent.visible=$('plane').checked;
    replace(cutLine,new THREE.BufferGeometry().setFromPoints(cut.map(t=>new THREE.Vector3(t.x,height*t.value+.04,-t.y))));replace(pathLine,new THREE.BufferGeometry().setFromPoints(trail.map(t=>new THREE.Vector3(t.x,height*t.value+.045,-t.y))));
  }
  const resize=()=>{const w=host.clientWidth,h=host.clientHeight;renderer.setSize(w,h,false);camera.aspect=w/h;camera.fov=Math.min(60,38*Math.max(1,1.25/camera.aspect));camera.updateProjectionMatrix();};new ResizeObserver(resize).observe(host);resize();
  const raycaster=new THREE.Raycaster();let press;renderer.domElement.addEventListener('pointerdown',e=>{press=[e.clientX,e.clientY];});renderer.domElement.addEventListener('pointerup',e=>{if(!press||Math.hypot(e.clientX-press[0],e.clientY-press[1])>5)return;const box=renderer.domElement.getBoundingClientRect();raycaster.setFromCamera(new THREE.Vector2((e.clientX-box.left)/box.width*2-1,1-(e.clientY-box.top)/box.height*2),camera);const hit=raycaster.intersectObject(surface)[0];if(hit)setPoint(hit.point.x,-hit.point.z);});
  return {build,update,reset(){orbit.reset();},render(){orbit.update();renderer.render(scene,camera);}};
}
try{view=makeScene();}catch(error){$('fallback').hidden=false;$('camera').disabled=true;}
new ResizeObserver(()=>{if(samples.length)display();}).observe($('contours'));
function frame(now){if(running&&now-lastStep>100){lastStep=now;advance();}view?.render();requestAnimationFrame(frame);}
rebuild();requestAnimationFrame(frame);
