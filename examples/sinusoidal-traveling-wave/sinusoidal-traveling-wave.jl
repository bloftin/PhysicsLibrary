module SinusoidalTravelingWave
using Printf
export parameters,preset,cases,sample,crest,metrics,reference
parameters(;A=.03,lambda=1.,f=1.,phi=0.,direction=1,form="cos",probe=.65)=(;A,lambda,f,phi,direction,form,probe)
function preset(id="explore")
    p=parameters(); t=.15
    if id=="example1";p=parameters(lambda=.5,f=5.,phi=pi/6,probe=.75);t=0.
    elseif id=="example2";p=parameters(A=.02,lambda=2.,phi=pi/3,probe=1.);t=.25
    elseif id=="left";p=parameters(direction=-1,phi=pi/6)
    elseif id=="sine";p=parameters(form="sin",phi=pi/2)
    elseif id=="zero";p=parameters(A=0.)
    elseif id!="explore";throw(ArgumentError("Unknown example"))
    end
    (;p,t)
end
function sample(p,x,t)
    cycles=2x/p.lambda-2p.direction*p.f*t+p.phi/pi
    z=cispi(cycles)
    (;x,t,theta=pi*cycles,u=p.A*(p.form=="cos" ? real(z) : imag(z)))
end
metrics(p)=(k=2pi/p.lambda,omega=2pi*p.f,T=1/p.f)
function crest(p,t)
    p.A==0 && return nothing
    base=p.form=="cos" ? 0. : .5
    # floor(x+.5) matches the browser's nearest-integer tie convention.
    order=floor(Int,(2/p.lambda+p.phi/pi-base)/2+.5)
    p.lambda*(base+2order+2p.direction*p.f*t-p.phi/pi)/2
end
function cases()
    result=[id=>preset(id) for id in ("explore","example1","example2","left","sine","zero")]
    push!(result,"short_fast"=>(p=parameters(A=.05,lambda=.25,f=5.,phi=-pi,direction=-1,probe=2.),t=.4))
    push!(result,"long_slow"=>(p=parameters(A=.001,lambda=2.,f=.5,phi=pi,form="sin",probe=0.),t=2.))
    result
end
fmt(x)=isnothing(x) ? "" : x isa AbstractString ? x : @sprintf("%.17g",x)
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,A_m,lambda_m,f_Hz,phi_rad,direction,form,probe_m,x_m,t_s,u_m,phase_rad,crest_x_m")
        for (name,c) in cases(),j in 0:20,i in 0:16
            p=c.p;d=sample(p,2i/16,2j/20)
            println(io,join(fmt.([name,p.A,p.lambda,p.f,p.phi,p.direction,p.form,p.probe,d.x,d.t,d.u,d.theta,crest(p,d.t)]),","))
        end
    end
    open(joinpath(folder,"events.csv"),"w") do io
        println(io,"case,x_m,t_s,u_m,phase_rad,k_rad_per_m,omega_rad_per_s,lambda_m,T_s,f_Hz")
        for (name,c) in cases()
            p=c.p;d=sample(p,p.probe,c.t);m=metrics(p)
            println(io,join(fmt.([name,d.x,d.t,d.u,d.theta,m.k,m.omega,p.lambda,m.T,p.f]),","))
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    SinusoidalTravelingWave.reference()
end
