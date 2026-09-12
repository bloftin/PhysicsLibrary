"""Publish already-generated Julia results; never execute Julia or accept web input."""
import argparse
import csv
import hashlib
import html
import json
from pathlib import Path
import shutil
import zipfile

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

HERE = Path(__file__).resolve().parent
DEFAULT_SITE = HERE.parents[1] / "data" / "examples" / "julia-oscillator"
INPUTS = ("oscillator.jl", "presets.toml", "Project.toml", "Manifest.toml")
SOURCES = INPUTS + ("test/runtests.jl", "README.md", "LICENSE.txt", "article.tex", "preamble.tex", "preview.tex", "build.py", "verify.py", "viewer.template.html", "style.css")
IDS = ("underdamped", "critical", "overdamped")
COLORS = ("#157b72", "#b43d58", "#435fac")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_toml(path):
    with path.open("rb") as stream:
        return tomllib.load(stream)


def verified_data():
    config = read_toml(HERE / "presets.toml")
    provenance = read_toml(HERE / "results" / "provenance.toml")
    for name in INPUTS:
        if digest(HERE / name) != provenance["inputs_sha256"][name]:
            raise ValueError(f"Changed {name}; regenerate Julia results before publishing")
    if tuple(p["id"] for p in config["presets"]) != IDS:
        raise ValueError("This viewer is designed for the three published presets")
    # Explanatory text and axes describe this specific experiment.
    expected = dict(mass=1.0, stiffness=4.0, displacement=1.0, velocity=0.0, duration=12.0, samples=601)
    if config["model"] != expected or [p["damping"] for p in config["presets"]] != [0.8, 4.0, 8.0]:
        raise ValueError("Update the viewer and article before publishing a different experiment")
    data = {}
    for name in IDS:
        path = HERE / "results" / (name + ".csv")
        if digest(path) != provenance["outputs_sha256"][path.name]:
            raise ValueError(f"Changed {path.name}; regenerate Julia results")
        with path.open(newline="") as stream:
            data[name] = [{key: float(value) for key, value in row.items()} for row in csv.DictReader(stream)]
        if len(data[name]) != 601:
            raise ValueError("Incomplete dataset")
    return config, provenance, data


def draw_plots(site, config, data):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11,
                         "axes.spines.top": False, "axes.spines.right": False})

    def axes_style(ax):
        ax.set_xlim(0, 12)
        ax.set_xticks(range(0, 13, 2))
        ax.grid(True, color="#e3e8e5", linewidth=0.7)
        ax.set_axisbelow(True)
        ax.tick_params(colors="#4a5750")

    for preset, color in zip(config["presets"], COLORS):
        rows = data[preset["id"]]
        t = [row["time_s"] for row in rows]
        fig, axes = plt.subplots(2, 1, figsize=(10, 6.2), sharex=True)
        for ax in axes:
            axes_style(ax)
        axes[0].plot(t, [row["displacement_m"] for row in rows], color=color, linewidth=2.4)
        axes[0].axhline(0, color="#88968e", linewidth=.8)
        axes[0].set_ylim(-.65, 1.1)
        axes[0].set_ylabel("Displacement (m)")
        axes[0].set_title(preset["label"], loc="left", fontsize=14, pad=12)
        axes[1].plot(t, [row["energy_J"] for row in rows], color=color, linewidth=2.4)
        axes[1].set_ylim(-.05, 2.15)
        axes[1].set_ylabel("Mechanical energy (J)")
        axes[1].set_xlabel("Time (s)")
        fig.subplots_adjust(left=.10, right=.98, top=.91, bottom=.10, hspace=.20)
        fig.savefig(site / (preset["id"] + ".png"), dpi=100)
        fig.set_size_inches(6, 6.2)
        for ax in axes:
            ax.set_xticks((0, 4, 8, 12))
        axes[0].set_yticks((-.5, 0, .5, 1))
        axes[1].set_yticks((0, 1, 2))
        fig.subplots_adjust(left=.16, right=.97)
        fig.savefig(site / (preset["id"] + "-mobile.png"), dpi=100)
        plt.close(fig)
    fig, ax = plt.subplots(figsize=(10, 5.6))
    axes_style(ax)
    for preset, color, dash in zip(config["presets"], COLORS, ("-", "--", "-.")):
        rows = data[preset["id"]]
        ax.plot([r["time_s"] for r in rows], [r["displacement_m"] for r in rows],
                color=color, linestyle=dash, linewidth=2.2, label=preset["label"])
    ax.axhline(0, color="#88968e", linewidth=.8)
    ax.set_ylim(-.65, 1.1)
    ax.set_ylabel("Displacement (m)")
    ax.set_xlabel("Time (s)")
    ax.legend(loc="upper right", frameon=False)
    fig.subplots_adjust(left=.10, right=.98, top=.94, bottom=.12)
    fig.savefig(site / "comparison.png", dpi=100)
    fig.set_size_inches(6, 4.8)
    ax.set_xticks((0, 4, 8, 12))
    ax.set_yticks((-.5, 0, .5, 1))
    ax.legend(loc="upper right", frameon=False, fontsize=9)
    fig.subplots_adjust(left=.16, right=.97, bottom=.15)
    fig.savefig(site / "comparison-mobile.png", dpi=100)
    plt.close(fig)


def publish(site):
    config, provenance, data = verified_data()
    site.mkdir(parents=True, exist_ok=True)
    draw_plots(site, config, data)
    for name in IDS:
        shutil.copyfile(HERE / "results" / (name + ".csv"), site / (name + ".csv"))
    shutil.copyfile(HERE / "results" / "provenance.toml", site / "provenance.toml")
    for name in ("style.css", "LICENSE.txt"):
        shutil.copyfile(HERE / name, site / name)
    logo = HERE.parents[1] / "data" / "images" / "physicslibrarylogotransparent.png"
    if not logo.exists():
        logo = HERE / "viewer" / "logo.png"
    if logo.resolve() != (site / "logo.png").resolve():
        shutil.copyfile(logo, site / "logo.png")
    panels, choices = [], []
    for i, preset in enumerate(config["presets"]):
        name, label = preset["id"], html.escape(preset["label"])
        checked = " checked" if i == 0 else ""
        choices.append(f'<input type="radio" name="preset" id="{name}"{checked} aria-controls="{name}-panel"><label for="{name}">{label}</label>')
        zeta = preset["damping"] / 4
        panels.append(f'''<section class="preset" id="{name}-panel" aria-label="{label}">
          <picture><source media="(max-width: 650px)" srcset="{name}-mobile.png" width="600" height="620"><img src="{name}.png" width="1000" height="620" alt="{label}: displacement and mechanical energy versus time; {html.escape(preset['description'])}"></picture>
          <aside><h3>{label}</h3><p>{html.escape(preset['description'])}</p>
          <dl><div><dt>Damping coefficient</dt><dd>{preset['damping']:g} N s/m</dd></div><div><dt>Damping ratio</dt><dd>&#950; = {zeta:g}</dd></div></dl>
          <a href="{name}.csv" download>Download CSV data</a><p class="small">0 to 12 s &middot; 0.02 s sampling</p></aside>
        </section>''')
    page = (HERE / "viewer.template.html").read_text()
    page = page.replace("@@CHOICES@@", "\n".join(choices)).replace("@@PANELS@@", "\n".join(panels))
    page = page.replace("@@JULIA_VERSION@@", html.escape(provenance["julia_version"]))
    # The bundle includes a self-contained offline viewer. Its link points to the enclosing download.
    (site / "index.html").write_text(page.replace("@@ZIP_SIZE@@", "ZIP"), encoding="utf-8")
    assets = ["index.html", "style.css", "logo.png", "LICENSE.txt", "provenance.toml", "comparison.png", "comparison-mobile.png"]
    assets += [name + ext for name in IDS for ext in (".png", "-mobile.png", ".csv")]
    bundle = site / "julia-oscillator.zip"
    with zipfile.ZipFile(bundle, "w", zipfile.ZIP_DEFLATED) as archive:
        def add(path, name):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes())
        for name in SOURCES:
            add(HERE / name, name)
        for name in [p + ".csv" for p in IDS] + ["provenance.toml"]:
            add(HERE / "results" / name, "results/" + name)
        for name in assets:
            if name == "index.html":
                info = zipfile.ZipInfo("viewer/index.html", date_time=(2026, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                offline = (site / name).read_text().replace('href="julia-oscillator.zip"', 'href="../README.md"').replace("Download Julia project", "Project README")
                archive.writestr(info, offline)
            else:
                add(site / name, "viewer/" + name)
        add(site / "comparison.png", "comparison.png")
    (site / "index.html").write_text(page.replace("@@ZIP_SIZE@@", f"{bundle.stat().st_size / 1024:.0f} KB"), encoding="utf-8")
    report = {"sources_sha256": {name: digest(HERE / name) for name in SOURCES},
              "files_sha256": {name: digest(site / name) for name in assets + [bundle.name]}}
    (site / "build.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    total = sum((site / name).stat().st_size for name in assets + [bundle.name, "build.json"])
    if total > 1024 * 1024:
        raise ValueError("Published artifacts exceed the prototype's 1 MiB budget")
    print(f"Published {site}: {total / 1024:.0f} KiB including downloadable project")


def check(site):
    from verify import verify
    verified_data()
    verify(site)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_SITE)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    check(args.output) if args.check else publish(args.output)
