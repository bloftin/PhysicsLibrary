# Sinusoidal Oscillation (WM02)

Companion to [Wave Mechanics: Sinusoidal Oscillation](https://physicslibrary.org/encyclopedia/WM02.html), WM02, article 1150. This is a prescribed time history at one point, not a force-based oscillator or spatial wave simulation.

Open the published `data/examples/sinusoidal-oscillation/index.html` directly, or `index.html` at the root of the downloaded ZIP. The bundled viewer needs no server, Julia installation, remote assets or audio permissions. It includes both worked examples, quarter-period steps, phase/projection and displacement views, f/T/omega entry, sine/cosine equivalence, radius/arc visualization, selectable cm/mm units, optional doubled-frequency or zero-phase comparison, a quarter-cycle event table, and SI CSV export.

## Interpretation And Scope

The model is `u(t)=A cos(omega*t+phi)` (or sine), with positive `omega=2pi*f` and `T=1/f`. Amplitude is in meters internally. Display units do not alter any physical parameter. Rate-entry mode changes notation only; editing its numeric value changes the shared frequency.

The circle is a geometric phase reference, not a particle orbit. Its arrow rotates counterclockwise from +x. Cosine uses the horizontal projection; sine uses the vertical projection. The coral bead moves along an independent fixed +/-5 cm displacement scale, which matches the history scale (+/-50 mm in millimeter mode). The reference radius is in geometric centimeters and is independent of the oscillator amplitude. Changing it changes arc length, not phase or motion.

The gold arc uses `alpha=theta modulo 2pi` in [0,2pi). The total phase readout retains complete turns; the elapsed-cycle count ft starts at t=0, independent of phi. The arc's s/r equals alpha. A full circumference corresponds to 2pi radians; the arc returns to zero when its orientation completes a turn. A reference with a larger radius has a proportionally longer arc for the same angle.

Changing phi changes the physical time history relative to t=0. Switching trigonometric convention instead adjusts phi by +/-pi/2, wrapped into [-pi,pi), preserving displacement and its time slope. The circle arrow turns by 90 degrees and the selected projection axis changes together, so the projected number and physical bead remain unchanged. A sine's numeric phi=0 is not the same motion as a cosine's phi=0. The zero-phase comparison always means the physical zero-phase cosine, independent of the selected convention.

The derivative is used only to label rising, falling and turning points, and appears in SI CSV. No acceleration, force law, energy model or differential-equation integration is claimed. Opposite phases +/-pi/2 illustrate the same equilibrium displacement with opposite directions. Quarter-cycle table events are relative to t=0, not a phase-rebased maximum; at nonzero initial phase their values need not be +A,0,-A,0,+A.

The history domain is always [0,4] seconds, its vertical range stays +/-5 cm, and the bead scale does not normalize to amplitude. The doubled-frequency comparison shares A, phi and form and can reach 8 Hz. Playback speed changes the displayed clock speed, not the physical rate. Playback stops at 4 s. Selecting a history point, slider or landmark stops playback. A hidden page also pauses.

At A=0, the signal is constant: no observable phase, crest or smallest positive period exists. Positive frequency/period settings and the rotating reference remain nominal. The projection u/A is explicitly undefined, and its red circle marker is hidden. The bead stays at equilibrium.

## Article Examples

1. A=4 cm, f=2 Hz, phi=0, cosine: omega=4pi rad/s and T=.5 s. The five quarter-cycle values are +4,0,-4,0,+4 cm.
2. A=6 mm, T=.4 s, phi=pi/2, cosine: f=2.5 Hz and omega=5pi rad/s. At t=0, u=0 and the quantity is falling. The preset uses mm without changing the underlying SI amplitude .006 m.

Julia independently uses the real/imaginary parts of `cispi` to generate 1,449 reference samples (nine cases, 161 times) plus nine worked/calibration events. The browser directly evaluates sine and cosine. No numerical time integration is involved.

## Reproduce

Julia 1.10.12, standard libraries only:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. sinusoidal-oscillation.jl
```

Node 22+, pnpm 11.25.0 and Python 3.11+:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

The ZIP includes a ready-to-open viewer and rebuildable source. Publication in this repository goes to `data/examples/sinusoidal-oscillation`, otherwise to `dist`. Dependency installation may need a network; a cached install can use `--offline`. The viewer makes no network requests. Optional `node test/viewer.cjs` uses Playwright (tested with 1.62.1); set `BROWSER_EXECUTABLE` for an existing browser if needed. Ignored screenshots go to `qa/`.

## Attach To WM02

Deploy the static publication and updated catalog, then upload `computational-resources.json` to the existing **WM02 filebox, article 1150**. It selects `sinusoidal-oscillation`. Merge this ID into an existing manifest instead of replacing its other resource IDs (maximum four). No database migration, production Julia runtime, new service or article rerender is needed. This PR does not upload production attachments automatically.

Original software is GPLv3-or-later. Explanation, figures and data are CC BY-SA 4.0. See COPYING, LICENSE.txt and the generated THIRD-PARTY.txt.
