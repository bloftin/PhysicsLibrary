module OnePointOscillation
using Printf
export defaults, shape, sample, pair, cases, reference
const defaults=(shape="rounded",A=.02,T=2.0,axis=1,unit="cm",level=.5,f2=4.0)
const heights=[0.,1.,0.,-1.,0.]
knots(name)=name=="uneven" ? [0.,.15,.5,.65,1.] : [0.,.25,.5,.75,1.]
slopes(name)=name=="uneven" ? [4.,0.,-4.,0.,4.] : [6.,0.,-6.,0.,6.]
function shape(name,s)
    r=mod(s,1); k=knots(name); i=min(4,searchsortedlast(k,r)); d=k[i+1]-k[i]; z=(r-k[i])/d
    if name=="triangle"
        value=(1-z)*heights[i]+z*heights[i+1]
        derivative=abs(r-.25)<1e-11 || abs(r-.75)<1e-11 ? nothing : (heights[i+1]-heights[i])/d
    else
        m=slopes(name); a,b=heights[i],heights[i+1]
        value=(2z^3-3z^2+1)*a+(z^3-2z^2+z)*d*m[i]+(-2z^3+3z^2)*b+(z^3-z^2)*d*m[i+1]
        derivative=((6z^2-6z)*a+(3z^2-4z+1)*d*m[i]+(-6z^2+6z)*b+(3z^2-2z)*d*m[i+1])/d
    end
    (;value,derivative,leg=i-1,start=heights[i])
end
function sample(p,t)
    s=t/p.T; q=shape(p.shape,s); physical=p.A*q.value; u=p.axis*physical
    velocity=p.A==0 ? 0. : isnothing(q.derivative) ? nothing : p.axis*p.A*q.derivative/p.T
    distance=p.A*(4floor(s)+q.leg+abs(q.value-q.start))
    cycles=p.A==0 ? 0 : floor(Int,s+1e-10); crossings=p.A==0 ? 0 : floor(Int,2s+1e-10)
    direction=isnothing(velocity) ? "corner" : p.A==0||abs(q.derivative)<1e-10 ? "still" : p.axis*q.derivative>0 ? "positive" : "negative"
    (;t,u,physical,velocity,distance,cycles,crossings,f=p.A==0 ? nothing : 1/p.T,period=p.A==0 ? nothing : p.T,progress=p.A==0 ? 0. : s,direction)
end
function root(name,target,a,b)
    fa=shape(name,a).value-target; fb=shape(name,b).value-target
    abs(fa)<1e-14 && return a; abs(fb)<1e-14 && return b
    x=(a+b)/2
    for _ in 1:100
        q=shape(name,x); f=q.value-target; abs(f)<1e-14 && return x
        if signbit(f)==signbit(fa); a=x; fa=f; else; b=x; end
        candidate=isnothing(q.derivative)||q.derivative==0 ? (a+b)/2 : x-f/q.derivative
        x=a<candidate<b ? candidate : (a+b)/2
    end
    x
end
function pair(p)
    p.A==0 && return nothing
    k=knots(p.shape); target=p.axis*p.level
    intervals=target>=0 ? [(0.,k[2]),(k[2],.5)] : [(.5,k[4]),(k[4],1.)]
    roots=abs(target)<1e-13 ? [0.,.5] : [root(p.shape,target,a,b) for (a,b) in intervals]
    first=sample(p,roots[1]*p.T); second=sample(p,roots[2]*p.T); repeat=sample(p,(roots[1]+1)*p.T)
    (;first,second,repeat,gap=second.t-first.t)
end
function cases()
    ["rounded_default"=>defaults,"rounded_small"=>merge(defaults,(A=.003,T=.25,level=-.9,)),
     "rounded_fast"=>merge(defaults,(T=.05,level=0.,)),"rounded_reversed"=>merge(defaults,(axis=-1,level=.6,)),
     "triangle_default"=>merge(defaults,(shape="triangle",)),"triangle_slow"=>merge(defaults,(shape="triangle",T=4.,level=-.7,)),
     "triangle_fast"=>merge(defaults,(shape="triangle",T=.05,level=0.,)),"triangle_reversed"=>merge(defaults,(shape="triangle",axis=-1,level=-.4,)),
     "uneven_default"=>merge(defaults,(shape="uneven",)),"uneven_slow"=>merge(defaults,(shape="uneven",T=3.2,A=.04,level=-.9,)),
     "uneven_reversed"=>merge(defaults,(shape="uneven",T=.4,axis=-1,level=.7,)),"zero"=>merge(defaults,(A=0.,))]
end
fmt(x)=isnothing(x) ? "" : x isa AbstractString ? x : @sprintf("%.17g",x)
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,shape,A,T,axis,unit,level,f2,t,u,physical,velocity,distance,cycles,crossings,f,period,progress,direction")
        for (name,p) in cases(),i in 0:300
            d=sample(p,3p.T*i/300)
            println(io,join(fmt.([name,p.shape,p.A,p.T,p.axis,p.unit,p.level,p.f2,d.t,d.u,d.physical,d.velocity,d.distance,d.cycles,d.crossings,d.f,d.period,d.progress,d.direction]),","))
        end
    end
    open(joinpath(folder,"crossings.csv"),"w") do io
        println(io,"case,defined,t1,t2,t_repeat,u1,u2,u_repeat,v1,v2,v_repeat,gap")
        for (name,p) in cases()
            q=pair(p)
            println(io,isnothing(q) ? name*",0,,,,,,,,,," : join(fmt.([name,1,q.first.t,q.second.t,q.repeat.t,q.first.u,q.second.u,q.repeat.u,q.first.velocity,q.second.velocity,q.repeat.velocity,q.gap]),","))
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    OnePointOscillation.reference(); println("Wrote 3612 path samples and 12 crossing cases.")
end
