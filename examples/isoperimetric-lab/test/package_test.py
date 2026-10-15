"""Verify publication hashes, independent references, manifest and offline archive."""
import csv
import hashlib
import json
import tomllib
import zipfile
from pathlib import Path
HERE = Path(__file__).resolve().parents[1]
REPO = HERE.parents[1]
SITE = REPO / "data/examples/isoperimetric-lab" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
p = tomllib.loads((SITE / "provenance.toml").read_text())
assert p["julia_version"] == "1.11.2" and p["article_id"] == 1208
assert p["exercises"] == [1, 3, 4, 6]
for name in ("reference.csv", "isoperimetric-lab.jl", "model.js", "explanations.js", "Manifest.toml", "pnpm-lock.yaml"):
    assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == p[name.replace("-", "_").replace(".", "_") + "_sha256"]
assert hashlib.sha256((SITE / "viewer.js").read_bytes()).hexdigest() == p["viewer_sha256"]
rows = list(csv.DictReader((SITE / "reference.csv").open()))
assert len(rows) == 533 and len({r["case"] for r in rows}) == 13
assert json.loads((HERE / "computational-resources.json").read_text()) == {"schema_version": 1, "resources": ["isoperimetric-lab"]}
with zipfile.ZipFile(SITE / "isoperimetric-lab.zip") as archive:
    names = archive.namelist()
    assert len(names) == len(set(names)) and archive.testzip() is None
    assert not any(name.startswith("/") or ".." in Path(name).parts for name in names)
    for name in ("viewer.js", "index.html", "style.css", "reference.csv", "LICENSE.txt", "THIRD-PARTY.txt", "provenance.toml", ".gitattributes"):
        assert archive.read(name) == (SITE / name).read_bytes()
    for name in ("model.js", "explorer.js", "explanations.js", "isoperimetric-lab.jl", "Project.toml", "Manifest.toml", "pnpm-lock.yaml", "build.mjs", "build.py", "README.md", "COPYING", "test/package_test.py", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs"):
        assert archive.read(name) == (HERE / name).read_bytes()
print("Publication hashes, 533 Julia samples, manifest and offline ZIP passed.")
