using Test
include("../sinusoidal-oscillation.jl")
using .SinusoidalOscillation
@testset "Sinusoidal phase, units, cycle and convention" begin
    for (_,c) in cases(), t in (0., .125, .4, 1., 4.)
        p=c.p; d=sample(p,t); m=metrics(p)
        @test abs(d.u)<=p.A+1e-15
        @test sample(p,t+m.T).u ≈ d.u atol=2e-15
        @test m.omega*m.T ≈ 2pi
        phi=p.phi+(p.form=="cos" ? pi/2 : -pi/2)
        q=parameters(A=p.A,f=p.f,phi=phi,form=p.form=="cos" ? "sin" : "cos")
        @test sample(q,t).u ≈ d.u atol=2e-15
        @test sample(q,t).slope ≈ d.slope atol=5e-14
    end
    c=preset("example1"); @test c.p.A==.04; @test metrics(c.p).T==.5
    @test metrics(c.p).omega ≈ 4pi
    @test [sample(c.p,i*.125).u for i in 0:4] ≈ [.04,0.,-.04,0.,.04] atol=1e-15
    c=preset("example2"); @test c.p.A==.006; @test metrics(c.p).T==.4
    @test metrics(c.p).omega ≈ 5pi
    @test abs(sample(c.p,0.).u)<1e-15
    @test sample(c.p,0.).slope<0
    @test sample(preset("rising").p,0.).slope>0
    for radius in (.5,1.,1.5), alpha in (0.,1.,pi/2,pi,2pi)
        @test (radius*alpha)/radius ≈ alpha
    end
end
