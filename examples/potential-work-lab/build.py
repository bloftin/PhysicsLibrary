"""Publish the offline E01 viewer and a reproducible source archive."""
import hashlib
import shutil
import zipfile
from pathlib import Path
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[1]
SITE=REPO/"data/examples/potential-work-lab" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
PUBLIC=("index.html","style.css","potential-work-lab.jl","reference.csv","events.csv","LICENSE.txt",".gitattributes")
SOURCES=PUBLIC+("model.js","integral.js","explorer.js","Project.toml","Manifest.toml","package.json","pnpm-lock.yaml","pnpm-workspace.yaml","COPYING","build.py","build.mjs","README.md","computational-resources.json","test/model.test.mjs","test/runtests.jl","test/viewer.cjs","test/package_test.py")
HASHED=("reference.csv","events.csv","potential-work-lab.jl","model.js","integral.js","Manifest.toml","pnpm-lock.yaml")
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def build():
    SITE.mkdir(parents=True,exist_ok=True)
    for name in SOURCES:
        if not (HERE/name).is_file():raise FileNotFoundError(HERE/name)
    for name in PUBLIC:shutil.copyfile(HERE/name,SITE/name)
    p=(
        'article = "https://physicslibrary.org/encyclopedia/ElectricChargeElectricPotentialAndVoltage.html"\narticle_id = 1572\n'
        'julia_version = "1.10.12"\nreference_generator = "julia --startup-file=no --project=. potential-work-lab.jl"\n'
        'reference_method = "256-bit BigFloat evaluation of potential, field, path distance, energy and worked events; independent Julia model"\n'
        'browser_method = "analytic electrostatic potential and field, prescribed piecewise-linear paths; no mechanical dynamics"\n'
        'renderer = "D3 7.9.0 contours/charts and Lucide 0.468.0; bundled offline with ODEX 2.0.4"\n'
        'work_integral = "ODEX Gragg-Bulirsch-Stoer integrates E dot dr segment by segment, absolute and relative tolerance 1e-12, max parameter step .05; result in volts multiplied by test charge"\n'
        'constant = "k=1/(4*pi*8.8541878188e-12); rounded 2022 CODATA epsilon0; e=1.602176634e-19 C exactly"\n'
        'constant_source = "https://physics.nist.gov/cuu/pdf/wall_2022.pdf"\n'
        'units = "point-source map coordinates in meters; uniform-field map unit d/2 meters; test q input nC, microC or e; source Q input nC; internal/export SI except explicitly labeled map coordinates"\n'
        'voltage = "deltaV=V(B)-V(A); ideal meter red=A,black=B reads its negative; lead swapping does not reverse the prescribed path"\n'
        'reference_zero = "point sources use zero at infinity before common shift C; uniform field V(-1)=C; map colors/contours always V-C, numeric potentials and U include C"\n'
        'scope = "externally held point sources in vacuum or ideal uniform-field patch; probe has no back-reaction; no finite conductor, plate edge, induction, radiation or actual particle trajectory"\n'
        'masking = "no softening; 0.16 m point-source display exclusions; exact segment-to-source distance rejects intersecting paths; excluded endpoints withhold voltage/energy"\n'
        'visual_scales = "equal x/y spatial scale; user-selected fixed signed voltage color span with clipping; E and force arrows direction only; profile vertical scale automatic and labeled"\n'
        'battery = "steady DC Thevenin source with internal resistance, parallel external load and finite meter resistance; includes all branch currents and powers"\n'
        'charge_transfer = "integer -20 to +20 electrons transferred between two initially neutral bodies; total charge zero; not a conductor redistribution simulation"\n'
        'reference_cases = 9\nreference_samples = 1170\nreference_events = 9\n'
    )
    for name in HASHED:p+=f'{name.replace("-","_").replace(".","_")}_sha256 = "{sha(HERE/name)}"\n'
    p+=f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(p,encoding="ascii",newline="\n")
    with zipfile.ZipFile(SITE/"potential-work-lab.zip","w",zipfile.ZIP_DEFLATED) as z:
        for name in SOURCES:z.write(HERE/name,name)
        for name in ("viewer.js","THIRD-PARTY.txt","provenance.toml"):z.write(SITE/name,name)
    print(f"Published {SITE}")
if __name__=="__main__":build()
