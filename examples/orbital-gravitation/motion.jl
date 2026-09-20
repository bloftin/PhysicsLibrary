module PLOrbitalGravitation

using Printf, SHA, TOML

const TWO_PI = 2pi

filehash(path) = bytes2hex(open(sha256, path))

function load_config(path=joinpath(@__DIR__, "cases.toml"))
    config = TOML.parsefile(path)
    model, sweep = config["model"], config["sweep"]
    for key in ("gravitational_constant", "earth_mass_kg", "earth_radius_m",
                "initial_radius_factor", "duration_orbits")
        isfinite(model[key]) || error("Nonfinite model value: $key")
        model[key] > 0 || error("Positive model value required: $key")
    end
    model["samples"] isa Integer && 101 <= model["samples"] <= 1001 || error("Invalid sample count")
    for key in ("minimum_speed_factor", "maximum_speed_factor", "step")
        isfinite(sweep[key]) || error("Nonfinite sweep value: $key")
        sweep[key] > 0 || error("Positive sweep value required: $key")
    end
    sweep["minimum_speed_factor"] < sweep["maximum_speed_factor"] < 1.5 || error("Sweep must remain below 1.5 circular speeds")
    refs = config["reference_cases"]
    ids = [r["id"] for r in refs]
    length(unique(ids)) == length(ids) || error("Duplicate reference ID")
    all(id -> occursin(r"^[a-z][a-z0-9-]*$", id), ids) || error("Invalid reference ID")
    config
end

function model_values(config)
    m = config["model"]
    mu = m["gravitational_constant"] * m["earth_mass_kg"]
    r0 = m["initial_radius_factor"] * m["earth_radius_m"]
    vc = sqrt(mu / r0)
    period = TWO_PI * sqrt(r0^3 / mu)
    (; mu, r0, vc, period, radius=m["earth_radius_m"], samples=m["samples"],
       duration=m["duration_orbits"] * period)
end

acceleration(mu, x, y) = begin
    r2 = x*x + y*y
    factor = -mu / (r2 * sqrt(r2))
    (factor*x, factor*y)
end

"""Velocity-Verlet integration for a planar test particle.

The saved sample spacing is the integrator spacing.  The resource limits its
two-period window and speed sweep so a visitor cannot trigger unbounded work.
"""
function trajectory(values, speed_factor)
    isfinite(speed_factor) && 0.5 <= speed_factor < 1.5 || error("Invalid launch speed factor")
    n = values.samples
    dt = values.duration / (n - 1)
    x, y, vx, vy = values.r0, 0.0, 0.0, speed_factor * values.vc
    rows = Vector{NamedTuple}(undef, n)
    for i in 1:n
        r = hypot(x, y)
        ax, ay = acceleration(values.mu, x, y)
        rows[i] = (time=(i-1)*dt, x=x, y=y, vx=vx, vy=vy, r=r,
                   speed=hypot(vx, vy), acceleration=hypot(ax, ay),
                   specific_energy=(vx*vx + vy*vy)/2 - values.mu/r,
                   angular_momentum=x*vy-y*vx)
        i == n && break
        vxhalf, vyhalf = vx + ax*dt/2, vy + ay*dt/2
        x, y = x + vxhalf*dt, y + vyhalf*dt
        axnext, aynext = acceleration(values.mu, x, y)
        vx, vy = vxhalf + axnext*dt/2, vyhalf + aynext*dt/2
    end
    rows
end

function speed_factors(config)
    s = config["sweep"]
    count = round(Int, (s["maximum_speed_factor"] - s["minimum_speed_factor"]) / s["step"])
    values = [s["minimum_speed_factor"] + i*s["step"] for i in 0:count]
    length(values) == 37 || error("Viewer expects 37 launch-speed cases")
    values
end

function write_trajectory(io, rows)
    println(io, "time_s,x_m,y_m,vx_m_s,vy_m_s,radius_m,speed_m_s,acceleration_m_s2,specific_energy_J_kg,angular_momentum_m2_s")
    for row in rows
        @printf(io, "%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n",
                row.time, row.x, row.y, row.vx, row.vy, row.r, row.speed,
                row.acceleration, row.specific_energy, row.angular_momentum)
    end
end

function generate()
    config = load_config()
    values = model_values(config)
    output = joinpath(@__DIR__, "results")
    mkpath(output)
    for reference in config["reference_cases"]
        open(joinpath(output, reference["id"] * ".csv"), "w") do io
            write_trajectory(io, trajectory(values, reference["speed_factor"]))
        end
    end
    open(joinpath(output, "sweep.csv"), "w") do io
        println(io, "case_index,speed_factor,time_s,x_m,y_m,vx_m_s,vy_m_s,radius_m,speed_m_s,specific_energy_J_kg,angular_momentum_m2_s")
        for (index, factor) in enumerate(speed_factors(config))
            for row in trajectory(values, factor)
                @printf(io, "%d,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n",
                    index - 1, factor, row.time, row.x, row.y, row.vx, row.vy,
                    row.r, row.speed, row.specific_energy, row.angular_momentum)
            end
        end
    end
    inputs = ("motion.jl", "cases.toml", "Project.toml", "Manifest.toml")
    outputs = [r["id"] * ".csv" for r in config["reference_cases"]]
    push!(outputs, "sweep.csv")
    provenance = Dict(
        "julia_version" => string(VERSION),
        "platform" => string(Sys.MACHINE),
        "method" => "Planar two-body gravity; Float64 velocity-Verlet; fixed two-period window",
        "command" => "julia --startup-file=no --project=. motion.jl",
        "inputs_sha256" => Dict(name => filehash(joinpath(@__DIR__, name)) for name in inputs),
        "outputs_sha256" => Dict(name => filehash(joinpath(output, name)) for name in outputs))
    open(joinpath(output, "provenance.toml"), "w") do io
        TOML.print(io, provenance; sorted=true)
    end
    println("Generated $(length(speed_factors(config))) orbital trajectories and $(length(outputs)-1) reference datasets")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) || error("No command-line arguments expected")
    PLOrbitalGravitation.generate()
end
