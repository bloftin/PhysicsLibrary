using Test, LinearAlgebra
include("../spectroscopic-binary.jl")
using .SpectroscopicBinary
@testset "Keplerian spectra and masses" begin
    for (_,p) in SpectroscopicBinary.CASES
        el=elements(p)
        @test el.k1 ≈ p.q*el.k2 atol=1e-12
        @test el.m1sin ≈ p.m1*sind(p.i)^3 atol=1e-12
        @test el.m2sin ≈ el.m2*sind(p.i)^3 atol=1e-12
        @test el.f ≈ el.m2^3*sind(p.i)^3/(p.m1+el.m2)^2 atol=1e-12
        p.i>0 && @test companion_mass(el.f,p.m1,p.i) ≈ el.m2 rtol=1e-12
        for phase in range(0,1,length=101)
            v=state(p,phase); h=1e-6
            @test norm(p.m1*v.r1+el.m2*v.r2)<1e-12
            @test norm(p.m1*v.v1+el.m2*v.v2)<1e-9
            numerical=(state(p,phase+h).r1-state(p,phase-h).r1)*el.a/(2h*p.period*SpectroscopicBinary.DAY)
            @test numerical ≈ v.v1 rtol=1e-7 atol=1e-6
            @test v.rv1 ≈ p.gamma-v.v1[3]
            @test .35-1e-12<=spectrum(p,v.rv1,v).combined<=1
        end
    end
    @test companion_mass(0.0,1.0)==0.0
    @test_throws ArgumentError companion_mass(.1,1.0,0.0)
    @test_throws ArgumentError elements(parameters(e=1.0))
    @test line_shape(parameters(resolution=3000.0)).depth<line_shape(parameters(resolution=100000.0)).depth
end
