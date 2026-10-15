using Test
include("../isoperimetric-lab.jl")
using .IsoperimetricLab
@testset "Arc geometry and signed stationarity" begin
    for mode in (1,3,4),a in (.5,1.5,3.),alpha in (15.,45.,90.),L in (2.,8.,16.)
        p=parameters(;mode,a,alpha,length=L,ratio=-1.);r=state(p)
        @test r.length ≈ 2r.R*r.alpha
        @test r.a ≈ r.R*sin(r.alpha)
        @test r.residual ≈ 0 atol=1e-12
        for u in (-1.,-.3,0.,.7,1.)
            q=sample(p,u)
            @test q.tx^2+q.ty^2 ≈ 1
            @test q.tx*q.nx+q.ty*q.ny ≈ 0 atol=1e-12
        end
        @test sample(p,-1.).y ≈ 0 atol=1e-12
        @test r.fraction <= 1+1e-12
        if mode==3
            @test r.R ≈ a
            @test r.area ≈ pi*a^2/2
            @test sample(p,1.).tx ≈ 0 atol=1e-12
        end
    end
end
@testset "Dido and equal perimeter" begin
    for alpha in 15.:5.:165.
        p=parameters(mode=4,alpha=alpha);r=state(p)
        @test r.length ≈ 8
        @test r.area <= 8^2/(2pi)+1e-12
        if alpha==90
            @test r.area ≈ 8^2/(2pi)
        end
    end
    previous=0.
    for n in 3:60
        r=state(parameters(mode=6,n=n))
        @test previous<r.fraction<1
        previous=r.fraction
        n==4 && @test r.fraction ≈ pi/4
    end
    @test_throws ArgumentError state(parameters(alpha=100.))
    @test_throws ArgumentError state(parameters(mode=6,n=3.5))
end
