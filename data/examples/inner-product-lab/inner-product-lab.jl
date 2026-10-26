module InnerProductLab
using Printf
export cases, inner, analyze, reference, poly
function make(mode,u,v; a=-1,b=1,weight="uniform")
    (;mode,u=Rational{Int}.(u),v=Rational{Int}.(v),a=a//1,b=b//1,weight)
end
function cases()
    [
        "vector_projection"=>make("vectors",[3,2],[2,1]),
        "vector_orthogonal"=>make("vectors",[1,1],[1,-1]),
        "vector_obtuse"=>make("vectors",[-2,1],[3,0]),
        "vector_zero_target"=>make("vectors",[3,2],[0,0]),
        "vector_zero_source"=>make("vectors",[0,0],[1,-1]),
        "function_square"=>make("functions",[0,0,1,0],[1,0,0,0]),
        "function_cubic"=>make("functions",[0,0,0,1],[0,1,0,0]),
        "function_cancel"=>make("functions",[1,0,0,0],[0,1,0,0]),
        "function_interval"=>make("functions",[1,0,0,0],[0,1,0,0],a=0),
        "function_weighted"=>make("functions",[0,1,0,0],[1,0,0,0],a=0,weight="ramp"),
        "function_norm"=>make("functions",[0,1,0,0],[0,1,0,0]),
        "function_quadratic"=>make("functions",[1,1,0,0],[1,0,1,0],weight="quadratic"),
        "function_zero_target"=>make("functions",[0,1,1,0],[0,0,0,0],a=0,b=2),
        "matrix_trace"=>make("matrices",[3,2,-1,1],[1,0,0,1]),
        "matrix_symmetric"=>make("matrices",[1,2,2,-1],[0,-1,1,0]),
        "matrix_general"=>make("matrices",[1,-2,3,1],[2,1,0,-1]),
        "matrix_zero_target"=>make("matrices",[1,2,3,4],[0,0,0,0])
    ]
end
poly(c,x)=evalpoly(x,Tuple(c))
function multiply(u,v)
    out=fill(0//1,length(u)+length(v)-1)
    for i in eachindex(u),j in eachindex(v); out[i+j-1]+=u[i]*v[j]; end
    out
end
weight(p)=p.weight=="ramp" ? [-2p.a/(p.b-p.a),2/(p.b-p.a)] : p.weight=="quadratic" ? [1//1,0//1,1//1] : [1//1]
function inner(p,u,v)
    p.mode!="functions" && return sum(u.*v)
    product=multiply(multiply(u,v),weight(p))
    sum(c*(p.b^i-p.a^i)/i for (i,c) in enumerate(product))
end
function analyze(p,c)
    uv=inner(p,p.u,p.v); uu=inner(p,p.u,p.u); vv=inner(p,p.v,p.v)
    optimal=vv==0 ? nothing : uv/vv
    r=p.u.-c.*p.v
    angle=uu==0||vv==0 ? nothing : acos(clamp(Float64(uv)/sqrt(Float64(uu*vv)),-1.,1.))*180/pi
    (;uv,uu,vv,optimal,c,rv=inner(p,r,p.v),error2=inner(p,r,r),angle)
end
fmt(x)=isnothing(x) ? "" : x isa AbstractString ? x : @sprintf("%.17g",Float64(x))
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,mode,a,b,weight,u0,u1,u2,u3,v0,v1,v2,v3,uv,uu,vv,optimal_c,trial_c,residual_inner_v,error_squared,angle_deg")
        for (name,p) in cases()
            opt=analyze(p,0//1).optimal
            for c in [-2//1,-1//1,0//1,1//4,1//2,1//1,2//1,3//1,isnothing(opt) ? 0//1 : opt]
                d=analyze(p,c);u=vcat(p.u,fill(0//1,4-length(p.u)));v=vcat(p.v,fill(0//1,4-length(p.v)))
                println(io,join(fmt.([name,p.mode,p.a,p.b,p.weight,u...,v...,d.uv,d.uu,d.vv,d.optimal,c,d.rv,d.error2,d.angle]),","))
            end
        end
    end
    open(joinpath(folder,"samples.csv"),"w") do io
        println(io,"case,x,u,v,weight,product,optimal_projection,residual")
        for (name,p) in cases()
            p.mode=="functions" || continue
            c=something(analyze(p,0//1).optimal,0//1)
            for i in 0:64
                x=p.a+(p.b-p.a)*i/64; u=poly(p.u,x);v=poly(p.v,x);w=poly(weight(p),x)
                println(io,join(fmt.([name,x,u,v,w,w*u*v,c*v,u-c*v]),","))
            end
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    InnerProductLab.reference()
end
