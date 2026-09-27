using Test
include("../interception.jl")
using .MinimumEffortInterception

@testset "Interception model" begin
    s = solution(100.0,10.0)
    @test s.time == 10
    @test s.speed == 20
    @test s.endpoint == 200
    @test s.effort == 2000
    @test sample_position(100.0,10.0,s.time,0) == (vehicle=0, target=100)
    @test sample_position(100.0,10.0,s.time,s.time) == (vehicle=200, target=200)
    @test trial(100.0,10.0,5.0).effort > s.effort
    @test trial(100.0,10.0,20.0).effort > s.effort
    for d in (20.0, 100.0, 200.0), v in (2.0, 10.0, 20.0)
        s = solution(d,v)
        @test isapprox(s.time,d/v)
        @test isapprox(s.speed,2v)
        @test isapprox(s.endpoint,2d)
        @test isapprox(s.effort,2d*v)
        @test isapprox(sample_position(d,v,s.time,s.time).vehicle,sample_position(d,v,s.time,s.time).target)
        for factor in (0.4, 0.75, 1.25, 2.5)
            @test trial(d,v,factor*s.time).effort > s.effort
        end
    end
    @test_throws ArgumentError solution(0.0,10.0)
    @test_throws ArgumentError solution(100.0,0.0)
    @test_throws ArgumentError trial(100.0,10.0,0.0)
    @test_throws ArgumentError sample_position(100.0,10.0,10.0,11.0)
end
