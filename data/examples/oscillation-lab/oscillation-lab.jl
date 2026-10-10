module OscillationLab
using LinearAlgebra, Printf
export parameters, scales, generator, initial, evaluate, trajectory, reference, CASES
parameters(; mode="harmonic",m=1.0,k=4.0,zeta=0.12,force=0.8,ratio=1.0,phase=0.0,x0=1.0,v0=0.0,cycles=8.0)=
    (;mode,m,k,zeta,force,ratio,phase,x0,v0,cycles)
function scales(p)
    p.mode in ("harmonic","damped","driven") || throw(ArgumentError("invalid mode"))
    for (key,lo,hi) in ((:m,.25,5),(:k,1,40),(:zeta,0,2),(:force,0,4),(:ratio,.1,3),(:phase,-180,180),(:x0,-1.5,1.5),(:v0,-3,3),(:cycles,2,12))
        v=getproperty(p,key)
        isfinite(v) && lo<=v<=hi || throw(ArgumentError("invalid $key"))
    end
    omega0=sqrt(p.k/p.m); period=2pi/omega0
    zeta=p.mode=="harmonic" ? 0.0 : p.zeta
    (;omega0,period,f0=1/period,zeta,c=2zeta*sqrt(p.m*p.k),omega=p.ratio*omega0,
        force=p.mode=="driven" ? p.force : 0.0,duration=p.cycles*period)
end
function generator(p)
    s=scales(p)
    A=[0.0 1 0 0; -p.k/p.m -s.c/p.m s.force/p.m 0; 0 0 0 -s.omega; 0 0 s.omega 0]
    G=zeros(22,22); G[1:4,1:4]=A
    # Julia's column-major vec convention independently constructs the lift.
    G[5:20,5:20]=kron(Matrix{Float64}(I,4,4),A)+kron(A,Matrix{Float64}(I,4,4))
    G[21,5+(2-1)+4*(2-1)]=s.c
    G[22,5+(2-1)+4*(3-1)]=s.force
    G
end
function initial(p)
    z=[p.x0,p.v0,cosd(p.phase),sind(p.phase)]
    [z;vec(z*z');0;0]
end
function unpack(p,z,t)
    s=scales(p); x,v=z[1:2]; K=.5p.m*v^2; U=.5p.k*x^2; F=s.force*z[3]
    (;t,x,v,a=(F-s.c*v-p.k*x)/p.m,K,U,E=K+U,Q=z[21],W=z[22],F,
        balance=K+U+z[21]-z[22]-(.5p.m*p.v0^2+.5p.k*p.x0^2))
end
function evaluate(p,t)
    s=scales(p)
    isfinite(t) && 0<=t<=s.duration+1e-8 || throw(ArgumentError("invalid time"))
    unpack(p,exp(generator(p)*t)*initial(p),t)
end
function trajectory(p,count=1200)
    count isa Integer && 20<=count<=4000 || throw(ArgumentError("invalid samples"))
    s=scales(p); dt=s.duration/count; step=exp(generator(p)*dt); z=initial(p)
    rows=[unpack(p,z,0.0)]
    for i in 1:count
        z=step*z; push!(rows,unpack(p,z,i*dt))
    end
    rows
end
const CASES=[
    ("release",parameters()),("kick",parameters(x0=0.0,v0=2.0)),
    ("damped",parameters(mode="damped")),("critical",parameters(mode="damped",zeta=1.0)),
    ("overdamped",parameters(mode="damped",zeta=1.6)),
    ("resonance",parameters(mode="driven",x0=0.0)),
    ("undamped",parameters(mode="driven",zeta=0.0,x0=0.0)),
    ("beats",parameters(mode="driven",zeta=.03,force=.4,ratio=.85)),
    ("edge",parameters(mode="driven",m=.25,k=40.0,zeta=2.0,force=4.0,ratio=3.0,phase=-180.0,x0=-1.5,v0=-3.0,cycles=12.0))
]
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,sample,mode,m,k,zeta,force,ratio,phase,x0,v0,cycles,time_s,x_m,v_m_s,a_m_s2,kinetic_J,potential_J,mechanical_J,dissipated_J,drive_work_J,drive_force_N,balance_error_J")
        for (name,p) in CASES, i in 0:80
            r=evaluate(p,scales(p).duration*i/80)
            print(io,"$name,$i,$(p.mode)")
            for v in (p.m,p.k,p.zeta,p.force,p.ratio,p.phase,p.x0,p.v0,p.cycles,r.t,r.x,r.v,r.a,r.K,r.U,r.E,r.Q,r.W,r.F,r.balance)
                @printf(io,",%.16g",v)
            end
            println(io)
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    OscillationLab.reference()
end
