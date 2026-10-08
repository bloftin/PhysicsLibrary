using Test, LinearAlgebra
include("../em-field-lab.jl")
using .EMFieldLab
@testset "Scalar and vector plane fields" begin
    for (_,p) in EMFieldLab.CASES
        frame=basis(p); s=scales(p); points=probes(p)
        @test norm(frame.n) ≈ 1
        @test norm(frame.e) ≈ 1
        @test abs(dot(frame.n,frame.e))<1e-14
        @test s.lambda*s.f ≈ EMFieldLab.C
        @test s.period*s.f ≈ 1
        for time in range(0,2,length=101)
            a=evaluate(p,points.a,time); b=evaluate(p,points.b,time)
            @test norm(a.E) ≈ a.magnitude atol=1e-13
            @test abs(dot(a.E,frame.n))<1e-13
            @test b.psi ≈ evaluate(p,points.a,time-p.spacing).psi atol=1e-13
            @test a.psi ≈ evaluate(p,points.a+frame.n*.1,time+.1).psi atol=1e-13
            @test physical(p,points.a*s.lambda,time*s.period).E ≈ a.E atol=1e-13
            @test evaluate(p,points.a+frame.e*.3,time).psi ≈ a.psi atol=1e-13
        end
    end
    @test evaluate(parameters(),[0,0,0],.5).E==[-5.0,0.0,0.0]
    @test_throws ArgumentError scales(parameters(frequency=0.0))
    @test_throws ArgumentError scales(parameters(amplitude=-1.0))
end
