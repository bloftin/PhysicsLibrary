"""Read-only checks of the Julia reference output and static publication."""
from __future__ import annotations

import csv
import hashlib
import math
import tomllib
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data" / "examples" / "minimum-effort-interception"


def verify() -> None:
    publication = tomllib.loads((SITE / "provenance.toml").read_text())
    assert publication["generator"] == "julia"
    assert publication["julia_version"] == "1.10.12"
    for name, key in (("reference.csv", "reference_sha256"),
                      ("interception.jl", "julia_source_sha256"),
                      ("explorer.js", "viewer_sha256")):
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == publication[key]
    with (SITE / "reference.csv").open(newline="") as file:
        rows = list(csv.DictReader(file))
    assert len(rows) == 303
    cases = {"article": (100, 10), "near": (60, 12), "distant": (180, 6)}
    for name, (d, v) in cases.items():
        subset = [r for r in rows if r["case"] == name]
        assert len(subset) == 101
        assert float(subset[0]["time_s"]) == 0
        for i, row in enumerate(subset):
            t = d / v * i / 100
            assert math.isclose(float(row["d_m"]), d)
            assert math.isclose(float(row["v_m_s"]), v)
            assert math.isclose(float(row["time_s"]), t, abs_tol=1e-11)
            assert math.isclose(float(row["vehicle_m"]), 2*v*t, abs_tol=1e-10)
            assert math.isclose(float(row["target_m"]), d+v*t, abs_tol=1e-10)
            assert math.isclose(float(row["optimum_time_s"]), d/v)
            assert math.isclose(float(row["optimum_speed_m_s"]), 2*v)
            assert math.isclose(float(row["effort_m2_s"]), 2*d*v)
        assert math.isclose(float(subset[-1]["vehicle_m"]), float(subset[-1]["target_m"]))
    page = (SITE / "index.html").read_text()
    assert '<form' not in page and '<iframe' not in page
    assert '<script src="explorer.js" defer></script>' in page
    for name in ("style.css", "explorer.js", "reference.csv", "LICENSE.txt", "provenance.toml", "minimum-effort-interception.zip"):
        assert (SITE / name).is_file()
    assert (SITE / "minimum-effort-interception.zip").stat().st_size < 1_000_000
    with zipfile.ZipFile(SITE / "minimum-effort-interception.zip") as archive:
        assert "test/runtests.jl" in archive.namelist()
        assert "test/viewer.cjs" in archive.namelist()
        assert "build.py" in archive.namelist()
        assert "verify.py" in archive.namelist()
        assert archive.read("reference.csv") == (SITE / "reference.csv").read_bytes()
        assert archive.read("COPYING").startswith(b'                    GNU GENERAL PUBLIC LICENSE')
    print("PASS: Julia output, exact trajectory identities, hashes, static files and offline archive")


if __name__ == "__main__":
    verify()
