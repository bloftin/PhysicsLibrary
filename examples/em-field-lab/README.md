# Wave and Field Explorer (EM01)

Static computational companion to [Electromagnetic Waves: From a 1D Wave to a Field](https://physicslibrary.org/encyclopedia/AntennasElectromagneticWaves.html), objects UID 1209. The historical URL contains "Antennas", but this article introduces field notation, spatial snapshots, fixed-point histories, and the distinction between field and propagation directions. This first lab addresses that foundation, rather than introducing antenna radiation prematurely.

## The first visualization

- A full-bleed 3D field at 175 fixed sample positions. Scalar view uses signed colors and an X-Y slice with contours; vector view gives local electric-field arrows. Optional constant-phase sheets move while sample locations stay fixed.
- Spatial snapshot along the propagation axis and time histories at two fixed ideal probes, with signed components or magnitude. The plane wave is uniform perpendicular to propagation, so the snapshot also matches the probes' projected positions.
- Wave amplitude, frequency, initial phase, propagation tilt/azimuth, transverse field rotation, probe position/spacing and scalar-slice position. Playback, camera controls, keyboard/pointer time selection and CSV export.
- Signed scalar coefficient versus nonnegative magnitude, transverse field/propagation directions, propagation reversal, downstream delay, and whole-wavelength phase ambiguity.
- Article +z/x case, reverse propagation, oblique wave, rotated field, zero amplitude and GPS L1 frequency-only presets.

## Model and conventions

`psi(r,t) = E0 cos(k n dot r - omega t + phase)` and `E(r,t) = e psi(r,t)`, with unit vectors `n dot e = 0`. The scalar coefficient is measured in V/m; it is not electric potential. Vacuum c = 299792458 m/s, lambda = c/f, T = 1/f, k = 2pi/lambda and omega = 2pi f.

Propagation uses spherical polar angle theta from +z and azimuth phi from +x towards +y. `n = Rz(phi) Ry(theta) z`; the transverse basis is `e = Rz(phi) Ry(theta) (x cos(beta) + y sin(beta))`. The reverse preset preserves +x field orientation while reversing propagation. Inspection-camera changes never alter the physical wave.

Coordinates and the display clock are normalized as r/lambda and t/T. Frequency changes therefore rescale physical metres and seconds, not the normalized wave pattern. Glyph bases and probes stay fixed during time playback. Arrow length is 0.04 lambda per V/m, not physical displacement. The scalar palette has a fixed -10 to +10 V/m scale. Contours exclude the data-domain boundary, which is not a physical isoline. Pointer/keyboard probe selection on the snapshot moves A along propagation, preserving its transverse offset and the coordinate limits.

Probe B is A + spacing*n in wavelength units. Its trace equals A's trace delayed by spacing*T. Delay is a known geometric quantity in this model; a single-frequency phase measurement alone cannot establish an unambiguous time of flight. The whole-wavelength case has equal-phase traces but a one-period geometric delay.

This is an illustrative monochromatic, linearly polarized electric plane field. No magnetic-field display, antenna voltage, energy-flux calculation, radiation source/pattern, signal modulation, finite aperture, reflection or dispersive medium. The GPS preset supplies only the L1 frequency of 1575.42 MHz; actual GPS signal polarization/modulation is not modeled.

References: [article](https://physicslibrary.org/encyclopedia/AntennasElectromagneticWaves.html), [OpenStax plane electromagnetic waves](https://openstax.org/books/university-physics-volume-2/pages/16-2-plane-electromagnetic-waves), [NIST GPS frequencies](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z/time-frequency-z-g).

## Reproduction and publication

Julia 1.10.12 references use independent rotation matrices and cospi phase evaluation, with standard libraries only. Browser vector geometry uses Three.js; contours/plots use D3. Node >=22, pnpm 11.19.0 and Python 3.10+:

```sh
julia --startup-file=no --project=. em-field-lab.jl
julia --startup-file=no --project=. test/runtests.jl
pnpm install --frozen-lockfile
pnpm test
pnpm build
python build.py
```

Output is `data/examples/em-field-lab` in the repository, `dist` outside it. Published files and the zip's root contain a ready-to-open viewer with no network assets. The archive includes source, locked Julia/browser environments, 1,820 independent reference samples, numerical and browser tests, full licenses and provenance hashes. It performs no database writes, server computation or scheduled jobs.

Browser QA: `node test/viewer.cjs`, using Playwright via NODE_PATH if needed. `BROWSER_EXECUTABLE` overrides the default Edge executable; `VIEWER_FILE` overrides the publication path. Screenshots are saved to ignored `qa/`. Covers desktop/mobile rendering and overflow, WebGL colors/motion, scalar/vector views, camera independence, fixed probes, sign/magnitude, units, delay, invalid inputs, export and fallback. In the repo run `prove bin/test/computational-resources.t` with the existing Perl dependencies too.

After static deployment, attach the contents of the included manifest to UID 1209 under its filebox name `computational-resources.json`. If a manifest already exists, merge `em-field-lab` into its resource IDs rather than replacing other attachments. Published viewer URL: `https://images.physicslibrary.org/examples/em-field-lab/index.html`. No production changes are made by the build.

## Recommended follow-on labs

1. **Polarization and local antenna response:** linear, circular and elliptical field-tip motion at a fixed receiver, independently oriented ideal receiving dipole, phase/amplitude response and polarization mismatch. This makes a natural bridge towards the article's antenna and GPS discussion; circular polarization should be modeled explicitly rather than inferred from the L1 frequency preset.
2. **Electric field, magnetic field and energy flux:** synchronized E and B with a local Poynting vector, propagation handedness and instantaneous versus time-averaged flux. Connect field amplitudes to energy transport before link-budget power formulas.
3. **Array phase and beam steering:** coherent signals at a small receiving array, spacing/arrival direction/relative delay, constructive and destructive combining, and grating-lobe ambiguity. Best introduced after the local-field and polarization labs.
