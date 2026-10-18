"""Publish the offline CV07 viewer and reproducible Julia reference project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/vector-target-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "vector-target-lab.jl", "reference.csv", "LICENSE.txt", ".gitattributes")
SOURCES = PUBLIC + ("model.js", "explorer.js", "vendor/bisect.js", "vendor/LICENSE.fmin", "Project.toml", "Manifest.toml",
                    "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", "build.mjs", "build.py", "README.md",
                    "computational-resources.json", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs", "test/package_test.py")

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
        'article = "https://physicslibrary.org/encyclopedia/CalculusOfVariationsSeveralDependentVariablesAndVectorFunctionals.html"\n'
        'article_id = 1469\n'
        'article_scope = "extension of CV07 Example 1 and section 16: vector Dirichlet energy with endpoint constrained to a surface"\n'
        'reference_generator = "julia --startup-file=no --project=. vector-target-lab.jl"\n'
        'julia_version = "1.11.2"\n'
        'reference_method = "independent Julia vector formulas and safeguarded Newton ellipsoid projection; known normal-ray and quadrature tests"\n'
        'browser_method = "analytic vector paths and first variations; fmin bisect for ellipsoid projection"\n'
        'solver_source = "https://github.com/benfred/fmin/blob/6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b/src/bisect.js"\n'
        'solver_license = "BSD-3-Clause; included in THIRD-PARTY.txt and vendor/LICENSE.fmin"\n'
        'renderer = "Three.js 0.180.0; D3 7.9.0; procedural surfaces; offline with no remote assets"\n'
        'functional = "J=integral(|qdot|^2/2,0,T); q=A+s(B-A)+h*sin(pi*s)*ez; s=t/T"\n'
        'endpoint = "g(B)=0; p=qdot(T); pt=p-(p.n)n; stationarity requires qddot=0 AND pt=0; p=lambda*grad(g)"\n'
        'variation = "eta(t)=s*eta_B; boundary=p.eta_B; interior=pi*h*eta_B_z/T; total=(B-A).eta_B/T"\n'
        'scope = "fixed interval; curved targets require exterior start; endpoint only, not obstacle or first-impact; sphere far-side stationarity is a full-space saddle"\n'
        'display = "physical xyz maps to Three (x,z,-y); all momentum arrows share one scale; color is straight-path endpoint cost, not potential"\n'
        'reference_cases = 14\n'
        'reference_samples = 294\n'
    )
    for name in ("reference.csv", "vector-target-lab.jl", "model.js", "vendor/bisect.js", "Manifest.toml", "pnpm-lock.yaml"):
        key = name.replace("-", "_").replace(".", "_").replace("/", "_")
        provenance += f'{key}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"vector-target-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
