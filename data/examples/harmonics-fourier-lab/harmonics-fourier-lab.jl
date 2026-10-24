module HarmonicsFourierLab
using Printf
export preset, signal, stats, cases, tone, writewav, reference
const MAX_N=24
function preset(id="article"; N=nothing, f0=110.0)
    a=zeros(MAX_N); b=zeros(MAX_N); dc=0.; count=3
    if id=="article"; dc=1.; a[1]=2.; b[2]=-.75; a[3]=.4
    elseif id=="single"; count=1; a[1]=1.
    elseif id=="missing"; a[2]=1.; b[3]=1.
    elseif id=="even"; count=4; a[2]=1.; b[4]=.5
    elseif id=="constant"; count=0; dc=1.
    elseif id in ("square","triangle","sawtooth")
        count=9
        for n in 1:MAX_N
            id=="square" && isodd(n) && (b[n]=4/(pi*n))
            id=="triangle" && isodd(n) && (b[n]=8*(-1)^((n-1)÷2)/(pi*n)^2)
            id=="sawtooth" && (b[n]=2*(-1)^(n+1)/(pi*n))
        end
    else; throw(ArgumentError("Unknown waveform"))
    end
    (;a,b,dc,N=isnothing(N) ? count : N,f0)
end
# Complex coefficients give an independent evaluation of the real sine/cosine sum.
signal(p,q)=p.dc+real(sum((p.a[n]-im*p.b[n])*cispi(2n*q) for n in 1:p.N;init=0.0im))
function stats(p)
    ns=[n for n in 1:p.N if hypot(p.a[n],p.b[n])>1e-10]
    divisor=foldl(gcd,ns;init=0)
    ac2=sum((p.a[n]^2+p.b[n]^2)/2 for n in ns;init=0.)
    (;divisor,period=divisor==0 ? nothing : 1/(p.f0*divisor),ac_rms=sqrt(ac2),rms=sqrt(p.dc^2+ac2))
end
function cases()
    result=[id=>preset(id) for id in ("article","square","triangle","sawtooth","single","missing","even","constant")]
    append!(result,["square_1"=>preset("square";N=1),"square_3"=>preset("square";N=3),
        "square_23"=>preset("square";N=23),"triangle_23"=>preset("triangle";N=23),
        "sawtooth_24"=>preset("sawtooth";N=24)])
    p=preset("constant";N=6,f0=220.); p.a[2]=.7cospi(.37);p.b[2]=.7sinpi(.37); p.a[6]=-.9
    push!(result,"phase_mixture"=>p)
    result
end
function tone(p;rate=48000,seconds=2.,volume=.15,selected=0)
    8000<=rate<=192000 && .1<=seconds<=10 && 0<=volume<=.3 || throw(ArgumentError("Invalid sound settings"))
    ns=[n for n in 1:p.N if n*p.f0<.45rate && (selected==0 || n==selected)]
    bound=sum(hypot(p.a[n],p.b[n]) for n in ns;init=0.)
    count=round(Int,rate*seconds)
    gain=bound==0 ? 0. : volume/bound
    [gain*max(0.,min(1.,i/rate/.025,(count-1-i)/rate/.025))*
        real(sum((p.a[n]-im*p.b[n])*cispi(2n*p.f0*i/rate) for n in ns;init=0.0im)) for i in 0:count-1]
end
function writewav(file,p;rate=48000,seconds=2.)
    samples=tone(p;rate,seconds); size=2length(samples)
    open(file,"w") do io
        write(io,"RIFF",htol(UInt32(36+size)),"WAVEfmt ",htol(UInt32(16)),
            htol(UInt16(1)),htol(UInt16(1)),htol(UInt32(rate)),htol(UInt32(2rate)),
            htol(UInt16(2)),htol(UInt16(16)),"data",htol(UInt32(size)))
        for x in samples; write(io,htol(round(Int16,32767x))); end
    end
end
fmt(x)=isnothing(x) ? "" : x isa AbstractString ? x : @sprintf("%.17g",x)
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,N,f0_Hz,A0,cycle,value,ac_rms,period_s")
        for (name,p) in cases(), i in 0:128
            q=2i/128; m=stats(p)
            println(io,join(fmt.([name,p.N,p.f0,p.dc,q,signal(p,q),m.ac_rms,m.period]),","))
        end
    end
    open(joinpath(folder,"coefficients.csv"),"w") do io
        println(io,"case,n,A_n,B_n")
        for (name,p) in cases(), n in 1:MAX_N
            println(io,join(fmt.([name,n,p.a[n],p.b[n]]),","))
        end
    end
    writewav(joinpath(folder,"julia-square.wav"),preset("square"))
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    HarmonicsFourierLab.reference()
end
