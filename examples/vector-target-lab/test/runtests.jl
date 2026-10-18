using Test, LinearAlgebra
include(joinpath(@__DIR__,"..","vector-target-lab.jl"))
using .VectorTargetLab
@testset "Vector endpoints and exact energy" begin
    for (_,p) in cases()
        r=evaluate(p); m=evaluate(minimize(p))
        @test sample(p,0).q ≈ r.A
        @test sample(p,1).q ≈ r.B
        @test r.J+1e-10 >= r.Jmin
        @test m.tangent < 1e-10
        @test m.residual == 0
        @test m.J ≈ r.Jmin atol=1e-10
        @test abs(dot(r.n,r.eta)) < 1e-12
        @test r.boundary+r.interior ≈ r.total atol=1e-12
        n=2000; energy=sum(sum(abs2,sample(p,(i+0.5)/n).velocity)/2*p.T/n for i in 0:n-1)
        @test energy ≈ r.J atol=1e-10
    end
end
@testset "Independent known normal-ray projections" begin
    for lon in (-170.0,-30.0,40.0,150.0),lat in (-60.0,10.0,75.0)
        p=merge(defaults,(mode="ellipsoid",tilt=53.0,yaw=-74.0,rx=0.6,ry=2.2,rz=1.3,))
        B=surface(p,lon,lat); E,C=frame(p); b=E'*(B-C); n=normalize(E*(b./[p.rx,p.ry,p.rz].^2)); A=B+2.1n
        p=merge(p,(ax=A[1],ay=A[2],az=A[3]))
        @test nearest(p) ≈ B atol=1e-11
    end
end
@testset "Sphere far-side stationarity is not a minimum" begin
    p=merge(defaults,(mode="sphere",tilt=0.0,yaw=0.0,ax=4.0,ay=0.0,az=0.0,lon=180.0,lat=0.0,))
    r=evaluate(p)
    @test r.tangent<1e-12
    @test r.J>r.Jmin
end
