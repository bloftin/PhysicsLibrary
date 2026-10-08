module EMFieldLab
using LinearAlgebra, Printf
export parameters, basis, scales, evaluate, physical, probes, reference
const C=299792458.0
parameters(;amplitude=5.0,frequency=100.0,theta=0.0,phi=0.0,beta=0.0,phase=0.0,x=0.0,y=0.0,z=0.0,spacing=.25,slice=0.0)=
    (;amplitude,frequency,theta,phi,beta,phase,x,y,z,spacing,slice)
function scales(p)
    all(isfinite,values(p)) || throw(ArgumentError("finite parameters required"))
    0<=p.amplitude<=10 && 10<=p.frequency<=2000 && 0<=p.theta<=180 && 0<=p.spacing<=1 && max(abs(p.x),abs(p.y),abs(p.z))<=.5 && abs(p.slice)<=1.1 || throw(ArgumentError("invalid parameters"))
    f=p.frequency*1e6
    (;f,lambda=C/f,period=1/f,k=2pi*f/C,omega=2pi*f)
end
function basis(p)
    # Independent rotation-matrix construction of the spherical transverse frame.
    Ry=[cosd(p.theta) 0 sind(p.theta); 0 1 0; -sind(p.theta) 0 cosd(p.theta)]
    Rz=[cosd(p.phi) -sind(p.phi) 0; sind(p.phi) cosd(p.phi) 0; 0 0 1]
    R=Rz*Ry
    (;n=R[:,3],e=R[:,1]*cosd(p.beta)+R[:,2]*sind(p.beta))
end
function evaluate(p,r,time)
    frame=basis(p)
    psi=p.amplitude*cospi(2(dot(frame.n,r)-time)+p.phase/180)
    (;psi,E=frame.e*psi,magnitude=abs(psi))
end
function physical(p,r_metres,time_seconds)
    s=scales(p)
    evaluate(p,r_metres/s.lambda,time_seconds/s.period)
end
function probes(p)
    a=[p.x,p.y,p.z]
    (;a,b=a+p.spacing*basis(p).n)
end
const CASES=[
    ("article",parameters()),
    ("reverse",parameters(theta=180.0,beta=180.0)),
    ("oblique",parameters(theta=55.0,phi=35.0,beta=25.0,x=.2,y=-.2,z=.1)),
    ("rotated",parameters(beta=90.0)),
    ("gps",parameters(frequency=1575.42)),
    ("zero",parameters(amplitude=0.0)),
    ("edge",parameters(amplitude=10.0,frequency=2000.0,theta=132.0,phi=300.0,beta=175.0,phase=330.0,x=.5,y=-.5,z=.5,spacing=1.0,slice=-1.1))
]
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,sample,amplitude,frequency,theta,phi,beta,phase,x,y,z,spacing,slice,time,rx,ry,rz,psi,ex,ey,ez,magnitude,nx,ny,nz,ux,uy,uz,lambda,period")
        for (name,p) in CASES, time in range(0,2,length=65)
            points=probes(p); frame=basis(p); s=scales(p)
            for (label,r) in (("A",points.a),("B",points.b),("off_axis",[.37,-.41,.73]),("slice",[-.4,.6,p.slice]))
                v=evaluate(p,r,time)
                values=(p.amplitude,p.frequency,p.theta,p.phi,p.beta,p.phase,p.x,p.y,p.z,p.spacing,p.slice,time,r...,v.psi,v.E...,v.magnitude,frame.n...,frame.e...,s.lambda,s.period)
                println(io,name,",",label,",",join((@sprintf("%.16g",x) for x in values),","))
            end
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    EMFieldLab.reference()
    println("Generated 1,820 independent Julia field reference samples")
end
