"""Publish the static antenna lab and self-contained Julia/browser source ZIP."""
import hashlib
import shutil
import zipfile
from pathlib import Path
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[1]
SITE=REPO/"data/examples/antenna-carrier-lab" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
PUBLIC=("index.html","style.css","antenna-carrier-lab.jl","reference.csv","parameters.csv","LICENSE.txt",".gitattributes")
SOURCES=PUBLIC+("model.js","scene.js","explorer.js","Project.toml","Manifest.toml","package.json","pnpm-lock.yaml","pnpm-workspace.yaml","COPYING","build.py","build.mjs","README.md","computational-resources.json","test/model.test.mjs","test/runtests.jl","test/viewer.cjs","test/package_test.py")
HASHED=("reference.csv","parameters.csv","antenna-carrier-lab.jl","model.js","scene.js","Manifest.toml","pnpm-lock.yaml")
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def build():
    SITE.mkdir(parents=True,exist_ok=True)
    for name in SOURCES:
        if not (HERE/name).is_file():raise FileNotFoundError(HERE/name)
    for name in PUBLIC:shutil.copyfile(HERE/name,SITE/name)
    p=(
        'article = "https://physicslibrary.org/encyclopedia/ElectromagneticWavesAntennasAndRFRadiationFromTimeVaryingCurrentsAndTheHertzianDipole.html"\narticle_id = 1449\n'
        'scientific_source = "https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/MIT6_013S09_chap10.pdf"\n'
        'julia_version = "1.10.12"\nreference_generator = "julia --startup-file=no --project=. antenna-carrier-lab.jl"\n'
        'reference_method = "256-bit BigFloat complex phasors, independent Julia current, charge, carrier drift, power and retarded far field"\n'
        'browser_method = "analytic sinusoidal steady-state equivalent circuit; no transient numerical integrator or full-wave field solver"\n'
        'renderer = "Three.js 0.180.0, D3 7.9.0, Lucide 0.468.0 bundled offline"\n'
        'antenna = "total physical length L, triangular current I(z)=Ifeed*(1-2abs(z)/L), effective length L/2; L/lambda below 0.1 across all controls"\n'
        'constants = "c=299792458 m/s exact, epsilon0=8.8541878188e-12 F/m rounded 2022 value, eta=1/(epsilon0*c), e=1.602176634e-19 C exact"\n'
        'radiation_resistance = "eta*k^2*(L/2)^2/(6*pi); consistent with integrated far-field power; not uniform-current Hertzian resistance for physical length L"\n'
        'circuit = "10 pF assumed antenna capacitance, optional lossless series tuning inductance, prescribed ohmic loss; load or generator series resistance; peak phasors exp(+j*omega*t)"\n'
        'receive = "equivalent loop EMF Epeak*(L/2)*sin(theta)*cos(psi); terminal polarity chosen for positive axial current; all power contributions cycle averaged"\n'
        'carriers = "illustrative n=8.5e28 /m^3, effective area=1e-6 m^2; u=-q/(n*e*A), v=-I/(n*e*A), spatial triangular weighting; no skin-effect prediction"\n'
        'charge = "q_upper=integral(Ifeed dt), q_lower=-q_upper; uniform incremental line charge on each arm implied by continuity in the prescribed mode"\n'
        'closeup = "schematic wire cross-section; adaptive electron displacement gain stated numerically; local drive cue is not total E inside a conductor"\n'
        'wave_view = "receive plane-wave E/B; transmit radiation samples at r/lambda=2 to 4 in 0.25 steps; normalized E and cB arrows, retarded phase exp(-jkr); no near-field continuation"\n'
        'limitations = "feed-associated dipole mode only; full open-circuit polarization and structural scattering, boundary currents, mutual coupling, material kinetics, modulation and transients not solved"\n'
        'power = "radiation resistance is an average-power equivalent, not instantaneous far-zone flux; receive includes current-associated re-radiation; transmit accounts for source resistor separately"\n'
        'reference_cases = 9\nreference_samples = 1161\nreference_parameters = 9\n'
    )
    for name in HASHED:p+=f'{name.replace("-","_").replace(".","_")}_sha256 = "{sha(HERE/name)}"\n'
    p+=f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(p,encoding="ascii",newline="\n")
    with zipfile.ZipFile(SITE/"antenna-carrier-lab.zip","w",zipfile.ZIP_DEFLATED) as z:
        for name in SOURCES:z.write(HERE/name,name)
        for name in ("viewer.js","THIRD-PARTY.txt","provenance.toml"):z.write(SITE/name,name)
    print(f"Published {SITE}")
if __name__=="__main__":build()
