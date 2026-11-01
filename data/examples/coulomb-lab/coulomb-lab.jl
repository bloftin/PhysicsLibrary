module CoulombLab
using Printf
export cases, field, forces, reference, K
const K = setprecision(256) do
    1/(4big(pi)*parse(BigFloat,"8.8541878188e-12"))
end
c(x,y,q)=(x=BigFloat(x),y=BigFloat(y),q=BigFloat(q)*big"1e-6")
function cases()
    ["dipole"=>[c(-1,0,1),c(1,0,-1)],"like"=>[c(-1,0,1),c(1,0,1)],
     "unequal"=>[c(-1,0,1),c(1,0,-2)],
     "triangle"=>[c(-1,-.7,1),c(1,-.7,1),c(0,1,-1)],
     "quadrupole"=>[c(-1,-1,1),c(1,-1,-1),c(1,1,1),c(-1,1,-1)],
     "balance"=>[c(-1,0,1),c(0,0,.5),c(1,0,1)],
     "positive"=>[c(0,0,1),c(2,0,0)],"negative"=>[c(0,0,-1),c(2,0,0)],
     "six"=>[c(1.5*cos(i*pi/3),1.5*sin(i*pi/3),isodd(i) ? -1 : 1) for i in 0:5],
     "zero"=>[c(-1,0,0),c(1,0,0)]]
end
function field(charges,x,y;omit=0)
    ex=BigFloat(0);ey=BigFloat(0)
    for (i,q) in enumerate(charges)
        (i==omit||q.q==0)&&continue
        dx=BigFloat(x)-q.x;dy=BigFloat(y)-q.y;r2=dx^2+dy^2
        r2==0&&return nothing
        ex+=K*q.q*dx/(r2*sqrt(r2));ey+=K*q.q*dy/(r2*sqrt(r2))
    end
    (x=ex,y=ey,magnitude=sqrt(ex^2+ey^2))
end
function forces(charges)
    map(eachindex(charges)) do i
        fx=BigFloat(0);fy=BigFloat(0);a=charges[i]
        for (j,b) in enumerate(charges)
            i==j&&continue
            dx=a.x-b.x;dy=a.y-b.y;r=sqrt(dx^2+dy^2)
            magnitude=K*a.q*b.q/r^2
            fx+=magnitude*(dx/r);fy+=magnitude*(dy/r)
        end
        (x=fx,y=fy,magnitude=sqrt(fx^2+fy^2))
    end
end
fmt(x)=x isa AbstractString ? x : @sprintf("%.17g",Float64(x))
function reference(folder=@__DIR__)
    open(joinpath(folder,"configurations.csv"),"w") do io
        println(io,"case,index,q_C,x_m,y_m")
        for (name,qs) in cases(),(i,q) in enumerate(qs)
            println(io,join(fmt.([name,i,q.q,q.x,q.y]),","))
        end
    end
    open(joinpath(folder,"forces.csv"),"w") do io
        println(io,"case,index,Fx_N,Fy_N,F_N,E_external_x_N_per_C,E_external_y_N_per_C")
        for (name,qs) in cases()
            fs=forces(qs)
            for i in eachindex(qs)
                f=fs[i];e=field(qs,qs[i].x,qs[i].y,omit=i)
                println(io,join(fmt.([name,i,f.x,f.y,f.magnitude,e.x,e.y]),","))
            end
        end
    end
    open(joinpath(folder,"fields.csv"),"w") do io
        println(io,"case,x_m,y_m,Ex_N_per_C,Ey_N_per_C,E_N_per_C")
        for (name,qs) in cases(), j in 0:11, i in 0:11
            x=big"-2.75"+i/BigFloat(2);y=big"-2.75"+j/BigFloat(2);e=field(qs,x,y)
            println(io,join(fmt.([name,x,y,e.x,e.y,e.magnitude]),","))
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    CoulombLab.reference()
end
