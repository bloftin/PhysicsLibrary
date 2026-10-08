# Spectroscopic Binary Lab

A static, English-language companion to [Binary Stars as Physical Laboratories](https://physicslibrary.org/encyclopedia/BinaryStarsAsPhysicalLaboratories.html) (objects UID 1410). Runs locally by opening `index.html` in the published folder or offline archive. No external assets, API requests, server computation, database changes, or scheduled jobs.

## Views and parameters

- Barycentric 3D orbit, sky plane, fixed Earth direction, physical inclination and orbital velocity vectors. Camera inspection does not change the observer.
- Synchronized radial velocities, continuum-normalized absorption profiles, and a full-orbit trailed spectrum. Phase is uniform time, measured from periastron. Playback, keyboard/pointer phase selection and CSV export.
- Primary mass, mass ratio, period, physical inclination, eccentricity, periastron angle, systemic velocity, continuum flux ratio, intrinsic line FWHM and spectral resolving power.
- SB2 exposes both amplitudes, the mass ratio and minimum masses. SB1 exposes the primary's mass function, with the companion's absorption suppressed but its featureless continuum retained.
- Independent inclination hypothesis and, for SB1, assumed primary mass. These affect only inference, never the orbit, measured velocities or spectra. Face-on spectra correctly report masses and mass ratio as unconstrained.

## Scientific conventions

Relative semimajor axis follows Kepler's law with nominal solar GM = 1.3271244e11 km^3/s^2, AU = 149597870.7 km and day = 86400 s. Positions displayed in units of relative a. Rotation is Rx(i) Rz(omega) of the star2-minus-star1 relative orbit, Earth on +Z; observer recession RV = gamma - barycentric vZ. Thus RV1 = gamma + K1[cos(nu + omega) + e cos(omega)] and RV2 has the opposite term. Omega is the relative-orbit convention, rather than the argument of the primary's barycentric periastron. Gamma is the time average, not the midpoint of eccentric curve extrema.

K1/K2 = M2/M1. In nominal solar units the mass function is P K1^3 (1-e^2)^(3/2)/(2 pi GM_sun), with P in seconds and K in km/s. The corresponding SB2 M1 sin^3(i) uses (K1+K2)^2 K2; M2 sin^3(i) uses K1. For SB1, bracketed inversion of f = M2^3 sin^3(i)/(M1+M2)^2 gives the companion mass for independently assumed M1 and i; i=90 degrees gives its conditional lower bound.

One Gaussian absorption line at rest wavelength 500 nm, intrinsic depth 0.65. Instrument FWHM = c/R, added in quadrature with intrinsic FWHM. Convolved depth is reduced to preserve equivalent width. Components are continuum-weighted absorption contributions, not separately normalized stellar spectra. Wavelength uses the low-velocity optical convention lambda = lambda0 (1+RV/c). SB1/SB2 is explicitly selected, not automatically classified from line blending or light ratio.

Schematic sizes/colors, ideal two-body dynamics, and noiseless spectra only. No atmosphere synthesis, eclipses, spots, tidal distortion, Rossiter-McLaughlin effect, precision barycentric corrections or relativistic effects. This is not a real-data fit.

Sources: [article](https://physicslibrary.org/encyclopedia/BinaryStarsAsPhysicalLaboratories.html), [UCLA Astronomy 140 binary-star notes](https://astro.ucla.edu/~wright/A140/A140.pdf), [IAU 2015 Resolution B3](https://www.iau.org/common/Uploaded%20files/IAUGA2015-Resolution-B3-recommended-nominal-conversion.pdf), [Astropy optical Doppler convention](https://docs.astropy.org/en/stable/api/astropy.units.doppler_optical.html).

## Reproduction

Julia 1.10.12 reference calculations use only standard libraries, with independent eccentric-anomaly bisection and direct Cartesian orbital velocities. Browser propagation and mass inversion use Astronomia 4.1.1; Three.js, D3 and Lucide are bundled locally. Node >=22, pnpm 11.19.0 and Python 3.10+:

```sh
julia --startup-file=no --project=. spectroscopic-binary.jl
julia --startup-file=no --project=. test/runtests.jl
pnpm install --frozen-lockfile
pnpm test
pnpm build
python build.py
```

In the repo, output is `data/examples/spectroscopic-binary`; outside it, `dist`. The zip includes a ready-to-open viewer at its root as well as source, locks, tests, full GPL text, bundled dependency notices and provenance SHA-256 hashes. `reference.csv` has 1,015 orbital states; `spectrum-reference.csv` has 7,602 samples across seven cases including face-on, SB1 and e=0.8 stress cases.

Headless QA: `node test/viewer.cjs`, using Playwright via NODE_PATH if not installed locally. Set `BROWSER_EXECUTABLE` to override the default Edge executable and `VIEWER_FILE` to override the publication path. Screenshots go to ignored `qa/`. Tests include desktop/mobile, WebGL pixels and motion, SB1/SB2, physical/camera orientation separation, independent inference, profile/trail tabs, CSV download, and WebGL fallback. In the repo also run `prove bin/test/computational-resources.t` with the existing Perl dependencies.

## Article attachment

After the static files and catalog are deployed, update the article's filebox `computational-resources.json`, preserving any other reviewed resource IDs. The generic manifest selects only this lab. For UID 1410, `binary-stars-computational-resources.json` contains both the already-published observer lab and this lab: upload that content under the existing filebox name `computational-resources.json`, not under its convenience filename. This avoids replacing the previous resource. Normal article rerender/filebox workflow then exposes both. No production changes are performed by the build or tests.
