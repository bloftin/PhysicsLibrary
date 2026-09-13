module PLConstantAcceleration

using LinearAlgebra, Printf, SHA, TOML

function load_cases(path=joinpath(@__DIR__, "cases.toml"))
    config = TOML.parsefile(path)
    ids = String[]
    for c in config["cases"]
        occursin(r"^[a-z][a-z0-9-]*$", c["id"]) || error("Invalid case id")
        c["id"] in ids && error("Duplicate case id")
        push!(ids, c["id"])
        for k in ("mass", "force", "x0", "v0", "t0", "duration")
            isfinite(c[k]) || error("$k must be finite")
        end
        c["mass"] > 0 && c["duration"] > 0 || error("Positive mass and duration required")
        c["samples"] isa Integer && 2 <= c["samples"] <= 1001 || error("Invalid sample count")
    end
    config
end

function solution(c)
    a = c["force"] / c["mass"]
    # Augment the state with 1 so constant forcing is a linear system.
    A = [0.0 1.0 0.0; 0.0 0.0 a; 0.0 0.0 0.0]
    u0 = [c["x0"], c["v0"], 1.0]
    [(t=c["t0"] + tau, x=u[1], v=u[2], a=a)
     for tau in range(0.0, c["duration"]; length=c["samples"])
     for u in (exp(tau * A) * u0,)]
end

filehash(path) = bytes2hex(open(sha256, path))

function generate()
    config = load_cases()
    output = joinpath(@__DIR__, "results")
    mkpath(output)
    BLAS.set_num_threads(1)
    for c in config["cases"]
        open(joinpath(output, c["id"] * ".csv"), "w") do io
            println(io, "time_s,position_m,velocity_m_s,acceleration_m_s2")
            for r in solution(c)
                @printf(io, "%.12g,%.12g,%.12g,%.12g\n", r.t, r.x, r.v, r.a)
            end
        end
    end
    provenance = Dict(
        "release" => "1", "julia_version" => string(VERSION),
        "platform" => string(Sys.MACHINE), "blas" => string(BLAS.get_config()),
        "blas_threads" => BLAS.get_num_threads(),
        "method" => "LinearAlgebra.exp on augmented [x,v,1] state; Float64; no time stepping",
        "command" => "julia --startup-file=no --project=. motion.jl",
        "inputs_sha256" => Dict(n => filehash(joinpath(@__DIR__, n))
            for n in ("motion.jl", "cases.toml", "Project.toml", "Manifest.toml")),
        "outputs_sha256" => Dict(c["id"] * ".csv" => filehash(joinpath(output, c["id"] * ".csv"))
            for c in config["cases"]))
    open(joinpath(output, "provenance.toml"), "w") do io
        TOML.print(io, provenance; sorted=true)
    end
    println("Generated three constant-acceleration datasets")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) || error("Usage: julia --project=. motion.jl")
    PLConstantAcceleration.generate()
end
