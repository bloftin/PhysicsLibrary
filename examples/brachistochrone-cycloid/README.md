# Brachistochrone Cycloid and Travel Time

A static PhysicsLibrary computational resource for CV17, **The Brachistochrone
Problem**. Julia solves the cycloid endpoint equation by monotone bisection,
samples the resulting trajectory, records the complete bisection history, and
generates a travel-time convergence study for a piecewise-linear approximation.

Three published endpoint regimes use the same depth scale `Y = 1 m`:

- `before-bottom`: `X=1 m`, so the endpoint occurs before the bottom of the arch;
- `at-bottom`: `X=pi/2 m`, so `theta_B=pi` exactly;
- `after-bottom`: `X=4 m`, the CV17 example, for which the fastest cycloid dips
  below the endpoint and rises back to it.

## Interactive explorer

The Julia-oscillator-style explorer has four linked panels controlled by the
selected reference endpoint:

1. **Cycloid versus straight line.** Scrub through saved `(x,y,t,v)` cycloid
   samples while the straight chord remains visible.
2. **Travel-time comparison.** Compare the exact cycloid time with the analytic
   straight-line time and the idealized vertical-drop-plus-horizontal path.
3. **Travel-time convergence.** Scrub saved midpoint-segment estimates from
   4 through 16384 segments and watch the relative error approach zero.
4. **Endpoint-root solve.** Scrub every saved bisection iteration. The explorer
   shows the current bracket, midpoint, bracket width, and nonlinear-equation
   residual.

The explorer is fully static. JavaScript draws the saved datasets onto canvases;
it does not perform the endpoint solve, numerical convergence calculation, or
any Julia execution. Moving controls makes no network requests. Static PNGs and
CSV downloads remain available as fallbacks.

## Reproduce locally

Target environment: Julia 1.10.12, standard libraries only.

```bash
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. brachistochrone.jl
```

Then build the published plots, offline explorer and source archive with Python
3.11+ and Matplotlib:

```bash
python3 build.py
python3 verify.py
```

For an extracted project use `python3 build.py --output viewer` and open
`viewer/index.html` directly.

## Numerical method

For endpoint `(X,Y)` the dimensionless terminal parameter solves

`X/Y = (theta - sin(theta))/(1 - cos(theta))`, `0 < theta < 2pi`.

The ratio is monotone on the relevant cycloid arch, so bracketed bisection is
simple and robust. Every iteration is written to `results/root-history.csv`.
Once `theta_B` is found,

`a = Y/(1-cos(theta_B))`,

`x = a(theta-sin(theta))`, `y = a(1-cos(theta))`, and

`T = theta_B*sqrt(a/g)`.

For the independent time check, the cycloid is replaced by `N` short straight
segments. Each segment uses the speed at its midpoint depth. The saved values
for `N = 4, 8, ..., 16384` are written to `results/time-convergence.csv`. Tests
check that the absolute error decreases at every refinement level for all three
reference cases.

Tests also check endpoint closure, `v^2=2gy`, the special `theta_B=pi` case,
geometric/time scaling, the bisection brackets, and the final endpoint residual.

## PhysicsLibrary integration

1. Add the object/filebox manifest `computational-resources.json` to CV17.
2. Add `catalog-entry.json`'s resource object to the site catalog
   `etc/computational-resources.json`.
3. Publish the generated static files under
   `data/examples/brachistochrone-cycloid/`.
4. Keep the article's ordinary explorer link for PDF readers.

The public target URL is intended to be:
`https://images.physicslibrary.org/examples/brachistochrone-cycloid/index.html`.

## Draft-data note

The package produced in this ChatGPT session includes preview CSV files generated
from an independent Python implementation of the same formulas because a Julia
runtime was not available in the authoring container. The included `build.py`
refuses to treat those files as publication provenance unless `--allow-draft` is
supplied. **Before publishing, run the two Julia commands above**, which replace
the results and provenance with actual Julia-generated files, then rebuild
without `--allow-draft`.

Software is GPLv3-or-later; mathematical text, figures and data retain the normal
PhysicsLibrary CC BY-SA terms. See `LICENSE.txt`.
