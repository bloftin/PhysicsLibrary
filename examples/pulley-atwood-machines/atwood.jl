module PulleyAtwoodMachines

export state, duration, write_reference

function state(mode::Symbol, mass1::Real, mass2::Real, gravity::Real, time::Real)
    mode in (:fixed, :movable) || throw(ArgumentError("mode must be :fixed or :movable"))
    m1, m2, g, t = Float64.((mass1, mass2, gravity, time))
    all(isfinite, (m1, m2, g, t)) || throw(ArgumentError("inputs must be finite"))
    m1 > 0 && m2 > 0 && g > 0 && t >= 0 ||
        throw(ArgumentError("masses and gravity must be positive; time must be nonnegative"))

    if mode === :fixed
        # m2 downward and m1 upward are positive for the acceleration formula.
        a = (m2 - m1) * g / (m1 + m2)
        tension = 2m1 * m2 * g / (m1 + m2)
        d = a * t^2 / 2
        return (mode=mode, mass1=m1, mass2=m2, gravity=g, time=t,
                acceleration=a, tension=tension, mass1_down=-d, mass2_down=d,
                mass1_down_speed=-a*t, mass2_down_speed=a*t,
                constraint=-d+d)
    end

    # m2 is the load on the moving pulley, upward positive for acceleration.
    # The free mass m1 has twice that acceleration downward.
    a = (2m1 - m2) * g / (4m1 + m2)
    tension = m1 * (g - 2a)
    d = a * t^2 / 2
    return (mode=mode, mass1=m1, mass2=m2, gravity=g, time=t,
            acceleration=a, tension=tension, mass1_down=2d, mass2_down=-d,
            mass1_down_speed=2a*t, mass2_down_speed=-a*t,
            constraint=2(-d)+2d)
end

function duration(mode::Symbol, m1::Real, m2::Real, g::Real)
    acceleration = state(mode, m1, m2, g, 0).acceleration
    stroke = mode === :fixed ? 0.75 : acceleration < 0 ? 0.3 : 0.5
    return abs(acceleration) < 1e-9 ? 3.0 : sqrt(2 * stroke / abs(acceleration))
end

function write_reference(path::AbstractString)
    cases = (("atwood", :fixed, 3.0, 5.0, 9.81),
             ("balanced", :fixed, 4.0, 4.0, 9.81),
             ("movable", :movable, 4.0, 6.0, 9.81),
             ("movable-balanced", :movable, 3.0, 6.0, 9.81))
    open(path, "w") do file
        println(file, "case,mode,m1_kg,m2_kg,gravity_m_s2,time_s,m1_down_m,m2_down_m,m1_down_m_s,m2_down_m_s,load_up_m_s2,tension_N,constraint_m")
        for (name, mode, m1, m2, g) in cases
            finish = duration(mode, m1, m2, g)
            for i in 0:120
                s = state(mode, m1, m2, g, finish * i / 120)
                println(file, join((name, mode, m1, m2, g, s.time, s.mass1_down,
                    s.mass2_down, s.mass1_down_speed, s.mass2_down_speed,
                    s.acceleration, s.tension, s.constraint), ','))
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    write_reference(joinpath(@__DIR__, "reference.csv"))
end

end
