# Orbital Elements and Kepler Propagation

English-only, offline Three.js explorer for the Physics Library GPSORB series.
The Earth is at a focus. The six elements control size, eccentricity, plane,
apsidal direction and orbital phase. Position/velocity and anomaly readouts,
camera views, angle highlighting, illustrative presets and CSV export are
computed locally. The browser advances mean anomaly and solves Kepler's
equation with astronomia's `kepler3`; it does not advance true anomaly linearly.

## Reproduce

Julia 1.10+ needs only standard libraries; no package installation is required.
From this directory:

```sh
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. orbital-elements.jl
pnpm install --frozen-lockfile --ignore-scripts
node --test test/model.test.mjs
node build.mjs
python3 build.py
```

`reference.csv` contains independently generated Julia ECI states at nine time
fractions for six presets, both without and with first-order secular J2 rates.
The JavaScript tests compare all 108 records, check energy/angular momentum,
rotation handedness, node crossings, circular/equatorial cases and Kepler time.
`provenance.toml` records units, approximation, versions and SHA-256 hashes.

`data/examples/orbital-elements/index.html` opens directly in a browser; it needs
no dev server, CDN, backend, Julia runtime or network connection. In the offline
ZIP the bundled viewer is alongside `index.html`. Rebuilding the bundle needs
Node 20+, pnpm 11.19+ and Python 3.10+; the exact dependencies are pinned in the lockfile.
In an extracted standalone project, rebuild output goes into its own `dist/`
directory rather than a repository publication path.

Browser QA uses Playwright and an installed Chromium browser:

```sh
CHROME_BIN=/path/to/chromium node test/viewer.cjs
```

Set `NODE_PATH` if Playwright is supplied by the host tooling rather than a
local installation. `ORBIT_VIEWER_PATH` can select an extracted offline ZIP's
index file; `ORBIT_QA_DIR` controls screenshot/output placement. QA checks
desktop/mobile framing, canvas pixels, controls, camera views, propagation,
J2, CSV download, label collisions and offline behavior.

## Scientific conventions

- Distances: kilometres; time: seconds; controls: degrees.
- Earth-centred inertial, right-handed: X equinox reference, Z north.
- PQW to ECI: Rz(RAAN) Rx(inclination) Rz(argument of perigee).
- mu = 398600.4418 km^3/s^2, RE = 6378.137 km, J2 = 1.08262668e-3.
- Bound ellipses only. Earth-intersecting inputs show a warning and cannot play.
- Circular orbits have no defined perigee; equatorial orbits have no defined
  node/RAAN. In those cases the chosen angles set a conventional phase reference.
  Undefined node/perigee markers are omitted.
- Optional J2 changes only RAAN and argument of perigee at first-order secular
  rates; a/e/i and the two-body mean-motion law stay fixed. Velocity is the
  instantaneous two-body osculating velocity, not the derivative of the
  precessing frame. This is a qualitative secular model, not a precision propagator.
- No GPS LNAV/CNAV decoding, harmonic broadcast corrections, ECI-to-ECEF
  transformation, short-period J2 terms, atmospheric drag or lunar/solar forces.
- Earth grid and illustrative presets are not live geography/ephemerides.
- The velocity arrow's length is proportional to speed, normalized against
  that ellipse's perigee speed; the satellite marker size is symbolic.

## Attach to articles

After merging and deploying the static files, an authorized editor can upload
`computational-resources.json` into each desired article's filebox and save the
article. Appropriate starting points are GPSORB05 (1261), GPSORB06 (1262),
GPSORB07 (1263), GPSORB09 (1265) and GPSORB10 (1266). Merge the `orbital-elements`
ID into any existing manifest rather than replacing other resources. No SQL,
timer, server-side job or production filebox mutation is part of this change.

Published path: `https://images.physicslibrary.org/examples/orbital-elements/`.

Visual inspiration: https://ki-math.github.io/orbital-elements-viewer/.
This is an independent implementation. No upstream code/media was copied.
Third-party software notices are bundled; original software is GPLv3 or later
and mathematical explanations/reference data are CC BY-SA 4.0.
