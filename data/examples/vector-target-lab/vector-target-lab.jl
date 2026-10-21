module VectorTargetLab
using LinearAlgebra, Printf
export defaults, frame, surface, nearest, evaluate, sample, minimize, cases, reference

const defaults=(mode="plane",ax=-3.4,ay=-2.2,az=3.8,T=2.0,tilt=28.0,yaw=15.0,offset=0.0,radius=1.5,rx=1.8,ry=1.1,rz=1.5,u=0.8,v=0.6,lon=30.0,lat=25.0,bend=0.0,psi=20.0)
function frame(p)
    b,a=deg2rad(p.tilt),deg2rad(p.yaw)
    E=[cos(b)*cos(a) -sin(a) sin(b)*cos(a); cos(b)*sin(a) cos(a) sin(b)*sin(a); -sin(b) 0 cos(b)]
    E,p.offset*E[:,3]
end
axes(p)=p.mode=="sphere" ? fill(p.radius,3) : [p.rx,p.ry,p.rz]
function surface(p,x,y)
    E,C=frame(p)
    b=p.mode=="plane" ? [x,y,0.0] : axes(p).*[cosd(y)*cosd(x),cosd(y)*sind(x),sind(y)]
    C+E*b
end
function nearest(p)
    E,C=frame(p); a=E'*([p.ax,p.ay,p.az]-C)
    p.mode=="plane" && return C+E*[a[1],a[2],0.0]
    p.mode=="sphere" && return C+E*(p.radius*a/norm(a))
    d=axes(p).^2
    sum(a.^2 ./d)>1 || error("Start must be exterior")
    # Safeguarded Newton is independent of the browser's vendored bisection.
    lo,hi=0.0,maximum(axes(p))*norm(a); l=(lo+hi)/2
    for _ in 1:150
        f=sum(d.*a.^2 ./(d.+l).^2)-1
        abs(f)<2e-15 && break
        f>0 ? (lo=l) : (hi=l)
        derivative=-2sum(d.*a.^2 ./(d.+l).^3)
        candidate=l-f/derivative
        l=lo<candidate<hi ? candidate : (lo+hi)/2
    end
    C+E*(d.*a./(d.+l))
end
function evaluate(p=defaults)
    E,C=frame(p); A=[p.ax,p.ay,p.az]
    B=surface(p,p.mode=="plane" ? p.u : p.lon,p.mode=="plane" ? p.v : p.lat)
    star=nearest(p); delta=B-A; b=E'*(B-C)
    grad=p.mode=="plane" ? E[:,3] : E*(2b./axes(p).^2); n=grad/norm(grad)
    t1=p.mode=="plane" ? E[:,1] : normalize(cross(abs(n[3])<0.9 ? [0,0,1] : [1,0,0],n))
    t2=cross(n,t1); eta=cosd(p.psi)*t1+sind(p.psi)*t2
    momentum=delta/p.T-[0,0,pi*p.bend/p.T]; pn=dot(momentum,n)*n; pt=momentum-pn
    J=dot(delta,delta)/(2p.T)+pi^2*p.bend^2/(4p.T); Jmin=sum(abs2,star-A)/(2p.T)
    boundary=dot(momentum,eta); interior=pi*p.bend*eta[3]/p.T
    (;A,B,star,grad,n,eta,momentum,pt,J,Jmin,gap=max(0,J-Jmin),tangent=norm(pt),residual=pi^2*abs(p.bend)/(sqrt(2)*p.T^2),lambda=dot(momentum,grad)/sum(abs2,grad),boundary,interior,total=dot(delta,eta)/p.T)
end
function sample(p,s)
    r=evaluate(p); delta=r.B-r.A
    (;q=r.A+s*delta+[0,0,p.bend*sinpi(s)],velocity=delta/p.T+[0,0,pi*p.bend/p.T*cospi(s)],acceleration=[0,0,-pi^2*p.bend/p.T^2*sinpi(s)],qstar=r.A+s*(r.star-r.A))
end
function minimize(p)
    E,C=frame(p); b=E'*(nearest(p)-C)
    p.mode=="plane" && return merge(p,(u=b[1],v=b[2],bend=0.0))
    v=b./axes(p)
    merge(p,(lon=rad2deg(atan(v[2],v[1])),lat=asind(clamp(v[3],-1,1)),bend=0.0))
end
function cases()
    plane=defaults; sphere=merge(defaults,(mode="sphere",)); ellipsoid=merge(defaults,(mode="ellipsoid",))
    ["plane_trial"=>plane,"plane_bent"=>merge(plane,(bend=0.65,)),"plane_min"=>minimize(plane),
     "plane_zero"=>merge(plane,(ax=0.0,ay=0.0,az=0.0,u=0.0,v=0.0,offset=0.0)),
     "sphere_trial"=>sphere,"sphere_bent"=>merge(sphere,(bend=-0.4,T=3.1,)),"sphere_min"=>minimize(sphere),
     "sphere_pole"=>merge(sphere,(lat=90.0,)),"sphere_rotated"=>merge(sphere,(tilt=71.0,yaw=-143.0,offset=0.7,)),
     "ellipsoid_trial"=>ellipsoid,"ellipsoid_bent"=>merge(ellipsoid,(bend=0.7,)),"ellipsoid_min"=>minimize(ellipsoid),
     "ellipsoid_rotated"=>merge(ellipsoid,(tilt=73.0,yaw=121.0,offset=-0.7,rx=0.6,ry=2.4,rz=1.7,)),
     "ellipsoid_near_surface"=>merge(ellipsoid,(tilt=0.0,yaw=0.0,ax=1.81,ay=0.0,az=0.0,))]
end
const vectorfields=(:B,:star,:momentum,:n,:pt,:eta)
const scalarfields=(:J,:Jmin,:gap,:tangent,:residual,:lambda,:boundary,:interior,:total)
function reference(path=joinpath(@__DIR__,"reference.csv"))
    numeric=filter(!=(:mode),collect(keys(defaults)))
    header=["case","mode",string.(numeric)...,"s",["$(k)_$(i)" for k in (:q,:velocity,:acceleration,:qstar) for i in 1:3]...,["$(k)_$(i)" for k in vectorfields for i in 1:3]...,string.(scalarfields)...]
    open(path,"w") do io
        println(io,join(header,","))
        for (name,p) in cases(),s in range(0,1,length=21)
            r=evaluate(p); d=sample(p,s)
            numbers=[getproperty(p,k) for k in numeric]
            append!(numbers,[s]);for k in (:q,:velocity,:acceleration,:qstar);append!(numbers,getproperty(d,k));end
            for k in vectorfields;append!(numbers,getproperty(r,k));end
            append!(numbers,[getproperty(r,k) for k in scalarfields])
            println(io,join([name,p.mode,[@sprintf("%.17g",v) for v in numbers]...],","))
        end
    end
    path
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    println("Wrote ",VectorTargetLab.reference())
end
