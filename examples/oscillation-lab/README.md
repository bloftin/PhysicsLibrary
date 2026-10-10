# Oscillation Lab

Companion to [Oscillation](https://physicslibrary.org/encyclopedia/Oscillation.html), article **1288**. The first screen is an offline spring-mass experiment, with displacement, phase portrait, and energy/work curves. All calculations run locally; no Julia runtime or server-side job is needed to use the viewer.

## Model

`m*x'' + c*x' + k*x = F0*cos(omega_d*t + phase)` with `c = 2*zeta*sqrt(m*k)`.
Harmonic mode sets `c=F0=0`; damped mode sets `F0=0`; driven mode retains both. Displacement is measured from equilibrium, so a constant gravitational offset is already removed. Inputs and plots use SI units; drive phase is entered in degrees.

The browser uses the established [mathjs matrix-exponential implementation](https://mathjs.org/docs/reference/functions/expm.html), not a custom ODE integrator. The four-state vector is `(x,v,cos,sin)`. Its 16 quadratic products plus accumulated dissipated heat `Q` and applied-force work `W` form a 22-state linear system. One matrix exponential advances each uniform sample. Thus work and heat are integrated by the same transition, rather than by separate numerical quadrature. Julia's `LinearAlgebra.exp` independently constructs the lift using column-major Kronecker products and evaluates each reference time directly.

`K=m*v^2/2`, `U=k*x^2/2`, `E=K+U`; `Q'=c*v^2` and `W'=F*v`. The invariant `E+Q-W=E(0)` is tested and displayed. Negative drive work is permitted. The phase portrait uses velocity, not momentum.

Eight presets cover free release, initial velocity, weak damping, critical and overdamped return, damped resonance, undamped resonance, and a driven transient. Critical and overdamped free motion are not periodic oscillations. The displayed natural period always refers to the *undamped* oscillator. Undamped exact resonance has no bounded steady-state amplitude; a nonresonant undamped particular solution does not imply that transients decay.

The scene uses a trajectory-wide fixed displacement scale so growing resonant motion stays visible; its spring is a schematic, not a geometrically accurate material model. Numerical displacement is never clamped. Time is sampled at 1,201 points across the selected number of natural periods. Scrubbing and animation use those samples and stop at the end. Very small position values are rounded only in readouts, not in exported data. WebGL failure leaves the calculations, plots, and CSV export available.

Assumptions: one degree of freedom, a linear massless spring, viscous damping, and a prescribed sinusoidal force. No nonlinear pendulum, Coulomb friction, self-excitation, coupled modes, or parameter fitting. A nonlinear pendulum and amplitude-dependent period would be the next companion resource.

## Reproduce

The checked-in reference was generated with **Julia 1.11.2** using only standard libraries. The environment and dependency lockfiles are included.

```sh
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. oscillation-lab.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm build
python build.py
python test/package_test.py
```

Node 22+ and pnpm 11.25.0 were used for the viewer build. The archive includes ready-to-open `index.html`, CSS, and `viewer.js`; rebuilding outside the repository publishes into `dist/`. Open the HTML directly. No dev server, CDN, or runtime network request is necessary. `THIRD-PARTY.txt` contains licenses for bundled dependencies. `provenance.toml` records source, environment, reference, and bundle SHA-256 hashes.

Browser checks: install Playwright in your test environment, then run `node test/viewer.cjs`. Set `BROWSER_EXECUTABLE` if using an installed Chromium/Edge instead of Playwright's Chromium. Tests cover desktop/mobile layouts, real canvas pixels, animation, camera reset, presets, inputs, CSV export, offline loading, and a disabled-WebGL fallback. Screenshots go to ignored `qa/`.

## Attach to Article 1288

After this PR is deployed, upload the included `computational-resources.json` into the Oscillation article's filebox. It selects the reviewed catalog resource `oscillation-lab`. If a manifest already exists, merge this ID into its `resources` array instead of replacing other resources (maximum four). Keep `schema_version: 1`. The existing mass-spring example article is a separate related entry and is not modified.

The website serves the publication from `data/examples/oscillation-lab/` through the configured static image origin. No database migration, extra service, Julia installation on the production server, or article rerender is required. The manifest is read when the entry is viewed. This PR does not upload attachments or alter production articles.
