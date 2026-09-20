"""Verify the static orbital-gravitation publication without running Julia."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
from urllib.parse import urlsplit
import zipfile

HERE = Path(__file__).resolve().parent

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

class Viewer(HTMLParser):
    def __init__(self): super().__init__(); self.local = []; self.ranges = []; self.scripts = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ("form", "iframe", "object", "embed"): raise ValueError("Unexpected active viewer element: " + tag)
        if tag == "script": self.scripts.append(attrs.get("src"))
        if any(key.startswith("on") for key in attrs): raise ValueError("Inline handler is not allowed")
        if tag == "input": self.ranges.append((attrs.get("id"), attrs.get("type"), attrs.get("min"), attrs.get("max"), attrs.get("step")))
        for key in ("href", "src", "srcset"):
            if key not in attrs: continue
            value, parsed = attrs[key], urlsplit(attrs[key])
            if parsed.scheme:
                if key != "href" or value != "https://physicslibrary.org/": raise ValueError("Unexpected external asset: " + value)
            elif parsed.netloc or parsed.query or parsed.fragment or "/" in value or "\\" in value: raise ValueError("Unexpected asset path: " + value)
            else: self.local.append(value)

def verify(site):
    report = json.loads((site / "build.json").read_text())
    for section, root in (("sources_sha256", HERE), ("files_sha256", site)):
        for name, expected in report[section].items():
            if digest(root / name) != expected: raise ValueError("Stale file: " + name)
    parser = Viewer(); parser.feed((site / "index.html").read_text())
    if parser.scripts != ["orbit-data.js", "explorer.js"]: raise ValueError("Unexpected scripts")
    if parser.ranges != [("launch-speed", "range", "0", "36", "1"), ("orbit-time", "range", "0", "360", "1"), ("test-mass", "range", "0", "40", "1")]: raise ValueError("Unexpected control bounds")
    if any(not (site / name).is_file() for name in parser.local): raise ValueError("Broken local asset link")
    raw = (site / "orbit-data.js").read_text(); prefix = "window.PLOrbitData = "
    if not raw.startswith(prefix) or not raw.endswith(";\n"): raise ValueError("Invalid trajectory script")
    data = json.loads(raw[len(prefix):-2])
    if data.get("version") != 1 or data.get("samples") != 361 or data.get("scale") != 100 or len(data.get("cases", [])) != 37: raise ValueError("Invalid trajectory data")
    for i, case in enumerate(data["cases"]):
        if abs(case["factor"] - (.70 + .02*i)) > 1e-9: raise ValueError("Invalid speed grid")
        for key in ("x", "y", "vx", "vy", "r", "energy"):
            if len(case[key]) != 361 or not all(type(value) is int for value in case[key]): raise ValueError("Invalid saved samples")
    with zipfile.ZipFile(site / "orbital-gravitation.zip") as archive:
        if archive.testzip() is not None: raise ValueError("Damaged source archive")
        for name, expected in report["sources_sha256"].items():
            if hashlib.sha256(archive.read(name)).hexdigest() != expected: raise ValueError("Archive differs: " + name)
    print("PASS: static assets, bounded explorer, 37 saved Julia trajectories, hashes and archive")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("--site", type=Path, default=HERE.parents[1] / "data" / "examples" / "orbital-gravitation")
    verify(parser.parse_args().site)
