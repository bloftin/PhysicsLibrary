"""Read-only publication checks; Python standard library only."""
import argparse
import csv
import hashlib
from html.parser import HTMLParser
import json
import math
from pathlib import Path
from urllib.parse import urlsplit
import zipfile

HERE = Path(__file__).resolve().parent
IDS = ("speeding-up", "coasting", "turning")

def sha(data):
    return hashlib.sha256(data).hexdigest()

def check_rows(c, rows):
    assert len(rows) == 121, "Incomplete trajectory"
    a = c["force"] / c["mass"]
    for i, row in enumerate(rows):
        assert len(row) == 4 and all(math.isfinite(v) for v in row), "Invalid row"
        t, x, v, actual_a = row
        tau = i * 0.05
        expected = (c["t0"]+tau, c["x0"]+c["v0"]*tau+a*tau*tau/2, c["v0"]+a*tau, a)
        assert all(math.isclose(p, q, rel_tol=1e-10, abs_tol=1e-10) for p, q in zip(row, expected)), "Trajectory differs from integrated solution"
        assert math.isclose(c["mass"]*(v*v-c["v0"]**2)/2, c["force"]*(x-c["x0"]), abs_tol=1e-8), "Work-energy mismatch"

class Viewer(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = set()
        self.scripts = []
        self.in_script = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        assert tag not in ("form", "iframe", "object", "embed"), "Unexpected active element"
        assert not any(k.startswith("on") for k in attrs), "Inline handler"
        if tag == "script":
            assert attrs.get("src") in ("trajectory-data.js", "explorer.js") and "defer" in attrs
            self.scripts.append(attrs["src"])
            self.in_script = True
        for key in ("src", "srcset", "href"):
            if key not in attrs:
                continue
            value = attrs[key]
            parsed = urlsplit(value)
            if parsed.scheme or parsed.netloc:
                assert key == "href" and parsed.scheme == "https" and parsed.netloc == "physicslibrary.org", "External dependency"
            else:
                assert value and not any(c in value for c in ("/", "\\", "?", "#")), "Expected local filename"
                self.links.add(value)

    def handle_endtag(self, tag):
        if tag == "script":
            self.in_script = False

    def handle_data(self, data):
        assert not self.in_script or not data.strip(), "Inline script"

def verify(site):
    report = json.loads((site / "build.json").read_text())
    for section, root in (("sources_sha256", HERE), ("files_sha256", site)):
        for name, expected in report[section].items():
            path = (root / name).resolve()
            assert root.resolve() in path.parents, "Path outside publication"
            assert sha(path.read_bytes()) == expected, "Changed file: " + name
    page = (site / "index.html").read_text(encoding="utf-8")
    parser = Viewer()
    parser.feed(page)
    assert parser.scripts == ["trajectory-data.js", "explorer.js"]
    assert all((site / name).is_file() for name in parser.links), "Broken asset link"
    script = (site / "trajectory-data.js").read_text()
    prefix = "window.PLConstantAcceleration = "
    assert script.startswith(prefix) and script.endswith(";\n")
    cases = json.loads(script[len(prefix):-2])
    assert [c["id"] for c in cases] == list(IDS)
    for c, force in zip(cases, (4, 0, -2)):
        assert all(c[k] == v for k, v in dict(mass=2, force=force, x0=1, v0=3, t0=2, duration=6, samples=121).items())
        with (site / (c["id"] + ".csv")).open() as stream:
            rows = list(csv.reader(stream))
        assert rows[0] == ["time_s", "position_m", "velocity_m_s", "acceleration_m_s2"]
        values = [[float(v) for v in r] for r in rows[1:]]
        assert values == c["rows"], "Explorer data differs from CSV"
        check_rows(c, values)
    with zipfile.ZipFile(site / "newton-constant-acceleration.zip") as z:
        assert z.testzip() is None
        for name, expected in report["sources_sha256"].items():
            assert sha(z.read(name)) == expected, "Stale bundled source: " + name
        for name in report["files_sha256"]:
            if name.endswith(".zip"):
                continue
            expected = (site / name).read_bytes()
            if name == "index.html":
                expected = page.replace('href="newton-constant-acceleration.zip"', 'href="../README.md"').replace("Download Julia project", "Project README").encode()
            assert z.read("viewer/" + name) == expected, "Stale offline asset: " + name
        for name in [n + ".csv" for n in IDS] + ["provenance.toml"]:
            assert z.read("results/" + name) == (site / name).read_bytes()
    with zipfile.ZipFile(site / "article-attachments.zip") as z:
        assert z.testzip() is None
        for name in ("article.tex", "preamble.tex", "computational-resources.json", "README.md", "LICENSE.txt"):
            assert z.read(name) == (HERE / name).read_bytes()
        assert z.read("comparison.png") == (site / "comparison.png").read_bytes()
    total = sum(p.stat().st_size for p in site.iterdir() if p.is_file())
    assert total <= 1024*1024, "Publication exceeds 1 MiB"
    print("PASS: hashes, three analytic trajectories, work-energy, CSV/explorer parity, ZIPs, local links; %d KiB total" % (total//1024))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", type=Path, default=HERE.parents[1] / "data/examples/newton-constant-acceleration")
    verify(parser.parse_args().site)
