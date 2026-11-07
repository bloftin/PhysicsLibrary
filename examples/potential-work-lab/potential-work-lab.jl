module PotentialWorkLab
using Printf
export cases, environment, point, endpoints, battery, reference, E_CHARGE
const E_CHARGE=big"1.602176634e-19"
const K=setprecision(256) do
    inv(4big(pi)*big"8.8541878188e-12")
end
pt(x,y)=(x=BigFloat(x),y=BigFloat(y))
src(x,y,q)=(x=BigFloat(x),y=BigFloat(y),q=BigFloat(q)*big"1e-9")
function cases()
    result=[]
    for id in ["plates","sign","worked","electron","positive","negative","dipole","like","zero"]
        kind="uniform";voltage=BigFloat(-10);q=big"2e-9";offset=BigFloat(0)
        a=pt(-1,0);b=pt(1,0);h=pt(0,big"1.15");sources=[]
        if id=="sign";voltage=BigFloat(5);q=big"2e-6";end
        if id=="worked";voltage=BigFloat(-3);q=big"-4e-6";offset=BigFloat(5);end
        if id=="electron";voltage=BigFloat(3);q=-E_CHARGE;end
        if id in ["positive","negative","dipole","like","zero"]
            kind="points";q=big"1e-9";a=pt(big"-1.7",big"-1.1");b=pt(big"1.7",big"-1.1");h=pt(0,big".6")
            if id in ["positive","negative"]
                sources=[src(0,0,id=="positive" ? 1 : -1)];a=pt(big".6",0);b=pt(2,0);h=pt(big"1.1",big"1.5")
            elseif id!="zero"
                sources=[src(-1,0,1),src(1,0,id=="like" ? 1 : -1)]
            end
        end
        push!(result,id=>(;kind,voltage,q,offset,gap=big".05",a,b,h,sources))
    end
    result
end
function environment(p,x,y)
    if p.kind=="uniform"
        return (v=p.voltage*(x+1)/2+p.offset,ex=-p.voltage/p.gap,ey=BigFloat(0))
    end
    v=BigFloat(0);ex=BigFloat(0);ey=BigFloat(0)
    for s in p.sources
        s.q==0&&continue
        dx=x-s.x;dy=y-s.y;r=sqrt(dx^2+dy^2)
        r==0&&return nothing
        v+=K*s.q/r;ex+=K*s.q*dx/r^3;ey+=K*s.q*dy/r^3
    end
    (v=v+p.offset,ex=ex,ey=ey)
end
dist(a,b)=sqrt((a.x-b.x)^2+(a.y-b.y)^2)
function point(p,route,f)
    vs=route=="direct" ? [p.a,p.b] : [p.a,p.h,p.b]
    lengths=[dist(vs[i],vs[i+1]) for i in 1:length(vs)-1]
    total=sum(lengths);remaining=total*f
    for i in eachindex(lengths)
        if remaining<=lengths[i]||i==length(lengths)
            t=lengths[i]==0 ? BigFloat(0) : remaining/lengths[i]
            return (x=vs[i].x+t*(vs[i+1].x-vs[i].x),y=vs[i].y+t*(vs[i+1].y-vs[i].y),s=f*total*(p.kind=="uniform" ? p.gap/2 : 1))
        end
        remaining-=lengths[i]
    end
end
function endpoints(p)
    a=environment(p,p.a.x,p.a.y);b=environment(p,p.b.x,p.b.y)
    dv=b.v-a.v;du=p.q*dv
    (;dv,du,work=-du,meter=-dv)
end
function battery(emf,r,load,rm)
    equivalent=load*rm/(load+rm);current=emf/(r+equivalent);terminal=emf-current*r
    (;terminal,current,sourcePower=emf*current,internalPower=current^2*r,loadPower=terminal^2/load,meterPower=terminal^2/rm)
end
fmt(x)=x isa AbstractString ? x : @sprintf("%.17g",Float64(x))
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,route,f,x_map,y_map,path_m,V_V,U_J,W_electric_J,Ex_V_per_m,Ey_V_per_m")
        for (id,p) in cases(),route in ["direct","bent"],i in 0:64
            f=BigFloat(i)/64;s=point(p,route,f);e=environment(p,s.x,s.y);a=environment(p,p.a.x,p.a.y)
            println(io,join(fmt.([id,route,f,s.x,s.y,s.s,e.v,p.q*e.v,p.q*(a.v-e.v),e.ex,e.ey]),","))
        end
    end
    open(joinpath(folder,"events.csv"),"w") do io
        println(io,"case,dV_V,dU_J,W_electric_J,meter_A_minus_B_V")
        for (id,p) in cases()
            e=endpoints(p);println(io,join(fmt.([id,e.dv,e.du,e.work,e.meter]),","))
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    PotentialWorkLab.reference()
end
