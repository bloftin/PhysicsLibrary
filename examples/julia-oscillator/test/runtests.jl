using Test
include(joinpath(@__DIR__, "..", "oscillator.jl"))
using .PLOscillator

# An independent scalar analytic solution for comparison with the matrix exponential.
function analytic(model, c, t)
    m, k = model["mass"], model["stiffness"]
    x0, v0 = model["displacement"], model["velocity"]
    a, w = c / (2m), sqrt(k / m)
    if isapprox(a, w; rtol=1e-14)
        b = v0 + a*x0
        return exp(-a*t)*(x0+b*t), exp(-a*t)*(b-a*(x0+b*t))
    elseif a < w
        wd = sqrt(w^2-a^2)
        b = (v0+a*x0)/wd
        f = x0*cos(wd*t)+b*sin(wd*t)
        return exp(-a*t)*f, exp(-a*t)*(-a*f-x0*wd*sin(wd*t)+b*wd*cos(wd*t))
    else
        r1, r2 = -a+sqrt(a^2-w^2), -a-sqrt(a^2-w^2)
        b1 = (v0-r2*x0)/(r1-r2)
        b2 = x0-b1
        return b1*exp(r1*t)+b2*exp(r2*t), r1*b1*exp(r1*t)+r2*b2*exp(r2*t)
    end
end

@testset "Published oscillator presets" begin
    config = PLOscillator.load_presets()
    @test length(config["presets"]) == 3
    model = config["model"]
    for preset in config["presets"]
        @testset "$(preset["id"])" begin
            rows = PLOscillator.solution(model, preset["damping"])
            @test length(rows) == 601
            @test rows[1].x == model["displacement"]
            @test rows[1].v == model["velocity"]
            expected = [analytic(model, preset["damping"], row.t) for row in rows]
            @test maximum(abs(row.x-pair[1]) for (row,pair) in zip(rows,expected)) < 1e-11
            @test maximum(abs(row.v-pair[2]) for (row,pair) in zip(rows,expected)) < 1e-11
            @test all(row.energy >= 0 for row in rows)
            @test all(diff([row.energy for row in rows]) .<= 1e-12)
            @test all(isfinite(row.x) && isfinite(row.v) for row in rows)
            if preset["id"] == "underdamped"
                @test minimum(row.x for row in rows) < 0
            else
                @test all(row.x >= 0 for row in rows)
                @test all(diff([row.x for row in rows]) .<= 1e-12)
            end
        end
    end
    undamped = PLOscillator.solution(model, 0.0)
    @test maximum(abs(row.energy-undamped[1].energy) for row in undamped) < 1e-11
    # Exercise nonzero initial velocity independently of the published release-from-rest cases.
    moving = merge(model, Dict("velocity" => 0.7))
    for c in (0.8, 4.0, 8.0)
        @test all(isapprox(row.x, analytic(moving,c,row.t)[1]; atol=1e-11)
            for row in PLOscillator.solution(moving, c))
    end
end
