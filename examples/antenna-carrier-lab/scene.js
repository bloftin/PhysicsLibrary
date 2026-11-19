import * as T from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {parameters,state,incident,farField} from './model.js';
const vec=a=>new T.Vector3(...a);
function label(text,color='#405c63'){
 const canvas=document.createElement('canvas');let c=canvas.getContext('2d');c.font='32px Arial';canvas.width=Math.ceil(c.measureText(text).width)+20;canvas.height=48;c=canvas.getContext('2d');c.font='32px Arial';c.textAlign='center';c.fillStyle=color;c.fillText(text,canvas.width/2,35);
 const texture=new T.CanvasTexture(canvas);texture.colorSpace=T.SRGBColorSpace;texture.minFilter=T.LinearFilter;texture.generateMipmaps=false;
 const material=new T.SpriteMaterial({map:texture,transparent:true,depthTest:false});const sprite=new T.Sprite(material);sprite.scale.set(.28*canvas.width/48,.28,1);return sprite;
}
function sphere(radius,color){return new T.Mesh(new T.SphereGeometry(radius,14,10),new T.MeshBasicMaterial({color}));}
function setArrow(arrow,origin,direction,length){
 arrow.visible=Number.isFinite(length)&&length>1e-5&&direction.length()>1e-10;if(!arrow.visible)return;arrow.position.copy(origin);arrow.setDirection(direction.clone().normalize());arrow.setLength(length,Math.min(.15,length*.35),Math.min(.07,length*.16));
}
export function createScene(host){
 let renderer;
 try{renderer=new T.WebGLRenderer({antialias:true,alpha:false,preserveDrawingBuffer:true});}catch{return null;}
 renderer.setPixelRatio(Math.min(devicePixelRatio||1,2));renderer.setClearColor(0xf5fafb);host.append(renderer.domElement);
 const scene=new T.Scene(),camera=new T.PerspectiveCamera(37,1,.01,100);camera.up.set(0,0,1);const controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=false;controls.enablePan=false;controls.minDistance=3;controls.maxDistance=60;
 const close=new T.Group(),wave=new T.Group();scene.add(close,wave);
 const armMaterial=new T.MeshBasicMaterial({color:0x85979e,transparent:true,opacity:.25});
 for(const sign of [-1,1]){const arm=new T.Mesh(new T.CylinderGeometry(.09,.09,1.06,18),armMaterial);arm.rotation.x=Math.PI/2;arm.position.z=sign*.67;close.add(arm);}
 const feed=new T.Mesh(new T.BoxGeometry(.35,.28,.22),new T.MeshBasicMaterial({color:0x3d817d}));close.add(feed);
 const feedLabel=label('Feed / external circuit');feedLabel.position.set(.2,0,-1.82);close.add(feedLabel);
 const upper=label('Upper arm'),lower=label('Lower arm');upper.position.set(0,0,1.55);lower.position.set(0,0,-1.48);close.add(upper,lower);
 const electrons=[],net=[];
 for(const sign of [-1,1])for(let j=0;j<8;j++){
  const z=sign*(.2+j*.13),ion=sphere(.037,0x909ba2);ion.position.set(-.13,0,z);close.add(ion);
  const e=sphere(.047,0x0b819a);e.position.set(.13,0,z);e.userData.z=z;electrons.push(e);close.add(e);
 }
 for(const sign of [-1,1])for(let j=0;j<3;j++){
  const plus=label('+','#bd4552'),minus=label('-','#087c9b');plus.scale.set(.2*plus.material.map.image.width/48,.2,1);minus.scale.set(.2*minus.material.map.image.width/48,.2,1);plus.position.set(.48,0,sign*(.35+j*.3));minus.position.copy(plus.position);close.add(plus,minus);net.push({sign,plus,minus});
 }
 const current=new T.ArrowHelper(new T.Vector3(0,0,1),new T.Vector3(-.68,0,-.3),.7,0x997317),drift=new T.ArrowHelper(new T.Vector3(0,0,-1),new T.Vector3(.9,0,.3),.7,0x0b819a),drive=new T.ArrowHelper(new T.Vector3(0,0,1),new T.Vector3(-1.4,0,-.3),.8,0x267e88);close.add(current,drift,drive);
 const il=label('Conventional I','#8a6915'),el=label('Electron drift','#08768c'),dl=label('Axial drive','#267e88');il.position.set(-1,0,1.05);el.position.set(1.1,0,-1.05);dl.position.set(-1.45,0,-.85);close.add(il,el,dl);
 const center=sphere(.07,0x425f67);wave.add(center);const originLabel=label('Antenna location');originLabel.position.set(0,0,-.5);wave.add(originLabel);
 const arrows=[];
 for(let i=0;i<120;i++){const e=new T.ArrowHelper(new T.Vector3(0,0,1),new T.Vector3(),1,0x087f89),b=new T.ArrowHelper(new T.Vector3(0,1,0),new T.Vector3(),1,0x8b5693);wave.add(e,b);arrows.push({e,b});}
 const flow=new T.ArrowHelper(new T.Vector3(1,0,0),new T.Vector3(),1.2,0x997317);wave.add(flow);
 const distanceLabel=label('');distanceLabel.visible=false;
 let lastView='close',fitScale=1;
 function reframe(front=false){const far=lastView==='wave';fitScale=Math.max(1,host.clientHeight/host.clientWidth);camera.position.set(...(front?[0,-(far?14.5:6.4),.1]:far?[7,-10,6]:[2.4,-5.2,2])).multiplyScalar(fitScale);controls.target.set(0,0,0);camera.lookAt(0,0,0);controls.update();render();}
 function render(){const w=host.clientWidth,h=host.clientHeight,fit=Math.max(1,h/w);camera.position.multiplyScalar(fit/fitScale);fitScale=fit;renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix();renderer.render(scene,camera);}
 function update(p,cycles,view='close'){
  const changed=view!==lastView;lastView=view;const m=parameters(p),s=state(p,cycles);close.visible=view==='close';wave.visible=view==='wave';
  const q=m.qPeak?s.charge/m.qPeak:0,i=m.peak?s.current/m.peak:0;
  for(const e of electrons){const shape=1-Math.abs(e.userData.z)/1.2;e.position.z=e.userData.z-q*.11*shape;}
  for(const n of net){n.plus.visible=q*n.sign>1e-4;n.minus.visible=q*n.sign<-1e-4;}
  feed.material.color.set(p.mode==='receive'?0x3d817d:0x9c771a);
  setArrow(current,new T.Vector3(-.68,0,-.4*Math.sign(i||1)),new T.Vector3(0,0,i),.8*Math.abs(i));setArrow(drift,new T.Vector3(.9,0,.4*Math.sign(i||1)),new T.Vector3(0,0,-i),.8*Math.abs(i));
  const driveFraction=p.mode==='receive'?m.g.projection*Math.cos(2*Math.PI*cycles)*(p.E0?1:0):Math.cos(2*Math.PI*cycles)*(p.voltage?1:0);
  setArrow(drive,new T.Vector3(-1.4,0,-.4*Math.sign(driveFraction||1)),new T.Vector3(0,0,driveFraction),.8*Math.abs(driveFraction));
  for(const a of arrows){a.e.visible=false;a.b.visible=false;}
  if(p.mode==='receive'){
   const n=vec(m.g.n),across=new T.Vector3(0,1,0);let index=0;
   for(let j=0;j<19;j++)for(const lane of [-.7,.7]){
    const position=n.clone().multiplyScalar(-3.5+j*7/18).addScaledVector(across,lane),f=incident(p,cycles,position.toArray()),a=arrows[index++];
    setArrow(a.e,position,vec(f.e),p.E0?vec(f.e).length()/p.E0*.65:0);setArrow(a.b,position.clone().addScaledVector(n,.06),vec(f.b),p.E0?vec(f.b).length()*299792458/p.E0*.65:0);
   }
   setArrow(flow,n.clone().multiplyScalar(-2.8).add(new T.Vector3(0,0,1)),n,p.E0?1.2:0);
  }else{
   let index=0;const reference=farField(p,0,3,90).peak;
   for(const radius of [2,2.25,2.5,2.75,3,3.25,3.5,3.75,4])for(const theta of [45,90,135])for(const phi of [0,Math.PI/2,Math.PI,3*Math.PI/2]){
    const t=theta*Math.PI/180,n=new T.Vector3(Math.sin(t)*Math.cos(phi),Math.sin(t)*Math.sin(phi),Math.cos(t)),eth=new T.Vector3(Math.cos(t)*Math.cos(phi),Math.cos(t)*Math.sin(phi),-Math.sin(t)),eph=new T.Vector3(-Math.sin(phi),Math.cos(phi),0),position=n.clone().multiplyScalar(radius),f=farField(p,cycles,radius,theta),signed=reference?f.eTheta/reference:0,a=arrows[index++];
    setArrow(a.e,position,eth.clone().multiplyScalar(signed),Math.abs(signed)*.6);setArrow(a.b,position.clone().addScaledVector(n,.06),eph.clone().multiplyScalar(signed),Math.abs(signed)*.6);
   }
   setArrow(flow,new T.Vector3(2,0,0),new T.Vector3(1,0,0),m.peak?1.2:0);
  }
  if(changed)reframe();else render();
 }
 controls.addEventListener('change',render);new ResizeObserver(render).observe(host);reframe();
 return {update,reset:()=>reframe(),front:()=>reframe(true),dispose:()=>{controls.dispose();renderer.dispose();},camera};
}
