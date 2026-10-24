"""Publish the offline WM07 explorer and reproducible source archive."""
import hashlib
import shutil
import zipfile
from pathlib import Path
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[1]
SITE=REPO/"data/examples/sinusoidal-traveling-wave" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
PUBLIC=("index.html","style.css","sinusoidal-traveling-wave.jl","reference.csv","events.csv","LICENSE.txt",".gitattributes")
SOURCES=PUBLIC+("model.js","explorer.js","Project.toml","Manifest.toml","package.json","pnpm-lock.yaml","pnpm-workspace.yaml","build.py","build.mjs","README.md","computational-resources.json","test/model.test.mjs","test/runtests.jl","test/viewer.cjs","test/package_test.py")
def sha(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()
def build():
    SITE.mkdir(parents=True,exist_ok=True)
    for name in SOURCES:
        if not (HERE/name).is_file():raise FileNotFoundError(HERE/name)
    for name in PUBLIC:shutil.copyfile(HERE/name,SITE/name)
    p=(
        'article = "https://physicslibrary.org/encyclopedia/WaveMechanicsTheSinusoidalTravelingWave.html"\n'
        'article_alias = "WM07"\narticle_id = 1160\n'
        'julia_version = "1.10.12"\n'
        'reference_generator = "julia --startup-file=no --project=. sinusoidal-traveling-wave.jl"\n'
        'reference_method = "independent cispi complex exponential evaluation; exact periodicity and fixed-phase branch checks"\n'
        'browser_method = "direct sine/cosine analytic kinematics; D3 scales, Canvas2D and a cached fixed-scale space-time field"\n'
        'renderer = "D3 7.9.0 and Lucide 0.468.0, bundled offline without runtime requests"\n'
        'scope = "WM07 prescribed transverse-displacement illustration; no force model, dispersion relation, PDE solution or wave-energy calculation"\n'
        'convention = "u=A cos(kx-direction*omega*t+phi), or sine; positive k and omega, direction=+1 for right, -1 for left"\n'
        'basis_switch = "phi_sine=phi_cosine+pi/2 modulo 2pi; switching form preserves the physical field and tracked crest"\n'
        'tracked_crest = "one fixed integer phase branch initially nearest x=1 m at t=0; never wrapped into the window; absent when A=0"\n'
        'units = "internal/export SI meters, seconds and radians; plotted vertical displacement in cm; horizontal x in m"\n'
        'domains = "fixed x in [0,2] m, t in [0,2] s, vertical plot +/-6 cm, field color scale +/-5 cm; no amplitude auto-normalization"\n'
        'playback = "selectable 0.1x, 0.25x or real time; stops at 2 seconds; never changes physical parameters"\n'
        'degenerate_case = "A=0 gives a flat field; wavelength, period, phase and direction are nominal settings, with no observed crest or smallest repeat"\n'
        'reference_cases = 8\nreference_samples = 2856\nworked_events = 8\n'
    )
    for name in ("reference.csv","events.csv","sinusoidal-traveling-wave.jl","model.js","Manifest.toml","pnpm-lock.yaml"):
        p+=f'{name.replace("-","_").replace(".","_")}_sha256 = "{sha(HERE/name)}"\n'
    p+=f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(p,encoding="ascii",newline="\n")
    with zipfile.ZipFile(SITE/"sinusoidal-traveling-wave.zip","w",zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:archive.write(HERE/name,name)
        for name in ("viewer.js","THIRD-PARTY.txt","provenance.toml"):archive.write(SITE/name,name)
        archive.write(HERE/"COPYING","COPYING")
    print(f"Published {SITE}")
if __name__=="__main__":build()
