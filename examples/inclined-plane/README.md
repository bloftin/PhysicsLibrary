# Motion on an Inclined Plane

Three releases from rest on a 30 degree, 10 m ramp: frictionless, sliding
with friction, and held by static friction. The mass is 2 kg and g = 9.81 m/s^2.
The explorer animates saved Julia samples with weight, normal and friction
vectors. It works offline, requires no server computation, and makes no
network requests during playback. Without JavaScript the plots and math remain.

## Attach to a PhysicsLibrary article

1. Deploy the reviewed catalog and static publication from this branch.
2. Extract `article-attachments.zip` locally.
3. For a new Example, use title `Motion on an inclined plane` and put
   `article.tex` in the article body and `preamble.tex` in the preamble.
   These are fragments, not a complete LaTeX document.
4. Upload `inclined-plane-forces.png`, `comparison.png`, and
   `computational-resources.json` through the article filebox.
5. Preview the math and diagrams, then save. The Computational Resources
   section appears on the saved article, outside the rendered body.

For an existing article, upload just the manifest to attach the explorer.
If a manifest already exists, add `inclined-plane` to its `resources` array
without dropping its other IDs (maximum four). It can be combined with
`newton-constant-acceleration` or `julia-oscillator`.
Do not upload the attachment ZIP itself expecting automatic extraction.

## Reproduce locally

Use Julia 1.10.12 with the included Project and Manifest:

```bash
cd examples/inclined-plane
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. motion.jl
python3 build.py
python3 verify.py
```

Publication requires Python 3.11+ (or Python 3.10 plus `tomli`) and Matplotlib.
Verification uses only the Python standard library. No extra Julia packages
are required. Regenerate results after changing the model or inputs; the
publisher checks provenance hashes before building.

The default output in a repository checkout is `data/examples/inclined-plane`.
Use `python3 build.py --output viewer` in an extracted source bundle, followed
by `python3 verify.py --site viewer`. Open `viewer/index.html` directly.
The bundle includes all offline assets and a copy of the original logo.
`python3 build.py` also produces the two article PNGs beside `preview.tex`.
Compile `pdflatex -interaction=nonstopmode -halt-on-error preview.tex` twice
to check a standalone PDF. Production make4ht preview is a separate check.

Browser checks use Playwright; optionally set `BROWSER_PATH`, `PLAYWRIGHT_MODULE`,
`VIEWER_SITE`, and `SCREENSHOT_DIR`, then run `node test/viewer.cjs`.
They exercise desktop and narrow mobile layouts, all cases, playback, keyboard
controls, force visibility, offline links, canvas changes and no-JavaScript fallback.

## Model and checks

Static friction matches mg sin(theta) up to mu_s N; at the threshold rest is
retained. Above the threshold, acceleration is g(sin(theta)-mu_k cos(theta)).
The moving trajectories end at s=L; final speed is the arrival speed, not a
post-impact state. The static case is observed for four seconds. This model
does not cover initial uphill motion, rolling, or transitions to another surface.

Julia uses `LinearAlgebra.exp` on the augmented [s,v,1] state. Tests independently
check double integration, initial conditions, mass independence, the static
threshold, arrival, and K+U+Q conservation. Python checks every saved row,
CSV/viewer parity, publication hashes, packaged sources and offline assets.

Code is GPLv3-or-later; article, math, figures and data follow Physics Library
CC BY-SA. See `LICENSE.txt` and `COPYING`.
