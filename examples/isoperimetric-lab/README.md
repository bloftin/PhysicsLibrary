# Isoperimetric Geometry Lab (CV09E1)

An offline, Julia-backed companion to **CV09E1 exercises 1, 3, 4 and 6**:
https://physicslibrary.org/encyclopedia/CV09E1.html (article 1208).
One native select switches the geometry, parameters, chart and mathematical explanation.

- 1: fixed-chord circular graph family, signed curvature and the plus-convention multiplier lambda = -R. Varying the half-angle sets a new length budget, not a length-preserving deformation.
- 3: the semicircle with L = pi*a, finite parametric endpoint tangents and the graph's vertical endpoint slopes.
- 4: fixed curved rope length with sliding shoreline endpoints, orthogonality, major arcs and reflection. The shore costs no rope. A chart compares the exact circular family to the global reflection bound.
- 6: circle, square and regular polygon scaled separately to the same closed perimeter, with area ratios and a polygon triangle/apothem.

## Computation and limitations

`model.js` uses mathjs symbolic parametric derivatives for tangent/curvature and the area slope, plus D3 polygon area/perimeter. It is a fixed analytic catalog, not a general curve optimizer. The GUI never accepts or evaluates arbitrary expressions. The 2D drawings preserve a shared length scale for each shape comparison. Tangent/normal arrows are unit directions drawn at a common screen scale, not physical forces or the functional gradients. Animation moves a probe or changes polygon sides; it is not physical evolution.

The independent Julia implementation uses explicit analytic formulas, not the JS symbolic engine. `reference.csv` contains 533 samples from 13 cases, including shallow and semicircular arcs, minor and major Dido arcs, matched and mismatched multipliers, and polygons. Browser tests compare every applicable quantity to Julia, and independently integrate densely sampled boundary area and length. Polygon reference rows repeat aggregate metrics while their x/y columns sample the circumcircle, not polygon edges; JS vertex geometry is separately checked against analytic Julia areas, radii and apothems.

All educational text distinguishes interior stationarity, free-endpoint conditions and global maximality. Semicircles are smooth parametric curves but not C1 graphs at the endpoints. Reflection uses the separate closed-curve isoperimetric theorem. Polygon comparisons alone do not prove that theorem.

## Rebuild

Julia 1.11.2, Node >=22, pnpm 11.25.0 and Python >=3.11:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate(); include("test/runtests.jl"); include("isoperimetric-lab.jl"); IsoperimetricLab.reference()'
pnpm install --frozen-lockfile --ignore-scripts
node --test test/model.test.mjs
node build.mjs
python build.py
python test/package_test.py
```

The checkout publishes into `data/examples/isoperimetric-lab`; the extracted project rebuilds into `dist/`. The ZIP already has a ready-to-open `index.html` and bundled runtime: no installation, Julia, network, WebGL or server is needed to explore it. Dependency acquisition is only a build-time step. A cached pnpm store and Julia standard libraries suffice for an offline rebuild.

`test/viewer.cjs` requires Playwright, with an optional `BROWSER_EXECUTABLE` path for Edge/Chrome. It checks the dropdown, control validation, explanations, all four examples, animation, actual canvas pixels, CSV and desktop/mobile layouts at 1440/1024/768/390/320 pixels, with no HTTP requests.

## Attachment / deployment

Deploy reviewed catalog/static files normally. Upload **only** `computational-resources.json` from this folder to article **1208 (CV09E1)**'s filebox. Preserve any existing resource IDs in that manifest (maximum four). No article TeX edit or render is necessary. The previous `constrained-variations` lab remains unchanged on CV09. This change does not upload anything or modify a production database.

Original code GPLv3-or-later; original text/reference data CC BY-SA 4.0. See `LICENSE.txt`, `COPYING`, `THIRD-PARTY.txt` and `provenance.toml`.
