module SinusoidalOscillation
using Printf
export parameters, preset, sample, metrics, cases, reference

parameters(; A=.03, f=1., phi=0., form="cos") = (; A, f, phi, form)
metrics(p) = (T=1/p.f, omega=2pi*p.f)
function sample(p, t)
    # Independent complex-exponential reference; the browser uses direct trig.
    z = cispi(2p.f*t + p.phi/pi)
    omega = 2pi*p.f
    u, slope = p.form == "cos" ? (p.A*real(z), -p.A*omega*imag(z)) : (p.A*imag(z), p.A*omega*real(z))
    (; t, theta=pi*(2p.f*t+p.phi/pi), c=real(z), s=imag(z), u, slope)
end
function preset(id="explore")
    p=parameters(); t=.125
    if id=="example1"; p=parameters(A=.04,f=2.); t=0.
    elseif id=="example2"; p=parameters(A=.006,f=2.5,phi=pi/2); t=0.
    elseif id=="rising"; p=parameters(phi=-pi/2); t=0.
    elseif id=="falling"; p=parameters(phi=pi/2); t=0.
    elseif id=="sine"; p=parameters(form="sin",phi=pi/2)
    elseif id=="zero"; p=parameters(A=0.)
    elseif id!="explore"; throw(ArgumentError("Unknown preset"))
    end
    (; p,t)
end
function cases()
    result=[id=>preset(id) for id in ("explore","example1","example2","rising","falling","sine","zero")]
    push!(result,"fast_negative"=>(p=parameters(A=.05,f=4.,phi=-pi),t=.125))
    push!(result,"slow_sine"=>(p=parameters(A=.001,f=.25,phi=pi,form="sin"),t=4.))
    result
end
fmt(x)=x isa AbstractString ? x : @sprintf("%.17g",x)
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,A_m,f_Hz,phi_rad,form,t_s,phase_rad,cos_phase,sin_phase,u_m,du_dt_m_per_s")
        for (name,c) in cases(), i in 0:160
            p=c.p; d=sample(p,4i/160)
            println(io,join(fmt.([name,p.A,p.f,p.phi,p.form,d.t,d.theta,d.c,d.s,d.u,d.slope]),","))
        end
    end
    open(joinpath(folder,"events.csv"),"w") do io
        println(io,"case,t_s,u_m,phase_rad,du_dt_m_per_s,T_s,omega_rad_per_s")
        for (name,c) in cases()
            d=sample(c.p,c.t); m=metrics(c.p)
            println(io,join(fmt.([name,c.t,d.u,d.theta,d.slope,m.T,m.omega]),","))
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    SinusoidalOscillation.reference()
end
