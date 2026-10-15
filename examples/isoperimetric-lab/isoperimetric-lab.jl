module IsoperimetricLab
using Printf
export parameters, state, sample, reference, CASES

parameters(;mode=1,a=1.5,alpha=60.,length=8.,perimeter=12.,n=6,ratio=-.6)=(;mode,a,alpha,length,perimeter,n,ratio)
function state(p)
    p.mode in (1,3,4,6) || throw(ArgumentError("unknown exercise"))
    for (v,lo,hi) in ((p.a,.5,3),(p.alpha,15,165),(p.length,2,16),(p.perimeter,4,20),(p.n,3,60),(p.ratio,-2,1))
        isfinite(v) && lo<=v<=hi || throw(ArgumentError("invalid parameter"))
    end
    isinteger(p.n) || throw(ArgumentError("noninteger polygon"))
    p.mode==1 && p.alpha>90 && throw(ArgumentError("not a minor graph"))
    if p.mode==6
        P=p.perimeter;n=p.n;R=P/(2n*sinpi(1/n));apothem=P/(2n*tanpi(1/n));area=P*apothem/2;circle=P^2/(4pi)
        return (;R,a=0.,length=P,area,kappa=0.,lambda=0.,residual=0.,fraction=area/circle,circle,square=P^2/16,apothem,alpha=0.)
    end
    alpha=p.mode==3 ? pi/2 : deg2rad(p.alpha)
    R=p.mode==4 ? p.length/(2alpha) : p.a/sin(alpha)
    a=R*sin(alpha);L=2R*alpha;area=R^2*(alpha-sin(alpha)*cos(alpha));kappa=-1/R;lambda=(p.mode==1 ? p.ratio : -1)*R
    (;R,a,length=L,area,kappa,lambda,residual=1-lambda*kappa,fraction=area/(L^2/(2pi)),circle=0.,square=0.,apothem=0.,alpha)
end
function sample(p,u)
    -1<=u<=1 || throw(ArgumentError("invalid arc position"))
    r=state(p)
    if p.mode==6
        t=pi*u
        return (;x=r.R*cos(t),y=r.R*sin(t),tx=0.,ty=0.,nx=0.,ny=0.)
    end
    t=r.alpha*u
    (;x=r.R*sin(t),y=r.R*(cos(t)-cos(r.alpha)),tx=cos(t),ty=-sin(t),nx=sin(t),ny=cos(t))
end
const CASES=[
    ("graph_default",parameters()),("graph_matched",parameters(ratio=-1.)),
    ("graph_shallow",parameters(a=.5,alpha=15.,ratio=0.)),("graph_edge",parameters(a=3.,alpha=90.,ratio=-2.)),
    ("semicircle",parameters(mode=3)),("semicircle_large",parameters(mode=3,a=3.)),
    ("dido_minor",parameters(mode=4,alpha=35.)),("dido_max",parameters(mode=4,alpha=90.)),
    ("dido_major",parameters(mode=4,alpha=150.,length=16.)),
    ("triangle",parameters(mode=6,n=3)),("square",parameters(mode=6,n=4)),
    ("hexagon",parameters(mode=6,n=6)),("many_sides",parameters(mode=6,n=60,perimeter=20.))]
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,mode,a_input,alpha_input,length_input,perimeter_input,n,ratio,u,x,y,tx,ty,nx,ny,R,a,length,area,kappa,lambda,residual,fraction,circle,square,apothem")
        for (name,p) in CASES,i in 0:40
            u=-1+i/20;r=state(p);q=sample(p,u)
            print(io,"$name,$(p.mode)")
            for v in (p.a,p.alpha,p.length,p.perimeter,p.n,p.ratio,u,q.x,q.y,q.tx,q.ty,q.nx,q.ny,r.R,r.a,r.length,r.area,r.kappa,r.lambda,r.residual,r.fraction,r.circle,r.square,r.apothem)
                @printf(io,",%.16g",v)
            end
            println(io)
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    IsoperimetricLab.reference()
end
