using Test
include("../oscillation-lab.jl")
using .OscillationLab
@testset "Oscillation Lab" begin
    p=parameters(); s=scales(p)
    @test s.omega0 == 2
    for t in range(0,s.duration,length=101)
        r=evaluate(p,t)
        @test r.x ≈ cos(2t) atol=1e-10
        @test r.v ≈ -2sin(2t) atol=1e-10
        @test r.E ≈ 2 atol=1e-10
    end
    for (name,p) in CASES
        rows=trajectory(p,80)
        for r in rows
            exact=evaluate(p,r.t)
            @test r.x ≈ exact.x atol=2e-8 rtol=2e-8
            @test r.v ≈ exact.v atol=2e-8 rtol=2e-8
            @test abs(r.balance)<2e-7
            @test r.Q >= -1e-9
        end
    end
    p=parameters(mode="damped",zeta=1.0)
    for t in (0.0,0.1,1.0,5.0)
        @test evaluate(p,t).x ≈ (1+2t)*exp(-2t) atol=1e-10
    end
    p=parameters(mode="driven",zeta=0.0,x0=0.0)
    for t in (0.0,0.1,1.0,5.0)
        @test evaluate(p,t).x ≈ p.force/(2p.m*2)*t*sin(2t) atol=1e-10
    end
    @test_throws ArgumentError evaluate(parameters(),-1)
    @test_throws ArgumentError scales(parameters(m=0.0))
    @test_throws ArgumentError scales(parameters(mode="invalid"))
    @test_throws ArgumentError trajectory(parameters(),19)
end
