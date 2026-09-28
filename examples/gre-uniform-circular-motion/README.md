# GRE Uniform Circular Motion

This static Julia-backed explorer accompanies the existing [GRE Uniform Circular
Motion article](https://physicslibrary.org/encyclopedia/GREUniformCircularMotion.html)
(object 1322). Visitors choose radius, tangential speed, starting angle and mass.
The browser evaluates the article's exact uniform-motion formulae locally:

```text
theta(t) = theta0 + (v/R)t
r(t) = (R cos(theta), R sin(theta))
v(t) = (-v sin(theta), v cos(theta))
a(t) = -(v^2/R)(cos(theta), sin(theta))
T = 2 pi R/v, f = 1/T, F_net,inward = m v^2/R
```

The optional inner marker sits at half the radius and shares the outer marker's
angular speed, so its tangential speed and inward acceleration are both half.
The displayed vector arrows show directions; their lengths are scaled
independently rather than representing numerical magnitudes. The model is
kinematic and assumes constant speed. It does not introduce a new force called
"centripetal" or identify what physical interaction supplies the inward net
force. Julia generates four reference trajectories, including the article's
5 m / 8 m/s example and the 0.35 m wheel at 120 rpm.

## Reproduce

With Julia 1.10.12 and Python 3.11+:

```bash
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. circular_motion.jl
python3 build.py
python3 verify.py
```

Julia uses only standard libraries. `build.py` copies the reviewed static assets
to `data/examples/gre-uniform-circular-motion` and creates an offline ZIP. The
production site serves static HTML/CSS/JS/CSV only; no Julia execution is wired
to page views or input controls. `verify.py` checks all reference vectors and
kinematic quantities against independent formulas and verifies the publication
hashes and archive. Browser tests live in `test/viewer.cjs` and use Playwright.

## Attach to the article

1. Merge and deploy the static publication and reviewed catalog entry.
2. Upload this directory's `computational-resources.json` to object 1322's
   filebox using the authorized editor. If a manifest exists, preserve its other
   resource IDs (maximum four) rather than replacing them.
3. Reload the article. Its Computational Resources section should link the
   explorer, Julia archive, CSV, provenance and license. Try all four reference
   cases and the radius/speed/angle controls on desktop and mobile.

The manifest attachment is a separate authorized production step, not performed
by this PR. No database migration, background job, Julia installation on the
server, or article rerender is required. The static image host publishes the
explorer at
`https://images.physicslibrary.org/examples/gre-uniform-circular-motion/`.

Software is GPLv3-or-later. Mathematical text and reference data retain the
site's CC BY-SA article terms. See `LICENSE.txt`.
