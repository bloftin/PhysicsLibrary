"""Publish static field explorer and its reproducible offline project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/em-field-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "em-field-lab.jl", "reference.csv", "LICENSE.txt")
SOURCES = PUBLIC + ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml",
                    "build.mjs", "build.py", "README.md", "computational-resources.json", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs")

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
        'reference_generator = "julia --startup-file=no --project=. em-field-lab.jl"\n'
        'julia_version = "1.10.12"\n'
        'reference_method = "independent rotation matrices and cospi phase evaluation; standard libraries"\n'
        'browser_method = "analytic plane wave; Three.js vector basis; D3 contours and plots"\n'
        'renderer = "Three.js 0.180.0; D3 7.9.0; procedural field glyphs and scalar texture; no remote assets"\n'
        'model = "monochromatic linearly polarized transverse plane wave in vacuum; no antenna response"\n'
        'speed_m_s = 299792458\n'
        'coordinates = "r/lambda, time/T; frequency changes physical metres and seconds"\n'
        'scalar = "psi=E0*cos(2pi*(n dot r/lambda - time/T)+initial_phase)"\n'
        'vector = "E=e*psi; n=Rz(phi)*Ry(theta)*z; e=Rz(phi)*Ry(theta)*(x*cos(beta)+y*sin(beta))"\n'
        'probe_delay = "B=A+spacing*n; time delay=spacing*T; monochromatic phase modulo 2pi"\n'
        'reference_cases = 7\n'
        'reference_samples = 1820\n'
    )
    for name in ("reference.csv", "em-field-lab.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"em-field-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
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
