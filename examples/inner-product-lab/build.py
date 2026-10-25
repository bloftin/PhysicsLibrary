"""Publish the offline FS02 lab and its reproducible source archive."""
import hashlib
import shutil
import zipfile
from pathlib import Path
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/inner-product-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "inner-product-lab.jl", "reference.csv", "samples.csv", "LICENSE.txt", ".gitattributes")
SOURCES = PUBLIC + ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", "build.py", "build.mjs", "README.md", "computational-resources.json", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs", "test/package_test.py")

def sha(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()

def build():
    SITE.mkdir(parents=True, exist_ok=True)
    for name in SOURCES:
        if not (HERE / name).is_file():
            raise FileNotFoundError(HERE / name)
    for name in PUBLIC:
        shutil.copyfile(HERE / name, SITE / name)
    provenance = (
        'article = "https://physicslibrary.org/encyclopedia/InnerProductsOfFunctions.html"\n'
        'article_alias = "FS02"\narticle_id = 1519\n'
        'julia_version = "1.10.12"\n'
        'reference_generator = "julia --startup-file=no --project=. inner-product-lab.jl"\n'
        'reference_method = "exact rational polynomial moments and finite sums; independent of browser floating-point evaluation"\n'
        'browser_method = "analytic polynomial-product integration, Euclidean and Frobenius sums; separate midpoint approximations"\n'
        'renderer = "D3 7.9.0 and Lucide 0.468.0 bundled offline without runtime requests"\n'
        'scope = "real dimensionless vectors in R2, degree-at-most-three polynomial function spaces, and real 2x2 matrices with the Frobenius metric"\n'
        'projection = "c*=inner(u,v)/inner(v,v); r=u-c*v; E(c)=inner(r,r); trial and optimum remain distinct"\n'
        'angle = "acos(inner(u,v)/(norm(u)*norm(v))) for nonzero objects; abstract span diagram is an isometric representation, not the angle of function graphs"\n'
        'weight = "uniform 1, right ramp 2(x-a)/(b-a), or 1+x^2; ramp is positive in the interior with a zero endpoint"\n'
        'sampling = "4 to 128 midpoint rectangles include w(x_i)*dx; analytic scalar and approximate sample sum are reported separately"\n'
        'matrix = "inner(A,B)=trace(transpose(A)*B)=sum(A_ij*B_ij); identity projection extracts half the trace"\n'
        'normalization = "target rescaled to unit norm; trial coefficient adjusted to preserve the trial projection; zero target cannot be normalized"\n'
        'zero_cases = "angle undefined if either object is zero; zero target has a zero projection object, non-unique coefficient and constant squared error"\n'
        'graphics = "source and error axes adapt with visible numerical ticks; spatial and abstract vector-plane axes retain equal units; matrix heatmaps share a scale"\n'
        'precision = "17-digit CSV references; screen readouts suppress magnitudes below 1e-10; orthogonality checks are numerical, not symbolic claims"\n'
        'reference_cases = 17\ngeometry_reference_rows = 153\nfunction_reference_samples = 520\n'
    )
    for name in ("reference.csv", "samples.csv", "inner-product-lab.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        provenance += f'{name.replace("-", "_").replace(".", "_")}_sha256 = "{sha(HERE / name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE / "viewer.js")}"\n'
    (SITE / "provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE / "inner-product-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE / name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE / name, name)
        archive.write(HERE / "COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
