"""Verify saved references, publication hashes, and the self-contained archive."""
import csv
import hashlib
import json
import tomllib
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
REPO = HERE.parents[1]
SITE = REPO / "data/examples/oscillation-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
provenance = tomllib.loads((SITE / "provenance.toml").read_text())
assert provenance["julia_version"] == "1.11.2"
for name in ("reference.csv", "oscillation-lab.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
    assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == provenance[name.replace("-", "_").replace(".", "_") + "_sha256"]
assert hashlib.sha256((SITE / "viewer.js").read_bytes()).hexdigest() == provenance["viewer_sha256"]
rows = list(csv.DictReader((SITE / "reference.csv").open()))
assert len(rows) == 729
assert len({r["case"] for r in rows}) == 9
assert json.loads((HERE / "computational-resources.json").read_text()) == {"schema_version": 1, "resources": ["oscillation-lab"]}
with zipfile.ZipFile(SITE / "oscillation-lab.zip") as archive:
    names = archive.namelist()
    assert len(names) == len(set(names))
    assert archive.testzip() is None
    assert not any(name.startswith("/") or ".." in Path(name).parts for name in names)
    for name in ("viewer.js", "index.html", "style.css", "reference.csv", "LICENSE.txt", "THIRD-PARTY.txt", "provenance.toml"):
        assert archive.read(name) == (SITE / name).read_bytes()
    for name in ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "pnpm-lock.yaml", "build.mjs", "build.py", "README.md", "COPYING", "test/package_test.py", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs"):
        assert archive.read(name) == (HERE / name).read_bytes()
print("Publication hashes, 729 references, manifest, and self-contained ZIP passed.")
