module GradientLab
using Printf
export parameters, sample, reference, FIELDS
const FIELDS=("plane","bowl","saddle","gaussian","waves","wells")
parameters(;field="bowl",a=1.0,b=1.3,x=-.9,y=.6,angle=25.0)=(;field,a,b,x,y,angle)
function sample(p,x=p.x,y=p.y)
    p.field in FIELDS || throw(ArgumentError("unknown field"))
    for (v,lo,hi) in ((p.a,.25,2),(p.b,.25,2),(x,-2.5,2.5),(y,-2.5,2.5),(p.angle,-180,180))
        isfinite(v) && lo<=v<=hi || throw(ArgumentError("invalid parameter"))
    end
    a,b=p.a,p.b
    f,fx,fy=if p.field=="plane"
        (a*(x+b*y),a,a*b)
    elseif p.field=="bowl"
        (a*(x^2+b*y^2)/2,a*x,a*b*y)
    elseif p.field=="saddle"
        (a*(x^2-b*y^2)/2,a*x,-a*b*y)
    elseif p.field=="gaussian"
        g=a*exp(-b*(x^2+y^2)); (g,-2b*x*g,-2b*y*g)
    elseif p.field=="waves"
        (a*sin(b*x)*cos(b*y),a*b*cos(b*x)*cos(b*y),-a*b*sin(b*x)*sin(b*y))
    else
        (a*(x^4/4-x^2/2+b*y^2/2),a*(x^3-x),a*b*y)
    end
    (;x,y,value=f,fx,fy,magnitude=hypot(fx,fy),directional=fx*cosd(p.angle)+fy*sind(p.angle))
end
function reference(folder=@__DIR__)
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"field,a,b,angle,x,y,f,df_dx,df_dy,gradient_magnitude,directional_derivative")
        for field in FIELDS, (a,b,angle) in ((1.,1.3,25.),(.25,2.,-180.),(2.,.25,90.)), y in -2.5:.5:2.5, x in -2.5:.5:2.5
            p=parameters(;field,a,b,angle);r=sample(p,x,y);print(io,field)
            for v in (a,b,angle,x,y,r.value,r.fx,r.fy,r.magnitude,r.directional)
                @printf(io,",%.16g",v)
            end
            println(io)
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    GradientLab.reference()
end
