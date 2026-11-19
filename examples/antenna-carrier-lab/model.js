export const C0=299792458,EPS0=8.8541878188e-12,ETA=1/(EPS0*C0),E_CHARGE=1.602176634e-19;
export const CAP=10e-12,DENSITY=8.5e28,AREA=1e-6;
export const PRESETS={aligned:'Aligned receiver',crossed:'Cross-polarized receiver',oblique:'Oblique arrival',axial:'Arrival along antenna axis',detuned:'Detuned receiver',untuned:'Without tuning coil',lossless:'Lossless matched receiver',transmit:'Driven transmitter',zero:'Zero drive'};
export function preset(id='aligned'){
 if(!Object.hasOwn(PRESETS,id))throw new RangeError('Unknown preset.');
 const p={id,mode:'receive',fMHz:10,f0MHz:10,length:1,E0:1,voltage:1,theta:90,psi:0,loss:.5,load:1,source:50,tuning:true};
 if(id==='crossed')p.psi=90;
 if(id==='oblique'){p.theta=45;p.psi=30;}
 if(id==='axial')p.theta=0;
 if(id==='detuned')p.fMHz=10.05;
 if(id==='untuned')p.tuning=false;
 if(id==='lossless'){p.loss=0;p.load=parameters(p).rad;}
 if(id==='transmit')p.mode='transmit';
 if(id==='zero'){p.E0=0;p.voltage=0;}
 return validate(p);
}
export function validate(raw){
 const p={...raw};if(!['receive','transmit'].includes(p.mode))throw new RangeError('Unknown operating mode.');
 for(const [k,lo,hi]of [['fMHz',1,20],['f0MHz',1,20],['length',.1,1.4],['E0',0,10],['voltage',0,10],['theta',0,180],['psi',0,180],['loss',0,10],['load',.000001,1000],['source',0,1000]])if(!Number.isFinite(p[k])||p[k]<lo||p[k]>hi)throw new RangeError(k+' must be between '+lo+' and '+hi+'.');
 if(typeof p.tuning!=='boolean')throw new RangeError('Tuning must be on or off.');return p;
}
export function geometry(p){
 const t=p.theta*Math.PI/180,b=p.psi*Math.PI/180;
 const clean=x=>Math.abs(x)<1e-14?0:x;
 return {n:[clean(Math.sin(t)),0,clean(Math.cos(t))],e:[clean(-Math.cos(t)*Math.cos(b)),clean(Math.sin(b)),clean(Math.sin(t)*Math.cos(b))],projection:clean(Math.sin(t)*Math.cos(b))};
}
export function parameters(p){
 const f=p.fMHz*1e6,w=2*Math.PI*f,lambda=C0/f,heff=p.length/2,k=2*Math.PI/lambda;
 const rad=ETA*k*k*heff*heff/(6*Math.PI),ra=rad+p.loss,L=p.tuning?1/((2*Math.PI*p.f0MHz*1e6)**2*CAP):0,X=w*L-1/(w*CAP);
 const g=geometry(p),drive=p.mode==='receive'?p.E0*heff*g.projection:p.voltage,termination=p.mode==='receive'?p.load:p.source,R=ra+termination,den=R*R+X*X;
 const ir=drive*R/den,ii=-drive*X/den,peak=Math.hypot(ir,ii),phase=peak?Math.atan2(ii,ir):0,i2=peak*peak/2;
 const flux=p.E0*p.E0/(2*ETA),available=(p.E0*heff*g.projection)**2/(8*ra),efficiency=rad/ra;
 return {f,w,lambda,heff,k,rad,ra,L,X,R,drive,termination,ir,ii,peak,phase,qPeak:peak/w,driftPeak:peak/(DENSITY*E_CHARGE*AREA),excursion:peak/(w*DENSITY*E_CHARGE*AREA),flux,available,efficiency,aperture:ETA*heff*heff*g.projection*g.projection/(4*ra),loadPower:i2*p.load,heat:i2*p.loss,radiated:i2*rad,terminationPower:i2*termination,supplied:drive*ir/2,g};
}
export function state(p,cycles=0){
 const m=parameters(p),a=2*Math.PI*cycles,c=Math.cos(a),s=Math.sin(a),current=m.ir*c-m.ii*s,charge=(m.ir*s+m.ii*c)/m.w,di=m.w*(-m.ir*s-m.ii*c),drive=m.drive*c;
 return {current,charge,di,drive,terminal:current*m.termination,displacement:-charge/(DENSITY*E_CHARGE*AREA),velocity:-current/(DENSITY*E_CHARGE*AREA),uC:charge*charge/(2*CAP),uL:m.L*current*current/2,loadInstant:current*current*m.termination};
}
export function local(p,cycles,zFraction){
 if(!Number.isFinite(zFraction)||Math.abs(zFraction)>.5)throw new RangeError('Position is outside the wire.');
 const s=state(p,cycles),shape=1-2*Math.abs(zFraction);
 return {current:s.current*shape,displacement:s.displacement*shape,velocity:s.velocity*shape,lineCharge:zFraction===0?0:Math.sign(zFraction)*2*s.charge/p.length};
}
export function incident(p,cycles,rLambda=[0,0,0]){
 const g=geometry(p),phase=2*Math.PI*(cycles-g.n.reduce((s,n,i)=>s+n*rLambda[i],0)),amplitude=p.E0*Math.cos(phase),e=g.e.map(x=>x*amplitude),n=g.n;
 const b=[n[1]*e[2]-n[2]*e[1],n[2]*e[0]-n[0]*e[2],n[0]*e[1]-n[1]*e[0]].map(x=>x/C0);
 return {e,b,flux:amplitude*amplitude/ETA,n};
}
export function farField(p,cycles,rLambda=3,theta=90){
 if(!Number.isFinite(rLambda)||rLambda<2||!Number.isFinite(theta)||theta<0||theta>180)throw new RangeError('Far-field radius >=2 wavelengths; angle 0 to 180 degrees.');
 const m=parameters(p),r=rLambda*m.lambda,t=theta*Math.PI/180,st=Math.abs(Math.sin(t))<1e-14?0:Math.sin(t),scale=ETA*m.k*m.heff*st/(4*Math.PI*r),a=2*Math.PI*(cycles-rLambda);
 // e_theta component, phasor exp(+j omega t), outgoing exp(-jkr).
 const eTheta=scale*(-m.ii*Math.cos(a)-m.ir*Math.sin(a)),peak=scale*m.peak;
 return {eTheta,bPhi:eTheta/C0,flux:eTheta*eTheta/ETA,average:peak*peak/(2*ETA),peak,r};
}
export function tuneAndMatch(raw){const p=validate({...raw,f0MHz:raw.fMHz,tuning:true});p.load=parameters(p).ra;return validate(p);}
export function sweep(p,count=241){
 const m=parameters(p),bw=p.tuning?m.R/(2*Math.PI*m.L):p.f0MHz*1e6/8,center=p.f0MHz,half=p.tuning?5*bw/1e6:.45*center;
 const lo=Math.max(1,center-half),hi=Math.min(20,center+half);
 return Array.from({length:count},(_,i)=>{const fMHz=lo+(hi-lo)*i/(count-1),s=parameters({...p,fMHz});return{fMHz,power:p.mode==='receive'?s.terminationPower:s.radiated,current:s.peak};});
}
export function csv(p){
 const rows=['cycles,time_s,drive_V,current_A,charge_upper_C,electron_displacement_center_m,electron_velocity_center_m_s,terminal_V,U_C_J,U_L_J,Etheta_at_3lambda_broadside_V_m,S_far_W_m2'];
 for(let i=0;i<=240;i++){const cycles=i/120,s=state(p,cycles),f=farField(p,cycles);rows.push([cycles,cycles/(p.fMHz*1e6),s.drive,s.current,s.charge,s.displacement,s.velocity,s.terminal,s.uC,s.uL,f.eTheta,f.flux].join(','));}
 return rows.join('\n')+'\n';
}
