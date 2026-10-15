"""Check reference cases, publication hashes, manifest, and offline ZIP."""
import csv
import hashlib
import json
import tomllib
import zipfile
from pathlib import Path
HERE = Path(__file__).resolve().parents[1]
REPO = HERE.parents[1]
SITE = REPO / "data/examples/constrained-variations" if (REPO / "lib/Noosphere/ComputationalResources.pm").is_file() else HERE / "dist"
p = tomllib.loads((SITE / "provenance.toml").read_text())
assert p["julia_version"] == "1.11.2" and p["article_id"] == 1207
for name in ("reference.csv", "constrained-variations.jl", "model.js", "Manifest.toml", "pnpm-lock.yaml"):
    assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == p[name.replace("-", "_").replace(".", "_") + "_sha256"]
assert hashlib.sha256((SITE / "viewer.js").read_bytes()).hexdigest() == p["viewer_sha256"]
rows = list(csv.DictReader((SITE / "reference.csv").open()))
assert len(rows) == 574 and len({r["case"] for r in rows}) == 14
assert json.loads((HERE / "computational-resources.json").read_text()) == {"schema_version": 1, "resources": ["constrained-variations"]}
with zipfile.ZipFile(SITE / "constrained-variations.zip") as archive:
    names = archive.namelist()
    assert len(names) == len(set(names)) and archive.testzip() is None
    assert not any(name.startswith("/") or ".." in Path(name).parts for name in names)
    for name in ("viewer.js", "index.html", "style.css", "reference.csv", "LICENSE.txt", "THIRD-PARTY.txt", "provenance.toml", ".gitattributes"):
        assert archive.read(name) == (SITE / name).read_bytes()
    for name in ("model.js", "explorer.js", "Project.toml", "Manifest.toml", "pnpm-lock.yaml", "build.mjs", "build.py", "README.md", "COPYING", "test/package_test.py", "test/model.test.mjs", "test/runtests.jl", "test/viewer.cjs"):
        assert archive.read(name) == (HERE / name).read_bytes()
print("Publication hashes, 574 Julia samples, filebox manifest and offline ZIP passed.")
