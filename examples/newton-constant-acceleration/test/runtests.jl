using Test
include("../motion.jl")
using .PLConstantAcceleration

@testset "Newton's law and integrated initial-value solution" begin
    for c in PLConstantAcceleration.load_cases()["cases"]
        rows = PLConstantAcceleration.solution(c)
        a = c["force"] / c["mass"]
        @test first(rows).t == c["t0"]
        @test first(rows).x == c["x0"]
        @test first(rows).v == c["v0"]
        for r in rows
            tau = r.t - c["t0"]
            @test isapprox(r.x, c["x0"] + c["v0"]*tau + a*tau^2/2; atol=1e-10)
            @test isapprox(r.v, c["v0"] + a*tau; atol=1e-10)
            @test c["mass"] * r.a == c["force"]
            @test isapprox(c["mass"]*(r.v^2-c["v0"]^2)/2,
                           c["force"]*(r.x-c["x0"]); atol=1e-9)
        end
        for (p, q) in zip(rows, rows[2:end])
            @test isapprox(q.x-p.x, (p.v+q.v)*(q.t-p.t)/2; atol=1e-10)
        end
        shifted = merge(c, Dict("t0" => -7.0))
        @test [r.x for r in rows] == [r.x for r in PLConstantAcceleration.solution(shifted)]
    end
    c = last(PLConstantAcceleration.load_cases()["cases"])
    turning = PLConstantAcceleration.solution(c)[61]
    @test turning.t == 5.0
    @test isapprox(turning.v, 0.0; atol=1e-12)
    @test isapprox(turning.x, 5.5; atol=1e-12)
    # The same force on twice the mass halves acceleration, not initial velocity.
    heavy = PLConstantAcceleration.solution(merge(c, Dict("mass" => 4.0)))
    @test first(heavy).a == -0.5
    @test first(heavy).v == 3.0
end
