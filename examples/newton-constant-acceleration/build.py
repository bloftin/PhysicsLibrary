"""Publish saved Julia data, figures, an offline explorer and attachment bundles."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[1] / "data/examples/newton-constant-acceleration"
IDS = ("speeding-up", "coasting", "turning")
SOURCES = ("motion.jl", "cases.toml", "Project.toml", "Manifest.toml", "test/runtests.jl",
           "test/viewer.cjs", "build.py", "verify.py", "README.md", "LICENSE.txt", "COPYING",
           "article.tex", "preamble.tex", "preview.tex", "computational-resources.json",
           "viewer.template.html", "style.css", "explorer.js")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def archive(path, files):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)


def publish(site):
    from verify import check_rows
    config = tomllib.loads((HERE / "cases.toml").read_text())
    provenance = tomllib.loads((HERE / "results/provenance.toml").read_text())
    for section, root in (("inputs_sha256", HERE), ("outputs_sha256", HERE / "results")):
        for name, expected in provenance[section].items():
            if digest(root / name) != expected:
                raise ValueError("Regenerate Julia results: changed " + name)
    if tuple(c["id"] for c in config["cases"]) != IDS:
        raise ValueError("Update article/viewer before changing the case set")
    cases = []
    for c, force in zip(config["cases"], (4, 0, -2)):
        expected = dict(mass=2, force=force, x0=1, v0=3, t0=2, duration=6, samples=121)
        if any(c[k] != v for k, v in expected.items()):
            raise ValueError("Update article/viewer before publishing different parameters")
        with (HERE / "results" / (c["id"] + ".csv")).open() as stream:
            rows = list(csv.reader(stream))
        values = [[float(v) for v in row] for row in rows[1:]]
        check_rows(c, values)
        cases.append(dict(c, rows=values))
    site.mkdir(parents=True, exist_ok=True)
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    colors = ("#16766e", "#415fa5", "#b54865")

    def plot(path, selected, width):
        fig, axes = plt.subplots(3, 1, figsize=(width, 7.2), sharex=True)
        for index, (ax, label) in enumerate(zip(axes, ("Position (m)", "Velocity (m/s)", "Acceleration (m/s²)")), 1):
            for n in selected:
                c = cases[n]
                ax.plot([r[0]-c["t0"] for r in c["rows"]], [r[index] for r in c["rows"]],
                        color=colors[n], label=c["label"], linewidth=2, linestyle=("-", "--", "-.")[n])
            ax.set_ylabel(label)
            ax.grid(color="#e2e8e4", linewidth=0.7)
            ax.axhline(0, color="#9aa89f", linewidth=0.8)
            ax.set_xlim(0, 6)
            ax.set_ylim(((0, 60), (-4, 16), (-1.5, 2.5))[index-1])
            ax.spines[["top", "right"]].set_visible(False)
        axes[0].legend(fontsize=8, loc="upper left", frameon=False)
        axes[-1].set_xlabel("Elapsed time, t - t₀ (s)")
        fig.tight_layout()
        fig.savefig(path, dpi=110)
        plt.close(fig)

    panels = []
    for i, c in enumerate(cases):
        name = c["id"]
        plot(site / (name + ".png"), [i], 9)
        plot(site / (name + "-mobile.png"), [i], 4.2)
        panels.append(f'<figure><picture><source media="(max-width: 650px)" srcset="{name}-mobile.png"><img src="{name}.png" width="990" height="792" alt="{c["label"]}: position, velocity and acceleration versus elapsed time"></picture><figcaption>{c["label"]}: net force {c["force"]:g} N on a 2 kg mass. All plots use the same axis limits.</figcaption></figure>')
    plot(site / "comparison.png", [0, 1, 2], 9)
    for name in ("style.css", "explorer.js", "LICENSE.txt", "COPYING", "article.tex"):
        shutil.copyfile(HERE / name, site / name)
    for name in [n + ".csv" for n in IDS] + ["provenance.toml"]:
        shutil.copyfile(HERE / "results" / name, site / name)
    logo = HERE.parents[1] / "data/images/physicslibrarylogotransparent.png"
    if not logo.is_file():
        logo = HERE / "viewer/logo.png"
    if logo.resolve() != (site / "logo.png").resolve():
        shutil.copyfile(logo, site / "logo.png")
    page = (HERE / "viewer.template.html").read_text(encoding="utf-8")
    page = page.replace("@@PLOTS@@", "\n".join(panels)).replace("@@VERSION@@", provenance["julia_version"])
    (site / "index.html").write_text(page, encoding="utf-8")
    (site / "trajectory-data.js").write_text("window.PLConstantAcceleration = " + json.dumps(cases, allow_nan=False, separators=(",", ":")) + ";\n", encoding="utf-8")
    assets = ["index.html", "trajectory-data.js", "style.css", "explorer.js", "logo.png", "comparison.png", "article.tex", "LICENSE.txt", "COPYING", "provenance.toml"]
    assets += [name + ext for name in IDS for ext in (".csv", ".png", "-mobile.png")]
    files = {name: (HERE / name).read_bytes() for name in SOURCES}
    files.update({"results/" + name: (HERE / "results" / name).read_bytes() for name in [n + ".csv" for n in IDS] + ["provenance.toml"]})
    files.update({"viewer/" + name: (site / name).read_bytes() for name in assets})
    files["viewer/index.html"] = page.replace('href="newton-constant-acceleration.zip"', 'href="../README.md"').replace("Download Julia project", "Project README").encode()
    files["comparison.png"] = (site / "comparison.png").read_bytes()
    archive(site / "newton-constant-acceleration.zip", files)
    attachments = {name: (HERE / name).read_bytes() for name in ("article.tex", "preamble.tex", "computational-resources.json", "README.md", "LICENSE.txt")}
    attachments["comparison.png"] = (site / "comparison.png").read_bytes()
    archive(site / "article-attachments.zip", attachments)
    assets += ["newton-constant-acceleration.zip", "article-attachments.zip"]
    report = dict(sources_sha256={n: digest(HERE / n) for n in SOURCES},
                  files_sha256={n: digest(site / n) for n in assets})
    (site / "build.json").write_text(json.dumps(report, indent=2) + "\n")
    from verify import verify
    verify(site)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=SITE)
    args = parser.parse_args()
    publish(args.output)
