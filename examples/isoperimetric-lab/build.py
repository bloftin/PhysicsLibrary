"""Publish CV09E1's geometric examples and the reproducible Julia project."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/isoperimetric-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "isoperimetric-lab.jl", "reference.csv", "LICENSE.txt", ".gitattributes")
SOURCES = PUBLIC + ("model.js", "explorer.js", "explanations.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml",
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
        'article = "https://physicslibrary.org/encyclopedia/CalculusOfVariationsTheClassicalIsoperimetricProblemWorkedExamplesAndProofs.html"\n'
        'article_id = 1208\n'
        'exercises = [1, 3, 4, 6]\n'
        'reference_generator = "julia --startup-file=no --project=. isoperimetric-lab.jl"\n'
        'julia_version = "1.11.2"\n'
        'reference_method = "independent analytic Julia circle and regular-polygon geometry; 13 cases, 533 samples"\n'
        'browser_method = "mathjs 14.8.1 symbolic parametric derivatives and area slope; D3 7.9.0 polygon area/perimeter and chart scales"\n'
        'geometry = "planar Canvas2D; shared physical length scale within each comparison; angle-parameterized arcs including vertical endpoint tangents"\n'
        'sign_convention = "H=y+lambda*sqrt(1+y_prime^2); left-to-right upper arc has kappa=-1/R, hence lambda=-R"\n'
        'exercise_1 = "fixed half-chord a; alpha sets corresponding length L=2R*alpha; minor graph alpha<=pi/2; not a fixed-L deformation"\n'
        'exercise_3 = "R=a and L=pi*a; semicircle smooth parametrically but not C1 as a graph on the closed interval"\n'
        'exercise_4 = "fixed curved rope length L; endpoints slide on free straight shore; major arcs are parametric, not graphs; reflection bound L^2/(2*pi)"\n'
        'exercise_6 = "each circle/square/regular polygon separately scaled to the same closed perimeter P; polygons not inscribed in the displayed circle"\n'
        'scope = "exact circular families and regular polygons, not a general optimizer; interior stationarity distinct from endpoint conditions and global proof; animation is a geometric probe"\n'
        'reference_samples = 533\n'
    )
    for name in ("reference.csv", "isoperimetric-lab.jl", "model.js", "explanations.js", "Manifest.toml", "pnpm-lock.yaml"):
        provenance += f'{name.replace("-", "_").replace(".", "_")}_sha256 = "{sha(HERE/name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"isoperimetric-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
