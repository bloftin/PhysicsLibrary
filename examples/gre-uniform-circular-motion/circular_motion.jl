module GREUniformCircularMotion

export state, write_reference

using SHA

function state(radius, speed, theta0, time)
    isfinite(radius) && radius > 0 || throw(ArgumentError("radius must be positive and finite"))
    isfinite(speed) && speed > 0 || throw(ArgumentError("speed must be positive and finite"))
    isfinite(theta0) || throw(ArgumentError("starting angle must be finite"))
    isfinite(time) && time >= 0 || throw(ArgumentError("time must be nonnegative and finite"))
    omega = speed / radius
    theta = theta0 + omega * time
    c, s = cos(theta), sin(theta)
    accel = speed^2 / radius
    return (x=radius*c, y=radius*s, vx=-speed*s, vy=speed*c,
            ax=-accel*c, ay=-accel*s, omega=omega,
            period=2pi/omega, frequency=omega/(2pi), acceleration=accel)
end

function write_reference(path)
    cases = (("article", 5.0, 8.0, 0.0),
             ("wheel", 0.35, 4pi*0.35, 0.0),
             ("vectors", 2.0, 6.0, 0.0),
             ("disk", 0.6, 2.4, 0.0))
    open(path, "w") do file
        println(file, "case,radius_m,speed_m_s,theta0_rad,time_s,x_m,y_m,vx_m_s,vy_m_s,ax_m_s2,ay_m_s2,omega_rad_s,period_s,frequency_hz,acceleration_m_s2")
        for (name,radius,speed,theta0) in cases
            period = state(radius,speed,theta0,0.0).period
            for i in 0:120
                time = period * i / 120
                s = state(radius,speed,theta0,time)
                println(file, join((name,radius,speed,theta0,time,s.x,s.y,s.vx,s.vy,s.ax,s.ay,
                    s.omega,s.period,s.frequency,s.acceleration), ','))
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
