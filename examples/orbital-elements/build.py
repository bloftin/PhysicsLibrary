"""Publish reviewed browser files and an offline archive. No server execution."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/orbital-elements" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "orbital-elements.jl", "reference.csv", "LICENSE.txt")
SOURCES = PUBLIC + ("model.js", "explorer.js", "Project.toml", "package.json", "pnpm-lock.yaml",
                    "build.mjs", "build.py", "README.md", "computational-resources.json",
                    "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs")

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def build():
    SITE.mkdir(parents=True, exist_ok=True)
    for name in SOURCES:
        if not (HERE/name).is_file():
            raise FileNotFoundError(HERE/name)
    for name in PUBLIC:
        shutil.copyfile(HERE/name, SITE/name)
    provenance = (
        'reference_generator = "julia --startup-file=no --project=. orbital-elements.jl"\n'
        'model = "elliptic two-body Earth ECI; optional first-order secular J2 node and apsidal rates"\n'
        'julia_version = "1.10.12"\n'
        'browser_solver = "astronomia 4.1.1 kepler3"\n'
        'renderer = "Three.js 0.180.0; procedural Earth grid; no remote assets"\n'
        'frame = "right-handed ECI; X equinox; Z north; Rz(RAAN) Rx(i) Rz(argp)"\n'
        'units = "km, seconds, degrees (internal angles radians)"\n'
        'j2_velocity = "instantaneous two-body osculating velocity, not derivative of secular frame rotation"\n'
        f'reference_sha256 = "{sha(HERE/"reference.csv")}"\n'
        f'julia_source_sha256 = "{sha(HERE/"orbital-elements.jl")}"\n'
        f'browser_model_sha256 = "{sha(HERE/"model.js")}"\n'
        f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
        f'lockfile_sha256 = "{sha(HERE/"pnpm-lock.yaml")}"\n'
    )
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"orbital-elements.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        copying = HERE/"COPYING"
        if not copying.is_file():
            copying = HERE.parent/"orbital-gravitation/COPYING"
        archive.write(copying, "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
