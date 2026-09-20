"""Publish saved Julia orbital trajectories and an offline explorer without executing Julia."""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import zipfile

HERE = Path(__file__).resolve().parent
DEFAULT_SITE = HERE.parents[1] / "data" / "examples" / "orbital-gravitation"
INPUTS = ("motion.jl", "cases.toml", "Project.toml", "Manifest.toml")
REFERENCE_IDS = ("elliptical", "circular", "escape")
REFERENCES = ({"id": "elliptical", "label": "Elliptical orbit"},
              {"id": "circular", "label": "Circular orbit"},
              {"id": "escape", "label": "Near escape"})
SAMPLES = 361
EARTH_RADIUS_M = 6.371e6
MU = 6.67430e-11 * 5.9722e24
R0 = 4.0 * EARTH_RADIUS_M
DURATION_S = 2.0 * 2.0 * math.pi * math.sqrt(R0 ** 3 / MU)
SOURCES = INPUTS + ("test/runtests.jl", "README.md", "LICENSE.txt", "COPYING", "article.tex",
                    "preamble.tex", "preview.tex", "build.py", "verify.py", "viewer.template.html",
                    "style.css", "explorer.js", "computational-resources.json", "reference-orbits.png")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def provenance_values(path):
    """Read the string-only fields emitted by motion.jl without a TOML package."""
    section, values = "", {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        if raw.startswith("[") and raw.endswith("]"):
            section = raw[1:-1]
            continue
        matched = re.fullmatch(r'(?:"([^"]+)"|([A-Za-z0-9_]+)) = "([^"]*)"', raw)
        if matched:
            values[(section, matched.group(1) or matched.group(2))] = matched.group(3)
    return values


def read_rows(path):
    with path.open(newline="") as stream:
        return [{key: float(value) for key, value in row.items()} for row in csv.DictReader(stream)]


def checked_inputs():
    provenance = provenance_values(HERE / "results" / "provenance.toml")
    for name in INPUTS:
        if digest(HERE / name) != provenance.get(("inputs_sha256", name)):
            raise ValueError("Regenerate Julia results after changing " + name)
    factors = [round(.70 + .02 * i, 2) for i in range(37)]
    sweep = read_rows(HERE / "results" / "sweep.csv")
    if len(sweep) != 37 * SAMPLES:
        raise ValueError("Incomplete launch-speed sweep")
    if any(digest(HERE / "results" / name) != provenance.get(("outputs_sha256", name))
           for name in [row["id"] + ".csv" for row in REFERENCES] + ["sweep.csv"]):
        raise ValueError("Regenerate Julia results after modifying a CSV")
    if len(factors) != 37:
        raise ValueError("Unexpected speed grid")
    return provenance, sweep


def orbit_data(sweep):
    samples, scale = SAMPLES, 100
    cases = []
    for index, factor in enumerate([.70 + .02 * i for i in range(37)]):
        rows = sweep[index * samples:(index + 1) * samples]
        if any(int(row["case_index"]) != index or abs(row["speed_factor"] - factor) > 1e-9 for row in rows):
            raise ValueError("Unexpected case ordering in sweep")
        case = {"factor": round(factor, 2)}
        for output, source in (("x", "x_m"), ("y", "y_m"), ("vx", "vx_m_s"), ("vy", "vy_m_s"),
                               ("r", "radius_m"), ("energy", "specific_energy_J_kg")):
            values = [round(row[source] / scale) for row in rows]
            if any(abs(value) > 9000000000000000 for value in values):
                raise ValueError("Unsafe integer conversion")
            case[output] = values
        cases.append(case)
    return {"version": 1, "scale": scale, "samples": samples, "cases": cases,
            "earth_radius_m": EARTH_RADIUS_M, "mu": MU, "time_s": DURATION_S}


def draw_reference(site, refs):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Circle
    colors = ("#157b72", "#435fac", "#b23958")
    rows = {item["id"]: read_rows(HERE / "results" / (item["id"] + ".csv")) for item in refs}
    radius = EARTH_RADIUS_M
    for mobile in (False, True):
        fig, ax = plt.subplots(figsize=(6.0 if mobile else 10.8, 6.0))
        ax.add_patch(Circle((0, 0), radius / 1000, facecolor="#286caf", edgecolor="#143c75", linewidth=1.2, label="Earth"))
        for item, color in zip(refs, colors):
            r = rows[item["id"]]
            ax.plot([row["x_m"] / 1000 for row in r], [row["y_m"] / 1000 for row in r], color=color, linewidth=2.1, label=item["label"])
        ax.set_aspect("equal", adjustable="box")
        ax.set_xlabel("x (km)"); ax.set_ylabel("y (km)")
        ax.grid(color="#e2e8e4", linewidth=.7); ax.spines[["top", "right"]].set_visible(False)
        ax.legend(frameon=False, loc="upper left", fontsize=9 if mobile else 11)
        fig.tight_layout()
        fig.savefig(site / ("reference-orbits-mobile.png" if mobile else "reference-orbits.png"), dpi=100)
        plt.close(fig)


def archive(path, files):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as output:
        for name, contents in sorted(files.items()):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            output.writestr(info, contents)


def publish(site):
    provenance, sweep = checked_inputs()
    refs = REFERENCES
    site.mkdir(parents=True, exist_ok=True)
    data = orbit_data(sweep)
    (site / "orbit-data.js").write_text("window.PLOrbitData = " + json.dumps(data, separators=(",", ":"), allow_nan=False) + ";\n", encoding="utf-8")
    draw_reference(site, refs)
    shutil.copyfile(site / "reference-orbits.png", HERE / "reference-orbits.png")
    for item in refs:
        shutil.copyfile(HERE / "results" / (item["id"] + ".csv"), site / (item["id"] + ".csv"))
    shutil.copyfile(HERE / "results" / "provenance.toml", site / "provenance.toml")
    for name in ("style.css", "explorer.js", "LICENSE.txt", "COPYING", "article.tex"):
        shutil.copyfile(HERE / name, site / name)
    logo = HERE.parents[1] / "data" / "images" / "physicslibrarylogotransparent.png"
    shutil.copyfile(logo, site / "logo.png")
    page = (HERE / "viewer.template.html").read_text(encoding="utf-8").replace("@@JULIA_VERSION@@", provenance[("", "julia_version")])
    (site / "index.html").write_text(page.replace("@@ZIP_SIZE@@", "ZIP"), encoding="utf-8")
    attachments = ("article.tex", "preamble.tex", "computational-resources.json", "README.md", "LICENSE.txt", "reference-orbits.png")
    archive(site / "article-attachments.zip", {name: (HERE / name).read_bytes() for name in attachments})
    assets = ["index.html", "orbit-data.js", "style.css", "explorer.js", "logo.png", "LICENSE.txt", "COPYING", "article.tex", "provenance.toml", "reference-orbits.png", "reference-orbits-mobile.png", "article-attachments.zip"] + [item["id"] + ".csv" for item in refs]
    bundle_files = {name: (HERE / name).read_bytes() for name in SOURCES}
    bundle_files.update({"results/" + name: (HERE / "results" / name).read_bytes() for name in [item["id"] + ".csv" for item in refs] + ["sweep.csv", "provenance.toml"]})
    bundle_files.update({"viewer/" + name: (site / name).read_bytes() for name in assets})
    archive(site / "orbital-gravitation.zip", bundle_files)
    size = (site / "orbital-gravitation.zip").stat().st_size
    (site / "index.html").write_text(page.replace("@@ZIP_SIZE@@", f"{size / 1024:.0f} KB"), encoding="utf-8")
    assets += ["orbital-gravitation.zip"]
    report = {"sources_sha256": {name: digest(HERE / name) for name in SOURCES}, "files_sha256": {name: digest(site / name) for name in assets}}
    (site / "build.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    from verify import verify
    verify(site)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_SITE)
    publish(parser.parse_args().output)
