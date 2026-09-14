using Test
include(joinpath(@__DIR__, "..", "brachistochrone.jl"))
using .PLBrachistochrone

@testset "Cycloid endpoint solve and explorer datasets" begin
    @test isapprox(PLBrachistochrone.endpoint_ratio(pi), pi/2; atol=1e-14)
    @test isapprox(PLBrachistochrone.solve_theta(pi/2), pi; atol=2e-12)

    config = PLBrachistochrone.load_cases()
    model = config["model"]
    solutions = [PLBrachistochrone.solve_case(c, model) for c in config["cases"]]
    @test length(solutions) == 3

    for sol in solutions
        lastrow = last(sol.rows)
        @test isapprox(lastrow.x, sol.X; atol=2e-12)
        @test isapprox(lastrow.y, sol.Y; atol=2e-12)
        @test isapprox(lastrow.t, sol.time; atol=2e-12)
        @test isapprox(PLBrachistochrone.endpoint_ratio(sol.thetaB), sol.X/sol.Y; atol=2e-12)
        @test sol.time < sol.line_time
        @test all(r.y >= -1e-14 && r.t >= 0 && r.v >= 0 for r in sol.rows)
        for r in sol.rows[2:end]
            @test isapprox(r.v^2, 2 * sol.g * r.y; rtol=2e-12, atol=2e-12)
        end
        widths = [r.width for r in sol.history]
        @test all(diff(widths) .< 0)
        @test all(r.lo < sol.thetaB < r.hi for r in sol.history)
        @test abs(last(sol.history).residual) < 5e-12
        errors = Float64[]
        for n in model["convergence_segments"]
            estimate = PLBrachistochrone.segment_time(sol; segments=n)
            push!(errors, abs(estimate-sol.time))
        end
        @test all(diff(errors) .< 0)
        @test last(errors) / sol.time < 3e-5
    end

    before, bottom, after = solutions
    @test before.thetaB < pi
    @test isapprox(bottom.thetaB, pi; atol=2e-12)
    @test after.thetaB > pi
    @test isapprox(after.X, 4.0; atol=0)
    @test isapprox(after.Y, 1.0; atol=0)
    @test isapprox(after.thetaB, 4.376072413012887; atol=2e-12)
    @test isapprox(after.a, 0.7518727659760618; atol=2e-12)
    @test isapprox(after.time, 1.2114965265365136; atol=2e-12)
    @test isapprox(after.deepest, 1.5037455319521236; atol=2e-12)

    c = config["cases"][3]
    scaled = PLBrachistochrone.solve_case(merge(c, Dict("x"=>16.0, "y"=>4.0)), model)
    @test isapprox(scaled.thetaB, after.thetaB; atol=2e-12)
    @test isapprox(scaled.a, 4 * after.a; rtol=2e-12)
    @test isapprox(scaled.time, 2 * after.time; rtol=2e-12)
end
