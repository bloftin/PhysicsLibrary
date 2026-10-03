"""Check published files and reference data against independent force equations."""
from __future__ import annotations

import csv
import hashlib
import json
import math
import tomllib
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data" / "examples" / "pulley-atwood-machines"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def close(actual: float, expected: float) -> None:
    if not math.isclose(actual, expected, rel_tol=1e-11, abs_tol=1e-11):
        raise AssertionError(f"{actual} differs from {expected}")


def verify() -> None:
    with (HERE / "reference.csv").open(newline="") as file:
        rows = list(csv.DictReader(file))
    assert len(rows) == 4 * 121
    assert {row["case"] for row in rows} == {
        "atwood", "balanced", "movable", "movable-balanced"
    }
    for row in rows:
        m1, m2, g, t, y1, y2, v1, v2, a, tension, residual = (
            float(row[name]) for name in (
                "m1_kg", "m2_kg", "gravity_m_s2", "time_s", "m1_down_m",
                "m2_down_m", "m1_down_m_s", "m2_down_m_s",
                "load_up_m_s2", "tension_N", "constraint_m"
            )
        )
        if row["mode"] == "fixed":
            close(a, (m2 - m1) * g / (m1 + m2))
            close(tension - m1 * g, m1 * a)
            close(m2 * g - tension, m2 * a)
            close(y1 + y2, 0)
            close(v1 + v2, 0)
            close(y2, a * t * t / 2)
        else:
            close(a, (2 * m1 - m2) * g / (4 * m1 + m2))
            close(m1 * g - tension, 2 * m1 * a)
            close(2 * tension - m2 * g, m2 * a)
            close(y1 + 2 * y2, 0)
            close(v1 + 2 * v2, 0)
            close(y2, -a * t * t / 2)
        close(residual, 0)

    provenance = tomllib.loads((SITE / "provenance.toml").read_text(encoding="ascii"))
    assert provenance["reference_sha256"] == sha(HERE / "reference.csv")
    assert provenance["julia_source_sha256"] == sha(HERE / "atwood.jl")
    assert provenance["browser_model_sha256"] == sha(HERE / "model.js")
    assert provenance["viewer_sha256"] == sha(HERE / "explorer.js")
    for name in ("index.html", "style.css", "model.js", "explorer.js", "atwood.jl", "reference.csv"):
        assert sha(HERE / name) == sha(SITE / name), name
    with zipfile.ZipFile(SITE / "pulley-atwood-machines.zip") as archive:
        assert archive.testzip() is None
        assert "atwood.jl" in archive.namelist()
        assert "test/runtests.jl" in archive.namelist()
        assert "COPYING" in archive.namelist()
    manifest = json.loads((HERE / "computational-resources.json").read_text(encoding="utf-8"))
    catalog = json.loads((HERE.parents[1] / "etc" / "computational-resources.json").read_text(encoding="utf-8"))
    assert manifest == {"schema_version": 1, "resources": ["pulley-atwood-machines"]}
    resource = catalog["resources"]["pulley-atwood-machines"]
    for name in (resource["explorer"], resource["source"], resource["provenance"],
                 resource["license"], *(item["file"] for item in resource["datasets"])):
        assert (SITE / name).is_file(), name
    print(f"Verified {len(rows)} reference states and published assets")


if __name__ == "__main__":
    verify()
