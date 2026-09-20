using Test
include("../motion.jl")
using .PLOrbitalGravitation

@testset "Newtonian orbital gravitation" begin
    config = PLOrbitalGravitation.load_config()
    values = PLOrbitalGravitation.model_values(config)
    @test length(PLOrbitalGravitation.speed_factors(config)) == 37
    @test isapprox(values.vc^2, values.mu / values.r0; rtol=1e-14)
    @test isapprox(values.period, 2pi * sqrt(values.r0^3 / values.mu); rtol=1e-14)

    circular = PLOrbitalGravitation.trajectory(values, 1.0)
    @test first(circular).x == values.r0
    @test first(circular).y == 0.0
    @test first(circular).vx == 0.0
    @test first(circular).vy == values.vc
    @test maximum(abs(row.r - values.r0) for row in circular) / values.r0 < 7e-4
    e0, h0 = first(circular).specific_energy, first(circular).angular_momentum
    @test maximum(abs(row.specific_energy - e0) for row in circular) / abs(e0) < 2e-4
    @test maximum(abs(row.angular_momentum - h0) for row in circular) / abs(h0) < 2e-12

    elliptical = PLOrbitalGravitation.trajectory(values, 0.8)
    escaping = PLOrbitalGravitation.trajectory(values, 1.42)
    @test first(elliptical).specific_energy < 0
    @test first(escaping).specific_energy > 0
    @test minimum(row.r for row in elliptical) > values.radius
    @test last(escaping).r > first(escaping).r
    # Test-particle mass is absent from the acceleration and trajectory model.
    ax, ay = PLOrbitalGravitation.acceleration(values.mu, values.r0, 0.0)
    @test isapprox(ax, -values.mu / values.r0^2; rtol=1e-14)
    @test ay == 0.0
end
