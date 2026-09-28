"""Read-only verification of the Julia reference data and static publication."""
from __future__ import annotations

import csv
import hashlib
import math
import tomllib
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data" / "examples" / "gre-uniform-circular-motion"


def verify() -> None:
    provenance = tomllib.loads((SITE / "provenance.toml").read_text(encoding="utf-8"))
    assert provenance["generator"] == "julia"
    assert provenance["julia_version"] == "1.10.12"
    for name, key in (("reference.csv", "reference_sha256"),
                      ("circular_motion.jl", "julia_source_sha256"),
                      ("explorer.js", "viewer_sha256")):
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == provenance[key]
    with (SITE / "reference.csv").open(newline="") as file:
        rows = list(csv.DictReader(file))
    assert len(rows) == 4 * 121
    cases = {"article": (5.0, 8.0), "wheel": (0.35, 4*math.pi*0.35),
             "vectors": (2.0, 6.0), "disk": (0.6, 2.4)}
    for name, (radius, speed) in cases.items():
        subset = [row for row in rows if row["case"] == name]
        assert len(subset) == 121
        period = 2*math.pi*radius/speed
        for i, row in enumerate(subset):
            t = period*i/120
            theta = speed*t/radius
            x, y = radius*math.cos(theta), radius*math.sin(theta)
            for key, expected in {
                "radius_m":radius, "speed_m_s":speed, "time_s":t,
                "x_m":x, "y_m":y,
                "vx_m_s":-speed*math.sin(theta), "vy_m_s":speed*math.cos(theta),
                "ax_m_s2":-speed**2/radius*math.cos(theta),
                "ay_m_s2":-speed**2/radius*math.sin(theta),
                "omega_rad_s":speed/radius, "period_s":period,
                "frequency_hz":1/period, "acceleration_m_s2":speed**2/radius,
            }.items():
                assert math.isclose(float(row[key]), expected, abs_tol=1e-10), (name, i, key)
        assert math.isclose(float(subset[-1]["x_m"]),float(subset[0]["x_m"]),abs_tol=1e-10)
        assert math.isclose(float(subset[-1]["y_m"]),float(subset[0]["y_m"]),abs_tol=1e-10)
    page = (SITE / "index.html").read_text(encoding="utf-8")
    assert '<form' not in page and '<iframe' not in page
    assert '<script src="explorer.js" defer></script>' in page
    for name in ("index.html", "style.css", "explorer.js", "reference.csv", "LICENSE.txt", "provenance.toml", "gre-uniform-circular-motion.zip"):
        assert (SITE / name).is_file()
    assert (SITE / "gre-uniform-circular-motion.zip").stat().st_size < 1_000_000
    with zipfile.ZipFile(SITE / "gre-uniform-circular-motion.zip") as archive:
        for name in ("circular_motion.jl", "test/runtests.jl", "test/viewer.cjs", "build.py", "verify.py", "COPYING"):
            assert name in archive.namelist()
        assert archive.read("reference.csv") == (SITE / "reference.csv").read_bytes()
    print("PASS: Julia output, vectors, period, provenance, static assets and offline archive")


if __name__ == "__main__":
    verify()
