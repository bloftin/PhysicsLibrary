# Gradient Lab

An attachable Physics Library computational resource for the gradient of a smooth two-dimensional scalar field. The offline viewer links a rotatable 3D graph of `f(x,y)`, an interactive contour map, a directional section with its tangent, and directional derivative versus angle.

## Mathematics

`gradient(f) = (df/dx, df/dy)` and `D_u f = gradient(f) dot u`, where `u=(cos(theta),sin(theta))` is a unit vector. The largest directional derivative is the gradient magnitude, attained along the gradient. A perpendicular direction is tangent to a *regular* level set and has zero directional derivative. A zero gradient alone does not classify an extremum: the saddle and double well supply counterexamples.

Six reviewed fields: tilted plane `a*(x+b*y)`; elliptic bowl `a*(x^2+b*y^2)/2`; saddle `a*(x^2-b*y^2)/2`; Gaussian hill `a*exp(-b*(x^2+y^2))`; waves `a*sin(b*x)*cos(b*y)`; double well `a*(x^4/4-x^2/2+b*y^2/2)`. Amplitude `a` and shape `b` lie in `[0.25,2]`, and the coordinate domain is `[-2.5,2.5]^2`. All coordinates and field values are dimensionless, with Euclidean Cartesian coordinates. This is not a potential/force or temperature/heat-flow simulation.

The browser uses the established [mathjs symbolic differentiation API](https://mathjs.org/docs/reference/functions/derivative.html) to compile partial derivatives of fixed catalog expressions. There is no user-supplied expression evaluation. Julia independently evaluates explicit analytic derivatives; finite-difference tests provide a further check. Saved references contain 2,178 points spanning all six fields, three parameter sets, and an 11-by-11 grid including the origin.

Arrows show **normalized directions**, not a linear encoding of gradient magnitude. At a gradient magnitude below `1e-7`, the gradient-direction arrow and alignment controls disappear/disable, and the point is reported as stationary within tolerance. No maximum/minimum claim follows from that status. Numerical readouts and CSV preserve the actual components and magnitudes.

For framing, the 3D graph's vertical display coordinate is scaled uniformly for each field/shape at maximum amplitude 2; the multiplier is displayed. Changing amplitude therefore changes surface height without reframing it. The red surface arrow is the lifted ascent tangent `(fx, heightScale*|gradient|^2, fy)`, not a fictitious three-component gradient. The yellow surface arrow is the direction tangent `(ux, heightScale*D_u f, uy)`. World coordinates map mathematical `y` to negative Three.js `z`. The numerical gradient and slopes remain unscaled. The tangent patch is a local linear approximation, not another scalar-field surface. The map retains equal x/y scale; D3 contours are sampled approximations, not exact symbolic level sets. Contours at the sampled range endpoints are not highlighted as regular level sets.

## Interaction

Drag or click the contour map, use its arrow keys, enter probe coordinates, or click the 3D surface to place the point. Orbit the 3D scene independently of the probe. Change amplitude/shape and direction, align with the gradient, or select a level-set tangent. The tangent section and direction-slope plots update with the point and chosen direction. CSV export contains a 65-by-65 field/gradient grid evaluated at the current parameters and direction.

Ascent/descent steps use a **normalized gradient with Armijo backtracking**, not a time-dependent physical trajectory or a solver for gradient flow. Initial step length is `0.16`; sufficient-increase/decrease fraction is `0.1`, and backtracking halves the step. Steps preserve monotonic field change, stay within the domain, and stop at a stationary tolerance, domain boundary, small-step tolerance, or 400-step limit. A stationary starting point can stay at a saddle. The trail shows the accepted finite steps. WebGL failure leaves the contour map, parameters, calculations, steps, plots, and CSV functional.

## Reproduce

Julia **1.11.2** with standard libraries generated the reference. Node 22+ and pnpm 11.25.0 built the bundled viewer. Environments, source, reference CSV, and full dependency licenses are included.

```sh
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. gradient-lab.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm build
python build.py
python test/package_test.py
```

The ZIP includes ready-to-open `index.html`, CSS, and `viewer.js`, and requires no server or CDN. Outside the repository, rebuilding writes `dist/`. The provenance records reference/source/environment/bundle SHA-256 hashes. Browser QA: `node test/viewer.cjs` with Playwright installed; set `BROWSER_EXECUTABLE` for a system Chromium/Edge. Tests check actual surface pixels, surface picking, contour dragging, keyboard movement, direction alignment, steps, toggles, camera, CSV, responsive layout, no runtime network requests, and disabled-WebGL fallback. Screenshots go to ignored `qa/`.

## Attach

After deploying the static assets and resource catalog, upload `computational-resources.json` into the intended gradient article's filebox. It selects `gradient-lab`. If an article already has a manifest, merge this resource ID into its existing `resources` array (maximum four), retaining `schema_version: 1`. The resource is article-agnostic; this PR does not choose an article ID or modify production attachments.

The publication lives in `data/examples/gradient-lab/`, served by the existing static image origin. No database migration, Julia runtime on the server, new service, or article rerender is needed. A follow-on could treat physical gradients explicitly, for example `E=-gradient(V)` or Fourier heat flow.
