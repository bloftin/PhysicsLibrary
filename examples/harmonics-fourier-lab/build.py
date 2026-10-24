"""Publish the offline FS01 resource and a reproducible source archive."""
import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SITE = REPO/"data/examples/harmonics-fourier-lab" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
PUBLIC = ("index.html", "style.css", "harmonics-fourier-lab.jl", "reference.csv", "coefficients.csv", "julia-square.wav", "LICENSE.txt", ".gitattributes")
SOURCES = PUBLIC + ("model.js", "audio.js", "explorer.js", "Project.toml", "Manifest.toml", "package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml", "build.py", "build.mjs", "README.md", "computational-resources.json", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs", "test/package_test.py")
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def build():
    SITE.mkdir(parents=True, exist_ok=True)
    for name in SOURCES:
        if not (HERE/name).is_file():
            raise FileNotFoundError(HERE/name)
    for name in PUBLIC:
        shutil.copyfile(HERE/name, SITE/name)
    p = (
        'article = "https://physicslibrary.org/encyclopedia/PeriodicFunctionsHarmonicsAndWhyFourierSeriesExist.html"\n'
        'article_alias = "FS01"\narticle_id = 1517\n'
        'julia_version = "1.10.12"\n'
        'reference_generator = "julia --startup-file=no --project=. harmonics-fourier-lab.jl"\n'
        'reference_method = "complex exponential finite sums using cispi; analytic orthogonality RMS and integer gcd periods; independent PCM WAV synthesis"\n'
        'browser_method = "real sine/cosine finite sums; vertical projections of complex harmonic vectors; D3 scales and Canvas2D"\n'
        'audio_method = "Web Audio PeriodicWave with cosine real and sine imaginary coefficients, disableNormalization=true; DC excluded; gain bounded by sum of harmonic amplitudes"\n'
        'renderer = "D3 7.9.0 and Lucide 0.468.0, bundled offline without runtime requests"\n'
        'scope = "finite synthesis and Fourier previews, not coefficient derivation or a general convergence theorem"\n'
        'phase_convention = "R_n cos(n omega_0 t - delta_n), A_n=R_n cos(delta_n), B_n=R_n sin(delta_n)"\n'
        'period = "T_0 / gcd(nonzero harmonic numbers); coefficients below amplitude 1e-10 treated as zero for period classification; constants have no smallest positive period"\n'
        'audio_limits = "user gesture required; sound initially off; volume up to 0.3 full scale divided by L1 harmonic-amplitude bound; components at or above 0.45 sampleRate omitted from sound only; visual clock slowed independently"\n'
        'wav = "48000 Hz, mono signed 16-bit little-endian PCM, 2 seconds, linear 25 ms start/end fades; Julia generated square-wave reference"\n'
        'reference_cases = 14\nreference_samples = 1806\n'
    )
    for name in ("reference.csv", "coefficients.csv", "julia-square.wav", "harmonics-fourier-lab.jl", "model.js", "audio.js", "Manifest.toml", "pnpm-lock.yaml"):
        key=name.replace("-","_").replace(".","_")
        p+=f'{key}_sha256 = "{sha(HERE/name)}"\n'
    p+=f'viewer_sha256 = "{sha(SITE/"viewer.js")}"\n'
    (SITE/"provenance.toml").write_text(p, encoding="ascii", newline="\n")
    with zipfile.ZipFile(SITE/"harmonics-fourier-lab.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE/name, name)
        for name in ("viewer.js", "THIRD-PARTY.txt", "provenance.toml"):
            archive.write(SITE/name, name)
        archive.write(HERE/"COPYING", "COPYING")
    print(f"Published {SITE}")
if __name__=="__main__":
    build()
