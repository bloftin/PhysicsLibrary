import csv
import hashlib
import json
import tomllib
import unittest
import zipfile
from pathlib import Path
HERE = Path(__file__).resolve().parents[1]
REPO = HERE.parents[1]
SITE = REPO/"data/examples/one-point-oscillation" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
class PackageTests(unittest.TestCase):
    def test_provenance(self):
        p=tomllib.loads((SITE/"provenance.toml").read_text())
        self.assertEqual(p["article_id"],1148)
        for name in ("reference.csv","crossings.csv","one-point-oscillation.jl","model.js","vendor/bisect.js","Manifest.toml","pnpm-lock.yaml"):
            key=name.replace("-","_").replace(".","_").replace("/","_")+"_sha256"
            self.assertEqual(p[key],hashlib.sha256((HERE/name).read_bytes()).hexdigest())
        self.assertEqual(p["viewer_sha256"],hashlib.sha256((SITE/"viewer.js").read_bytes()).hexdigest())
    def test_references(self):
        for name,expected in (("reference.csv",3612),("crossings.csv",12)):
            with (SITE/name).open(newline="") as f:
                rows=list(csv.DictReader(f))
            self.assertEqual(len(rows),expected)
            self.assertTrue(all(None not in row and None not in row.values() for row in rows))
    def test_archive(self):
        with zipfile.ZipFile(SITE/"one-point-oscillation.zip") as z:
            self.assertIsNone(z.testzip())
            for name in ("index.html","style.css","viewer.js","reference.csv","crossings.csv","one-point-oscillation.jl","provenance.toml","THIRD-PARTY.txt","LICENSE.txt",".gitattributes"):
                self.assertEqual(z.read(name),(SITE/name).read_bytes())
            for name in ("model.js","explorer.js","Project.toml","Manifest.toml","package.json","pnpm-lock.yaml","pnpm-workspace.yaml","COPYING","vendor/bisect.js","vendor/LICENSE.fmin","test/model.test.mjs","test/runtests.jl","test/viewer.cjs","test/package_test.py","README.md","build.py","build.mjs","computational-resources.json"):
                self.assertEqual(z.read(name),(HERE/name).read_bytes())
            self.assertFalse(any("node_modules" in name or "qa/" in name for name in z.namelist()))
            self.assertIn(b"fmin bisect",z.read("THIRD-PARTY.txt"))
    def test_attachment(self):
        self.assertEqual(json.loads((HERE/"computational-resources.json").read_text()),{"schema_version":1,"resources":["one-point-oscillation"]})
        if (REPO/"etc/computational-resources.json").is_file():
            entry=json.loads((REPO/"etc/computational-resources.json").read_text())["resources"]["one-point-oscillation"]
            self.assertEqual(len(entry["datasets"]),2)
            self.assertLessEqual(len(entry["reproducibility"]),320)
if __name__ == "__main__":
    unittest.main()
