# Constrained Variations Lab

Companion to [CV09: Constrained Variations and Isoperimetric Problems](https://physicslibrary.org/encyclopedia/CalculusOfVariationsConstrainedVariationsAndIsoperimetricProblems.html), **article 1207**. The offline lab connects two-coefficient constraint geometry to actual endpoint-preserving functions and first-variation densities. The user's supplied parallel-gradient screenshot informed the visual comparison; the linked [video](https://www.youtube.com/watch?v=JA1lY5jSW-4) could not be retrieved and is not embedded or represented as having been reviewed. No video graphics or code are reused.

## Normals, Not Tangents

The convention matches the article: `J + lambda*(K-k0)`. Stationarity requires `delta J + lambda*delta K = 0` for every endpoint-preserving variation. In coefficient coordinates this is `grad J = -lambda*grad K`. A convention using `J-mu*K` instead has `mu=-lambda`. Blue is `grad J`; amber is `-lambda*grad K`. Their arrow lengths use **one common displayed scale**, never independent normalization, so changing the multiplier can match or mismatch both direction and length. A zero objective gradient is handled without inventing a direction.

The admissible first-order directions are tangent to `K=k0`; the functional gradients are normal. Green indicates a unit **coefficient-space** tangent `t`, drawn as a fixed-length direction marker separately from the normal-arrow scale. The function `eta=t_a*phi_0+t_b*phi_1` is its endpoint-preserving variation. Both first-variation pairings `delta K[eta]=0` and `delta J[eta]` are displayed. Fitting the normal component chooses `lambda=-(grad J dot grad K)/|grad K|^2`; away from stationarity this cannot cancel the tangent component.

The upper geometry uses Euclidean coefficient gradients (coordinate covectors identified with vectors). The lower density panel is the **L2 first-variation representation**, with integration by parts and fixed endpoints. These are different representations: the polynomial basis is not orthonormal, so coefficient vectors must not be interpreted as samples of the functional gradient. The common multiplier is consistent in both representations. The displayed L2 residual norm tests `gJ+lambda*gK`, not merely the two-coordinate residual.

## Fixed Mean

On `[0,1]`, take `phi_0=6x(1-x)` and `phi_1=6x(1-x)(2x-1)`, with `y=a*phi_0+b*phi_1`. Both basis functions vanish at the endpoints; their integrals are 1 and 0.

`J=1/2 integral(y'^2 dx)=6a^2+(18/5)b^2`; `K=integral(y dx)=a`. The exactly feasible family is the line `a=m`. Thus `grad J=(12a,36b/5)`, `grad K=(1,0)`, and `t=(0,1)`.

The first-variation densities are `gJ=-y''=12a+36b(2x-1)` and `gK=1`. The norm of their residual is `sqrt((12a+lambda)^2+432b^2)`. At `b=0` and `lambda=-12m`, both densities agree after scaling, the residual vanishes for all x, and `y*=6m*x*(1-x)`. The energy gap within the slice is `(18/5)b^2`. This curve is also the unique global minimizer in the full fixed-mean admissible class, not just in this slice: integration by parts gives `J[y*+u]-J[y*]=1/2 integral(u'^2)` for every fixed-endpoint zero-mean `u`.

## Normalization

On `[0,pi]`, take the orthonormal basis `phi_0=sqrt(2/pi)*sin x`, `phi_1=sqrt(2/pi)*sin 2x`, and `y=a*phi_0+b*phi_1`. Now `J=integral(y'^2)=a^2+4b^2`, `K=integral(y^2)=a^2+b^2=k0`. The exactly feasible family is a circle of radius `sqrt(k0)`, parametrized by its mixture angle. The tangent is `(-b,a)/sqrt(k0)`.

Here `gJ=-2y''=2a*phi_0+8b*phi_1`, `gK=2y`, and the residual norm is `2*sqrt((1+lambda)^2*a^2+(4+lambda)^2*b^2)`. Pure first modes have `lambda=-1` and `J=k0`, the full-space global minimum. Pure second modes have `lambda=-4` and `J=4k0`: they are stationary, and maximize J only on the displayed two-mode circle. They are **not** maxima in the full function space; higher modes make J arbitrarily large at fixed normalization.

The scan stays exactly on the constraint. The green tangent is a first-order direction, not a finite straight feasible path: `K[y+epsilon*eta]=k0+epsilon^2` here. Exact feasibility requires the circular family with its higher-order correction. All constraints used are normal: `grad K` never vanishes in the chosen domain (`k0>=0.25`). The lab does not demonstrate abnormal extremals, arbitrary bases, multiple constraints, or area at fixed arc length.

## Controls and Reproduction

Drag/click or use arrow keys on the coefficient map to move within the feasible family; clicking the 3D surface projects onto that family. Change mean/shape or normalization/mixture, and vary lambda independently. The fit button cancels only the normal component. The minimizer and second-mode commands set the exact stationary curve and its multiplier. Playback scans the family, not physical time or a minimization algorithm. The lower panels show `y` and `eta`, `gJ` versus `-lambda*gK`, and J along the constraint. CSV exports actual curve/density samples and parameter metadata. WebGL failure leaves the map, controls, function plots and CSV functional.

Julia **1.11.2** with standard libraries independently generated 574 saved rows across 14 cases. Tests verify analytic functionals and pairings by numerical quadrature. The browser uses mathjs symbolic differentiation of fixed objective/constraint polynomials, not arbitrary user expressions. Node 22+ and pnpm 11.25.0 build the viewer. D3 generates contours/plots; Three.js renders the procedural surface and constraint. All coordinates/quantities are dimensionless. The upper surface shows J with a fixed per-problem height multiplier; lower curves/densities are unscaled. Sampled contours are approximations.

```sh
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. constrained-variations.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm build
python build.py
python test/package_test.py
```

The archive contains ready-to-open `index.html`, source, environments, license texts, reference data, and SHA-256 provenance. It works offline without a web server; rebuilding outside the repository writes `dist/`. Browser QA uses Playwright: `node test/viewer.cjs` (`BROWSER_EXECUTABLE` may select an installed Chromium/Edge). Screenshots go to ignored `qa/`.

## Attach to CV09

After deployment, upload `computational-resources.json` to **article 1207's filebox**. Merge `constrained-variations` into any existing manifest's `resources` list rather than replacing other resources (maximum four, schema version 1). Static assets live in `data/examples/constrained-variations/`. This PR does not alter production articles, attachments, or the database. No new service, server-side Julia, or article rerender is required.
