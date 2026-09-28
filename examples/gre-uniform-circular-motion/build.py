"""Publish reviewed static circular-motion files; never run Julia on the server."""
from __future__ import annotations

import hashlib
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data" / "examples" / "gre-uniform-circular-motion"
SOURCES = (
    "Project.toml", "circular_motion.jl", "test/runtests.jl", "test/viewer.cjs",
    "README.md", "build.py", "verify.py", "LICENSE.txt", "index.html",
    "style.css", "explorer.js", "reference.csv", "computational-resources.json",
)
PUBLIC = ("index.html", "style.css", "explorer.js", "reference.csv", "LICENSE.txt")


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
        'generator = "julia"\n'
        'julia_version = "1.10.12"\n'
        'command = "julia --startup-file=no --project=. circular_motion.jl"\n'
        'model = "r=(R cos(theta),R sin(theta)); theta=theta0+v*t/R"\n'
        f'reference_sha256 = "{sha(HERE / "reference.csv")}"\n'
        f'julia_source_sha256 = "{sha(HERE / "circular_motion.jl")}"\n'
        f'viewer_sha256 = "{sha(HERE / "explorer.js")}"\n'
    )
    (SITE / "provenance.toml").write_text(provenance, encoding="ascii")
    with zipfile.ZipFile(SITE / "gre-uniform-circular-motion.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for name in SOURCES:
            archive.write(HERE / name, name)
        archive.write(HERE.parent / "orbital-gravitation" / "COPYING", "COPYING")
        archive.write(SITE / "provenance.toml", "provenance.toml")
    print(f"Published {SITE}")


if __name__ == "__main__":
    build()
