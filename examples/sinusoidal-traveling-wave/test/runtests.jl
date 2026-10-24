using Test
include(joinpath(@__DIR__,"..","sinusoidal-traveling-wave.jl"))
using .SinusoidalTravelingWave
@testset "Kinematic periodicity, direction, fixed phase and conventions" begin
    for (_,c) in cases()
        p=c.p;m=metrics(p)
        for x in (0.,.17,1.,2.),t in (0.,.25,.7,2.)
            d=sample(p,x,t)
            @test abs(d.u)<=p.A+1e-15
            @test sample(p,x+p.lambda,t).u ≈ d.u atol=1e-14
            @test sample(p,x,t+m.T).u ≈ d.u atol=1e-14
            @test sample(p,x+p.direction*p.lambda*p.f*t,t).u ≈ sample(p,x,0.).u atol=1e-14
            sine=merge(p,(form=p.form=="cos" ? "sin" : "cos",phi=p.phi+(p.form=="cos" ? pi/2 : -pi/2)))
            @test sample(sine,x,t).u ≈ d.u atol=1e-14
        end
        if p.A>0
            @test crest(p,m.T/4)-crest(p,0.) ≈ p.direction*p.lambda/4
            @test sample(p,crest(p,.7),.7).u ≈ p.A atol=1e-14
        else
            @test isnothing(crest(p,0.))
        end
    end
    c=preset("example2");d=sample(c.p,c.p.probe,c.t)
    @test d.theta ≈ 5pi/6
    @test 100d.u ≈ -sqrt(3)
    m=metrics(preset("example1").p)
    @test m.k ≈ 4pi
    @test m.omega ≈ 10pi
    @test m.T ≈ .2
    @test_throws ArgumentError preset("unknown")
end
