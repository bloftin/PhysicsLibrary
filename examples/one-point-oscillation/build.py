"""Publish the WM01 single-coordinate resource and rebuildable offline project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO/"data/examples/one-point-oscillation" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
PUBLIC = ("index.html", "style.css", "one-point-oscillation.jl", "reference.csv", "crossings.csv", "LICENSE.txt", ".gitattributes")
SOURCES = PUBLIC + ("model.js", "explorer.js", "vendor/bisect.js", "vendor/LICENSE.fmin", "Project.toml", "Manifest.toml",
    "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", "build.py", "build.mjs", "README.md", "computational-resources.json",
    "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs", "test/package_test.py")
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
        'article = "https://physicslibrary.org/encyclopedia/OscillationAtOnePoint.html"\n'
        'article_alias = "WM01"\n'
        'article_id = 1148\n'
        'reference_generator = "julia --startup-file=no --project=. one-point-oscillation.jl"\n'
        'julia_version = "1.11.2"\n'
        'reference_method = "independent cubic Hermite basis and piecewise-linear formulas; safeguarded Newton crossing times; sampled total variation and finite differences"\n'
        'browser_method = "analytic periodic polynomials/lines and exact monotone-segment distance; vendored fmin bisection for equal-displacement crossing times"\n'
        'solver_source = "https://github.com/benfred/fmin/blob/6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b/src/bisect.js"\n'
        'renderer = "D3 7.9.0 and Canvas2D; Lucide 0.468.0; no runtime remote assets"\n'
        'scope = "prescribed one-degree-of-freedom records, not a force law or a traveling wave; no angular-frequency, phase or spatial-wave parameters"\n'
        'coordinate = "physical coordinate unchanged under axis reversal; signed displacement and velocity reverse; distance and physical time do not"\n'
        'units = "internal SI meters and seconds; m/cm/mm display conversions; CSV always SI"\n'
        'smooth_shapes = "periodic cubic Hermite through normalized (0,1,0,-1,0); rounded knots 0,.25,.5,.75,1 slopes 6,0,-6,0,6; uneven knots 0,.15,.5,.65,1 slopes 4,0,-4,0,4"\n'
        'triangle = "piecewise linear; derivative undefined at sharp extrema and exported empty with velocity_defined=0"\n'
        'distance = "exact accumulated total variation from t=0; each monotone leg contributes A, each whole cycle 4A"\n'
        'degenerate_case = "A=0 is constant, with no smallest positive period, observed frequency, distinct crossings or observed cycle count"\n'
        'playback = "physical time clock rate selectable; playback does not alter period/frequency; animation stops at 3 nominal periods"\n'
        'reference_cases = 12\n'
        'reference_samples = 3612\n'
        'crossing_cases = 12\n'
    )
    for name in ("reference.csv", "crossings.csv", "one-point-oscillation.jl", "model.js", "vendor/bisect.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_").replace("/", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"one-point-oscillation.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")
if __name__ == "__main__":
    build()
