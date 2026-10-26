# Inner Product Lab (FS02)

Companion to [Inner Products of Functions](https://physicslibrary.org/encyclopedia/InnerProductsOfFunctions.html), FS02, article 1519. The vector and function modes bridge ordinary dot products and function-space geometry. A matrix mode extends the idea to objects without a literal physical arrow or function-graph interpretation.

Open the published `data/examples/inner-product-lab/index.html`, or `index.html` at the root of the downloaded source ZIP. The viewer is bundled offline, with no Julia runtime, server, remote requests or audio permissions. Software is GPLv3-or-later; explanations, figures and data are CC BY-SA 4.0. See COPYING, LICENSE.txt and generated THIRD-PARTY.txt.

## Three Spaces, One Projection

- Vectors: real R2, Euclidean dot product. Edit components or drag either tip. The spatial axes have equal scale.
- Functions: real polynomials `u0+u1*x+u2*x^2+u3*x^3`, on [-1,1], [0,1] or [0,2]. Inner products integrate their polynomial product with the selected weight analytically, using closed-form monomial moments. No free-form expression parser or numerical integration is needed for this finite subspace.
- Matrices: real 2x2 matrices, Frobenius inner product `trace(A'B)=sum(A_ij*B_ij)`. Coordinates are matrix entries, not physical positions. Projecting onto I gives `trace(A)/2 * I`; the residual is trace-free. A symmetric/skew-symmetric pair illustrates cancellation and orthogonality in this abstract space.

For nonzero v, `c*=inner(u,v)/inner(v,v)` minimizes `E(c)=norm(u-c*v)^2`. The same operation applies in all three spaces. The trial coefficient is independent of the optimal coefficient when the optimum checkbox is off. The residual has zero inner product with v at the minimum. Pythagoras applies there; the general identity includes the cross term `2c*inner(r,v)` away from the minimum. Normalizing v rescales the coefficient but preserves both its span and the current projection object (the manual coefficient is adjusted too).

The shared abstract span diagram is an isometric coordinate representation: v lies along a horizontal unit basis direction, u has coordinate `inner(u,v)/norm(v)` there, and its remaining nonnegative coordinate is the perpendicular norm. This is not a claim about function-graph crossing angles or the physical angle of matrix tiles. Reflection in the target axis gives the same inner-product geometry. Function and error plot limits adapt to values and are visibly ticked. Matrix tiles share one signed color scale across u, v, cv and r; colors are not independently normalized.

All objects and measures in this lab are real and dimensionless. Physical function inner products can carry units; complex spaces require conjugation. This is a one-direction projection lab, not a multi-basis Fourier solver.

## Function Weights And Sampling

Weights are 1, `2(x-a)/(b-a)`, or `1+x^2`. The ramp is positive in the interior and zero only at the left endpoint. It therefore defines a positive-definite inner product on continuous polynomials. On [0,1] it reproduces the article's `w=2x` weighted example. General L2 spaces identify functions equal almost everywhere; for these polynomials zero norm means the zero polynomial.

The signed product view can display u*v or residual*v. Its filled curve is the integrand, not the scalar inner product. Midpoint rectangles include the measure `w(x_i)*dx`; their sum is an explicitly separate approximation. Changing N changes only that approximation, not the analytic coefficient or residual test. The positive/negative sums in function mode refer to sampled contributions. Even when the exact residual integral is zero, a finite sample sum can have a small nonzero error.

The corresponding sampled vectors would be `sqrt(w_i*dx)*u_i` and `sqrt(w_i*dx)*v_i`. Their ordinary dot product is precisely the midpoint sum. Omitting dx does not approximate the same integral as the sampling density changes.

Presets include x^2 onto 1 (c*=1/3), x^3 onto x (c*=3/5), the norm of x (sqrt(2/3)), cancellation of 1 and x on [-1,1], the changed interval [0,1], and weighted x onto 1 on [0,1] (c*=2/3 rather than 1/2).

## Zero Cases And Precision

The zero target cannot be normalized. The angle is undefined if either object is zero. If v=0, the projected object is zero but the coefficient is non-unique: all coefficients give the same error. No zero-norm division is used. Entries must be finite with absolute value at most 100; manual coefficients are finite and at most 1e8 in magnitude. These bounds are safeguards, not mathematical limits of inner-product spaces.

Julia 1.10.12 independently computes exact rational finite sums and polynomial moments for 17 cases, covering 153 trial-coefficient results and 520 function samples. Values are exported with 17 significant digits. JavaScript uses floating-point arithmetic and direct polynomial evaluation. Screen readouts suppress magnitudes below 1e-10; numeric fields display five or six significant digits, and the residual status uses a scaled numerical tolerance. Display formatting does not change the stored values; CSV retains the underlying floating-point precision. No numerical ODE solver, animation loop or backend computation is involved.

## Reproduce

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. inner-product-lab.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

The environment pins Julia 1.10.12 (Printf/Test standard libraries), D3 7.9.0, Lucide 0.468.0 and esbuild 0.25.10. Frontend build uses Node 22+, pnpm 11.25.0 and Python 3.11+. Initial dependency installation may need a network; cached installation can use `--offline`. Publication goes to `data/examples/inner-product-lab` in the repo and `dist` outside it. The ZIP includes a ready-to-open viewer as well as rebuildable sources.

Optional browser QA: `node test/viewer.cjs` with Playwright (tested with 1.62.1). Set `BROWSER_EXECUTABLE` for an existing compatible browser if needed. Ignored screenshots go to `qa/`. Tests cover actual canvas pixels, controls, dragging, singular cases, analytic/sample separation, exports, desktop/mobile layouts, offline requests and no-JS fallback.

## Attach To FS02

Deploy the static publication and updated `etc/computational-resources.json`, then upload this folder's `computational-resources.json` to the existing **FS02 article filebox, article 1519**. It selects `inner-product-lab`. Merge this ID with existing resource IDs instead of replacing them (maximum four). No database migration, production Julia installation, extra service or article rerender is needed. The PR does not edit production attachments automatically.
