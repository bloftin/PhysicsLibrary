using Test
include("../inner-product-lab.jl")
using .InnerProductLab
@testset "Exact rational inner-product geometry" begin
    for (_,p) in cases()
        d=analyze(p,0//1)
        @test d.uu>=0 && d.vv>=0
        @test d.uv^2<=d.uu*d.vv
        @test inner(p,p.u,p.v)==inner(p,p.v,p.u)
        @test inner(p,2p.u.+3p.v,p.v)==2d.uv+3d.vv
        if !isnothing(d.optimal)
            best=analyze(p,d.optimal)
            @test best.rv==0
            @test d.uu==d.optimal^2*d.vv+best.error2
            for c in (-2//1,0//1,1//2,3//1)
                trial=analyze(p,c)
                @test trial.error2==best.error2+d.vv*(c-d.optimal)^2
            end
        else
            for c in (-2//1,0//1,1//2,3//1)
                @test analyze(p,c).error2==d.uu
            end
        end
    end
    byname=Dict(cases())
    @test analyze(byname["function_square"],0//1).optimal==1//3
    @test analyze(byname["function_cubic"],0//1).optimal==3//5
    @test analyze(byname["function_weighted"],0//1).optimal==2//3
    @test analyze(byname["function_norm"],0//1).uu==2//3
    @test analyze(byname["function_cancel"],0//1).uv==0
    @test analyze(byname["function_interval"],0//1).uv==1//2
    @test analyze(byname["matrix_trace"],0//1).optimal==2
    @test analyze(byname["matrix_symmetric"],0//1).uv==0
end
