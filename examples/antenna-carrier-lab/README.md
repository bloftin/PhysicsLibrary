# Antenna, Charges & Energy Lab

An offline Julia-verified companion to the Physics Library antenna/radiation series. Suggested attachment: [Radiation from Time-Varying Currents and the Hertzian Dipole](https://physicslibrary.org/encyclopedia/ElectromagneticWavesAntennasAndRFRadiationFromTimeVaryingCurrentsAndTheHertzianDipole.html), article **1449**. It can also be attached to another relevant article by merging its manifest IDs.

Open `data/examples/antenna-carrier-lab/index.html`, or the ZIP's root `index.html`. No local server, production Julia, remote assets or computation service. Ready-built viewer, Julia source, pinned environments, tests, reference CSVs, licenses and provenance are included.

## What To Explore

Receive mode connects a linearly polarized incident field to collective carrier motion, feed current, arm-charge accumulation and power in a receiver load. Change arrival direction/polarization, frequency, length, loss, load or tuning. The tune-and-match command cancels reactance at the operating frequency and sets load resistance to total antenna resistance. Transmit mode replaces the incident equivalent EMF with a generator and its resistance. Nine presets include aligned/crossed/oblique/axial arrival, detuning, no coil, lossless matching, transmit and zero drive.

The close-up separates fixed lattice markers, mobile electrons, conventional current and incremental positive/negative arm charge. Motion is **greatly exaggerated** with adaptive gain printed beside actual drift/excursion values. Markers never wrap, leave the wire or travel to a remote receiver. The separate wave view shows E/B and energy propagation. Camera orbit/reset/front views change inspection only, not the physical model.

## Model And Sign Conventions

Total wire length L=0.1-1.4 m, f=1-20 MHz: L/lambda <0.1 over every allowed combination. Use the prescribed short center-fed distribution `I(z)=Ifeed*(1-2|z|/L)`, effective length `h=L/2`, not the uniform-current Hertzian h=L. `eta=1/(epsilon0*c)`, `Rrad=eta*k^2*h^2/(6*pi)`. This is approximately 20*pi^2*(L/lambda)^2, with the exact expression retaining internal consistency of constants and far-field power.

Incident propagation `n=(sin(theta),0,cos(theta))`, electric polarization `e=(-cos(theta)*cos(psi),sin(psi),sin(theta)*cos(psi))`; n dot e=0. The equivalent **loop EMF** is `Vdrive=E0*h*sin(theta)*cos(psi)`, with sign chosen for positive axial current in the driven mode. This is not a claim that the loaded terminal voltage equals E0*h. The receive-load voltage is I*Rload; peak/RMS conventions never mix.

Illustrative antenna capacitance C=10 pF; optional external series L=1/((2*pi*f0)^2*C). Ohmic loss is prescribed, not calculated from geometry/material. `X=omega*L-1/(omega*C)`, `Iphasor=Vdrive/(Rrad+Rloss+Rtermination+jX)`, with peak phasors exp(+j*omega*t). Rtermination is the receive load or transmitter generator resistance. All responses are sinusoidal steady state; changing a control does not integrate switch-on transients. The series LC model is pedagogical, not a broadband solved antenna impedance.

`q_upper=Re[(Iphasor/(j*omega))*exp(j*omega*t)]`; q_lower=-q_upper, so total added charge remains zero and dq_upper/dt=Ifeed. Continuity gives incremental line charge +/-2q/L on the arms. Actual conductor surface charge is more complicated. This is only the feed-associated current/charge mode, **not all open-circuit polarization or structural scattering**.

Assumed carrier density n=8.5e28 m^-3 and effective conducting area A=1e-6 m^2 are fixed illustrative inputs: `u_center=-q/(n*e*A)`, `v_center=-I/(n*e*A)`. Apply the same triangular spatial factor. These are collective mean drift quantities, not ballistic individual trajectories. No RF skin depth/current penetration is predicted. The close-up scale factor is .11*L/(2.4*excursion), exactly matching the 2.4-unit schematic wire length; comparisons must use physical readouts rather than adaptive animation travel.

## Fields And Energy

The incoming plane wave uses E=E0*e*cos(omega*t-k*n dot r), B=n cross E/c and S=E cross B/mu0. The close-up incident-drive cue is not the solved total electric field inside a conductor.

Outgoing radiation uses `Etheta=Re[j*eta*k*h*Iphasor*sin(theta)/(4*pi*r)*exp(j*(omega*t-kr))]`, `Bphi=Etheta/c`. Plot only r/lambda from 2 to 4 in quarter-wavelength steps; no far-field formula is extended into the reactive near zone. Retardation and inverse-radius amplitude are retained. E and cB arrows have a shared scale normalized to broadside field peak at 3 wavelengths. The receive wave view is normalized to incident E0. Antenna close-up, wave coordinates and the angular sin^2(theta) power pattern are deliberately separate scales.

Cycle-average input power splits as `|I|^2*(Rtermination+Rloss+Rrad)/2`. Receive labels Rrad as current-associated **re-radiation**, not absorption by the load or heat. Transmit also includes generator-resistance loss, separate from antenna radiation efficiency. Radiation resistance is an average-power equivalent: `Rrad*I(t)^2` is **not** presented as instantaneous radiated flux at every radius. Equivalent LC stored energy is not total near-field energy.

Available matched receive power is `Voc_peak^2/(8*Ra)`, incident average flux E0^2/(2*eta), effective aperture `eta*h^2*sin^2(theta)*cos^2(psi)/(4*Ra)`. Tests verify its equality to `lambda^2*G/(4*pi)` including polarization/arrival factors, and the lossless conjugate-matched equality of load and re-radiated average power. Far-field intensity integrates to the same radiated power used by the circuit.

Scientific reference: [MIT 6.013 chapter 10](https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/MIT6_013S09_chap10.pdf), sections 10.2-10.3. Graphics/code are original. Assumptions exclude full-wave conductor boundaries, feed radiation, material dynamics, mutual coupling, modulation, arrays and structural scattering.

## Reproduction And Verification

Julia 1.10.12 independently calculates 256-bit BigFloat complex-phasor references: **1161** two-cycle samples and **9** operating points, CSV rounded to 17 significant digits. Standard libraries only. Node tests cover phasors, local charge continuity, opposite drift, projection/sign/scaling, circuit energy balance, matching, aperture reciprocity, E/B geometry, far-field retardation and angular power integration.

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. antenna-carrier-lab.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

Node22+, pnpm11.25.0, Python3.11+. Three.js0.180.0, D3 7.9.0, Lucide0.468.0, esbuild0.25.10 pinned. Cached installs can use --offline. Publication targets `data/examples/antenna-carrier-lab` in-repo or `dist` outside it. Optional `node test/viewer.cjs` uses Playwright and BROWSER_EXECUTABLE; ignored screenshots go to qa. No-JS leaves the guide/data available; WebGL failure leaves numerical controls/charts usable.

## Deployment

Deploy `data/examples/antenna-carrier-lab` and updated `etc/computational-resources.json`. Upload/merge this source folder's `computational-resources.json` into article **1449**'s filebox, preserving other IDs (maximum four). The manifest selects `antenna-carrier-lab`. No DB migration, Apache change, new service, server Julia or article rerender. No automatic production attachment or deployment.

Original code GPLv3-or-later; original explanations/data CC BY-SA4.0. Bundled dependency licenses in THIRD-PARTY.txt.
