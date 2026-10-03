"""Publish reviewed static pulley files; never run Julia on the web server."""
from __future__ import annotations

import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data" / "examples" / "pulley-atwood-machines"
SOURCES = (
    "Project.toml", "atwood.jl", "model.js", "explorer.js", "index.html",
    "style.css", "test/model.test.cjs", "test/runtests.jl", "test/viewer.cjs", "README.md",
    "build.py", "build-reference.cjs", "verify.py", "reference.csv",
    "LICENSE.txt", "computational-resources.json",
)
PUBLIC = ("index.html", "style.css", "model.js", "explorer.js", "atwood.jl",
          "reference.csv", "LICENSE.txt")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build() -> None:
    SITE.mkdir(parents=True, exist_ok=True)
    for name in SOURCES:
        if not (HERE / name).is_file():
            raise FileNotFoundError(HERE / name)
    for name in PUBLIC:
        shutil.copyfile(HERE / name, SITE / name)
    provenance = (
        'reference_generator = "node build-reference.cjs"\n'
        'julia_reference_command = "julia --startup-file=no --project=. atwood.jl"\n'
        'model = "ideal fixed Atwood and one ideal movable pulley; release from rest"\n'
        f'reference_sha256 = "{sha(HERE / "reference.csv")}"\n'
        f'julia_source_sha256 = "{sha(HERE / "atwood.jl")}"\n'
        f'browser_model_sha256 = "{sha(HERE / "model.js")}"\n'
        f'viewer_sha256 = "{sha(HERE / "explorer.js")}"\n'
    )
    (SITE / "provenance.toml").write_text(provenance, encoding="ascii")
    with zipfile.ZipFile(SITE / "pulley-atwood-machines.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE / name, name)
        archive.write(HERE.parent / "orbital-gravitation" / "COPYING", "COPYING")
        archive.write(SITE / "provenance.toml", "provenance.toml")
    print(f"Published {SITE}")


if __name__ == "__main__":
    build()
