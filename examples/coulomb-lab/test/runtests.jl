using Test
include("../coulomb-lab.jl")
using .CoulombLab
@testset "BigFloat Coulomb force and field checks" begin
    for (_,qs) in cases()
        fs=forces(qs)
        @test abs(sum(f.x for f in fs))<big"1e-70"
        @test abs(sum(f.y for f in fs))<big"1e-70"
        for (i,q) in enumerate(qs)
            e=field(qs,q.x,q.y,omit=i)
            @test fs[i].x≈q.q*e.x atol=big"1e-70"
            @test fs[i].y≈q.q*e.y atol=big"1e-70"
        end
    end
    qs=Dict(cases())["dipole"];f=forces(qs)
    @test f[1].x>0 && f[2].x<0
    @test f[1].magnitude≈K*big"1e-12"/4
    moved=[(x=2q.x,y=2q.y,q=q.q) for q in qs]
    @test forces(moved)[1].magnitude≈f[1].magnitude/4
    doubled=[(x=q.x,y=q.y,q=2q.q) for q in qs]
    @test forces(doubled)[1].magnitude≈4f[1].magnitude
    @test field(qs,-1,0)===nothing
    for name in ("like","balance","quadrupole")
        e=field(Dict(cases())[name],0,0,omit=name=="balance" ? 2 : 0)
        @test e.magnitude<big"1e-70"
    end
end
