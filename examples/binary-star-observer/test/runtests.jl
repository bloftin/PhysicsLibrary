using Test, Transits, JSON
include(joinpath(@__DIR__,"..","binary-star-observer.jl"))
using .BinaryObserver
@testset "Binary observer Julia references" begin
    twins=presets[1]
    @test flux(twins,.25) ≈ .5
    @test flux(twins,.75;limb=true) ≈ .5
    @test flux(twins,0) ≈ 1
    @test probability(twins).any ≈ .24
    @test probability(presets[end]).both ≈ .186019
    for p in presets, phase in 0:.01:1
        v=state(p,phase)
        @test isfinite(v.d)
        @test 0 <= flux(p,phase) <= 1
        @test 0 <= flux(p,phase;limb=true) <= 1
    end
    grid=JSON.parsefile(joinpath(@__DIR__,"..","limb-grid.json"))
    @test length(grid["values"])==grid["nk"]*grid["nx"]
    @test all(isfinite,grid["values"])
    @test all(x -> 0<=x<=1,grid["values"])
    @test QuadLimbDark([.4,.25])(0.,4.) ≈ 0
    @test QuadLimbDark([.4,.25])(2.,.5) ≈ 1
    # Central occultation independently integrates the quadratic radial intensity.
    k=.5;u1=.4;u2=.25;N=20000;dr=k/N
    blocked=sum(2r*(1-u1*(1-sqrt(1-r^2))-u2*(1-sqrt(1-r^2))^2)*dr for r in (dr/2):dr:k)
    @test QuadLimbDark([u1,u2])(0.,k) ≈ 1-blocked/(1-u1/3-u2/6) atol=1e-9
end
