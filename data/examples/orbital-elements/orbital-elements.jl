module OrbitalElements
using LinearAlgebra
using Printf

const MU = 398600.4418
const RE = 6378.137
const J2 = 1.08262668e-3
const PRESETS = [
    (name="gps", a=26560.0, e=.01, i=55.0, raan=40.0, argp=45.0, nu=30.0),
    (name="iss", a=6797.0, e=.0007, i=51.6, raan=139.1, argp=206.2, nu=30.0),
    (name="sso", a=7078.137, e=.001, i=98.19, raan=20.0, argp=90.0, nu=30.0),
    (name="geo", a=42164.0, e=0.0, i=0.0, raan=0.0, argp=0.0, nu=30.0),
    (name="gto", a=24371.0, e=.73, i=28.5, raan=40.0, argp=35.0, nu=20.0),
    (name="molniya", a=26600.0, e=.74, i=63.4349488, raan=30.0, argp=270.0, nu=60.0),
]
wrap(x) = mod(x, 2pi)
rz(x) = [cos(x) -sin(x) 0; sin(x) cos(x) 0; 0 0 1]
rx(x) = [1 0 0; 0 cos(x) -sin(x); 0 sin(x) cos(x)]
rotation(p) = rz(deg2rad(p.raan)) * rx(deg2rad(p.i)) * rz(deg2rad(p.argp))

function validate(p)
    all(isfinite, (p.a, p.e, p.i, p.raan, p.argp, p.nu)) || throw(ArgumentError("nonfinite element"))
    p.a > 0 && 0 <= p.e < 1 && 0 <= p.i <= 180 || throw(ArgumentError("bound elliptic elements required"))
end
function state(p)
    validate(p)
    nu = deg2rad(p.nu)
    l = p.a * (1 - p.e^2)
    radius = l / (1 + p.e * cos(nu))
    R = rotation(p)
    r = R * [radius * cos(nu), radius * sin(nu), 0]
    v = R * (sqrt(MU / l) .* [-sin(nu), p.e + cos(nu), 0])
    E = wrap(atan(sqrt(1 - p.e^2) * sin(nu), p.e + cos(nu)))
    M = wrap(E - p.e * sin(E))
    n = sqrt(MU / p.a^3)
    (; r, v, E, M, n, period=2pi/n, energy=-MU/(2p.a), h=sqrt(MU*l))
end
function rates(p)
    validate(p)
    k = J2 * sqrt(MU / p.a^3) * (RE / (p.a * (1 - p.e^2)))^2
    c = cosd(p.i)
    (; raan=-1.5k*c, argp=.75k*(5c^2 - 1))
end

# Independent monotone bracket solver, including the high-eccentricity regime.
function eccentric_anomaly(e, M)
    low, high = 0.0, 2pi
    for _ in 1:60
        mid = (low + high) / 2
        if mid - e*sin(mid) < M
            low = mid
        else
            high = mid
        end
    end
    (low + high) / 2
end
function advance(p, seconds, j2=false)
    isfinite(seconds) || throw(ArgumentError("time must be finite"))
    s = state(p)
    E = eccentric_anomaly(p.e, wrap(s.M + s.n*seconds))
    nu = rad2deg(wrap(atan(sqrt(1-p.e^2)*sin(E), cos(E)-p.e)))
    dr = j2 ? rates(p) : (raan=0.0, argp=0.0)
    merge(p, (nu=nu, raan=rad2deg(wrap(deg2rad(p.raan)+dr.raan*seconds)),
                  argp=rad2deg(wrap(deg2rad(p.argp)+dr.argp*seconds))))
end
function reference(path="reference.csv")
    open(path, "w") do io
        println(io, "preset,j2,fraction,time_s,x_km,y_km,z_km,vx_km_s,vy_km_s,vz_km_s,nu_deg,raan_deg,argp_deg")
        for p in PRESETS, j2 in (false, true), fraction in 0:.125:1
            t = state(p).period * fraction
            q = advance(p, t, j2)
            s = state(q)
            print(io, p.name, ",", Int(j2), ",")
            values = [fraction, t, s.r..., s.v..., q.nu, q.raan, q.argp]
            println(io, join([@sprintf("%.16g", x) for x in values], ","))
        end
    end
end
end

if abspath(PROGRAM_FILE) == @__FILE__
    OrbitalElements.reference(isempty(ARGS) ? "reference.csv" : ARGS[1])
end
