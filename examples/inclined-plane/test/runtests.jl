using Test
include("../motion.jl")
using .PLInclinedPlane

@testset "Inclined plane: independent mechanics checks" begin
    cases = PLInclinedPlane.load_cases()
    for c in cases
        p = PLInclinedPlane.parameters(c)
        rows = PLInclinedPlane.solution(c)
        theta = deg2rad(c["angle_deg"])
        expected_a = p.stuck ? 0.0 : c["gravity"]*(sin(theta)-c["mu_k"]*cos(theta))
        @test rows[1].s == rows[1].v == 0
        @test length(rows) == c["samples"]
        for r in rows
            @test r.a ≈ expected_a atol=1e-12
            @test r.s ≈ expected_a*r.t^2/2 atol=1e-10
            @test r.v ≈ expected_a*r.t atol=1e-10
            @test r.kinetic + r.potential + r.dissipated ≈ c["mass"]*c["gravity"]*c["length"]*sin(theta)
            @test r.kinetic ≈ (p.downhill-p.friction)*r.s atol=1e-10
        end
        @test rows[end].s ≈ (p.stuck ? 0.0 : c["length"]) atol=1e-10
        @test PLInclinedPlane.parameters(merge(c, Dict("mass"=>20.0))).acceleration ≈ expected_a atol=1e-12
    end
    base = cases[2]
    @test PLInclinedPlane.parameters(merge(base, Dict("angle_deg"=>0.0))).stuck
    limit = merge(base, Dict("angle_deg"=>45.0, "mu_s"=>1.0, "mu_k"=>0.5))
    @test PLInclinedPlane.parameters(limit).stuck
    @test !PLInclinedPlane.parameters(merge(limit, Dict("angle_deg"=>45.001))).stuck
    for bad in (Dict("mass"=>0), Dict("gravity"=>Inf), Dict("angle_deg"=>90), Dict("length"=>-1), Dict("mu_k"=>0.4), Dict("samples"=>1))
        @test_throws ErrorException PLInclinedPlane.parameters(merge(base,bad))
    end
end
