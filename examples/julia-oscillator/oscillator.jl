module PLOscillator

using LinearAlgebra, Printf, SHA, TOML

function load_presets(path=joinpath(@__DIR__, "presets.toml"))
    config = TOML.parsefile(path)
    model = config["model"]
    for field in ("mass", "stiffness", "duration")
        value = model[field]
        isfinite(value) && value > 0 || error("$field must be finite and positive")
    end
    for field in ("displacement", "velocity")
        isfinite(model[field]) || error("$field must be finite")
    end
    samples = model["samples"]
    samples isa Integer && 2 <= samples <= 10001 || error("samples must be 2..10001")
    ids = String[]
    for preset in config["presets"]
        id = preset["id"]
        occursin(r"^[a-z][a-z0-9-]*$", id) || error("Invalid preset id")
        id in ids && error("Duplicate preset id")
        push!(ids, id)
        c = preset["damping"]
        isfinite(c) && c >= 0 || error("damping must be finite and nonnegative")
    end
    return config
end

function solution(model, damping)
    m, k = model["mass"], model["stiffness"]
    # The standard-library matrix exponential also handles repeated roots at critical damping.
    A = [0.0 1.0; -k / m -damping / m]
    initial = [model["displacement"], model["velocity"]]
    times = range(0.0, model["duration"]; length=model["samples"])
    states = [exp(t * A) * initial for t in times]
    return [(t=t, x=u[1], v=u[2], energy=(m*u[2]^2+k*u[1]^2)/2)
            for (t, u) in zip(times, states)]
end

filehash(path) = bytes2hex(open(sha256, path))

function sweep(config)
    model = merge(config["model"], Dict("samples" => 151))
    scale = 1_000_000
    cases = []
    for step in 0:20
        zeta = step / 10
        damping = 2zeta * sqrt(model["mass"] * model["stiffness"])
        rows = solution(model, damping)
        push!(cases, Dict("zeta" => zeta, "damping" => damping,
            "x" => [round(Int, r.x * scale) for r in rows],
            "v" => [round(Int, r.v * scale) for r in rows],
            "energy" => [round(Int, r.energy * scale) for r in rows]))
    end
    return Dict("version" => 1, "scale" => scale, "duration" => model["duration"],
        "samples" => model["samples"], "cases" => cases)
end

function generate(output=joinpath(@__DIR__, "results"))
    config = load_presets()
    mkpath(output)
    BLAS.set_num_threads(1)
    for preset in config["presets"]
        rows = solution(config["model"], preset["damping"])
        open(joinpath(output, preset["id"] * ".csv"), "w") do io
            println(io, "time_s,displacement_m,velocity_m_s,energy_J")
            for row in rows
                @printf(io, "%.12g,%.12g,%.12g,%.12g\n", row.t, row.x, row.v, row.energy)
            end
        end
    end
    open(joinpath(output, "sweep.toml"), "w") do io
        TOML.print(io, sweep(config); sorted=true)
    end
    provenance = Dict(
        "julia_version" => string(VERSION),
        "method" => "LinearAlgebra.exp: exp(t*A)*initial_state; Float64",
        "platform" => string(Sys.MACHINE),
        "blas" => string(BLAS.get_config()),
        "blas_threads" => BLAS.get_num_threads(),
        "inputs_sha256" => Dict(name => filehash(joinpath(@__DIR__, name))
            for name in ("oscillator.jl", "presets.toml", "Project.toml", "Manifest.toml")),
        "outputs_sha256" => Dict(name => filehash(joinpath(output, name))
            for name in vcat([p["id"] * ".csv" for p in config["presets"]], ["sweep.toml"])),
    )
    open(joinpath(output, "provenance.toml"), "w") do io
        TOML.print(io, provenance; sorted=true)
    end
    println("Generated three reference presets and a 21-case sweep in ", output)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) <= 1 || error("Usage: julia --project=. oscillator.jl [output-directory]")
    PLOscillator.generate(isempty(ARGS) ? joinpath(@__DIR__, "results") : only(ARGS))
end
