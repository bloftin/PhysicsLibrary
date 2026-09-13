# Damped harmonic motion: Julia publishing prototype

An Example article with a precomputed damping explorer and three reference presets.
Browsing or choosing a case never executes Julia. Optional local JavaScript draws
saved trajectories and creates CSV downloads; without it, native radio controls,
CSS, and PNGs retain the three reference presets. There are no forms, cookies,
external fonts, requests triggered by the explorer controls, or polling.
No execution service, execution permission, database schema, or article type
changes are needed. An optional filebox manifest connects the publication to an
article's Computational Resources section.

## Reproduce locally

The published calculations were produced with Julia 1.10.12 on Linux x86-64,
using only Julia standard libraries. Start in this directory (or the root of
the extracted download):

```bash
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. oscillator.jl
```

Both commands work without downloading packages on the recorded Julia version.
`Manifest.toml` records the environment; `results/provenance.toml` records the
actual runtime, BLAS configuration, source hashes, and CSV hashes. Different
Julia/BLAS versions can produce tiny floating-point differences. The tests use
numerical tolerances, not byte equality across platforms.

The script evaluates `exp(t*A)*u0` at 601 reference sample times. It does not implement a
time-stepping integrator. The independent tests verify displacement and velocity
against the three analytic forms, nonnegative/monotone energy, initial conditions,
an undamped energy-conservation case, and nonzero initial velocity.

The presets use m=1 kg, k=4 N/m, x0=1 m, v0=0 m/s and damping c=0.8, 4, 8 N s/m.
To conduct another experiment, edit `presets.toml` locally. The publishing script
intentionally refuses different physical parameters until its explanatory text
and article are updated. Preset-specific tests likewise describe the published
experiment and may need adjustment.

The interactive sweep keeps those same initial conditions, mass and stiffness,
with 21 damping ratios from 0 to 2 in steps of 0.1. Julia generates 151 samples
per case, at 0.08 s intervals, saved in `results/sweep.toml`. Displacement,
velocity and energy are quantized to integers at scale 1,000,000 (absolute
rounding error at most 0.0000005 in m, m/s or J). Tests compare every saved
sample against independent analytic solutions. The browser displays these
samples without solving the equation or interpolating between damping cases.
Selected-case CSV downloads contain these rounded values; the three reference
CSVs retain their original higher precision and denser sampling.

## Build the published plots and download

Python is used only by the author/build machine to plot the Julia-produced CSVs
with Matplotlib and package the download. It does not compute the trajectories.
Requirements: Python 3.11+ and Matplotlib (published with 3.10.8); Python 3.10
also works with `tomli` installed.

```bash
python3 build.py
python3 build.py --check
```

In the repository this updates `data/examples/julia-oscillator/`. In an extracted
download use an explicit output directory:

```bash
python3 build.py --output viewer
python3 build.py --output viewer --check
```

The builder rejects stale source/CSV combinations, records published artifact
hashes in `build.json`, and limits the total published payload (including the ZIP)
to 1 MiB. Hashes detect inconsistent builds; they are not a code-signing system.
Open `index.html` in the published directory, or `viewer/index.html` in the ZIP,
directly in a browser. Three preset PNGs total much less than the download; the
comparison image is lazy-loaded. No dev server is needed.

Optional browser regression test on the development machine (Node.js,
Playwright and its Chromium browser must already be installed):

```bash
node test/viewer.cjs
```

`PLAYWRIGHT_MODULE` and `BROWSER_PATH` can select an existing installation.
For an extracted download, set `VIEWER_SITE` to the absolute `viewer` directory.
The test checks desktop/mobile controls, playback, selected CSV downloads,
request bounds, reduced motion and the no-JavaScript fallback. None of these
browser-test dependencies are required on production.

## Production checkout and checks

Run on production after reviewing `git status --short`. Preserve local changes
before switching branches; do not reset the worktree.

```bash
cd /var/www/pp
git status --short
git fetch origin
git switch codex/computational-resources
git pull --ff-only
sudo -u apache prove -v bin/test/computational-resources.t
python3 examples/julia-oscillator/verify.py
sudo apachectl configtest
sudo systemctl restart httpd
curl -fI https://images.physicslibrary.org/examples/julia-oscillator/index.html
```

The explorer is static. Neither Julia nor Python plotting dependencies are
required on production. Restart httpd to load the new article integration module;
later static-only asset updates do not require a restart. The repository's image
virtual host serves `/var/www/pp/data`. The new directory avoids the denied
`data/doc` path. Confirm the deployed virtual host matches this configuration.
If the URL is denied, inspect that virtual host's rules; do not relax the existing
restrictions on `data/doc` or `data/files`.

The publication verification command uses only Python's standard library. It
checks source and artifact hashes, the actual ZIP contents, local asset links,
the two expected local scripts, absence of inline scripts/submission forms,
bounded controls, sweep structure, and the 1 MiB size budget.

Live manual tests:

1. Visit the URL signed out. Select damping ratios 0, 0.2, 1 and 2. Scrub time,
   switch displacement/velocity/energy, play, pause and reset. At zero damping,
   energy stays at 2 J. Download a selected case: expect 151 data rows and the
   selected damping ratio in its filename. Playback starts only when requested,
   pauses when the tab is hidden, and is disabled with reduced-motion enabled.
2. Open Three reference presets and switch all three cases. Disable JavaScript
   and reload: the reference controls still work and the explorer stays hidden.
   Use Tab and arrow keys to change the native radio selection.
3. Check at a narrow mobile width and on desktop. No horizontal page scrolling
   or overlapping labels should occur.
4. Download the ZIP, extract it locally, and run the two Julia commands above.
   Open its `viewer/index.html` without a server.
5. In the Network panel, all server requests should be static GETs. Moving the
   explorer controls must make no new network requests. Switching reference presets
   may retrieve a saved PNG if the browser deferred it, but must never POST,
   poll, or call a rendering route. Compare CPU/process monitoring if desired.

After merge, use `git switch main` and `git pull --ff-only` on production.

## Publish as a PhysicsLibrary article

Create an **Example** titled **Three Damping Regimes of a Harmonic Oscillator**.
Choose the existing harmonic-oscillator topic as the parent using its actual
canonical name; the prototype does not assume an object id or create a DB row.

- Preamble: `preamble.tex`.
- Article body: `article.tex` (no documentclass or document environment).
- Filebox: upload `comparison.png` from the published directory. The body links
  to the public preset viewer and downloadable project.
- Filebox: also upload `computational-resources.json` from this directory (or
  the ZIP root), keeping its filename unchanged. After saving, the article's
  Computational Resources section links the reviewed explorer, project, three
  datasets, provenance and license. No additional LaTeX command is needed.
- Optionally attach `julia-oscillator.zip` and the three CSVs for the article's
  own filebox, preserving the original filenames.

Preview with make4ht and PDF, confirm the comparison figure and download link,
then publish through the normal editor. New article rendering may run LaTeX;
it does not run Julia. Keep the bundled example license with source downloads.
The resources section is outside the rendered content, so it also appears below
the PDF or PNG viewer. It is not inserted inside a downloaded PDF or the editor
preview. The article body's ordinary link remains available to PDF readers.
Maintainers can find the reusable manifest/catalog format and deployment checks
in `docs/computational-resources.md` in the site repository.

## Boundary for a future execution service

The static prototype is deliberately not an untrusted-code execution service.
Publishing scripts are run explicitly by an author on their development machine;
do not connect filebox uploads, page GETs, rerender actions, or article saves to
these commands. Never automatically run downloaded user code in CI.

If live execution is added later, require approval for an exact code revision,
bounded numerical inputs, authenticated CSRF-protected POSTs, a separate isolated
worker without site credentials or network access, hard process/resource limits,
account and global budgets, queue bounds, and deduplicated jobs. Static output
still consumes bandwidth: apply edge/server download limits and caching separately.
This prototype includes no deployment of workers or claim of bot-proof hosting.
