using Test
include("../constrained-variations.jl")
using .ConstrainedVariations
function integrate(p,f)
    n=4096;h=state(p).L/n
    h*(f(density(p,0.))/2+sum(f(density(p,h*i)) for i in 1:n-1)+f(density(p,h*n))/2)
end
@testset "Constrained Variations" begin
    for (name,p) in CASES
        r=state(p)
        @test abs(r.dK)<1e-12
        @test integrate(p,d->p.mode=="mean" ? d.yp^2/2 : d.yp^2) ≈ r.J atol=2e-5
        @test integrate(p,d->p.mode=="mean" ? d.y : d.y^2) ≈ r.K atol=2e-6
        @test integrate(p,d->d.gJ*d.eta) ≈ r.dJ atol=2e-5
        @test integrate(p,d->d.gK*d.eta) ≈ r.dK atol=2e-6
        @test sqrt(integrate(p,d->d.residual^2)) ≈ r.resL2 atol=1e-5
        @test abs(density(p,0.).y)<1e-12
        @test abs(density(p,r.L).y)<1e-12
        for i in 0:40
            d=density(p,r.L*i/40)
            @test all(isfinite,(d.y,d.yp,d.eta,d.gJ,d.gK,d.residual))
        end
    end
    for m in (-1.,-.5,0.,.5,1.)
        p=parameters(mean=m,b=0.,lambda=-12m);r=state(p)
        @test r.resL2<1e-12
        @test r.J ≈ 6m^2
        @test density(p,.37).y ≈ 6m*.37*.63
    end
    for theta in (0.,90.,180.,270.,360.)
        lambda=theta in (90.,270.) ? -4. : -1.
        @test state(parameters(mode="normalization",angle=theta,lambda=lambda)).resL2<1e-12
    end
    @test_throws ArgumentError state(parameters(norm=0.))
    @test_throws ArgumentError density(parameters(),-1.)
end
