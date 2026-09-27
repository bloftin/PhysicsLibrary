"""Copy reviewed static resources; never run Julia or execute user input."""
from __future__ import annotations

import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data" / "examples" / "minimum-effort-interception"
SOURCES = (
    "Project.toml", "interception.jl", "test/runtests.jl", "test/viewer.cjs", "README.md", "build.py", "verify.py",
    "LICENSE.txt", "index.html", "style.css", "explorer.js",
    "reference.csv", "computational-resources.json",
)
PUBLIC = ("index.html", "style.css", "explorer.js", "reference.csv", "LICENSE.txt")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build() -> None:
    SITE.mkdir(parents=True, exist_ok=True)
    for name in SOURCES:
        path = HERE / name
        if not path.is_file():
            raise FileNotFoundError(path)
    for name in PUBLIC:
        shutil.copyfile(HERE / name, SITE / name)
    provenance = (
        'generator = "julia"\n'
        'julia_version = "1.10.12"\n'
        'command = "julia --startup-file=no --project=. interception.jl"\n'
        'model = "x_prime=u; target=d+Vt; J=integral(u^2/2)dt"\n'
        f'reference_sha256 = "{sha(HERE / "reference.csv")}"\n'
        f'julia_source_sha256 = "{sha(HERE / "interception.jl")}"\n'
        f'viewer_sha256 = "{sha(HERE / "explorer.js")}"\n'
    )
    (SITE / "provenance.toml").write_text(provenance, encoding="ascii")
    with zipfile.ZipFile(SITE / "minimum-effort-interception.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE / name, name)
        archive.write(HERE.parent / "orbital-gravitation" / "COPYING", "COPYING")
        archive.write(SITE / "provenance.toml", "provenance.toml")
    print(f"Published {SITE}")


if __name__ == "__main__":
    build()
