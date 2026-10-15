module ConstrainedVariations
using Printf
export parameters, state, density, reference, CASES
parameters(;mode="mean",mean=.5,b=.6,norm=1.,angle=35.,lambda=-6.)=(;mode,mean,b,norm,angle,lambda)
function state(p)
    p.mode in ("mean","normalization") || throw(ArgumentError("invalid mode"))
    for (v,lo,hi) in ((p.mean,-1,1),(p.b,-1,1),(p.norm,.25,2),(p.angle,0,360),(p.lambda,-16,16))
        isfinite(v) && lo<=v<=hi || throw(ArgumentError("invalid parameter"))
    end
    if p.mode=="mean"
        a,b=p.mean,p.b;J=6a^2+18b^2/5;K=a;ja,jb=12a,36b/5;ka,kb=1.,0.;ta,tb=0.,1.;fit=-12a;resL2=hypot(12a+p.lambda,sqrt(432)*b);L=1.
    else
        r=sqrt(p.norm);a,b=r*cosd(p.angle),r*sind(p.angle);J=a^2+4b^2;K=a^2+b^2;ja,jb=2a,8b;ka,kb=2a,2b;ta,tb=-b/r,a/r;fit=-J/K;resL2=2hypot((1+p.lambda)*a,(4+p.lambda)*b);L=pi
    end
    ra,rb=ja+p.lambda*ka,jb+p.lambda*kb
    (;a,b,J,K,ja,jb,ka,kb,ta,tb,fit,resL2,L,ra,rb,dJ=ja*ta+jb*tb,dK=ka*ta+kb*tb)
end
function density(p,x)
    r=state(p);0<=x<=r.L+1e-12 || throw(ArgumentError("invalid x"))
    if p.mode=="mean"
        p0,p1=6x*(1-x),6x*(1-x)*(2x-1);dp0,dp1=6-12x,-36x^2+36x-6
        gJ=12r.a+36r.b*(2x-1)
    else
        c=sqrt(2/pi);p0,p1=c*sin(x),c*sin(2x);dp0,dp1=c*cos(x),2c*cos(2x);gJ=2r.a*p0+8r.b*p1
    end
    y=r.a*p0+r.b*p1;yp=r.a*dp0+r.b*dp1;eta=r.ta*p0+r.tb*p1;etap=r.ta*dp0+r.tb*dp1;gK=p.mode=="mean" ? 1. : 2y
    (;x,y,yp,eta,etap,gJ,gK,scaledK=-p.lambda*gK,residual=gJ+p.lambda*gK)
end
const CASES=[
    ("mean_trial",parameters()),("mean_min",parameters(b=0.)),("mean_wrong_lambda",parameters(b=0.,lambda=0.)),
    ("mean_negative",parameters(mean=-.5,b=0.,lambda=6.)),("mean_zero",parameters(mean=0.,b=0.,lambda=0.)),
    ("mean_edge",parameters(mean=1.,b=1.,lambda=-12.)),("mean_skew",parameters(mean=0.,b=-1.,lambda=4.)),
    ("norm_trial",parameters(mode="normalization",lambda=-2.)),("norm_min",parameters(mode="normalization",angle=0.,lambda=-1.)),
    ("norm_mode2",parameters(mode="normalization",angle=90.,lambda=-4.)),("norm_wrong_lambda",parameters(mode="normalization",angle=90.,lambda=1.)),
    ("norm_large",parameters(mode="normalization",norm=2.,angle=225.,lambda=-2.5)),
    ("norm_small",parameters(mode="normalization",norm=.25,angle=315.,lambda=-2.5)),("norm_wrap",parameters(mode="normalization",angle=360.,lambda=-1.))]
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,mode,mean,b_input,norm,angle,lambda,x,y,y_prime,eta,eta_prime,gJ,gK,minus_lambda_gK,residual,a,b,J,K,ja,jb,ka,kb,ta,tb,lambda_fit,residual_L2,deltaJ,deltaK")
        for (name,p) in CASES, i in 0:40
            r=state(p);d=density(p,r.L*i/40);print(io,"$name,$(p.mode)")
            for v in (p.mean,p.b,p.norm,p.angle,p.lambda,d.x,d.y,d.yp,d.eta,d.etap,d.gJ,d.gK,d.scaledK,d.residual,r.a,r.b,r.J,r.K,r.ja,r.jb,r.ka,r.kb,r.ta,r.tb,r.fit,r.resL2,r.dJ,r.dK)
                @printf(io,",%.16g",v)
            end
            println(io)
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    ConstrainedVariations.reference()
end
