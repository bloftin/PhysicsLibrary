import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {scaleLinear,line,extent} from 'd3';
import {createIcons,Play,Pause,RotateCcw,Orbit,Download,Target,MoveRight} from 'lucide';
import {DEFAULTS,FIELDS,parameters,at,curve,surface,frame,local,sub,norm,minimizer,csv} from './model.js';

const $=id=>document.getElementById(id),colors={blue:0x226eb3,coral:0xbd4c42,green:0x17836c,gold:0x9c7411};
let state={...DEFAULTS},tab='endpoint',running=false,last=0,sceneView;
const fmt=x=>Math.abs(x)<5e-9?'0':Number(x.toPrecision(5)).toString();
const icons=()=>createIcons({icons:{Play,Pause,RotateCcw,Orbit,Download,Target,MoveRight}});
function stop(){running=false;$('play').setAttribute('aria-pressed','false');$('play').innerHTML='<i data-lucide="play"></i>';icons();}
function visibleField(k){return !(['u','v'].includes(k)&&state.mode!=='plane'||['lon','lat'].includes(k)&&state.mode==='plane'||k==='radius'&&state.mode!=='sphere'||['rx','ry','rz'].includes(k)&&state.mode!=='ellipsoid');}
function fields(){
  $('fields').replaceChildren();
  for(const [k,title,min,max,step,group] of FIELDS){if(group!==tab||!visibleField(k))continue;
    const box=document.createElement('div');box.className='field';
    const head=document.createElement('div');head.className='field-head';
    const label=document.createElement('label');label.htmlFor=k;label.textContent=title;
    const number=document.createElement('input');number.id=k;number.type='number';number.min=min;number.max=max;number.step=step;number.value=state[k];
    const slider=document.createElement('input');slider.id=k+'-range';slider.type='range';slider.min=min;slider.max=max;slider.step=step;slider.value=state[k];slider.setAttribute('aria-label',title);
    const change=(event)=>{stop();try{const candidate={...state,[k]:Number(event.target.value)};if(event.target.value==='')throw new RangeError('Enter a number.');parameters(candidate);state=candidate;$('error').hidden=true;number.value=slider.value=state[k];update(k!=='psi');}catch(error){$('error').textContent=error.message;$('error').hidden=false;slider.value=state[k];}};
    slider.addEventListener('input',change);number.addEventListener('change',change);head.append(label,number);box.append(head,slider);$('fields').append(box);
  }
}
function selectTab(next){tab=next;for(const button of document.querySelectorAll('[data-tab]')){const active=button.dataset.tab===tab;button.setAttribute('aria-selected',active);button.tabIndex=active?0:-1;}$('fields').setAttribute('aria-labelledby','tab-'+tab);fields();}
for(const button of document.querySelectorAll('[data-tab]')){button.addEventListener('click',()=>selectTab(button.dataset.tab));button.addEventListener('keydown',event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;event.preventDefault();const tabs=['endpoint','target','start'];let i=tabs.indexOf(tab);i=event.key==='Home'?0:event.key==='End'?2:(i+(event.key==='ArrowRight'?1:2))%3;selectTab(tabs[i]);$('tab-'+tab).focus();});}

const point=v=>new THREE.Vector3(v[0],v[2],-v[1]);
class SceneView{
  constructor(){
    this.host=$('scene');this.scene=new THREE.Scene();this.scene.background=new THREE.Color('#f0f7f7');
    this.renderer=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});this.renderer.setPixelRatio(Math.min(devicePixelRatio,2));this.host.prepend(this.renderer.domElement);
    this.camera=new THREE.PerspectiveCamera(42,1,.01,300);this.controls=new OrbitControls(this.camera,this.renderer.domElement);this.controls.enableDamping=false;this.controls.addEventListener('change',()=>this.render());
    this.scene.add(new THREE.HemisphereLight(0xffffff,0xa1b1b3,2.2));const light=new THREE.DirectionalLight(0xffffff,2);light.position.set(5,8,4);this.scene.add(light);
    this.group=new THREE.Group();this.scene.add(this.group);this.ray=new THREE.Raycaster();
    this.renderer.domElement.addEventListener('pointerdown',e=>{this.down=[e.clientX,e.clientY];});
    this.renderer.domElement.addEventListener('pointerup',e=>{if(!this.down||Math.hypot(e.clientX-this.down[0],e.clientY-this.down[1])>5)return;const rect=this.renderer.domElement.getBoundingClientRect();this.ray.setFromCamera(new THREE.Vector2(2*(e.clientX-rect.left)/rect.width-1,1-2*(e.clientY-rect.top)/rect.height),this.camera);const hit=this.ray.intersectObject(this.target)[0];if(!hit)return;const b=local(frame(state),sub([hit.point.x,-hit.point.z,hit.point.y],frame(state).C));let patch;if(state.mode==='plane')patch={u:b[0],v:b[1]};else{const axes=state.mode==='sphere'?[state.radius,state.radius,state.radius]:[state.rx,state.ry,state.rz],v=b.map((x,i)=>x/axes[i]);patch={lon:Math.atan2(v[1],v[0])*180/Math.PI,lat:Math.asin(Math.max(-1,Math.min(1,v[2])))*180/Math.PI};}stop();state=parameters({...state,...patch});fields();update(false);});
    new ResizeObserver(()=>this.resize()).observe(this.host);
  }
  clear(){this.group.traverse(o=>{o.geometry?.dispose();if(o.material){for(const m of Array.isArray(o.material)?o.material:[o.material])m.dispose();}});this.group.clear();}
  path(points,color,dashed=false,width=1){const g=new THREE.BufferGeometry().setFromPoints(points.map(point)),m=dashed?new THREE.LineDashedMaterial({color,dashSize:.12,gapSize:.08}):new THREE.LineBasicMaterial({color,linewidth:width});const l=new THREE.Line(g,m);if(dashed)l.computeLineDistances();this.group.add(l);return l;}
  marker(v,color,size){const mesh=new THREE.Mesh(new THREE.SphereGeometry(size,18,12),new THREE.MeshStandardMaterial({color,roughness:.5}));mesh.position.copy(point(v));this.group.add(mesh);}
  arrow(v,color,scale,offset=0){const length=norm(v)*scale;if(length<1e-8)return;const direction=point(v).normalize(),origin=point(this.r.B);origin.addScaledVector(point(this.r.n),offset);this.group.add(new THREE.ArrowHelper(direction,origin,length,color,Math.min(length*.25,.18),Math.min(length*.12,.09)));}
  update(r,fit=false){
    this.r=r;this.clear();const samples=curve(r),positions=[],indices=[],costs=[],nu=64,nv=r.mode==='plane'?40:32;
    const near=local(r,sub(r.star,r.C)),middle=[(r.u+near[0])/2,(r.v+near[1])/2],half=[Math.max(2.3,Math.abs(r.u-near[0])/2+.8),Math.max(2.3,Math.abs(r.v-near[1])/2+.8)];
    for(let j=0;j<=nv;j++)for(let i=0;i<=nu;i++){const v=surface(r,r.mode==='plane'?middle[0]-half[0]+2*half[0]*i/nu:-180+360*i/nu,r.mode==='plane'?middle[1]-half[1]+2*half[1]*j/nv:-90+180*j/nv);positions.push(...point(v).toArray());costs.push(norm(sub(v,r.A))**2/(2*r.T));}
    for(let j=0;j<nv;j++)for(let i=0;i<nu;i++){const a=j*(nu+1)+i,b=a+nu+1;indices.push(a,b,a+1,b,b+1,a+1);}
    const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));geometry.setIndex(indices);geometry.computeVertexNormals();const lo=Math.min(...costs),hi=Math.max(...costs),low=new THREE.Color('#4aa99a'),mid=new THREE.Color('#e4d994'),high=new THREE.Color('#da887a'),vertex=[];
    for(const cost of costs){const f=(cost-lo)/(hi-lo||1),c=f<.5?low.clone().lerp(mid,2*f):mid.clone().lerp(high,2*f-1);vertex.push(c.r,c.g,c.b);}geometry.setAttribute('color',new THREE.Float32BufferAttribute(vertex,3));
    this.target=new THREE.Mesh(geometry,new THREE.MeshStandardMaterial({vertexColors:true,transparent:true,opacity:.57,side:THREE.DoubleSide,roughness:.9,depthWrite:false}));this.target.renderOrder=0;this.group.add(this.target);
    const wire=new THREE.LineSegments(new THREE.WireframeGeometry(geometry),new THREE.LineBasicMaterial({color:0x638e92,transparent:true,opacity:.08}));this.group.add(wire);
    const span=Math.max(3,norm(sub(r.B,r.A)),2*Math.max(r.rx,r.ry,r.rz,r.radius));this.span=span;
    this.path(samples.map(d=>d.q),colors.blue);
    if($('reference').checked)this.path(samples.map(d=>d.qstar),colors.green,true);
    this.marker(r.A,colors.blue,.055*span/5);this.marker(r.B,colors.coral,.068*span/5);
    if($('reference').checked&&norm(sub(r.B,r.star))>.03)this.marker(r.star,colors.green,.065*span/5);
    const arrowScale=.23*span/Math.max(1,norm(r.momentum));$('scale').textContent='Momentum scale: '+fmt(arrowScale)+' length / unit p';
    if($('normals').checked){this.arrow(r.pn,colors.gold,arrowScale,.014);this.arrow(r.momentum,colors.blue,arrowScale);this.arrow(r.pt,colors.coral,arrowScale);}
    if($('tangents').checked){
      const radius=.18*span,verts=[];for(let i=0;i<=64;i++){const theta=2*Math.PI*i/64;verts.push(r.B.map((v,k)=>v+radius*(r.t1[k]*Math.cos(theta)+r.t2[k]*Math.sin(theta))));}this.path(verts,0x95b3ac);
      const disk=new THREE.Mesh(new THREE.CircleGeometry(radius,64),new THREE.MeshBasicMaterial({color:0x93c9b5,transparent:true,opacity:.15,side:THREE.DoubleSide,depthWrite:false}));disk.position.copy(point(r.B));disk.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),point(r.n));this.group.add(disk);this.arrow(r.eta,colors.green,radius);
    }
    const axesLength=span*.16,origin=[0,0,0];for(const [k,color] of [[0,0x98a9b0],[1,0xb4a09e],[2,0x9daea4]]){const endpoint=[0,0,0];endpoint[k]=axesLength;this.path([origin,endpoint],color);}
    if(fit||!this.center){
      const bounds=new THREE.Box3().setFromObject(this.group),size=bounds.getSize(new THREE.Vector3());this.center=bounds.getCenter(new THREE.Vector3());this.radius=size.length()/2;
      this.group.updateMatrixWorld(true);this.fitPoints=[];
      this.group.traverse(o=>{const positions=o.geometry?.getAttribute('position');if(positions)for(let i=0;i<positions.count;i+=2)this.fitPoints.push(new THREE.Vector3().fromBufferAttribute(positions,i).applyMatrix4(o.matrixWorld));});this.home();
    }else this.render();
  }
  home(){
    if(!this.center)return;this.camera.aspect=this.host.clientWidth/this.host.clientHeight;this.camera.near=.01;this.camera.far=this.radius*100+100;this.camera.updateProjectionMatrix();
    const direction=new THREE.Vector3(1,.85,1.25).normalize(),probe=new THREE.Vector3();let low=this.radius*.2,high=this.radius*30;
    // Fit actual geometry rather than its bounding sphere, especially for a thin plane.
    for(let i=0;i<26;i++){const distance=(low+high)/2;this.camera.position.copy(this.center).addScaledVector(direction,distance);this.camera.lookAt(this.center);this.camera.updateMatrixWorld(true);const fits=this.fitPoints.every(p=>{probe.copy(p).project(this.camera);return Math.abs(probe.x)<.85&&Math.abs(probe.y)<.83&&probe.z>-1&&probe.z<1;});if(fits)high=distance;else low=distance;}
    this.camera.position.copy(this.center).addScaledVector(direction,high);this.controls.target.copy(this.center);this.controls.update();this.render();
  }
  resize(){this.renderer.setSize(this.host.clientWidth,this.host.clientHeight,false);this.camera.aspect=this.host.clientWidth/this.host.clientHeight;this.camera.updateProjectionMatrix();this.home();}
  render(){
    this.renderer.render(this.scene,this.camera);if(!this.r)return;
    const zero=norm(sub(this.r.A,this.r.B))<1e-7;
    $('label-b').textContent=zero?'A = B'+(this.r.minimum?' = B*':''):this.r.minimum?'B = B*':'B';
    const occupied=[];
    for(const [id,v] of [['label-a',this.r.A],['label-b',this.r.B],['label-star',this.r.star]]){
      const label=$(id),p=point(v).project(this.camera),same=id==='label-star'&&norm(sub(this.r.B,this.r.star))<.03||id==='label-a'&&zero;
      label.hidden=same||id==='label-star'&&!$('reference').checked||Math.abs(p.x)>.95||Math.abs(p.y)>.95||p.z>1;if(label.hidden)continue;
      const width=label.offsetWidth,height=label.offsetHeight,px=(p.x+1)*this.host.clientWidth/2,py=(1-p.y)*this.host.clientHeight/2;
      const candidates=[[6,-17],[6,7],[-width-6,-17],[6,31],[-width-6,7]].map(([dx,dy])=>({x:Math.max(5,Math.min(this.host.clientWidth-width-5,px+dx)),y:Math.max(5,Math.min(this.host.clientHeight-height-5,py+dy)),width,height}));
      const rect=candidates.find(a=>occupied.every(b=>a.x+a.width+3<b.x||b.x+b.width+3<a.x||a.y+a.height+3<b.y||b.y+b.height+3<a.y))||candidates[0];occupied.push(rect);label.style.left=rect.x+'px';label.style.top=rect.y+'px';
    }
  }
}

function chart(id,series,xDomain,xLabel){
  const canvas=$(id),width=canvas.clientWidth,height=canvas.clientHeight,dpr=Math.min(devicePixelRatio,2);canvas.width=width*dpr;canvas.height=height*dpr;const c=canvas.getContext('2d');c.scale(dpr,dpr);c.clearRect(0,0,width,height);const left=47,right=12,top=17,bottom=35,range=extent(series.flatMap(s=>s.values.map(v=>v[1]))),pad=Math.max(.15,(range[1]-range[0])*.14),x=scaleLinear().domain(xDomain).range([left,width-right]),y=scaleLinear().domain([Math.min(0,range[0]-pad),Math.max(0,range[1]+pad)]).nice().range([height-bottom,top]);
  c.font='11px Arial';c.lineWidth=1;
  for(const v of y.ticks(4)){c.strokeStyle='#dce5e7';c.beginPath();c.moveTo(left,y(v));c.lineTo(width-right,y(v));c.stroke();c.fillStyle='#536c74';c.textAlign='right';c.fillText(fmt(v),left-7,y(v)+4);}
  c.textAlign='center';for(const v of x.ticks(width<300?3:5))c.fillText(fmt(v),x(v),height-bottom+18);c.fillText(xLabel,(left+width-right)/2,height-4);
  const path=line().x(v=>x(v[0])).y(v=>y(v[1])).context(c);for(const s of series){c.beginPath();c.strokeStyle=s.color;c.lineWidth=s.dash?1.3:2;c.setLineDash(s.dash?[5,4]:[]);path(s.values);c.stroke();}c.setLineDash([]);
  if(id==='variation'){const r=at(state);for(const [value,color] of [[r.boundary,'#226eb3'],[r.total,'#bd4c42']]){c.fillStyle=color;c.beginPath();c.arc(x(r.psi),y(value),3,0,Math.PI*2);c.fill();}}
}
function plots(r){const samples=curve(r),series=[];for(const [i,color] of ['#226eb3','#bd4c42','#17836c'].entries()){if($('reference').checked)series.push({color,dash:true,values:samples.map(d=>[d.time,d.qstar[i]])});series.push({color,values:samples.map(d=>[d.time,d.q[i]])});}chart('components',series,[0,r.T],'t');const angles=Array.from({length:181},(_,i)=>-180+2*i),values=angles.map(angle=>{const psi=angle*Math.PI/180,eta=r.t1.map((v,i)=>v*Math.cos(psi)+r.t2[i]*Math.sin(psi));return {angle,boundary:r.momentum.reduce((s,v,i)=>s+v*eta[i],0),total:sub(r.B,r.A).reduce((s,v,i)=>s+v*eta[i],0)/r.T};});chart('variation',[{color:'#226eb3',values:values.map(d=>[d.angle,d.boundary])},{color:'#bd4c42',dash:true,values:values.map(d=>[d.angle,d.total])}],[-180,180],'Variation angle (degrees)');}
function update(fit=false){
  const r=at(state),name={plane:'plane',sphere:'sphere',ellipsoid:'ellipsoid'}[r.mode];$('figure-title').textContent='A path ending on a '+name;
  for(const [id,key] of [['energy','J'],['gap','gap'],['tangent-residual','tangent'],['interior-residual','residual'],['boundary','boundary'],['interior','interior'],['total','total']])$(id).textContent=fmt(r[key]);
  $('surface-caption').textContent='Target colors: low (teal) to high (coral) straight-path endpoint cost ||B - A||²/(2T). B* is the nearest point. '+(r.mode==='plane'?'The displayed patch is part of an infinite plane.':'Only the endpoint is constrained; the path can cross the surface.');
  $('variation-caption').textContent='Full variation η(t) = (t/T)ηB. '+(Math.abs(r.bend)>1e-9?'The bend makes the boundary and total curves differ; the interior term supplies the difference.':'The straight path has no interior contribution, so the curves coincide. A single zero is not stationarity in every direction.');
  let title,text;
  if(r.residual>1e-8){title='The path has an interior error';text='The bend keeps both endpoints fixed but makes q″ nonzero. Its energy penalty is '+fmt(r.bendCost)+'. Straighten the path before interpreting endpoint normality as a complete stationarity test.';}
  else if(r.minimum){title='The straight path attains the global minimum';text='Both tests vanish: q″ = 0 and pt = 0. The endpoint is the nearest point B*, and J = dist(A, S)²/(2T). '+(norm(r.momentum)<1e-8?'Here A is already on the plane, so the constant path has zero momentum and zero energy.':'The fitted multiplier in p = λ∇g is '+fmt(r.lambda)+'. A negative value means the incoming momentum opposes the chosen outward normal.');}
  else if(r.stationary){title='Stationary does not always mean minimum';text='The straight path satisfies both first-order conditions, but its endpoint is not the nearest point. This is a saddle of the full path problem: some admissible endpoint changes lower J, while interior bends raise J.';}
  else{title='The interior equation holds; the endpoint still wants to slide';text='This segment has q″ = 0, but ||pt|| = '+fmt(r.tangent)+'. A displacement opposite pt lowers J to first order. The chosen green direction gives δJ = '+fmt(r.total)+'; only a zero tangential vector makes every allowed direction stationary.';}
  $('interpretation-title').textContent=title;$('interpretation').textContent=text;$('status').textContent=r.minimum?'Global minimum':r.stationary?'Stationary, not minimum':r.residual>1e-8?'Interior residual present':'Endpoint can improve';
  $('target-guide-title').textContent=r.mode==='plane'?'Plane: orthogonal projection':r.mode==='sphere'?'Sphere: nearest radial point':'Ellipsoid: the normal is not generally radial';
  $('target-guide').innerHTML=r.mode==='plane'?'<p>The target is g(B) = n·(B − C) = 0, with unit normal n. Its minimizing endpoint is B* = A − [n·(A − C)]n. Sliding B away from that projection increases the squared length of the straight segment.</p>':r.mode==='sphere'?'<p>The target is ||B − C||²/R² = 1. For an exterior start, B* = C + R(A − C)/||A − C||. The near and far radial points are both first-order stationary, but only the near one minimizes J.</p>':'<p>In target-local coordinates, g(B) = b₁²/a² + b₂²/b² + b₃²/c² − 1. Its gradient is proportional to (b₁/a², b₂/b², b₃/c²), not usually to B − C. The nearest point is computed with a bracketed scalar root solve, then checked against the endpoint normal condition.</p>';
  sceneView?.update(r,fit);plots(r);
}
$('target').addEventListener('change',()=>{stop();state={...DEFAULTS,mode:$('target').value};$('error').hidden=true;fields();update(true);});
$('reset').addEventListener('click',()=>{stop();state={...DEFAULTS,mode:state.mode};$('error').hidden=true;fields();update(true);});
$('minimum').addEventListener('click',()=>{stop();state=minimizer(state);$('error').hidden=true;fields();update(true);});
$('straighten').addEventListener('click',()=>{stop();state={...state,bend:0};fields();update(false);});
$('camera').addEventListener('click',()=>sceneView?.home());
for(const id of ['reference','normals','tangents'])$(id).addEventListener('change',()=>update(false));
$('download').addEventListener('click',()=>{const url=URL.createObjectURL(new Blob([csv(state)],{type:'text/csv'})),a=document.createElement('a');a.href=url;a.download='vector-target-'+state.mode+'.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
$('play').addEventListener('click',()=>{running=!running;$('play').setAttribute('aria-pressed',running);$('play').innerHTML=running?'<i data-lucide="pause"></i>':'<i data-lucide="play"></i>';icons();last=performance.now();});
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
try{sceneView=new SceneView();}catch{$('scene').querySelector('canvas')?.remove();$('fallback').hidden=false;for(const id of ['label-a','label-b','label-star'])$(id).hidden=true;$('camera').disabled=true;$('scale').textContent='3D unavailable';}
selectTab('endpoint');icons();update(true);new ResizeObserver(()=>plots(at(state))).observe($('components'));
function animate(now){if(running&&now-last>75){state={...state,psi:((state.psi+(now-last)*.035+180)%360)-180};last=now;for(const id of ['psi','psi-range'])if($(id))$(id).value=state.psi.toFixed(1);update(false);}requestAnimationFrame(animate);}requestAnimationFrame(animate);
