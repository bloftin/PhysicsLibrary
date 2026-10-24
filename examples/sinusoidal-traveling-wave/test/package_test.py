import csv
import hashlib
import json
import tomllib
import unittest
import zipfile
from html.parser import HTMLParser
from pathlib import Path
HERE=Path(__file__).resolve().parents[1]
REPO=HERE.parents[1]
SITE=REPO/"data/examples/sinusoidal-traveling-wave" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
class PackageTests(unittest.TestCase):
 def test_hashes(self):
  p=tomllib.loads((SITE/"provenance.toml").read_text());self.assertEqual(p["article_alias"],"WM07")
  for name in ("reference.csv","events.csv","sinusoidal-traveling-wave.jl","model.js","Manifest.toml","pnpm-lock.yaml"):
   self.assertEqual(p[name.replace("-","_").replace(".","_")+"_sha256"],hashlib.sha256((HERE/name).read_bytes()).hexdigest())
  self.assertEqual(p["viewer_sha256"],hashlib.sha256((SITE/"viewer.js").read_bytes()).hexdigest())
 def test_archive(self):
  with zipfile.ZipFile(SITE/"sinusoidal-traveling-wave.zip") as z:
   self.assertIsNone(z.testzip())
   for name in z.namelist():
    self.assertNotIn("node_modules",name)
    source=SITE/name if name in ("viewer.js","provenance.toml","THIRD-PARTY.txt") else HERE/name
    self.assertEqual(z.read(name),source.read_bytes())
   for name in ("Project.toml","Manifest.toml","COPYING","test/model.test.mjs","test/runtests.jl","model.js","README.md","build.py"):self.assertIn(name,z.namelist())
  self.assertLess((SITE/"sinusoidal-traveling-wave.zip").stat().st_size,1500000)
 def test_links(self):
  owner=self
  class Links(HTMLParser):
   def handle_starttag(self,tag,attrs):
    attrs=dict(attrs)
    for key in ("href","src"):
     url=attrs.get(key,"")
     if url and not url.startswith(("https:","#")):owner.assertTrue((SITE/url).is_file(),url)
    if tag=="script":owner.assertFalse(attrs.get("src","").startswith("http"))
  Links().feed((SITE/"index.html").read_text())
  self.assertNotIn("fetch(",(SITE/"viewer.js").read_text())
 def test_references(self):
  for name,count in (("reference.csv",2856),("events.csv",8)):
   with (SITE/name).open(newline="") as f:rows=list(csv.DictReader(f))
   self.assertEqual(len(rows),count);self.assertTrue(all(None not in row and None not in row.values() for row in rows))
 def test_manifest(self):
  self.assertEqual(json.loads((HERE/"computational-resources.json").read_text()),{"schema_version":1,"resources":["sinusoidal-traveling-wave"]})
  if (REPO/"etc/computational-resources.json").is_file():
   entry=json.loads((REPO/"etc/computational-resources.json").read_text())["resources"]["sinusoidal-traveling-wave"]
   self.assertLessEqual(len(entry["reproducibility"]),320)
   for field in ("explorer","source","provenance","license"):self.assertTrue((SITE/entry[field]).is_file())
if __name__=="__main__":unittest.main()
