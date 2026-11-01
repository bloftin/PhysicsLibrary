"""Publish the Coulomb lab, references and reproducible offline source ZIP."""
import hashlib
import shutil
import zipfile
from pathlib import Path
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[1]
SITE=REPO/"data/examples/coulomb-lab" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
PUBLIC=("index.html","style.css","coulomb-lab.jl","configurations.csv","forces.csv","fields.csv","LICENSE.txt",".gitattributes")
SOURCES=PUBLIC+("model.js","lines.js","explorer.js","Project.toml","Manifest.toml","package.json","pnpm-lock.yaml","pnpm-workspace.yaml","build.py","build.mjs","README.md","computational-resources.json","test/model.test.mjs","test/lines.test.mjs","test/runtests.jl","test/viewer.cjs","test/package_test.py")
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def build():
    SITE.mkdir(parents=True,exist_ok=True)
    for name in SOURCES:
        if not (HERE/name).is_file():raise FileNotFoundError(HERE/name)
    for name in PUBLIC:shutil.copyfile(HERE/name,SITE/name)
    p=(
        'article = "https://physicslibrary.org/encyclopedia/CoulombsLaw.html"\narticle_id = 60\n'
        'julia_version = "1.10.12"\n'
        'reference_generator = "julia --startup-file=no --project=. coulomb-lab.jl"\n'
        'reference_method = "256-bit BigFloat field sums and independent pair-force direction/magnitude evaluation"\n'
        'browser_method = "unsoftened analytic Coulomb superposition, exact pairwise reaction assignment; SI units"\n'
        'renderer = "D3 7.9.0, Lucide 0.468.0 and ODEX 2.0.4 bundled offline"\n'
        'constant = "k=1/(4*pi*epsilon0), epsilon0=8.8541878188e-12 F/m, rounded 2022 CODATA central value"\n'
        'constant_source = "https://physics.nist.gov/cuu/pdf/wall_2022.pdf"\n'
        'scope = "two to six prescribed stationary point charges in vacuum; 2D slice of a 3D inverse-square electric field; no mechanical trajectory, conductor or radiation model"\n'
        'units = "source/test charges entered in microcoulombs, coordinates in meters; internal/reference/export calculations in SI"\n'
        'self_force = "source i excluded from its own external field; pair forces are equal and opposite"\n'
        'probe = "virtual test charge is not a source; Ftest=qtest*E; changing it never changes the field"\n'
        'singularities = "no softening; singular field at a nonzero source; 0.30 m minimum source separation; 0.12 m display exclusion disks with probe values withheld"\n'
        'field_lines = "ODEX Gragg-Bulirsch-Stoer, dr/ds=+/-E/abs(E); s is arclength, not time; negative backward traces reversed for physical arrow direction"\n'
        'tracing = "absolute/relative tolerance 2e-6, maximum step 0.045 m, maximum length 18 m, up to 1600 steps; stop at source masks, view boundary or relative field-null threshold"\n'
        'seeding = "illustrative signed-source seeds with a bounded global budget; skip duplicate negative-to-positive reverse connections; not a calibrated 3D flux-density diagram"\n'
        'force_arrows = "one common adaptive linear force scale per configuration, quantitative 40 CSS-pixel reference bar; pair and net arrows share that scale"\n'
        'field_arrows = "direction only, including probe E and virtual test force; field magnitude reported numerically and by fixed log shading 1e2 to 1e6 N/C"\n'
        'interaction = "pointer or numeric source/probe positioning, optional 0.1 m snap, no automatic charge motion; live arrows replace lines while dragging"\n'
        'inverse_square = "two-charge sweep holds charge values fixed, 0.3 to at least 5 m, extending to the present separation when needed; logarithmic force axis"\n'
        'reference_cases = 10\nreference_sources = 28\nreference_forces = 28\nreference_fields = 1440\n'
    )
    for name in ("configurations.csv","forces.csv","fields.csv","coulomb-lab.jl","model.js","lines.js","Manifest.toml","pnpm-lock.yaml"):
        p+=f'{name.replace("-","_").replace(".","_")}_sha256 = "{sha(HERE/name)}"\n'
    p+=f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(p,encoding="ascii",newline="\n")
    with zipfile.ZipFile(SITE/"coulomb-lab.zip","w",zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:archive.write(HERE/name,name)
        for name in ("viewer.js","THIRD-PARTY.txt","provenance.toml"):archive.write(SITE/name,name)
        archive.write(HERE/"COPYING","COPYING")
    print(f"Published {SITE}")
if __name__=="__main__":build()
