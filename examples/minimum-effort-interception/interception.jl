module MinimumEffortInterception

export solution, trial, sample_position, write_reference

using SHA

function checked(d, v)
    isfinite(d) && d > 0 || throw(ArgumentError("initial separation must be positive and finite"))
    isfinite(v) && v > 0 || throw(ArgumentError("target speed must be positive and finite"))
end

function trial(d, v, t)
    checked(d, v)
    isfinite(t) && t > 0 || throw(ArgumentError("intercept time must be positive and finite"))
    u = v + d / t
    return (time=t, speed=u, endpoint=d+v*t, effort=u^2*t/2)
end

function solution(d, v)
    checked(d, v)
    t = d / v
    result = trial(d, v, t)
    return (time=t, speed=result.speed, endpoint=result.endpoint, effort=result.effort)
end

function sample_position(d, v, t, sample)
    state = trial(d, v, t)
    isfinite(sample) && 0 <= sample <= t || throw(ArgumentError("sample must lie within interception"))
    return (vehicle=state.speed*sample, target=d+v*sample)
end

function write_reference(path)
    cases = (("article", 100.0, 10.0), ("near", 60.0, 12.0), ("distant", 180.0, 6.0))
    open(path, "w") do file
        println(file, "case,d_m,v_m_s,time_s,vehicle_m,target_m,optimum_time_s,optimum_speed_m_s,effort_m2_s")
        for (name,d,v) in cases
            optimum = solution(d,v)
            for i in 0:100
                time = optimum.time*i/100
                println(file, join((name,d,v,time,optimum.speed*time,d+v*time,
                    optimum.time,optimum.speed,optimum.effort), ','))
            end
        end
    end
    return bytes2hex(sha256(read(path)))
end

if abspath(PROGRAM_FILE) == @__FILE__
    path = joinpath(@__DIR__, "reference.csv")
    println("reference.csv sha256 ", write_reference(path))
    println("Julia ", VERSION)
end

end
