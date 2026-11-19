import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {C0,EPS0,ETA,E_CHARGE,CAP,DENSITY,AREA,PRESETS,preset,validate,parameters,state,local,geometry,incident,farField,tuneAndMatch,sweep,csv} from '../model.js';
const near=(a,b,abs=1e-12,rel=1e-9)=>assert.ok(Math.abs(a-b)<=abs+rel*Math.max(Math.abs(a),Math.abs(b)),`${a} versus ${b}`);
function rows(file){const[header,...lines]=readFileSync(new URL('../'+file,import.meta.url),'utf8').trim().split('\n'),keys=header.split(',');return lines.map(l=>Object.fromEntries(l.split(',').map((x,i)=>[keys[i],i?Number(x):x])));}
test('1161 independent Julia waveforms and nine parameter references',()=>{
 for(const r of rows('parameters.csv')){const m=parameters(preset(r.case));for(const [key,value]of Object.entries({lambda_m:m.lambda,heff_m:m.heff,Rrad_ohm:m.rad,reactance_ohm:m.X,I_peak_A:m.peak,q_peak_C:m.qPeak,P_input_W:m.supplied,P_term_W:m.terminationPower,P_heat_W:m.heat,P_rad_W:m.radiated,excursion_m:m.excursion,aperture_m2:m.aperture}))near(value,r[key],key==='reactance_ohm'?1e-10:1e-25);}
 for(const r of rows('reference.csv')){const p=preset(r.case),m=parameters(p),s=state(p,r.cycles),f=farField(p,r.cycles,3.25,60),scales={drive_V:Math.abs(m.drive),current_A:m.peak,q_upper_C:m.qPeak,terminal_V:m.peak*m.termination,electron_displacement_m:m.excursion,electron_velocity_m_s:m.driftPeak,U_C_J:m.qPeak**2/(2*CAP),U_L_J:m.L*m.peak**2/2,Etheta_V_m:f.peak,Bphi_T:f.peak/C0,S_W_m2:f.peak**2/ETA,S_average_W_m2:f.average};for(const [key,value]of Object.entries({drive_V:s.drive,current_A:s.current,q_upper_C:s.charge,terminal_V:s.terminal,electron_displacement_m:s.displacement,electron_velocity_m_s:s.velocity,U_C_J:s.uC,U_L_J:s.uL,Etheta_V_m:f.eTheta,Bphi_T:f.bPhi,S_W_m2:f.flux,S_average_W_m2:f.average}))near(value,r[key],2e-12*Math.max(scales[key],1e-30));}
});
test('charge continuity, opposite electron drift and triangular spatial current',()=>{
 for(const id of ['aligned','oblique','detuned','untuned','transmit']){const p=preset(id),m=parameters(p),h=1e-5;for(const t of [.07,.2,.46]){const s=state(p,t),dq=(state(p,t+h).charge-state(p,t-h).charge)/(2*h/m.f);near(dq,s.current,1e-12,1e-8);near(s.velocity,-s.current/(DENSITY*E_CHARGE*AREA),1e-25);near(local(p,t,.5).current,0);near(local(p,t,0).current,s.current);for(const z of [-.3,.3]){const dz=1e-6,dl=(local(p,t+h,z).lineCharge-local(p,t-h,z).lineCharge)/(2*h/m.f),di=(local(p,t,z+dz).current-local(p,t,z-dz).current)/(2*dz*p.length);near(dl,-di,1e-10,1e-8);}}}
 const p=tuneAndMatch(preset());near(state(p,.25).current,0);near(state(p,.25).charge,parameters(p).qPeak,1e-25);
});
test('polarization and arrival projection; power follows squared field',()=>{
 for(const id of ['crossed','axial','zero'])assert.equal(parameters(preset(id)).peak,0);
 const p=preset(),base=parameters(p);near(parameters({...p,psi:60}).supplied,base.supplied/4);near(parameters({...p,theta:30}).supplied,base.supplied/4);near(parameters({...p,E0:2}).supplied,base.supplied*4);
 const reverse=parameters({...p,psi:180});near(reverse.supplied,base.supplied);near(reverse.ir,-base.ir);for(const theta of [0,35,90,180])for(const psi of [0,45,90,180]){const g=geometry({...p,theta,psi});near(Math.hypot(...g.n),1);near(Math.hypot(...g.e),1);near(g.n.reduce((s,x,i)=>s+x*g.e[i],0),0);}
});
test('average energy, conjugate match, efficiency and effective-aperture reciprocity',()=>{
 for(const id of Object.keys(PRESETS)){const p=preset(id),m=parameters(p);near(m.supplied,m.heat+m.radiated+m.terminationPower);const area=1.5*m.efficiency*m.g.projection**2*m.lambda**2/(4*Math.PI);near(m.aperture,area);near(m.available,m.flux*m.aperture);}
 const p=tuneAndMatch(preset('detuned')),m=parameters(p);near(m.X,0,1e-10);near(m.terminationPower,m.available);assert.ok(m.terminationPower>parameters({...p,load:p.load*2}).terminationPower);
 const lossless=parameters(preset('lossless'));near(lossless.radiated,lossless.terminationPower);near(lossless.efficiency,1);
 const tiny=tuneAndMatch({...preset(),length:.1,fMHz:1,loss:0});assert.ok(tiny.load<.001&&tiny.load>.000001);near(parameters(tiny).terminationPower,parameters(tiny).available);
});
test('transverse E/B, outward energy, retardation, inverse radius and radiation integral',()=>{
 const p=preset('transmit');assert.equal(farField(p,0,3,0).peak,0);assert.equal(farField(p,0,3,180).peak,0);
 const a=farField(p,.125,2,90),b=farField(p,1.125,3,90);near(a.eTheta*2,b.eTheta*3);near(a.average*4,b.average*9);near(a.eTheta,a.bPhi*C0);assert.ok(a.flux>=0);
 const m=parameters(p),r=3*m.lambda,n=2000;let power=0;for(let i=0;i<n;i++){const t=(i+.5)*Math.PI/n;power+=farField(p,0,3,t*180/Math.PI).average*2*Math.PI*r*r*Math.sin(t)*Math.PI/n;}near(power,m.radiated,1e-14,1e-7);
 const f=incident(preset('oblique'),.07,[.2,.3,.4]),cross=[f.e[1]*f.b[2]-f.e[2]*f.b[1],f.e[2]*f.b[0]-f.e[0]*f.b[2],f.e[0]*f.b[1]-f.e[1]*f.b[0]];for(let i=0;i<3;i++)near(cross[i]*EPS0*C0*C0,f.flux*f.n[i]);
});
test('passive series circuit identity and period invariance',()=>{
 const p=preset('detuned'),m=parameters(p);for(const t of [.02,.19,.6]){const s=state(p,t),derivative=s.charge*s.current/CAP+m.L*s.current*s.di;near(s.drive*s.current,m.R*s.current**2+derivative,1e-11);const next=state(p,t+1);near(s.current,next.current);near(s.charge,next.charge,1e-25);}
});
test('supported ranges, short-wire condition, export and response sampling',()=>{
 assert.ok(1.4/(C0/20e6)<.1);for(const changes of [{fMHz:0},{E0:NaN},{length:2},{load:0},{loss:-1},{tuning:'true'}])assert.throws(()=>validate({...preset(),...changes}));assert.throws(()=>local(preset(),0,.6));assert.throws(()=>farField(preset(),0,1));for(const id of Object.keys(PRESETS)){const p=preset(id),data=sweep(p);assert.equal(data.length,241);assert.ok(data.every(x=>Number.isFinite(x.power)&&x.fMHz>=1&&x.fMHz<=20));}assert.equal(csv(preset()).trim().split('\n').length,242);assert.ok(!/NaN|Infinity|undefined/.test(csv(preset('zero'))));
});
