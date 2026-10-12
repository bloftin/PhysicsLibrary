using Test
include("../gradient-lab.jl")
using .GradientLab
@testset "Gradient Lab" begin
    for field in FIELDS, a in (.25,1.,2.), b in (.25,1.3,2.), x in (-2.,-.8,0.,.6,2.), y in (-2.,-.4,0.,.9,2.)
        p=parameters(;field,a,b,x,y);r=sample(p);h=1e-5
        @test r.fx ≈ (sample(p,x+h,y).value-sample(p,x-h,y).value)/(2h) atol=1e-7 rtol=1e-7
        @test r.fy ≈ (sample(p,x,y+h).value-sample(p,x,y-h).value)/(2h) atol=1e-7 rtol=1e-7
        @test abs(r.directional)<=r.magnitude+1e-10
        @test all(isfinite,(r.value,r.fx,r.fy,r.magnitude,r.directional))
    end
    @test sample(parameters(field="saddle",x=0.,y=0.)).magnitude==0
    @test sample(parameters(field="bowl",x=0.,y=0.)).magnitude==0
    @test sample(parameters(field="gaussian",x=0.,y=0.)).value==1
    @test_throws ArgumentError sample(parameters(a=0.))
    @test_throws ArgumentError sample(parameters(field="unknown"))
end
