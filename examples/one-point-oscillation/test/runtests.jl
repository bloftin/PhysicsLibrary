using Test
include(joinpath(@__DIR__,"..","one-point-oscillation.jl"))
using .OnePointOscillation
@testset "Amplitude, periods, distance and coordinate reversal" begin
    for (_,p) in cases()
        reversed=merge(p,(axis=-p.axis,))
        for s in (0.,.1,.15,.25,.4,.5,.65,.75,1.,1.4,3.)
            d=sample(p,s*p.T); r=sample(reversed,s*p.T); again=sample(p,(s+1)*p.T)
            @test abs(d.u)<=p.A+1e-12
            @test r.u ≈ -d.u atol=1e-12
            @test r.physical ≈ d.physical
            @test r.distance ≈ d.distance
            @test again.u ≈ d.u atol=1e-12
            if !isnothing(d.velocity); @test again.velocity ≈ d.velocity atol=1e-10; end
        end
        @test sample(p,.5p.T).distance ≈ 2p.A
        @test sample(p,p.T).distance ≈ 4p.A
        @test sample(p,3p.T).distance ≈ 12p.A
        points=[sample(p,3p.T*i/6000).u for i in 0:6000]
        @test sum(abs,diff(points)) ≈ 12p.A atol=1e-11
        if p.A>0
            q=pair(p)
            @test q.first.u ≈ p.A*p.level atol=1e-12
            @test q.second.u ≈ q.first.u atol=1e-12
            @test q.first.velocity*q.second.velocity<0
            @test q.repeat.velocity ≈ q.first.velocity atol=1e-10
            @test q.repeat.t-q.first.t ≈ p.T
        else
            @test isnothing(pair(p))
            @test isnothing(sample(p,1).period)
            @test sample(p,100).cycles==0
        end
    end
end
@testset "Rates agree with finite differences away from corners" begin
    for name in ("rounded","triangle","uneven"),s in (.07,.2,.32,.57,.8,.91)
        p=merge(defaults,(shape=name,)); h=1e-6
        @test sample(p,s*p.T).velocity ≈ (sample(p,s*p.T+h).u-sample(p,s*p.T-h).u)/(2h) atol=1e-10
    end
    @test isnothing(sample(merge(defaults,(shape="triangle",)),.25defaults.T).velocity)
end
