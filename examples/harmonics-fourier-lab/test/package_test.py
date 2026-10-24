import hashlib
import json
import tomllib
import unittest
import wave
import zipfile
from html.parser import HTMLParser
from pathlib import Path
HERE=Path(__file__).resolve().parents[1]
REPO=HERE.parents[1]
SITE=REPO/"data/examples/harmonics-fourier-lab" if (REPO/"lib/Noosphere/ComputationalResources.pm").is_file() else HERE/"dist"
class PackageTests(unittest.TestCase):
    def test_hashes(self):
        p=tomllib.loads((SITE/"provenance.toml").read_text())
        self.assertEqual(p["article_alias"],"FS01")
        for name in ("reference.csv","coefficients.csv","julia-square.wav","harmonics-fourier-lab.jl","model.js","audio.js","Manifest.toml","pnpm-lock.yaml"):
            self.assertEqual(p[name.replace("-","_").replace(".","_")+"_sha256"],hashlib.sha256((HERE/name).read_bytes()).hexdigest())
        self.assertEqual(p["viewer_sha256"],hashlib.sha256((SITE/"viewer.js").read_bytes()).hexdigest())
    def test_wav(self):
        with wave.open(str(SITE/"julia-square.wav")) as w:
            self.assertEqual((w.getnchannels(),w.getsampwidth(),w.getframerate(),w.getnframes()),(1,2,48000,96000))
    def test_bundle(self):
        with zipfile.ZipFile(SITE/"harmonics-fourier-lab.zip") as z:
            self.assertIsNone(z.testzip())
            for name in z.namelist():
                self.assertNotIn("node_modules",name)
                source=SITE/name if name in ("viewer.js","provenance.toml","THIRD-PARTY.txt") else HERE/name
                self.assertEqual(z.read(name),source.read_bytes())
            for name in ("model.js","audio.js","Project.toml","Manifest.toml","COPYING","test/model.test.mjs","test/runtests.jl","build.py","computational-resources.json"):
                self.assertIn(name,z.namelist())
        self.assertLess((SITE/"harmonics-fourier-lab.zip").stat().st_size,1500000)
    def test_links_and_offline_assets(self):
        class Links(HTMLParser):
            def handle_starttag(self,tag,attrs):
                attrs=dict(attrs)
                for key in ("href","src"):
                    url=attrs.get(key,"")
                    if not url or url.startswith(("https:","#")):continue
                    self_test.assertTrue((SITE/url).is_file(),url)
                if tag=="script":self_test.assertFalse(attrs.get("src","").startswith("http"))
        self_test=self
        Links().feed((SITE/"index.html").read_text())
        viewer=(SITE/"viewer.js").read_text()
        self.assertNotIn("getUserMedia",viewer)
        self.assertNotIn("fetch(",viewer)
        self.assertIn("disableNormalization",viewer)
    def test_manifest_and_catalog(self):
        self.assertEqual(json.loads((HERE/"computational-resources.json").read_text()),{"schema_version":1,"resources":["harmonics-fourier-lab"]})
        if (REPO/"etc/computational-resources.json").is_file():
            entry=json.loads((REPO/"etc/computational-resources.json").read_text())["resources"]["harmonics-fourier-lab"]
            self.assertLessEqual(len(entry["reproducibility"]),320)
            for field in ("explorer","source","provenance","license"):self.assertTrue((SITE/entry[field]).is_file())
if __name__=="__main__":unittest.main()
