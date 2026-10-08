# Binary Star Observer

Two linked computational views for *Binary Stars as Physical Laboratories*
and *Geometric Eclipse Probability*: a binary orbit, magnified sky-plane disks,
an unresolved photometric source, a synchronized light curve, and a sphere of
isotropically distributed orbital poles. English only, fully local and offline.

## Publication and article attachment

The reviewed files live in `data/examples/binary-star-observer/` and are served at
https://images.physicslibrary.org/examples/binary-star-observer/index.html.
No Julia, database updates, cron jobs or additional server dependencies are needed.
After the normal static deployment, upload `computational-resources.json` through
each article's filebox and save the article. Suggested articles: UID 1410 (Binary
Stars as Physical Laboratories) and UID 1417 (Geometric Eclipse Probability).
If either already has a manifest, merge `binary-star-observer` into its `resources`
array instead of replacing existing resources; the existing four-resource limit applies.
The PR only publishes and registers the resource, not production attachments.

## Model

Relative semimajor axis is 1, orbital phase is mean anomaly / 2pi with phase zero
at periastron, and the observer is fixed on +Z. Projected X-Y disks determine
occultation. Relative position is rotated by Rx(i) Rz(omega); star positions are
`r1=-q/(1+q)*r`, `r2=1/(1+q)*r`, q=M2/M1. Positive relative Z means star 1 is
behind star 2 (eclipse A). Eclipse B has star 2 behind star 1. These labels avoid
calling a particular conjunction "primary" when its depth can change.

Inputs are inclination, fractional radius sum, radius ratio, surface-brightness
ratio, eccentricity, argument of periastron and mass ratio. R1/a and R2/a are
derived without redundant independent sliders. The detached constraint is
`radius_sum < 1-e`; conflicting edits reduce the other quantity, with a visible
status message. Free-camera orbiting never changes physical inclination.

Uniform disks use venn.js's exact circle-overlap area. Both stars emit light;
only the rear disk loses flux. Quadratic mode uses identical u1=0.4, u2=0.25 on
both stars, so integrated luminosity ratio remains J*k^2. Julia's Transits.jl
0.4.1 supplies exact survival fractions. The browser bilinearly interpolates
a 257 x 1025 table with grid coordinates aligned to internal and external
contact. Off-grid interpolation and reference-curve checks require absolute
normalized flux error below 0.0003. Data are embedded in viewer.js, not fetched.
The unresolved source is a schematic combined photometric signal; it does not
suggest an ordinary telescope can resolve these close stellar disks.

For a given omega, let u=nu+omega and r=(1-e^2)/(1+e*cos(nu)). The largest allowed
`cos(i)^2` at any orbital point is
`D(u)=((radius_sum/r)^2-cos(u)^2)/sin(u)^2`.
Maximize separately over u in (0,pi) and (pi,2pi). Differentiation reduces each
critical point to the bracketed root
`cos(u)-S^2*(1+e*cos(u-omega))*(cos(u)+e*cos(omega))=0`, S=radius_sum/(1-e^2).
The geometric probabilities are sqrt(max D) because isotropic poles are uniform
in |cos i|. The events share inclination: any=max(PA,PB), both=min(PA,PB), only
one=any-both. Replacing radius_sum by |R1-R2|/a gives internal disk contact.
Complete rear-disk coverage uses only the conjunction with the larger star in
front (A if R2>R1, B if R1>R2), not the maximum of both. Equal-radius total
coverage has zero measure in the orientation ensemble.
This is numerical geometry, not the approximate edge-on conjunction formula,
and is not a survey detection probability. An independent dense angular scan
tests the critical roots. Equal-weight Fibonacci sphere samples visualize the
ensemble with counts accurate to finite sampling, rather than random noise.

Contacts are bracketed separately around the critical point and refined with
fmin bisection. The closest projected approach determines midpoint and depth.
Adaptive samples inside contacts catch short periastron eclipses. Phase/time
advances uniformly, not true anomaly. Orbit colors label stars, not temperature.

This spherical detached model omits spots, third light, reflection, ellipsoidal
distortion, gravity darkening and Doppler beaming. Timing, duration and depth do
not uniquely infer all binary parameters. Radii below collision do not alone
guarantee Roche-lobe detachment; "detached" here means nonintersecting spheres.

## Reproduce

Julia 1.10.12, Node 22+, pnpm 10.26+ and Python 3.10+, with committed environments:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --project=. binary-star-observer.jl
julia --startup-file=no --project=. test/runtests.jl
pnpm install --frozen-lockfile
node --test test/model.test.mjs
node build.mjs
python build.py
```

The build publishes into the repository; extracted offline archives rebuild into
`dist/`. The archived index.html plus viewer.js and style.css opens directly as
a local file without building. QA uses Playwright and a Chromium installation:
`NODE_PATH=/path/to/playwright/modules node test/viewer.cjs`; set `CHROME_BIN`
when Edge is not installed at the Windows default. Optional `BINARY_VIEWER_PATH`
and `BINARY_QA_DIR` override the test target and screenshot directory.

## Sources and licensing

- https://physicslibrary.org/encyclopedia/BinaryStarsAsPhysicalLaboratories.html
- https://physicslibrary.org/encyclopedia/GeometricEclipseProbability.html
- https://juliaastro.org/Transits/stable/api/
- https://github.com/JuliaAstro/Transits.jl (MIT)
- https://github.com/benfred/venn.js (MIT circle-overlap geometry)
- https://github.com/benfred/fmin (BSD bisection)
- https://github.com/commenthol/astronomia (MIT Kepler solver)
- Three.js, D3 and Lucide: actual bundled dependency notices in THIRD-PARTY.txt.

Original code GPLv3 or later; reference numerical data and original text CC
BY-SA 4.0; branding excluded. SHA-256 checksums are saved in provenance.toml.
