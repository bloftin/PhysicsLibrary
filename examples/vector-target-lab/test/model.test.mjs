import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DEFAULTS,FIELDS,at,frame,local,surface,closest,minimizer,sample,curve,csv,parameters,dot,norm,sub,cross} from '../model.js';
const near=(a,b,tol=2e-9)=>assert.ok(Math.abs(a-b)<tol*Math.max(1,Math.abs(a),Math.abs(b)),`${a} != ${b}`);
const vector=(a,b)=>a.forEach((v,i)=>near(v,b[i]));
test('294 independent Julia references, including rotated and near-surface targets',()=>{
  const [head,...lines]=readFileSync(new URL('../reference.csv',import.meta.url),'utf8').trim().split(/\r?\n/),keys=head.split(',');assert.equal(lines.length,294);const cases=new Set();
  for(const row of lines){const values=row.split(','),d=Object.fromEntries(keys.map((k,i)=>[k,i<2?values[i]:Number(values[i])])),p={mode:d.mode};for(const [k] of FIELDS)p[k]=d[k];const r=at(p),s=sample(p,d.s);cases.add(d.case);
    for(const k of ['q','velocity','acceleration','qstar'])vector(s[k],[1,2,3].map(i=>d[k+'_'+i]));
    for(const [k,key] of [['B','B'],['star','star'],['momentum','momentum'],['n','n'],['pt','pt'],['eta','eta']])vector(r[k],[1,2,3].map(i=>d[key+'_'+i]));
    for(const k of ['J','Jmin','gap','tangent','residual','lambda','boundary','interior','total'])near(r[k],d[k]);
  }assert.equal(cases.size,14);
});
test('minimum normality, surface membership and global lower bound',()=>{
  for(const mode of ['plane','sphere','ellipsoid'])for(const tilt of [0,33,75]){
    const p={...DEFAULTS,mode,tilt,yaw:-70,offset:.3},r=at(p),m=at(minimizer(p));near(m.J,r.Jmin);near(m.tangent,0);assert.equal(m.minimum,true);near(dot(r.eta,r.n),0);near(norm(r.eta),1);
    const f=frame(p),b=local(f,sub(m.B,f.C)),axes=mode==='sphere'?[p.radius,p.radius,p.radius]:[p.rx,p.ry,p.rz];near(mode==='plane'?b[2]:b.reduce((s,v,i)=>s+(v/axes[i])**2,0)-1,0);
    for(let a=-160;a<=160;a+=40)for(let b=-70;b<=70;b+=35){const point=surface(p,mode==='plane'?a/30:a,mode==='plane'?b/30:b);assert.ok(norm(sub(point,r.A))**2/(2*p.T)>=r.Jmin-1e-9);}
  }
});
test('ellipsoid known normal rays, rather than radial projection',()=>{
  for(const lon of [-160,-40,45,140])for(const lat of [-65,20,75]){
    const p={...DEFAULTS,mode:'ellipsoid',tilt:53,yaw:-74,rx:.6,ry:2.2,rz:1.3,lon,lat},r=at(p),A=r.B.map((v,i)=>v+2.1*r.n[i]);vector(closest({...p,ax:A[0],ay:A[1],az:A[2]}),r.B);
  }assert.ok(norm(cross(at({...DEFAULTS,mode:'ellipsoid'}).n,sub(at({...DEFAULTS,mode:'ellipsoid'}).B,frame(DEFAULTS).C)))>.1);
});
test('exact energy by quadrature; full first variation and bend penalty',()=>{
  for(const mode of ['plane','sphere','ellipsoid']){
    const p={...DEFAULTS,mode,bend:.61,psi:57},r=at(p),n=1000;let energy=0;for(let i=0;i<n;i++){const d=sample(p,(i+.5)/n);energy+=dot(d.velocity,d.velocity)*p.T/(2*n);}near(energy,r.J);near(r.boundary+r.interior,r.total);near(r.J-at({...p,bend:0}).J,Math.PI**2*p.bend**2/(4*p.T));
    const delta=sub(r.B,r.A),epsilon=1e-5,E=e=>dot(delta.map((v,i)=>v+e*r.eta[i]),delta.map((v,i)=>v+e*r.eta[i]))/(2*p.T)+r.bendCost;near((E(epsilon)-E(-epsilon))/(2*epsilon),r.total,1e-8);
    assert.ok(Math.abs(r.interior)>.01);assert.equal(r.stationary,false);
  }
});
test('zero momentum, one misleading zero direction, and far-side saddle',()=>{
  const zero=at({...DEFAULTS,ax:0,ay:0,az:0,u:0,v:0,offset:0});assert.equal(zero.minimum,true);near(zero.J,0);
  const p={...DEFAULTS},r=at(p),psi=Math.atan2(-dot(r.momentum,r.t1),dot(r.momentum,r.t2))*180/Math.PI,one=at({...p,psi});near(one.total,0);assert.ok(one.tangent>.1);assert.equal(one.stationary,false);
  const far=at({...DEFAULTS,mode:'sphere',tilt:0,yaw:0,ax:4,ay:0,az:0,lon:180,lat:0});assert.equal(far.stationary,true);assert.equal(far.minimum,false);assert.ok(far.gap>1);
  assert.ok(at(minimizer({...DEFAULTS,mode:'sphere'})).lambda<0,'incoming momentum can oppose the outward normal');
});
test('fixed-time scaling, path endpoints, invalid input and export',()=>{
  const r=at(DEFAULTS),slow=at({...DEFAULTS,T:4});near(slow.J,r.J/2);near(slow.Jmin,r.Jmin/2);vector(sample(DEFAULTS,0).q,r.A);vector(sample(DEFAULTS,1).q,r.B);
  for(const p of [{mode:'bad'},{T:0},{rx:NaN},{mode:'sphere',ax:0,ay:0,az:0},{mode:'ellipsoid',ax:0,ay:0,az:0}])assert.throws(()=>parameters(p));assert.throws(()=>sample(DEFAULTS,-.1));assert.throws(()=>curve(DEFAULTS,2));
  for(const mode of ['plane','sphere','ellipsoid']){const rows=csv({...DEFAULTS,mode}).trim().split('\n');assert.equal(rows.length,122);assert.equal(new Set(rows.map(row=>row.split(',').length)).size,1);assert.ok(!/NaN|Infinity|undefined/.test(rows.join()));}
});
