# Oscillation at One Point (WM01)

Companion to [WM01](https://physicslibrary.org/encyclopedia/OscillationAtOnePoint.html), article **1148**. This resource is separate from the broader spring-mass `oscillation-lab` attached to article 1288. It deliberately stays with displacement, equilibrium, amplitude, distance, cycles, period and frequency. No traveling-wave, angular-frequency or phase parameters are introduced.

Open the published or unpacked `index.html` directly. The viewer works offline without a web server, Julia runtime, remote assets or server-side computation. Julia supplies reproducible independent reference calculations; the browser evaluates the prescribed records locally.

## Model And Interpretation

The physical coordinate is A times a normalized periodic shape. Every record begins at equilibrium, moving in the initial positive physical direction. The displayed coordinate is that physical value multiplied by the chosen axis sign. Axis reversal changes signed displacement and velocity but not the physical trajectory, elapsed time or distance.

Three records show that periodic motion need not yet be a sinusoid:
- Rounded: cubic Hermite interpolation through values (0,1,0,-1,0), at cycle fractions (0,.25,.5,.75,1), with derivatives (6,0,-6,0,6) per cycle.
- Uneven timing: the same values at (0,.15,.5,.65,1), derivatives (4,0,-4,0,4). The trace and its first derivative are continuous, including at the periodic join.
- Triangle: piecewise linear through the rounded record's knots. Its derivative is undefined at the sharp extrema, not zero. Exported undefined velocities are empty and identified by `velocity_defined=0`.

These are prescribed kinematic records, not Hookean spring solutions or a force-derived dynamics engine. The rounded trace uses polynomials rather than introducing WM02's sinusoidal equation. A straight physical axis is shown separately from the displacement-versus-time graph; nothing propagates through a spatial medium.

Each monotone leg has total variation A. Distance from t=0 is 4A for each whole cycle, plus completed legs and the absolute displacement change on the active leg. This is exact, not sampled quadrature. Returning to u=0 after half a period gives distance 2A and opposite velocity; a full cycle restores the original velocity and covers 4A. Turning points and equilibrium crossings are not interchangeable.

The equal-displacement comparison restricts u*/A to [-.9,.9], keeping both probes away from extrema. Browser roots use the unmodified BSD-3-Clause [fmin bisection](https://github.com/benfred/fmin/blob/6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b/src/bisect.js), pinned at commit `6b155c9f4a6ecf73ea5d71666da8e5dcd418b18b`. Julia independently evaluates the Hermite basis and uses safeguarded Newton. One-sided rate ambiguity is never presented as a smooth triangle velocity.

T is the fundamental period for each nonconstant displayed shape, f=1/T, and both records in the frequency panel use a physical one-second window. The panel separates elapsed cycle fractions from the integer number of completed cycles. Initial equilibrium at t=0 is not counted as a crossing. At A=0 the record is constant: it repeats after every positive interval, so no smallest positive period or observed frequency can be inferred. T and f controls then remain nominal generator settings only.

Amplitude is stored in meters. Display units m, cm and mm convert without changing the motion; all downloaded values use SI units. Amplitude ranges 0 to .05 m, period .05 to 4 s, and comparison frequency .25 to 20 Hz. Playback changes the clock rate, not the physical T or f; it stops after three nominal periods. Rate readouts are actual derivatives, not motion-arrow lengths; the arrow only indicates direction. The physical axis has a fixed scale so changing A visibly changes the excursion.

## Reproduce

Julia 1.11.2, standard libraries only:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. one-point-oscillation.jl
```

Node 22+ and pnpm 11.25.0:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

The archive contains a ready-to-open viewer and rebuildable sources. Builds publish to `data/examples/one-point-oscillation` in this repository, or `dist` outside it. Initial developer dependency installation may need a network; cached packages support `pnpm install --offline --frozen-lockfile --ignore-scripts`. The finished viewer never needs a network.

Browser QA uses Playwright, with `BROWSER_EXECUTABLE` pointing to Chromium/Edge when not using Playwright's bundled browser: `node test/viewer.cjs`. Screenshots go to ignored `qa/`. Tests cover canvas pixels, physical-coordinate preservation under sign/unit changes, controls, shape/preset selection, comparisons, animation, clock bounds, CSV, no-JavaScript messaging and 1440/1024/768/390/320px layouts. The numerical suite checks 3612 independent Julia path samples and 12 crossing cases, total variation, derivative agreement, exact timing, degenerate motion and triangle corners.

## Attach To WM01

After deployment, upload `computational-resources.json` to **WM01's filebox, article 1148**. It selects the catalog ID `one-point-oscillation`. If a manifest exists, merge the ID into its `resources` array rather than replacing other resources (maximum four). Keep `schema_version: 1`. The resource then participates in the existing computational-resource search.

No database migration, extra service, production Julia installation or article rerender is needed. This PR does not upload the attachment or change the production article. Original code is GPLv3 or later; original explanation/data are CC BY-SA 4.0. See `COPYING`, `LICENSE.txt`, `THIRD-PARTY.txt` and `vendor/LICENSE.fmin`. Provenance includes source, environment, reference and bundle hashes.
