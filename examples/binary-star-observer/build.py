"""Publish static resources and a reproducible offline project. No server execution."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/binary-star-observer" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "binary-star-observer.jl", "reference.csv", "LICENSE.txt")
SOURCES = PUBLIC + ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml",
                    "build.mjs", "build.py", "README.md", "computational-resources.json", "limb-grid.json",
                    "limb-check.csv", "TRANSITS-LICENSE.txt", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs")

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
        'reference_generator = "julia --startup-file=no --project=. binary-star-observer.jl"\n'
        'julia_version = "1.10.12"\n'
        'occultation_library = "Transits.jl 0.4.1; exact quadratic limb darkening"\n'
        'browser_solver = "astronomia 4.1.1 kepler3; venn.js 0.2.20 circleOverlap; fmin 0.0.2 bisect"\n'
        'renderer = "Three.js 0.180.0; procedural stellar spheres; D3 7.9.0 light curve; no remote assets"\n'
        'frame = "relative a=1; observer +Z; sky X-Y; R_x(i) R_z(omega); star2-star1 relative vector"\n'
        'model = "Keplerian detached spherical luminous stars, uniform or identical quadratic limb laws"\n'
        'limb_coefficients = [0.4, 0.25]\n'
        'limb_grid = "257 log-radius-ratio x 1025 contact-aligned impact samples; bilinear interpolation"\n'
        'probability = "numerical critical cos(i) for each conjunction; any=max, both=min; uniform orbital poles"\n'
        'phase = "mean anomaly / 2pi, zero at periastron; equal time samples, contacts refined separately"\n'
        'units = "relative a and orbital period; angles in degrees at UI, radians internally"\n'
    )
    for name in ("reference.csv", "limb-grid.json", "binary-star-observer.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"binary-star-observer.zip", "w", zipfile.ZIP_DEFLATED) as archive:
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
