import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {scaleLinear,extent,line,format} from 'd3';
import {createIcons,Play,Pause,RotateCcw,StepForward,Scan,Download} from 'lucide';
import {DEFAULTS,PRESETS,parameters,scales,classification,response,trajectory,csv} from './model.js';

const $=id=>document.getElementById(id), colors={x:'#16887c',v:'#d45c4d',K:'#16887c',U:'#b7831e',E:'#253b3e',Q:'#d45c4d',W:'#805c9c'};
const fields=[['m','Mass m (kg)',.25,5,.05],['k','Stiffness k (N/m)',1,40,.5],['zeta','Damping ratio \u03b6',0,2,.01],['x0','Initial x (m)',-1.5,1.5,.05],['v0','Initial v (m/s)',-3,3,.05],['force','Drive F\u2080 (N)',0,4,.05],['ratio','Drive \u03c9d / \u03c9\u2080',.1,3,.01],['phase','Drive phase (\u00b0)',-180,180,5],['cycles','Natural periods',2,12,1]];
let p={...DEFAULTS},s,rows=[],index=0,playing=false,speed=1,elapsed=0,plots=[],sceneView,updateTimer;
for(const [key,label,min,max,step] of fields){
  const div=document.createElement('div');div.className='field';
  div.innerHTML=`<div class="field-head"><label for="${key}-number">${label}</label><input id="${key}-number" type="number" min="${min}" max="${max}" step="${step}"></div><input id="${key}" type="range" min="${min}" max="${max}" step="${step}" aria-label="${label}">`;
  $('fields').append(div);
  for(const id of [key,key+'-number'])$(id).addEventListener('input',()=>{
    const input=$(id),value=Number(input.value);
    if(input.value.trim()===''||!Number.isFinite(value)||value<min||value>max){input.setAttribute('aria-invalid','true');$('error').hidden=false;$('error').textContent=`${label}: enter a value from ${min} to ${max}.`;return;}
    input.removeAttribute('aria-invalid');p[key]=value;$(key).value=value;$(key+'-number').value=value;$('preset').value='custom';
    clearTimeout(updateTimer);updateTimer=setTimeout(rebuild,70);
  });
}
function icons(){createIcons({icons:{Play,Pause,RotateCcw,StepForward,Scan,Download}});}
function setPlaying(value){playing=value;const label=value?'Pause':'Play';$('play').innerHTML=`<i data-lucide="${label.toLowerCase()}"></i>`;$('play').title=label;$('play').setAttribute('aria-label',label);icons();}
function sync(){
  for(const [key] of fields){for(const id of [key,key+'-number']){$(id).value=p[key];$(id).disabled=key==='zeta'?p.mode==='harmonic':['force','ratio','phase'].includes(key)?p.mode!=='driven':false;$(id).removeAttribute('aria-invalid');}}
  document.querySelectorAll('[data-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.mode===p.mode)));
}
document.querySelectorAll('[data-mode]').forEach(b=>b.addEventListener('click',()=>{p.mode=b.dataset.mode;$('preset').value='custom';rebuild();}));
$('preset').addEventListener('change',()=>{const {label,...preset}=PRESETS[$('preset').value]??{};p={...DEFAULTS,...preset};rebuild();});
$('play').addEventListener('click',()=>{if(index===rows.length-1){index=0;elapsed=0;}setPlaying(!playing);display();});
$('reset').addEventListener('click',()=>{setPlaying(false);index=0;elapsed=0;display();});
$('step').addEventListener('click',()=>{setPlaying(false);index=Math.min(index+5,rows.length-1);elapsed=rows[index].t;display();});
$('timeline').addEventListener('input',()=>{setPlaying(false);index=Number($('timeline').value);elapsed=rows[index].t;display();});
$('speed').addEventListener('change',()=>{speed=Number($('speed').value);});
$('camera').addEventListener('click',()=>sceneView?.reset());
$('download').addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([csv(p,rows)],{type:'text/csv'}));const a=document.createElement('a');a.href=url;a.download='oscillation.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
const num=(value,digits=3)=>Math.abs(value)<1e-10?'0':Math.abs(value)>=10000||Math.abs(value)<.001?value.toExponential(2):value.toFixed(digits);
function rebuild(){
  try{
    clearTimeout(updateTimer);p=parameters(p);s=scales(p);rows=trajectory(p);index=0;elapsed=0;setPlaying(false);sync();$('error').hidden=true;
    $('omega0').textContent=num(s.omega0)+' rad/s';$('period').textContent=num(s.period)+' s';$('frequency').textContent=num(s.f0)+' Hz';$('damping').textContent=num(s.c)+' N s/m';
    $('classification').textContent=classification(p)+(p.mode==='driven'?' \u00b7 Driven':p.mode==='harmonic'?' \u00b7 Free':' \u00b7 Free decay');
    const maxX=Math.max(.25,...rows.map(r=>Math.abs(r.x)));sceneView?.configure(2.4/maxX);$('scale').textContent='Range \u00b1'+num(maxX,2)+' m';
    $('force-label').hidden=p.mode!=='driven';$('response').hidden=p.mode!=='driven';
    const amplitude=response(p);
    $('response').textContent=amplitude===Infinity?'Undamped resonance: no bounded steady state.':(s.zeta===0?'Particular-solution amplitude: ':'Steady-state amplitude: ')+num(amplitude)+' m';
    plots=[makePlot('history','t',['x']),makePlot('phase-plot','x',['v']),makePlot('energy-plot','t',['K','U','E','Q','W'])];
    $('timeline').max=rows.length-1;display();
  }catch(error){$('error').textContent=error.message;$('error').hidden=false;setPlaying(false);}
}
function expanded(values){let [lo,hi]=extent(values);const pad=Math.max((hi-lo)*.09,.02);return [lo-pad,hi+pad];}
function makePlot(id,xKey,keys){
  const canvas=$(id),ctx=canvas.getContext('2d');
  const chart={canvas,ctx,xKey,keys};chart.domainX=xKey==='t'?[0,s.duration]:expanded(rows.map(r=>r[xKey]));chart.domainY=expanded(rows.flatMap(r=>keys.map(k=>r[k])));return chart;
}
function drawPlot(plot){
  const {canvas,ctx,xKey,keys}=plot,w=canvas.clientWidth,h=canvas.clientHeight,dpr=Math.min(devicePixelRatio||1,2);
  if(w<1||!ctx)return;
  canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);ctx.scale(dpr,dpr);ctx.clearRect(0,0,w,h);
  const x=scaleLinear().domain(plot.domainX).range([43,w-9]),y=scaleLinear().domain(plot.domainY).range([h-29,8]);
  ctx.font='10px system-ui';ctx.textBaseline='middle';ctx.strokeStyle='#e3ebe8';ctx.fillStyle='#748780';
  for(const v of y.ticks(4)){ctx.beginPath();ctx.moveTo(43,y(v));ctx.lineTo(w-9,y(v));ctx.stroke();ctx.textAlign='right';ctx.fillText(format('.2~g')(v),37,y(v));}
  for(const v of x.ticks(Math.max(3,Math.floor(w/75)))){ctx.textAlign='center';ctx.fillText(format('.2~g')(v),x(v),h-12);}
  ctx.save();ctx.beginPath();ctx.rect(43,8,Math.max(0,w-52),h-37);ctx.clip();
  if(plot.domainY[0]<0&&plot.domainY[1]>0){ctx.strokeStyle='#bccdc6';ctx.beginPath();ctx.moveTo(43,y(0));ctx.lineTo(w-9,y(0));ctx.stroke();}
  for(const key of keys){ctx.strokeStyle=colors[key];ctx.lineWidth=key==='E'?1.9:1.4;ctx.beginPath();line().x(r=>x(r[xKey])).y(r=>y(r[key])).context(ctx)(rows);ctx.stroke();}
  const row=rows[index];
  if(xKey==='t'){ctx.strokeStyle='#899f97';ctx.setLineDash([3,3]);ctx.beginPath();ctx.moveTo(x(row.t),8);ctx.lineTo(x(row.t),h-29);ctx.stroke();ctx.setLineDash([]);}
  for(const key of keys){ctx.fillStyle=colors[key];ctx.beginPath();ctx.arc(x(row[xKey]),y(row[key]),3,0,Math.PI*2);ctx.fill();}
  ctx.restore();
}
function display(){
  if(!rows.length)return;const r=rows[index];
  $('time').textContent=num(r.t,2)+' / '+num(s.duration,2)+' s';$('timeline').value=index;$('timeline').setAttribute('aria-valuetext',num(r.t,2)+' seconds');
  $('position').textContent=num(r.x)+' m';$('velocity').textContent=num(r.v)+' m/s';$('acceleration').textContent=num(r.a)+' m/s\u00b2';$('energy').textContent=num(r.E)+' J';
  $('balance').textContent='Balance error '+r.balance.toExponential(1)+' J';
  for(const plot of plots)drawPlot(plot);sceneView?.update(r);
}
function makeScene(){
  const host=$('scene'),renderer=new THREE.WebGLRenderer({antialias:true,alpha:false,preserveDrawingBuffer:true});
  renderer.setPixelRatio(Math.min(devicePixelRatio||1,2));renderer.setClearColor('#edf5f2');host.prepend(renderer.domElement);renderer.domElement.setAttribute('aria-label','Animated spring and mass, with equilibrium marker and applied force');renderer.domElement.setAttribute('role','img');
  const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(34,1,.1,100);camera.position.set(1.5,4.5,13);
  const controls=new OrbitControls(camera,renderer.domElement);controls.target.set(-1,0,0);controls.enablePan=false;controls.minDistance=10;controls.maxDistance=22;controls.maxPolarAngle=Math.PI*.49;controls.enableDamping=true;controls.update();controls.saveState();
  scene.add(new THREE.HemisphereLight('#ffffff','#769d87',3));const light=new THREE.DirectionalLight('#ffffff',3);light.position.set(-3,6,4);scene.add(light);
  const mat=(color)=>new THREE.MeshStandardMaterial({color,roughness:.45});
  const floor=new THREE.Mesh(new THREE.PlaneGeometry(20,10),mat('#dbeae3'));floor.rotation.x=-Math.PI/2;floor.position.y=-.5;scene.add(floor);
  const track=new THREE.Mesh(new THREE.BoxGeometry(10.5,.04,.12),mat('#8dac9f'));track.position.set(-.8,-.42,0);scene.add(track);
  const wall=new THREE.Mesh(new THREE.BoxGeometry(.18,1.8,1.3),mat('#80988f'));wall.position.set(-5.2,.35,0);scene.add(wall);
  const mass=new THREE.Mesh(new THREE.BoxGeometry(.8,.8,.8),mat('#d66b58'));scene.add(mass);
  const springMaterial=mat('#278b7c');let spring=new THREE.Mesh(new THREE.BufferGeometry(),springMaterial);scene.add(spring);
  const equilibrium=new THREE.Line(new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(0,-.42,.5),new THREE.Vector3(0,.9,.5)]),new THREE.LineDashedMaterial({color:'#6c9385',dashSize:.08,gapSize:.06}));equilibrium.computeLineDistances();scene.add(equilibrium);
  const force=new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,1.15,0),1,'#b7831e',.18,.12);scene.add(force);
  const ticks=new THREE.Group();for(let i=-4;i<=3;i++){const tick=new THREE.Mesh(new THREE.BoxGeometry(.015,.025,.5),mat('#9bb7aa'));tick.position.set(i,-.47,.5);ticks.add(tick);}scene.add(ticks);
  let conversion=1,lastX=NaN;
  const resize=()=>{const w=host.clientWidth,h=host.clientHeight;renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix();};new ResizeObserver(resize).observe(host);resize();
  function update(r){const x=r.x*conversion;mass.position.x=x;
    if(!Number.isFinite(lastX)||Math.abs(x-lastX)>1e-7){const points=[];for(let i=0;i<=192;i++){const f=i/192,angle=f*12*2*Math.PI;points.push(new THREE.Vector3(-5.1+(x-.4+5.1)*f,.22*Math.cos(angle),.22*Math.sin(angle)));}const old=spring.geometry;spring.geometry=new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points),192,.035,6,false);old.dispose();lastX=x;}
    force.visible=p.mode==='driven'&&Math.abs(r.F)>.005;force.position.set(x,1.15,0);force.setDirection(new THREE.Vector3(Math.sign(r.F)||1,0,0));force.setLength(.25+Math.min(Math.abs(r.F),4)*.35,.18,.12);
  }
  return {update,configure(value){conversion=value;lastX=NaN;},reset(){controls.reset();},render(){controls.update();renderer.render(scene,camera);}};
}
try{sceneView=makeScene();}catch(error){$('fallback').hidden=false;$('camera').disabled=true;}
new ResizeObserver(()=>display()).observe($('history'));
let last=performance.now();function frame(now){const dt=Math.min((now-last)/1000,.1);last=now;if(playing){elapsed=Math.min(elapsed+dt*speed,s.duration);const next=Math.min(rows.length-1,Math.round(elapsed/s.duration*(rows.length-1)));if(next!==index){index=next;display();}if(elapsed>=s.duration)setPlaying(false);}sceneView?.render();requestAnimationFrame(frame);}
rebuild();requestAnimationFrame(frame);
