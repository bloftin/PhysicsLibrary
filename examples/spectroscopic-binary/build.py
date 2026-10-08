"""Publish static resources and a reproducible offline project. No server execution."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/spectroscopic-binary" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "spectroscopic-binary.jl", "reference.csv", "spectrum-reference.csv", "LICENSE.txt")
SOURCES = PUBLIC + ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml",
                    "build.mjs", "build.py", "README.md", "computational-resources.json", "binary-stars-computational-resources.json",
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
        'reference_generator = "julia --startup-file=no --project=. spectroscopic-binary.jl"\n'
        'julia_version = "1.10.12"\n'
        'browser_solver = "astronomia 4.1.1 kepler3 and bracketed binaryRoot"\n'
        'renderer = "Three.js 0.180.0; D3 7.9.0; procedural spheres; no remote assets"\n'
        'frame = "relative a=1; Earth +Z; sky X-Y; Rx(i) Rz(omega); star2-star1 relative orbit"\n'
        'radial_velocity = "gamma minus barycentric vZ; positive is recession"\n'
        'doppler = "optical low-velocity convention; lambda0=500 nm"\n'
        'spectrum = "Gaussian absorption, intrinsic FWHM and Gaussian instrument c/R; continuum weighted"\n'
        'sb1 = "secondary absorption suppressed; featureless secondary continuum retained"\n'
        'mass_unit = "nominal solar GM=1.3271244e11 km^3/s^2 (IAU 2015 B3)"\n'
        'phase = "mean anomaly / 2pi, zero at periastron"\n'
        'reference_cases = 7\n'
        'reference_states = 1015\n'
        'reference_spectra_samples = 7602\n'
    )
    for name in ("reference.csv", "spectrum-reference.csv", "spectroscopic-binary.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"spectroscopic-binary.zip", "w", zipfile.ZIP_DEFLATED) as archive:
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
