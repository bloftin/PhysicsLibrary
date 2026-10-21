# Vector Path to a Target Surface (CV07)

One resource combines a tilted-plane endpoint problem with sphere and ellipsoid endpoints. It extends Example 1 and section 16 of [CV07](https://physicslibrary.org/encyclopedia/CalculusOfVariationsSeveralDependentVariablesAndVectorFunctionals.html), article 1469. It is not a verbatim exercise from the article.

Open `index.html` in the published directory or unpacked ZIP. No web server, CDN, remote fonts, Julia installation or network connection is needed to use the viewer. Julia supplies independently reproducible reference calculations; the browser evaluates the same finite family locally. No code is executed on the Physics Library server.

## Mathematics

The start A and duration T are fixed. Minimize J = integral(|qdot|^2/2, 0, T), with q(0)=A and g(q(T))=0. Only the endpoint is constrained, not the intervening path. Crossing a target is permitted; this is not collision detection, an obstacle, or a first-impact problem. Changing T selects a different fixed-time problem.

The interior equation is qddot=0. Endpoint stationarity requires p dot eta_B=0 for every tangent direction, hence p=lambda*grad(g), where p=qdot for this particular integrand. The multiplier may be negative. A single zero directional derivative does not imply stationarity: the displayed norm of tangential momentum checks the entire tangent plane.

The displayed family is q=A+s(B-A)+h*sin(pi*s)*ez, s=t/T. Its exact energy is |B-A|^2/(2T)+pi^2*h^2/(4T). For eta(t)=s*eta_B the first variation is boundary p(T) dot eta_B plus interior pi*h*eta_B_z/T. Their sum is (B-A) dot eta_B/T. The boundary term alone is the total only when the interior equation holds.

Cauchy-Schwarz proves J >= |B-A|^2/(2T) >= dist(A,S)^2/(2T). Equality is the constant-speed segment to the nearest point. Curved targets require an exterior start. The sphere's far-side radial point is also stationary, but is a saddle in the full path problem, not a global maximum. The plane includes the zero-motion case A=B.

The ellipsoid projection solves sum(d_i*a_i^2/(d_i+l)^2)=1 for positive l, d_i=axis_i^2, and b_i=d_i*a_i/(d_i+l). Browser bisection is the unmodified BSD-3-Clause [`fmin` implementation](https://github.com/benfred/fmin/blob/6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b/src/bisect.js), pinned at commit `6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b`. Julia uses independent safeguarded Newton. Both are tested against constructed ellipsoid normal rays with known closest points.

Physical (x,y,z) maps to Three.js (x,z,-y). All momentum arrows share one displayed scale. The green displacement is unit tangent direction at a separate geometric scale. Surface colors represent straight-path endpoint cost, not potential. Animation rotates this allowed direction; it is not physical motion or an optimizer. The minimum action chooses the exact global minimizer, not an iterative descent.

## Reproduce

Julia 1.11.2, stdlib-only project:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. vector-target-lab.jl
```

Node 22+ and pnpm 11.25.0 (the lockfile pins dependencies):

```sh
pnpm install --frozen-lockfile
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

Inside this repository output goes to `data/examples/vector-target-lab`; in the unpacked standalone project it goes to `dist`. The ZIP includes a ready-to-open root viewer as well as rebuildable sources. `pnpm install --offline --frozen-lockfile` works when its packages are already cached. Initial developer dependency installation may need a network; using the finished viewer does not.

Browser QA requires Playwright and its Chromium, or `BROWSER_EXECUTABLE` pointing to Edge/Chrome:

```sh
node test/viewer.cjs
```

The reference CSV contains 294 path samples in 14 independent cases. Tests cover energy quadrature, first variations, surface constraints, normality, normal-ray projections, global lower bounds, pole geometry, zero momentum, negative multipliers, and misleading single-direction zeros. Browser tests check controls, picking, orbit, animation, actual canvas pixels, offline downloads, fallback and responsive layouts. Provenance records mathematical scope, generator and SHA-256 hashes. Licenses are in `LICENSE.txt`, `COPYING`, `THIRD-PARTY.txt` and `vendor/LICENSE.fmin`.

## Attach to CV07

After deployment, upload `computational-resources.json` to the filebox of article **1469 (CV07)** using the site's normal reviewed-resource attachment workflow. It selects the catalog ID `vector-target-lab`. The resource is then discoverable through native computational-resource search. This PR does not upload files or modify the production database.
