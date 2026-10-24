# The Sinusoidal Traveling Wave (WM07)

Companion to [Wave Mechanics: The Sinusoidal Traveling Wave](https://physicslibrary.org/encyclopedia/WaveMechanicsTheSinusoidalTravelingWave.html), WM07, article 1160. This resource keeps the article's kinematic scope: it is not a string-force model or a numerical PDE solver, and it does not turn WM08's speed derivation into the main lesson.

Open `index.html` directly. The viewer is offline, with no Julia runtime, web server, remote assets, microphone/audio access or server-side jobs. It includes the two worked examples, left/right propagation, equivalent sine/cosine forms, amplitude/phase and wavelength/frequency or k/omega inputs, a fixed-position probe, quarter-period steps, initial-profile comparison, and a synchronized space-time field. Numerical exports use SI units. Displacements on screen use centimeters, positions meters and time seconds.

## Interpretation

The wave is `u(x,t)=A cos(kx-d omega t+phi)` or its sine equivalent, with `d=+1` for rightward motion and `-1` for leftward. k and omega stay positive. Wavelength and ordinary frequency determine `k=2pi/lambda` and `omega=2pi f`. Either parameter notation updates the same state; changing notation alone changes nothing physical.

The snapshot varies x at fixed t. The time history varies t at the same fixed x0. The space-time field uses x horizontally and increasing time upward. Its horizontal cut is the snapshot, its vertical cut is the probe history, and their intersection is the same event in every plot. Clicking a plot selects the corresponding event/position; native sliders and number fields provide keyboard access.

The illustration is a transverse displacement: material markers keep their x coordinates and oscillate vertically. They do not surf the wave. Displacement and horizontal position use different scales, so the graph is not a same-scale picture of a physical string. A gold phase marker follows one crest, selected near x=1 m at t=0 whenever wave parameters change. Its integer phase branch is then fixed throughout playback. It can leave the displayed window and is never relabeled or wrapped to a neighboring crest. The phase diagram shows its true clipped trajectory. Its location changes by direction*lambda/4 for each quarter-period step.

Sine/cosine switching changes the phase convention, not the field: `cos(theta)=sin(theta+pi/2)`. Phase is wrapped to [-pi,pi); the equivalent branch keeps crest positions unchanged. Changing the phase slider instead changes the field. Changing phi does not reverse direction. A single-point record can be identical for opposite directions at particular phases, so it is not enough by itself to identify direction.

The fixed x and t windows are both [0,2] in their respective SI units, so changing wavelength or frequency visibly changes the number of cycles. Vertical snapshot/history scales are fixed at +/-6 cm; the field's diverging color scale is fixed at +/-5 cm. Amplitude changes are not hidden by auto-normalization. Playback speed scales elapsed physical time, not the wave parameters, and stops at t=2 s. The generated field exists for all times; the initial ghost is always t=0.

At A=0 there is no distinguished crest, observed phase, or smallest positive spatial/temporal period. Lambda, f and derived T remain nominal generator settings. Phase contributions can still be calculated formally, but do not identify an observable wave feature in the flat field.

## Worked Examples And References

Example 1: A=.030 m, lambda=.5 m, f=5 Hz, phi=pi/6, rightward cosine. Thus k=4pi rad/m, omega=10pi rad/s and T=.2 s.

Example 2: A=.020 m, lambda=2 m, f=1 Hz, phi=pi/3, x0=1 m and t=.25 s. The phase is 5pi/6 and the disturbance is -sqrt(3) cm. The UI preset reproduces that exact event, including its centimeter-to-meter conversion.

Julia independently evaluates complex exponentials with `cispi` for eight cases on a 17-by-21 space-time grid, producing 2856 samples. `events.csv` records eight preset/calibration events with phases and derived k, omega, lambda, T and f. JavaScript uses direct trigonometric evaluation, checked against those references. No time integration or wave-equation boundary conditions are implied.

## Reproduce

Julia 1.10.12, standard libraries only:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. sinusoidal-traveling-wave.jl
```

Node 22+, pnpm 11.25.0 and Python 3.11+:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

The source archive includes a ready-to-open viewer and rebuildable sources. In this repository publication goes to `data/examples/sinusoidal-traveling-wave`; outside it, to `dist`. Initial dependency installation may need a network; a cached installation can use `--offline`. The viewer never uses a network.

Optional browser QA needs Playwright (tested with 1.62.1): `node test/viewer.cjs`. Set `BROWSER_EXECUTABLE` for an existing compatible browser if needed. It checks presets, coordinate/phase and sine/cosine invariance, directions, fixed markers versus moving crests, controls, animation, fixed physical domains, CSV, no-JS fallback, canvas pixels and desktop/mobile layouts. Screenshots go to ignored `qa/`. Package checks cover hashes, manifest/catalog, links, licenses and archive contents.

## Attach To WM07

Deploy the static publication and catalog, then upload `computational-resources.json` to the existing **WM07 article's filebox, article 1160**. It selects `sinusoidal-traveling-wave`. Merge that ID with an existing manifest instead of replacing other resource IDs (maximum four). No database migration, production Julia installation, extra service or article rerender is required. The PR does not edit production attachments automatically.

Original software is GPLv3-or-later; explanation, figures and data are CC BY-SA 4.0. See COPYING, LICENSE.txt and the generated THIRD-PARTY.txt.
