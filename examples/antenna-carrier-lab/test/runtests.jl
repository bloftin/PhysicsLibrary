using Test
include(joinpath(@__DIR__,"..","antenna-carrier-lab.jl"))
using .AntennaCarrierLab
@testset "Short-dipole independent reference" begin
    ps=Dict(cases())
    @test parameters(ps["crossed"]).peak==0
    @test parameters(ps["axial"]).peak==0
    @test parameters(ps["zero"]).peak==0
    a=parameters(ps["aligned"]);matched=parameters(ps["lossless"])
    @test isapprox(matched.terminationPower,matched.radiated,rtol=big"1e-60")
    @test isapprox(a.heff,big".5")
    @test abs(a.reactance)<big"1e-60"
    @test a.peak>parameters(ps["detuned"]).peak
    @test a.peak>parameters(ps["untuned"]).peak
    for (_,p) in cases()
        m=parameters(p)
        @test p.length/m.lambda<big".1"
        @test isapprox(m.supplied,m.terminationPower+m.heat+m.radiated,atol=big"1e-60",rtol=big"1e-60")
        for cycle in [BigFloat(0),big".125",big".25",big".5",big".75"]
            s=sample(p,cycle);r=radiation(p,cycle)
            @test isapprox(s.velocity,-s.current/(AntennaCarrierLab.N*AntennaCarrierLab.E*AntennaCarrierLab.AREA),atol=big"1e-60")
            @test s.uC>=0 && s.uL>=0 && r.flux>=0
            @test isapprox(r.eTheta,AntennaCarrierLab.C0*r.bPhi,atol=big"1e-60")
        end
    end
end
