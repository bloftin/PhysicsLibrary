module PLInclinedPlane
using LinearAlgebra, Printf, SHA, TOML

function parameters(c)
    for key in ("mass", "gravity", "angle_deg", "length", "mu_s", "mu_k")
        isfinite(c[key]) || error("Nonfinite parameter: $key")
    end
    c["mass"] > 0 && c["gravity"] > 0 && c["length"] > 0 || error("Positive mass, gravity and length required")
    0 <= c["angle_deg"] < 90 || error("Angle must be in [0, 90) degrees")
    0 <= c["mu_k"] <= c["mu_s"] || error("Require 0 <= mu_k <= mu_s")
    c["samples"] isa Integer && 2 <= c["samples"] <= 1001 || error("Invalid samples")
    weight = c["mass"] * c["gravity"]
    normal = weight * cosd(c["angle_deg"])
    downhill = weight * sind(c["angle_deg"])
    # At the static limit rest remains possible. Tolerance covers roundoff only.
    stuck = downhill <= c["mu_s"] * normal + 8eps(weight)
    friction = stuck ? downhill : c["mu_k"] * normal
    acceleration = stuck ? 0.0 : (downhill - friction) / c["mass"]
    duration = stuck ? 4.0 : sqrt(2c["length"] / acceleration)
    (; weight, normal, downhill, stuck, friction, acceleration, duration)
end

function solution(c)
    p = parameters(c)
    A = [0.0 1.0 0.0; 0.0 0.0 p.acceleration; 0.0 0.0 0.0]
    # Constant forcing is represented by the third, constant state component.
    [(t=t, s=u[1], v=u[2], a=p.acceleration,
      kinetic=c["mass"]*u[2]^2/2,
      potential=p.downhill*(c["length"]-u[1]), dissipated=p.friction*u[1])
     for t in range(0.0, p.duration; length=c["samples"])
     for u in (exp(t*A)*[0.0, 0.0, 1.0],)]
end

function load_cases()
    config = TOML.parsefile(joinpath(@__DIR__, "cases.toml"))
    common = Dict(k => v for (k,v) in config if k != "cases")
    cases = [merge(common, c) for c in config["cases"]]
    ids = [c["id"] for c in cases]
    length(unique(ids)) == length(ids) || error("Duplicate case")
    all(id -> occursin(r"^[a-z][a-z0-9-]*$", id), ids) || error("Invalid id")
    foreach(parameters, cases)
    cases
end

filehash(path) = bytes2hex(open(sha256, path))
function generate()
    cases = load_cases()
    output = joinpath(@__DIR__, "results")
    mkpath(output)
    BLAS.set_num_threads(1)
    for c in cases
        open(joinpath(output, c["id"]*".csv"), "w") do io
            println(io, "time_s,distance_m,speed_m_s,acceleration_m_s2,kinetic_J,potential_J,dissipated_J")
            for r in solution(c)
                @printf(io, "%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n", r.t,r.s,r.v,r.a,r.kinetic,r.potential,r.dissipated)
            end
        end
    end
    provenance = Dict("julia_version"=>string(VERSION), "platform"=>string(Sys.MACHINE),
        "method"=>"LinearAlgebra.exp on [s,v,1]; Coulomb friction; release from rest; stop sampling at ramp end",
        "command"=>"julia --startup-file=no --project=. motion.jl",
        "inputs_sha256"=>Dict(n=>filehash(joinpath(@__DIR__,n)) for n in ("motion.jl","cases.toml","Project.toml","Manifest.toml")),
        "outputs_sha256"=>Dict(c["id"]*".csv"=>filehash(joinpath(output,c["id"]*".csv")) for c in cases))
    open(joinpath(output,"provenance.toml"),"w") do io
        TOML.print(io, provenance; sorted=true)
    end
    println("Generated three inclined-plane datasets")
end
end
if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) || error("No command-line arguments expected")
    PLInclinedPlane.generate()
end
