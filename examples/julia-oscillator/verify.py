"""Read-only publication checks using Python's standard library (no Julia needed)."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
from urllib.parse import urlsplit
import zipfile

HERE = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


class Viewer(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.radios = []
        self.ranges = []
        self.scripts = []
        self.in_script = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ("form", "iframe", "object", "embed"):
            raise ValueError("Unexpected active element in the static viewer: " + tag)
        if tag == "script":
            if attrs.get("src") not in ("sweep-data.js", "explorer.js") or "defer" not in attrs:
                raise ValueError("Unexpected viewer script")
            self.scripts.append(attrs["src"])
            self.in_script = True
        if any(key.startswith("on") for key in attrs):
            raise ValueError("Unexpected inline event handler")
        if tag == "input":
            if attrs.get("type") == "radio":
                self.radios.append((attrs.get("name"), attrs.get("id") or attrs.get("value")))
            elif attrs.get("type") == "range":
                self.ranges.append((attrs.get("id"), attrs.get("min"), attrs.get("max"), attrs.get("step")))
            else:
                raise ValueError("Unexpected viewer input")
        for key in ("href", "src", "srcset"):
            if key in attrs:
                value = attrs[key]
                parsed = urlsplit(value)
                if parsed.scheme:
                    if key != "href" or parsed.scheme != "https" or parsed.netloc != "physicslibrary.org":
                        raise ValueError("Unexpected external dependency: " + value)
                else:
                    if parsed.netloc or parsed.query or parsed.fragment or "/" in value or "\\" in value:
                        raise ValueError("Expected a local static filename: " + value)
                    self.links.append(value)

    def handle_endtag(self, tag):
        if tag == "script":
            self.in_script = False

    def handle_data(self, data):
        if self.in_script and data.strip():
            raise ValueError("Inline script is not allowed")


def verify_sweep(data):
    if (data["version"], data["scale"], data["samples"], data["duration"]) != (1, 1000000, 151, 12):
        raise ValueError("Unexpected sweep format")
    if len(data["cases"]) != 21:
        raise ValueError("Incomplete damping sweep")
    for i, row in enumerate(data["cases"]):
        if row["zeta"] != i / 10 or abs(row["damping"] - i * .4) > 1e-12:
            raise ValueError("Unexpected damping grid")
        for key, initial in (("x", 1000000), ("v", 0), ("energy", 2000000)):
            values = row[key]
            if len(values) != 151 or values[0] != initial or any(type(n) is not int or abs(n) > 3000000 for n in values):
                raise ValueError("Invalid saved trajectory")
        if any(n < 0 for n in row["energy"]) or any(b > a for a, b in zip(row["energy"], row["energy"][1:])):
            raise ValueError("Invalid energy trajectory")


def verify(site, source=HERE):
    report = json.loads((site / "build.json").read_text())
    for section, root in (("sources_sha256", source), ("files_sha256", site)):
        for name, expected in report[section].items():
            path = (root / name).resolve()
            if root.resolve() not in path.parents:
                raise ValueError("Manifest path escapes the example directory")
            if sha(path.read_bytes()) != expected:
                raise ValueError("Stale or modified file: " + name)
    parser = Viewer()
    parser.feed((site / "index.html").read_text())
    if parser.radios != [("osc-quantity", key) for key in ("x", "v", "energy")] + [("preset", key) for key in ("underdamped", "critical", "overdamped")]:
        raise ValueError("Missing preset controls")
    if parser.ranges != [("osc-damping", "0", "20", "1"), ("osc-time", "0", "150", "1")]:
        raise ValueError("Unexpected explorer bounds")
    if parser.scripts != ["sweep-data.js", "explorer.js"]:
        raise ValueError("Missing explorer assets")
    script = (site / "sweep-data.js").read_text()
    prefix = "window.PLOscillatorSweep = "
    if not script.startswith(prefix) or not script.endswith(";\n"):
        raise ValueError("Unexpected sweep script")
    verify_sweep(json.loads(script[len(prefix):-2]))
    if any(not (site / name).is_file() for name in parser.links):
        raise ValueError("Broken local viewer link")
    with zipfile.ZipFile(site / "julia-oscillator.zip") as archive:
        if archive.testzip() is not None:
            raise ValueError("Damaged download archive")
        for name, expected in report["sources_sha256"].items():
            if sha(archive.read(name)) != expected:
                raise ValueError("Download contains stale source: " + name)
        for name in ("underdamped", "critical", "overdamped"):
            if archive.read("results/" + name + ".csv") != (site / (name + ".csv")).read_bytes():
                raise ValueError("Download data differs from the public data")
        if archive.read("results/sweep.toml") != (source / "results/sweep.toml").read_bytes():
            raise ValueError("Download sweep differs from source")
        for name in ("sweep-data.js", "explorer.js"):
            if archive.read("viewer/" + name) != (site / name).read_bytes():
                raise ValueError("Download explorer differs from publication")
    total = sum(path.stat().st_size for path in site.iterdir() if path.is_file())
    if total > 1024 * 1024:
        raise ValueError("Publication exceeds 1 MiB")
    print("PASS: hashes, ZIP, 21 saved trajectories, bounded controls, static fallback, local assets, size budget")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", type=Path, default=HERE.parents[1] / "data" / "examples" / "julia-oscillator")
    args = parser.parse_args()
    verify(args.site)
