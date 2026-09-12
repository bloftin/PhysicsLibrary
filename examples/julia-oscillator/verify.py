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

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ("script", "form", "iframe", "object", "embed"):
            raise ValueError("Unexpected active element in the static viewer: " + tag)
        if any(key.startswith("on") for key in attrs):
            raise ValueError("Unexpected inline event handler")
        if tag == "input":
            if attrs.get("type") != "radio":
                raise ValueError("Only preset radio inputs are expected")
            self.radios.append(attrs.get("id"))
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
    if parser.radios != ["underdamped", "critical", "overdamped"]:
        raise ValueError("Missing preset controls")
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
    total = sum(path.stat().st_size for path in site.iterdir() if path.is_file())
    if total > 1024 * 1024:
        raise ValueError("Publication exceeds 1 MiB")
    print("PASS: source/artifact hashes, ZIP contents, three static presets, local assets, size budget")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", type=Path, default=HERE.parents[1] / "data" / "examples" / "julia-oscillator")
    args = parser.parse_args()
    verify(args.site)
