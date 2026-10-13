"""Publish the offline gradient explorer and reproducible Julia project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/gradient-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "gradient-lab.jl", "reference.csv", "LICENSE.txt", ".gitattributes")
SOURCES = PUBLIC + ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml",
                    "build.mjs", "build.py", "README.md", "computational-resources.json", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs", "test/package_test.py")

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
        'reference_generator = "julia --startup-file=no --project=. gradient-lab.jl"\n'
        'julia_version = "1.11.2"\n'
        'reference_method = "independent explicit Julia scalar fields and analytic partial derivatives; central-difference tests"\n'
        'browser_method = "mathjs 14.8.1 symbolic partial differentiation and compiled expressions; no custom-expression execution"\n'
        'renderer = "Three.js 0.180.0; D3 7.9.0; procedural scalar surfaces and contours; no remote assets"\n'
        'coordinates = "dimensionless Cartesian x,y in [-2.5,2.5]; direction u is a Euclidean unit vector"\n'
        'gradient = "(df/dx,df/dy); directional derivative = gradient dot u"\n'
        'display = "normalized direction arrows; height scale fixed per field/shape at maximum amplitude 2; numerical slopes unscaled"\n'
        'steps = "normalized gradient, initial step length 0.16, Armijo fraction 0.1, backtracking factor 0.5, domain-limited"\n'
        'stationary_tolerance = 1e-7\n'
        'grid_side = 65\n'
        'reference_fields = 6\n'
        'reference_samples = 2178\n'
    )
    for name in ("reference.csv", "gradient-lab.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"gradient-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
