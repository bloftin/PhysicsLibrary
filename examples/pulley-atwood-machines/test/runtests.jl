using Test
include("../atwood.jl")
using .PulleyAtwoodMachines

@testset "Fixed Atwood machine" begin
    s = state(:fixed, 3, 5, 9.81, 0.6)
    @test s.acceleration ≈ 9.81 / 4
    @test s.tension ≈ 2 * 3 * 5 * 9.81 / 8
    @test s.mass1_down ≈ -s.mass2_down
    @test s.tension - 3 * 9.81 ≈ 3 * s.acceleration
    @test 5 * 9.81 - s.tension ≈ 5 * s.acceleration
    @test s.constraint ≈ 0
end

@testset "Movable pulley" begin
    s = state(:movable, 4, 6, 9.81, 0.7)
    @test s.acceleration ≈ 2 * 9.81 / 22
    @test s.mass1_down ≈ -2 * s.mass2_down
    @test s.mass1_down_speed ≈ -2 * s.mass2_down_speed
    @test 4 * 9.81 - s.tension ≈ 8 * s.acceleration
    @test 2 * s.tension - 6 * 9.81 ≈ 6 * s.acceleration
    @test s.constraint ≈ 0
end

@testset "Limits and directions" begin
    @test state(:fixed, 4, 4, 9.81, 2).acceleration == 0
    @test state(:movable, 3, 6, 9.81, 2).acceleration == 0
    @test state(:fixed, 6, 2, 9.81, 1).acceleration < 0
    @test state(:movable, 2, 6, 9.81, 1).acceleration < 0
    @test duration(:fixed, 4, 4, 9.81) == 3
    @test duration(:movable, 2, 6, 9.81) ≈ sqrt(0.6 / abs(state(:movable, 2, 6, 9.81, 0).acceleration))
    @test_throws ArgumentError state(:fixed, 0, 5, 9.81, 0)
    @test_throws ArgumentError state(:movable, 3, 5, 9.81, -1)
end
