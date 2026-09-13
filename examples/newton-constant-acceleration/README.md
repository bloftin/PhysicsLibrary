# Constant Acceleration from Newton's Second Law

Three constant net forces on the same initial state, a worked double integration,
saved Julia results and an offline explorer. Parent topic:
https://physicslibrary.org/encyclopedia/NewtonsLawsOfMotion.html

## Publish the article

Create an **Example** titled **Constant Acceleration from Newton's Second Law**
under parent canonical name `NewtonsLawsOfMotion`. Keep the parent article's
existing body and attribution intact.

1. Put `preamble.tex` in the preamble field and `article.tex` in the body field.
2. Upload `comparison.png` and `computational-resources.json` to its filebox,
   keeping these exact filenames. The image is in the source ZIP root and in
   the smaller `article-attachments.zip` bundle.
3. Preview HTML and PDF, then save. The Computational Resources section appears
   on the saved article, outside the body, not in the editor preview or PDF.
   The body includes a normal link for PDF readers.
4. Optionally upload the manifest to the parent Newton's laws article too. If
   it already has a manifest, add the id to its existing `resources` array.

Explorer: https://images.physicslibrary.org/examples/newton-constant-acceleration/index.html

## Mathematics and data

The model assumes an inertial frame, constant mass and constant signed net force
in one dimension. No drag, variable mass or relativistic effects. All cases use
m=2 kg, x0=1 m, v0=3 m/s, t0=2 s, and 6 s elapsed duration. Net forces are
+4 N, 0 N and -2 N. There are 121 samples at 0.05 s intervals.

At clock time 5 s the +4 N case has x=19 m and v=9 m/s. The -2 N case
has x=5.5 m and v=0; its continuing force reverses the motion. At clock time
8 s it returns to x=1 m with v=-3 m/s. Distance traveled is 9 m, although
displacement is zero. This is not a brake that switches off at rest.

Julia evaluates the standard-library matrix exponential for state [x,v,1].
Tests independently check integrated polynomials, initial values, work-energy,
signed velocity integrals, clock shifts and mass scaling. No time-stepping solver
is needed. Floating-point/CSV rounding is checked to numerical tolerances.
The browser reads saved samples without interpolation. Without JavaScript all
three trajectory figures and the derivation remain visible.

## Reproduce locally

Julia 1.10.12, standard libraries only, no package downloads required:

```bash
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. motion.jl
```

`results/provenance.toml` records runtime, platform, method and input/output hashes.
Edit `cases.toml` for local experiments. The publisher refuses altered parameters
until its explanatory text is updated.

Build with Python 3.11+ and Matplotlib (or Python 3.10 with `tomli`):

```bash
python3 build.py
python3 verify.py
```

In an extracted project use `python3 build.py --output viewer` and
`python3 verify.py --site viewer`. Open `viewer/index.html` directly in a browser.
For a local PDF run `pdflatex -interaction=nonstopmode -halt-on-error preview.tex`
twice from the project directory, with `comparison.png` in that directory.

The build plots saved data, packages both ZIPs and records hashes in `build.json`.
Publication size including both ZIPs is capped at 1 MiB. `verify.py` uses only
the Python standard library, so production needs neither Julia nor Matplotlib.
Never wire the generator into a web request or upload.

Optional browser regression tests use Node and Playwright:

```bash
node test/viewer.cjs
```

`PLAYWRIGHT_MODULE` and `BROWSER_PATH` select existing installations;
`VIEWER_SITE` can point at an extracted offline viewer. Tests cover saved values,
keyboard scrubbing, mobile layout, canvas, no extra requests from controls,
and the no-JavaScript fallback.

## Production checkout and tests

```bash
cd /var/www/pp
git status --short
git fetch origin
git switch codex/newton-constant-acceleration
git pull --ff-only
sudo -u apache prove -v bin/test/computational-resources.t
python3 examples/newton-constant-acceleration/verify.py
sudo apachectl configtest
sudo systemctl restart httpd
curl -fI https://images.physicslibrary.org/examples/newton-constant-acceleration/index.html
```

Restart after the catalog update. No database migration is needed.
Select +4 N and elapsed time 3 s: expect clock time 5 s, x=19 m, v=9 m/s.
Select -2 N at that time: x=5.5 m, v=0 m/s, a=-1 m/s^2. At elapsed time
6 s expect x=1 m and v=-3 m/s. With JavaScript disabled, all three figures
and the math remain visible. Check the saved article's resource links, CSVs
and source ZIP. After static assets load, controls make no network requests.

Software is GPLv3-or-later; mathematical text, figures and data retain Physics
Library CC BY-SA. See `LICENSE.txt` and `COPYING` in the downloadable project.
