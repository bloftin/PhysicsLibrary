import csv
import hashlib
import json
import tomllib
import unittest
import zipfile
from pathlib import Path
HERE = Path(__file__).resolve().parents[1]
REPO = HERE.parents[1]
SITE = REPO/"data/examples/vector-target-lab" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"

class PackageTests(unittest.TestCase):
    def test_provenance(self):
        p = tomllib.loads((SITE/"provenance.toml").read_text())
        self.assertEqual(p["article_id"], 1469)
        self.assertEqual(p["reference_samples"], 294)
        for name in ("reference.csv", "vector-target-lab.jl", "model.js", "vendor/bisect.js", "Manifest.toml", "pnpm-lock.yaml"):
            key = name.replace("-", "_").replace(".", "_").replace("/", "_")+"_sha256"
            self.assertEqual(p[key], hashlib.sha256((HERE/name).read_bytes()).hexdigest())
        self.assertEqual(p["viewer_sha256"], hashlib.sha256((SITE/"viewer.js").read_bytes()).hexdigest())
    def test_reference(self):
        with (SITE/"reference.csv").open(newline="") as f:
            rows = list(csv.DictReader(f))
        self.assertEqual(len(rows),294)
        self.assertEqual(len({r["case"] for r in rows}),14)
    def test_archive(self):
        with zipfile.ZipFile(SITE/"vector-target-lab.zip") as z:
            self.assertIsNone(z.testzip())
            for name in ("index.html","style.css","viewer.js","reference.csv","vector-target-lab.jl","provenance.toml","LICENSE.txt",".gitattributes"):
                self.assertEqual(z.read(name),(SITE/name).read_bytes())
            for name in ("model.js","explorer.js","Project.toml","Manifest.toml","package.json","pnpm-lock.yaml","pnpm-workspace.yaml","COPYING","vendor/bisect.js","vendor/LICENSE.fmin","test/model.test.mjs","test/runtests.jl","test/viewer.cjs","test/package_test.py","README.md","build.py","build.mjs","computational-resources.json"):
                self.assertEqual(z.read(name),(HERE/name).read_bytes())
            self.assertFalse(any("node_modules" in n or "qa/" in n for n in z.namelist()))
            self.assertIn(b"BSD",z.read("THIRD-PARTY.txt"))
            self.assertIn(b"three@0.180.0",z.read("THIRD-PARTY.txt"))
    def test_attachment(self):
        self.assertEqual(json.loads((HERE/"computational-resources.json").read_text()),{"schema_version":1,"resources":["vector-target-lab"]})
        self.assertNotIn("https://cdn",(SITE/"index.html").read_text())

if __name__ == "__main__":
    unittest.main()
