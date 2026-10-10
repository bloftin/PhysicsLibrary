"""Publish the offline oscillator and reproducible Julia project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/oscillation-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "oscillation-lab.jl", "reference.csv", "LICENSE.txt", ".gitattributes")
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
        'reference_generator = "julia --startup-file=no --project=. oscillation-lab.jl"\n'
        'julia_version = "1.11.2"\n'
        'reference_method = "LinearAlgebra.exp; independent column-major Kronecker lift; direct evaluation at each reference time"\n'
        'browser_method = "mathjs 14.8.1 expm; row-major quadratic lift; uniform transition matrix"\n'
        'renderer = "Three.js 0.180.0; D3 7.9.0; procedural spring and mass; no remote assets"\n'
        'model = "m*xddot+c*xdot+k*x=F0*cos(omega_d*t+phase); c=2*zeta*sqrt(m*k)"\n'
        'energy = "K=m*v^2/2; U=k*x^2/2; Q=integral(c*v^2 dt); W=integral(F*v dt); E+Q-W=E0"\n'
        'units = "seconds, metres, kilograms, newtons, joules; input drive phase in degrees"\n'
        'scene_scale = "fixed across each trajectory; displacement range fits the scene without clipping physical values"\n'
        'browser_samples = 1201\n'
        'reference_cases = 9\n'
        'reference_samples = 729\n'
    )
    for name in ("reference.csv", "oscillation-lab.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"oscillation-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
