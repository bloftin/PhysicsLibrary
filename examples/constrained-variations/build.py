"""Publish the constrained-variation lab and its reproducible Julia project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/constrained-variations" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "constrained-variations.jl", "reference.csv", "LICENSE.txt", ".gitattributes")
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
        'article = "https://physicslibrary.org/encyclopedia/CalculusOfVariationsConstrainedVariationsAndIsoperimetricProblems.html"\n'
        'article_id = 1207\n'
        'reference_generator = "julia --startup-file=no --project=. constrained-variations.jl"\n'
        'julia_version = "1.11.2"\n'
        'reference_method = "independent explicit Julia functionals and first-variation densities; trapezoidal verification of integral pairings"\n'
        'browser_method = "mathjs 14.8.1 symbolic coefficient derivatives; exact analytic functional formulas; fixed expression catalog"\n'
        'renderer = "Three.js 0.180.0; D3 7.9.0; procedural objective surfaces and constraint geometry; no remote assets"\n'
        'sign_convention = "J + lambda*(K-k0); grad J = -lambda*grad K; video convention mu = -lambda"\n'
        'mean_family = "y=6*a*x*(1-x)+6*b*x*(1-x)*(2*x-1); x in [0,1]; J=6*a^2+18*b^2/5; K=a=m"\n'
        'normalization_family = "y=sqrt(2/pi)*(a*sin(x)+b*sin(2*x)); x in [0,pi]; J=a^2+4*b^2; K=a^2+b^2=k0"\n'
        'geometry = "Euclidean gradients in coefficient space; tangent has unit coefficient norm; lower density panel is the L2 first-variation representation"\n'
        'display = "objective and scaled constraint normals share one displayed scale, never independently normalized; surface height scale shown"\n'
        'scope = "exact two-function slices; full first-variation residual shown; second mode not a full-space maximum; scan not physical dynamics"\n'
        'reference_cases = 14\n'
        'reference_samples = 574\n'
    )
    for name in ("reference.csv", "constrained-variations.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        provenance += f'{name.replace("-", "_").replace(".", "_")}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"constrained-variations.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
