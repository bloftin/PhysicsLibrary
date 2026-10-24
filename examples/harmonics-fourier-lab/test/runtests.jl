using Test
include(joinpath(@__DIR__,"..","harmonics-fourier-lab.jl"))
using .HarmonicsFourierLab
@testset "Finite sums, common periods, phase and orthogonality" begin
    for (_,p) in cases()
        m=stats(p)
        for q in (0.,.07,.25,.43,.9,1.1)
            @test signal(p,q+1) ≈ signal(p,q) atol=2e-12
            if !isnothing(m.period)
                @test signal(p,q+m.period*p.f0) ≈ signal(p,q) atol=2e-12
            end
        end
        values=[signal(p,i/2048) for i in 0:2047]
        @test sum(values)/length(values) ≈ p.dc atol=1e-12
        @test sqrt(sum(abs2,values)/length(values)) ≈ m.rms atol=1e-12
        samples=tone(p;seconds=.1)
        @test samples[1]==0. && samples[end]==0.
        @test maximum(abs,samples)<=.15+1e-12
    end
    @test signal(preset("article"),.25) ≈ 1. atol=1e-12
    @test stats(preset("even")).divisor==2
    @test stats(preset("missing")).divisor==1
    @test isnothing(stats(preset("constant")).period)
    @test all(iszero,tone(preset("constant")))
    p=preset("single"); p.a[1]=0.;p.b[1]=1.
    @test signal(p,.25) ≈ 1.
    @test signal(p,0.) ≈ 0. atol=1e-12
    @test_throws ArgumentError preset("unknown")
end
@testset "WAV structure" begin
    mktempdir() do folder
        file=joinpath(folder,"tone.wav");writewav(file,preset("square");seconds=.1)
        open(file) do io
            @test String(read(io,4))=="RIFF"
            @test ltoh(read(io,UInt32))==filesize(file)-8
            @test String(read(io,8))=="WAVEfmt "
            seek(io,24);@test ltoh(read(io,UInt32))==48000
            seek(io,40);@test ltoh(read(io,UInt32))==9600
        end
    end
end
