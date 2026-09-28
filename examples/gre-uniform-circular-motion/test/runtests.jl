using Test
include("../circular_motion.jl")
using .GREUniformCircularMotion

@testset "Uniform circular motion" begin
    example = state(5.0,8.0,0.0,0.0)
    @test example.omega == 1.6
    @test isapprox(example.period, 2pi/1.6)
    @test isapprox(example.frequency, 1/example.period)
    @test example.acceleration == 12.8
    @test example.vx == 0
    @test example.vy == 8
    @test example.ax == -12.8
    @test example.ay == 0
    wheel = state(0.35,4pi*0.35,0.0,0.0)
    @test isapprox(wheel.frequency, 2.0)
    @test isapprox(0.35*wheel.omega, 4pi*0.35)
    @test isapprox(wheel.acceleration, 0.35*(4pi)^2)
    vector = state(2.0,6.0,0.0,pi/6)
    @test abs(vector.x) < 1e-12
    @test isapprox(vector.y,2)
    @test isapprox(vector.vx,-6)
    @test abs(vector.vy) < 1e-12
    @test isapprox(vector.ay,-18)
    for r in (0.2,0.6,2.0,5.0), v in (0.8,2.4,6.0,8.0), theta0 in (0.0,0.7)
        base = state(r,v,theta0,0.0)
        for fraction in (0.0,0.2,0.5,1.0)
            s = state(r,v,theta0,base.period*fraction)
            @test isapprox(hypot(s.x,s.y),r)
            @test isapprox(hypot(s.vx,s.vy),v)
            @test isapprox(hypot(s.ax,s.ay),v^2/r)
            @test abs(s.vx*s.ax+s.vy*s.ay) < 1e-10
            @test isapprox(s.ax,-s.omega^2*s.x)
            @test isapprox(s.ay,-s.omega^2*s.y)
        end
        endstate = state(r,v,theta0,base.period)
        @test isapprox(endstate.x,base.x)
        @test isapprox(endstate.y,base.y,atol=1e-12)
    end
    inner = state(0.2,0.8,0.0,0.2)
    outer = state(0.6,2.4,0.0,0.2)
    @test isapprox(inner.omega,outer.omega)
    @test isapprox(outer.acceleration/inner.acceleration,3)
    @test_throws ArgumentError state(0.0,1.0,0.0,0.0)
    @test_throws ArgumentError state(1.0,0.0,0.0,0.0)
    @test_throws ArgumentError state(1.0,1.0,NaN,0.0)
    @test_throws ArgumentError state(1.0,1.0,0.0,-1.0)
end
