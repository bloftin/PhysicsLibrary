using Test
include(joinpath(@__DIR__,"..","potential-work-lab.jl"))
using .PotentialWorkLab
@testset "E01 independent references" begin
    ps=Dict(cases())
    @test endpoints(ps["plates"]).dv == -10
    @test isapprox(endpoints(ps["plates"]).du,big"-2e-8",rtol=big"1e-60")
    @test isapprox(endpoints(ps["plates"]).work,big"2e-8",rtol=big"1e-60")
    @test isapprox(endpoints(ps["sign"]).du,big"1e-5",rtol=big"1e-60")
    @test endpoints(ps["worked"]).du == big"12e-6"
    @test endpoints(ps["electron"]).du/E_CHARGE == -3
    for (_,p) in cases()
        e=endpoints(p)
        @test e.work == -e.du
        @test e.meter == -e.dv
        for route in ["direct","bent"]
            a=point(p,route,BigFloat(0));b=point(p,route,BigFloat(1))
            @test a.x == p.a.x && a.y == p.a.y
            @test isapprox(b.x,p.b.x,atol=big"1e-60") && isapprox(b.y,p.b.y,atol=big"1e-60")
            for f in [big".25",big".5",big".75"]
                s=point(p,route,f);v=environment(p,s.x,s.y)
                @test all(isfinite,[s.x,s.y,s.s,v.v,v.ex,v.ey])
            end
        end
    end
    dip=environment(ps["dipole"],BigFloat(0),BigFloat(0))
    @test dip.v==0 && dip.ex>0
    like=environment(ps["like"],BigFloat(0),BigFloat(0))
    @test like.ex==0 && like.ey==0 && like.v>0
    for r in BigFloat.([0,10,100]),load in BigFloat.([1,100,1e6]),rm in BigFloat.([100,1e7])
        b=battery(BigFloat(9),r,load,rm)
        @test isapprox(b.sourcePower,b.internalPower+b.loadPower+b.meterPower,rtol=big"1e-60")
        @test 0<=b.terminal<=9
    end
end
