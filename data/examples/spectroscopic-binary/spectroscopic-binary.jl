module SpectroscopicBinary
using Printf
export parameters, elements, state, line_shape, spectrum, companion_mass, reference
const MU_SUN=1.3271244e11
const DAY=86400.0
const AU=149597870.7
const C=299792.458
const REST=500.0
const FWHM=2sqrt(2log(2))
parameters(;m1=1.2,q=.7,period=12.0,i=65.0,e=.15,w=45.0,gamma=20.0,light=.55,width=12.0,resolution=60000.0,sb2=true)=
    (;m1,q,period,i,e,w,gamma,light,width,resolution,sb2)
function elements(p)
    all(isfinite, (p.m1,p.q,p.period,p.i,p.e,p.w,p.gamma,p.light,p.width,p.resolution)) || throw(ArgumentError("finite parameters required"))
    p.m1>0 && p.q>0 && p.period>0 && 0<=p.i<=90 && 0<=p.e<=.8 && p.light>=0 && p.width>0 && p.resolution>=1000 || throw(ArgumentError("invalid parameters"))
    m2=p.m1*p.q; n=2pi/(p.period*DAY); a=cbrt(MU_SUN*(p.m1+m2)/n^2)
    a1=a*p.q/(1+p.q); a2=a/(1+p.q); factor=n/sqrt(1-p.e^2)
    k1=a1*factor*sind(p.i); k2=a2*factor*sind(p.i); coefficient=p.period*DAY*(1-p.e^2)^1.5/(2pi*MU_SUN)
    (;m2,n,a,a1,a2,k1,k2,f=coefficient*k1^3,m1sin=coefficient*(k1+k2)^2*k2,m2sin=coefficient*(k1+k2)^2*k1)
end
function eccentric_anomaly(e,M)
    lo=0.0; hi=2pi; M=mod(M,2pi)
    # Independent monotone bisection, not the browser's Astronomia solver.
    for _ in 1:64
        mid=(lo+hi)/2
        if mid-e*sin(mid)<M; lo=mid; else; hi=mid; end
    end
    (lo+hi)/2
end
function state(p,phase)
    el=elements(p); E=eccentric_anomaly(p.e,2pi*phase)
    x=cos(E)-p.e; y=sqrt(1-p.e^2)*sin(E)
    factor=el.n*el.a/(1-p.e*cos(E)); vx=-factor*sin(E); vy=factor*sqrt(1-p.e^2)*cos(E)
    # Rx(i) Rz(w); Earth lies at +Z, positive RV is recession.
    rotate(x,y)=[x*cosd(p.w)-y*sind(p.w),(x*sind(p.w)+y*cosd(p.w))*cosd(p.i),(x*sind(p.w)+y*cosd(p.w))*sind(p.i)]
    r=rotate(x,y); v=rotate(vx,vy); f1=-p.q/(1+p.q); f2=1/(1+p.q)
    r1=f1*r; r2=f2*r; v1=f1*v; v2=f2*v
    (;el...,r1,r2,v1,v2,rv1=p.gamma-v1[3],rv2=p.gamma-v2[3])
end
function line_shape(p)
    intrinsic=p.width/FWHM; sigma=hypot(intrinsic,C/(p.resolution*FWHM))
    (;sigma,depth=.65*intrinsic/sigma)
end
function spectrum(p,velocity,v=state(p,0))
    shape=line_shape(p)
    a=shape.depth/(1+p.light)*exp(-.5*((velocity-v.rv1)/shape.sigma)^2)
    b=p.sb2 ? shape.depth*p.light/(1+p.light)*exp(-.5*((velocity-v.rv2)/shape.sigma)^2) : 0.0
    (;combined=1-a-b,component1=1-a,component2=1-b)
end
function companion_mass(f,m1,i=90.0)
    isfinite(f) && f>=0 && isfinite(m1) && m1>0 && isfinite(i) && 0<i<=90 || throw(ArgumentError("invalid mass hypothesis"))
    f==0 && return 0.0
    equation(m)=m^3*sind(i)^3/(m1+m)^2-f
    lo=0.0; hi=max(m1,2f/sind(i)^3)
    while equation(hi)<0; hi*=2; end
    for _ in 1:80
        mid=(lo+hi)/2
        if equation(mid)<0; lo=mid; else; hi=mid; end
    end
    (lo+hi)/2
end
const CASES=[
    ("unequal",parameters()),
    ("twins",parameters(m1=1.0,q=1.0,i=80.0,e=0.0,w=0.0,gamma=0.0,light=1.0)),
    ("eccentric",parameters(q=.55,period=35.0,i=70.0,e=.65,w=45.0,light=.45)),
    ("faceon",parameters(i=0.0,e=.3)),
    ("sb1",parameters(q=.6,period=20.0,i=60.0,e=.3,w=120.0,gamma=-15.0,light=.15,sb2=false)),
    ("blended",parameters(q=1.0,e=0.0,w=0.0,gamma=0.0,light=1.0,resolution=3000.0)),
    ("stress",parameters(m1=5.0,q=3.0,period=3.0,i=90.0,e=.8,w=277.0,gamma=-100.0,light=2.0,width=60.0,resolution=150000.0))
]
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,m1,q,period,i,e,w,gamma,light,width,resolution,sb2,phase,k1,k2,f,m1sin,m2sin,a,r1x,r1y,r1z,r2x,r2y,r2z,v1x,v1y,v1z,v2x,v2y,v2z,rv1,rv2")
        for (name,p) in CASES, phase in range(0,1,length=145)
            v=state(p,phase); values=(p.m1,p.q,p.period,p.i,p.e,p.w,p.gamma,p.light,p.width,p.resolution,Int(p.sb2),phase,v.k1,v.k2,v.f,v.m1sin,v.m2sin,v.a,v.r1...,v.r2...,v.v1...,v.v2...,v.rv1,v.rv2)
            println(io,name,",",join((@sprintf("%.16g",x) for x in values),","))
        end
    end
    open(joinpath(folder,"spectrum-reference.csv"),"w") do io
        println(io,"case,phase,velocity,lambda,combined,component1,component2")
        for (name,p) in CASES, phase in (0.0,.07,.25,.5,.8,1.0)
            v=state(p,phase)
            for velocity in range(-450,450,length=181)
                s=spectrum(p,velocity,v)
                println(io,name,",",join((@sprintf("%.16g",x) for x in (phase,velocity,REST*(1+velocity/C),s.combined,s.component1,s.component2)),","))
            end
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    SpectroscopicBinary.reference()
    println("Generated independent Julia orbital and spectrum references")
end
