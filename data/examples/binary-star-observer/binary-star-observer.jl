module BinaryObserver
using Transits, JSON, Printf
export state, flux, probability, generate, presets
const TAU = 2pi
const presets = [
    (name="twins", i=90., s=.24, k=1., j=1., e=0., w=0., q=1.),
    (name="unequal", i=87., s=.28, k=.55, j=.35, e=0., w=0., q=.65),
    (name="grazing", i=78., s=.24, k=.65, j=.55, e=0., w=0., q=.75),
    (name="missed", i=65., s=.24, k=1., j=1., e=0., w=0., q=1.),
    (name="eccentric", i=79., s=.16, k=.7, j=.45, e=.5, w=60., q=.7),
    (name="article", i=85., s=.186019, k=1., j=.7, e=0., w=0., q=1.)]

function bisect(f, a, b)
    fa = f(a)
    @assert fa*f(b) <= 0
    for _ in 1:80
        m = (a+b)/2
        if fa*f(m) > 0
            a=m
        else
            b=m
        end
    end
    (a+b)/2
end

function state(p, phase)
    M=TAU*mod(phase, 1)
    E=bisect(x -> x-p.e*sin(x)-M, 0., TAU)
    x, y = cos(E)-p.e, sqrt(1-p.e^2)*sin(E)
    w, i = deg2rad(p.w), deg2rad(p.i)
    X=x*cos(w)-y*sin(w)
    Y=(x*sin(w)+y*cos(w))*cos(i)
    Z=(x*sin(w)+y*cos(w))*sin(i)
    (x=X, y=Y, z=Z, d=hypot(X,Y))
end

function flux(p, phase; limb=false)
    v=state(p,phase)
    r1, r2 = p.s/(1+p.k), p.s*p.k/(1+p.k)
    f1, f2 = r1^2, p.j*r2^2
    law=limb ? QuadLimbDark([.4,.25]) : QuadLimbDark([0.,0.])
    # Only the more distant disk is occulted; both stars supply light.
    v.z >= 0 ? (f1*law(v.d/r1,p.k)+f2)/(f1+f2) :
               (f1+f2*law(v.d/r2,1/p.k))/(f1+f2)
end

function probability(p, radius=p.s)
    radius==0 && return (a=0., b=0., any=0., both=0.)
    w=deg2rad(p.w)
    S=radius/(1-p.e^2)
    f(u)=cos(u)-S^2*(1+p.e*cos(u-w))*(cos(u)+p.e*cos(w))
    function limit(lo,hi)
        u=bisect(f,lo,hi)
        r=(1-p.e^2)/(1+p.e*cos(u-w))
        sqrt(clamp(((radius/r)^2-cos(u)^2)/sin(u)^2,0,1))
    end
    a,b=limit(0.,pi),limit(pi,TAU)
    (a=a,b=b,any=max(a,b),both=min(a,b))
end

function generate()
    here=@__DIR__
    open(joinpath(here,"reference.csv"),"w") do io
        println(io,"preset,inclination,radius_sum,radius_ratio,brightness_ratio,eccentricity,omega,mass_ratio,phase,x,y,z,separation,uniform_flux,limb_flux,p_a,p_b")
        for p in presets, phase in sort(unique(vcat(collect(0:.025:1),collect(.21:.005:.29),collect(.71:.005:.79))))
            v=state(p,phase); pr=probability(p)
            @printf(io,"%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n",
                p.name,p.i,p.s,p.k,p.j,p.e,p.w,p.q,phase,v.x,v.y,v.z,v.d,flux(p,phase),flux(p,phase;limb=true),pr.a,pr.b)
        end
    end
    # Inner and outer contacts always occupy grid coordinates t=.5 and t=1.
    nk,nx=257,1025
    law=QuadLimbDark([.4,.25])
    values=Float64[]
    for ik in 0:nk-1
        k=exp(log(.25)+(log(4.)-log(.25))*ik/(nk-1))
        for ix in 0:nx-1
            t=ix/(nx-1)
            b=t<=.5 ? abs(1-k)*2t : abs(1-k)+4min(1,k)*(t-.5)
            v=law(b,k)
            @assert isfinite(v) && -.0000001 <= v <= 1.0000001
            push!(values,round(clamp(v,0,1),digits=8))
        end
    end
    open(joinpath(here,"limb-grid.json"),"w") do io
        JSON.print(io,Dict("nk"=>nk,"nx"=>nx,"kmin"=>.25,"kmax"=>4.,"u"=>[.4,.25],"values"=>values))
        println(io)
    end
    # Independent, off-grid library samples quantify browser interpolation error.
    open(joinpath(here,"limb-check.csv"),"w") do io
        println(io,"k,x,flux")
        for n in 1:2000
            k=exp(log(.25)+log(16)*mod(n*.6180339887498949,1))
            x=mod(n*.4142135623730951,1)
            @printf(io,"%.14g,%.14g,%.14g\n",k,x,law(x*(1+k),k))
        end
    end
    cp(joinpath(pkgdir(Transits),"LICENSE"),joinpath(here,"TRANSITS-LICENSE.txt");force=true)
    println("Saved Julia references and $(nk)x$(nx) limb-darkening kernel.")
end
end

if abspath(PROGRAM_FILE)==@__FILE__
    BinaryObserver.generate()
end
