module PLBrachistochrone

using Printf, SHA, TOML

const TWO_PI = 2 * pi

function load_cases(path=joinpath(@__DIR__, "cases.toml"))
    config = TOML.parsefile(path)
    model = config["model"]
    g = model["gravity"]
    isfinite(g) && g > 0 || error("gravity must be finite and positive")
    samples = model["samples"]
    samples isa Integer && 3 <= samples <= 10001 || error("samples must be 3..10001")
    conv = model["convergence_segments"]
    conv isa Vector && !isempty(conv) || error("convergence_segments must be a nonempty array")
    all(n -> n isa Integer && 2 <= n <= 1_000_000, conv) || error("invalid convergence segment count")
    issorted(conv) && length(unique(conv)) == length(conv) || error("convergence_segments must be unique and sorted")
    ids = String[]
    for c in config["cases"]
        id = c["id"]
        occursin(r"^[a-z][a-z0-9-]*$", id) || error("invalid case id")
        id in ids && error("duplicate case id")
        push!(ids, id)
        for key in ("x", "y")
            isfinite(c[key]) && c[key] > 0 || error("$key must be finite and positive")
        end
    end
    rmin, rmax, rstep = model["sweep_ratio_min"], model["sweep_ratio_max"], model["sweep_ratio_step"]
    0 < rmin <= rmax && rstep > 0 || error("invalid sweep range")
    return config
end

"""Dimensionless endpoint ratio R(theta)=(theta-sin(theta))/(1-cos(theta))."""
function endpoint_ratio(theta)
    0 < theta < TWO_PI || error("theta must lie in (0, 2pi)")
    if abs(theta) < 1e-4
        # Cancellation-safe series through theta^7.
        return theta/3 + theta^3/90 + theta^5/2520 + theta^7/75600
    end
    return (theta - sin(theta)) / (1 - cos(theta))
end

"""Saved bisection iterations for X/Y = R(theta_B)."""
function bisection_history(ratio; atol=1e-13, maxiter=200)
    isfinite(ratio) && ratio > 0 || error("endpoint ratio X/Y must be finite and positive")
    lo, hi = 1e-12, TWO_PI - 1e-10
    rows = NamedTuple[]
    for iteration in 1:maxiter
        mid = (lo + hi) / 2
        value = endpoint_ratio(mid)
        residual = value - ratio
        push!(rows, (iteration=iteration, lo=lo, hi=hi, mid=mid,
                     value=value, target=ratio, residual=residual,
                     width=hi-lo))
        if residual < 0
            lo = mid
        else
            hi = mid
        end
        hi - lo <= atol * max(1.0, abs(mid)) && return rows
    end
    error("endpoint solve did not converge")
end

"""Solve X/Y = R(theta_B) by monotone bisection on (0,2pi)."""
solve_theta(ratio; kwargs...) = begin
    history = bisection_history(ratio; kwargs...)
    lastrow = last(history)
    # The final update is not stored as another row, so use the midpoint of the
    # final pre-update bracket for a stable representative of the root.
    lastrow.mid
end

line_time(X, Y, g) = sqrt(2 * (X^2 + Y^2) / (g * Y))
l_path_time(X, Y, g) = sqrt(2 * Y / g) + X / sqrt(2 * g * Y)

function solve_case(c, model)
    X, Y, g = c["x"], c["y"], model["gravity"]
    history = bisection_history(X / Y)
    thetaB = last(history).mid
    a = Y / (1 - cos(thetaB))
    scale = sqrt(a / g)
    samples = model["samples"]
    rows = [(theta=theta,
             x=a*(theta - sin(theta)),
             y=a*(1 - cos(theta)),
             t=scale*theta,
             v=sqrt(max(0.0, 2 * g * a*(1 - cos(theta)))))
            for theta in range(0.0, thetaB; length=samples)]
    deepest = thetaB <= pi ? Y : 2 * a
    return (id=c["id"], label=c["label"], X=X, Y=Y, g=g,
            thetaB=thetaB, a=a, time=scale*thetaB,
            line_time=line_time(X,Y,g), l_time=l_path_time(X,Y,g),
            deepest=deepest, rows=rows, history=history)
end

"""Piecewise-linear path-time estimate using midpoint depth on each segment."""
function segment_time(sol; segments=10000)
    segments isa Integer && segments >= 2 || error("segments must be an integer >= 2")
    total = 0.0
    x0 = 0.0
    y0 = 0.0
    for k in 1:segments
        th = sol.thetaB * k / segments
        x1 = sol.a*(th - sin(th))
        y1 = sol.a*(1 - cos(th))
        ds = hypot(x1 - x0, y1 - y0)
        ymid = (y0 + y1)/2
        total += ds / sqrt(2 * sol.g * ymid)
        x0, y0 = x1, y1
    end
    total
end

filehash(path) = bytes2hex(open(sha256, path))

function generate(output=joinpath(@__DIR__, "results"))
    config = load_cases()
    model = config["model"]
    mkpath(output)
    solved = [solve_case(c, model) for c in config["cases"]]
    for sol in solved
        open(joinpath(output, sol.id * ".csv"), "w") do io
            println(io, "theta_rad,x_m,y_m,time_s,speed_m_s")
            for r in sol.rows
                @printf(io, "%.12g,%.12g,%.12g,%.12g,%.12g\n", r.theta, r.x, r.y, r.t, r.v)
            end
        end
    end
    open(joinpath(output, "root-history.csv"), "w") do io
        println(io, "case_id,iteration,lo_rad,hi_rad,mid_rad,ratio_mid,target_ratio,residual,bracket_width_rad")
        for sol in solved, r in sol.history
            @printf(io, "%s,%d,%.16g,%.16g,%.16g,%.16g,%.16g,%.16g,%.16g\n",
                    sol.id, r.iteration, r.lo, r.hi, r.mid, r.value,
                    r.target, r.residual, r.width)
        end
    end
    open(joinpath(output, "time-convergence.csv"), "w") do io
        println(io, "case_id,segments,time_estimate_s,exact_time_s,absolute_error_s,relative_error")
        for sol in solved, segments in model["convergence_segments"]
            estimate = segment_time(sol; segments=segments)
            error = estimate - sol.time
            @printf(io, "%s,%d,%.16g,%.16g,%.16g,%.16g\n",
                    sol.id, segments, estimate, sol.time, abs(error), error/sol.time)
        end
    end
    open(joinpath(output, "endpoint-sweep.csv"), "w") do io
        println(io, "x_over_y,theta_B_rad,a_per_y,time_over_sqrt_y_over_g,line_time_over_sqrt_y_over_g,deepest_over_y,time_savings_percent")
        rmin, rmax, dr = model["sweep_ratio_min"], model["sweep_ratio_max"], model["sweep_ratio_step"]
        n = round(Int, (rmax-rmin)/dr)
        for i in 0:n
            ratio = rmin + i*dr
            th = solve_theta(ratio)
            apery = 1 / (1 - cos(th))
            td = th*sqrt(apery)
            line = sqrt(2*(ratio^2+1))
            deepest = th <= pi ? 1.0 : 2 * apery
            saving = 100*(line-td)/line
            @printf(io, "%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n",
                    ratio, th, apery, td, line, deepest, saving)
        end
    end
    outputs = [sol.id * ".csv" for sol in solved]
    append!(outputs, ["endpoint-sweep.csv", "root-history.csv", "time-convergence.csv"])
    provenance = Dict(
        "release" => "2",
        "generator" => "julia",
        "julia_version" => string(VERSION),
        "platform" => string(Sys.MACHINE),
        "method" => "Monotone bisection with saved iteration history; closed-form cycloid sampling; saved midpoint-segment travel-time convergence",
        "command" => "julia --startup-file=no --project=. brachistochrone.jl",
        "inputs_sha256" => Dict(name => filehash(joinpath(@__DIR__, name))
            for name in ("brachistochrone.jl", "cases.toml", "Project.toml", "Manifest.toml")),
        "outputs_sha256" => Dict(name => filehash(joinpath(output, name)) for name in outputs),
    )
    open(joinpath(output, "provenance.toml"), "w") do io
        TOML.print(io, provenance; sorted=true)
    end
    println("Generated three brachistochrone paths, root histories, time-convergence data, and endpoint-ratio sweep in ", output)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) <= 1 || error("Usage: julia --project=. brachistochrone.jl [output-directory]")
    PLBrachistochrone.generate(isempty(ARGS) ? joinpath(@__DIR__, "results") : only(ARGS))
end