using Test, LinearAlgebra
include("../orbital-elements.jl")
using .OrbitalElements
const O = OrbitalElements
@testset "Elliptic ECI geometry and Kepler propagation" begin
    for p in O.PRESETS
        s = O.state(p)
        @test p.a*(1-p.e) > O.RE
        R = O.rotation(p)
        @test R'R ≈ Matrix{Float64}(I, 3, 3) atol=1e-14
        @test det(R) ≈ 1 atol=1e-14
        for fraction in 0:.05:1
            q = O.advance(p, s.period*fraction)
            z = O.state(q)
            @test dot(z.v,z.v)/2 - O.MU/norm(z.r) ≈ s.energy atol=1e-10
            @test norm(cross(z.r,z.v)) ≈ s.h rtol=1e-12
            @test dot(z.r,R[:,3]) ≈ 0 atol=1e-10
            @test abs(mod(z.M-s.M-2pi*fraction+pi,2pi)-pi) < 1e-12
        end
        @test O.state(O.advance(p,s.period)).r ≈ s.r atol=1e-8
    end
    @test O.rates(O.PRESETS[1]).raan < 0
    @test O.rates(O.PRESETS[3]).raan > 0
    @test abs(O.rates(O.PRESETS[6]).argp) < 1e-13
    for e in (0.0,.01,.74,.95,.999), M in (0.0,1e-8,.2,pi,5.9,2pi-1e-8)
        E = O.eccentric_anomaly(e,M)
        @test E-e*sin(E) ≈ M atol=2e-15
    end
    @test_throws ArgumentError O.state(merge(O.PRESETS[1],(e=1.0,)))
    @test_throws ArgumentError O.advance(O.PRESETS[1],Inf)
end
