"""Publish the offline WM02 explorer and reproducible source archive."""
import hashlib
import shutil
import zipfile
from pathlib import Path
HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO / "data/examples/sinusoidal-oscillation" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
PUBLIC = ("index.html", "style.css", "sinusoidal-oscillation.jl", "reference.csv", "events.csv", "LICENSE.txt", ".gitattributes")
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
        'article = "https://physicslibrary.org/encyclopedia/WM02.html"\n'
        'article_alias = "WM02"\narticle_id = 1150\n'
        'julia_version = "1.10.12"\n'
        'reference_generator = "julia --startup-file=no --project=. sinusoidal-oscillation.jl"\n'
        'reference_method = "independent cispi complex exponential evaluation of values, phases, projections and time slopes"\n'
        'browser_method = "exact analytic sine/cosine time histories and geometric projection; D3 scales and Canvas2D"\n'
        'renderer = "D3 7.9.0 and Lucide 0.468.0 bundled offline without runtime requests"\n'
        'scope = "WM02 kinematic oscillation at one point; no spatial wave, force model, energy calculation or ODE solver"\n'
        'convention = "u=A cos(omega*t+phi), or equivalent sine; omega=2pi*f; T=1/f; positive rate"\n'
        'basis_switch = "phi_sine=phi_cosine+pi/2 modulo 2pi; reference orientation and projection axis change together, preserving u and its slope"\n'
        'circle = "standard counterclockwise angle from +x, horizontal cosine or vertical sine projection; geometric reference, not a physical particle orbit"\n'
        'radians = "arc s=r*alpha, alpha=phase modulo 2pi in [0,2pi); radius in [0.5,1.5] reference cm is independent of amplitude"\n'
        'units = "internal and exported meters, seconds and radians; selectable plotted cm or mm; slopes only classify rising/falling"\n'
        'domains = "fixed t in [0,4] seconds and displacement +/-5 cm (+/-50 mm); no amplitude or period auto-normalization"\n'
        'comparison = "optional doubled frequency (up to 8 Hz) or zero-phase cosine; same amplitude, physical seconds and equivalent conventions"\n'
        'playback = "0.1x, 0.25x or real time; quarter-period stepping; stops at 4 seconds"\n'
        'degenerate_case = "A=0 is constant, u/A undefined; phase and positive repetition rates are nominal, not observed"\n'
        'reference_cases = 9\nreference_samples = 1449\nworked_events = 9\n'
    )
    for name in ("reference.csv", "events.csv", "sinusoidal-oscillation.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
        provenance += f'{name.replace("-", "_").replace(".", "_")}_sha256 = "{sha(HERE / name)}"\n'
    provenance += f'viewer_sha256 = "{sha(SITE / "viewer.js")}"\n'
    (SITE / "provenance.toml").write_text(provenance, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE / "sinusoidal-oscillation.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE / name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE / name, name)
        archive.write(HERE / "COPYING", "COPYING")
    print(f"Published {SITE}")

if __name__ == "__main__":
    build()
