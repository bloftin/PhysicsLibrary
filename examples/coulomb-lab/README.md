# Coulomb's Law Lab

Companion to [Coulomb's law](https://physicslibrary.org/encyclopedia/CoulombsLaw.html), article **60**. It bridges the article's force magnitude and vector direction with electrostatic superposition and field-line geometry.

Open the published `data/examples/coulomb-lab/index.html`, or `index.html` at the root of the downloadable ZIP. It runs offline with no server, production Julia runtime, network assets, audio permission or charge-motion animation. The ZIP includes source, environments, references, tests, licenses and provenance hashes.

## Model And Conventions

`F_on_i_by_j = k*q_i*q_j*(r_i-r_j)/|r_i-r_j|^3`. The signed product determines attraction or repulsion. Each pair is computed once and its reaction assigned as the exact negative vector. Net forces add vectorially; in a many-charge configuration two net forces need not be opposite even though every interacting pair obeys the reaction law.

`E(P) = k*sum(q_j*(P-r_j)/|P-r_j|^3)`. The external field at source i excludes its own contribution, so `F_i=q_i*E_others(r_i)`. The virtual test charge at P is not part of the sources and does not perturb the field. Changing its sign reverses the test force; setting it to zero eliminates the force without erasing a nonzero field.

Positions use meters and charge inputs use microcoulombs. Internal calculations and CSV exports use SI. The vacuum constant is computed as `1/(4*pi*8.8541878188e-12)` using the rounded 2022 CODATA central value of epsilon0. This is not an exact SI defining constant or an uncertainty analysis. [NIST source](https://physics.nist.gov/cuu/pdf/wall_2022.pdf).

The model is a two-dimensional slice through a three-dimensional point-charge field; it uses the physical inverse-square law, not two-dimensional logarithmic electrostatics. All sources are externally held. No conductor polarization, finite sphere geometry, radiation, magnetic force or mechanical trajectory is simulated. Source symbols are markers, not sphere radii.

## Interaction And Views

The initial configuration has two opposite 1 microcoulomb sources at x=-1 and x=+1 m. A count select supports two through six charges. Increasing count preserves existing sources and places new markers at separated positions; decreasing it truncates the list. Every source has individual charge and coordinate controls, and can also be selected/dragged on the canvas. Optional snapping rounds pointer positions to 0.1 m. Numerical fields provide a keyboard-accessible alternative.

Presets: dipole, like signs, unequal opposite signs, a three-charge triangle, an alternating quadrupole, symmetric three-charge balance, one positive/negative active source with a neutral second marker, six sources and all-zero sources. Position limits are +/-2.5 m, charge range +/-5 microcoulombs, and the fixed diagram domain is [-3,3] m on both axes with equal spatial units.

**Forces:** gold net vectors and optional dashed pair vectors on the selected source share one linear scale, adapted to keep the endpoints inside the view. The adjacent reference bar is exactly 40 CSS pixels and gives the corresponding force. Therefore magnitudes within one scene are comparable by length, but scenes should be compared with the numeric values or inverse-square sweep rather than changing automatic arrow lengths. In the two-charge case the single contribution and net vector coincide.

The two-source separation controls move both sources symmetrically around their current midpoint, preserving their joining-line direction. Their maximum permitted separation follows the current position bounds. The half/double commands disable when the result cannot fit. The inverse-square sweep always holds the two charge values fixed, uses r from 0.3 to at least 5 m (extending to the present separation when necessary), and labels its logarithmic force axis. It is hidden for larger configurations because a net force is not generally a function of one pair separation alone.

**Field:** choose field lines or a direction-only grid. Lines follow the physical E direction. Fixed logarithmic strength shading runs from 1e2 to 1e6 N/C; it clips outside that range rather than rescaling between configurations. A probe reports the actual field and a virtual-test-force magnitude. Its black E and purple test-force arrows are direction-only and are not length-comparable to source-force arrows. The component table follows the active view: source-force contributions on the selected source, or field contributions at P.

## Field-Line Numerics And Honest Limits

Tracing uses the established [ODEX 2.0.4 solver](https://github.com/littleredcomputer/odex-js), a JavaScript port of the Hairer/Wanner Gragg-Bulirsch-Stoer method. It integrates `dr/ds = direction*E/|E|` with arclength s, not time. Positive seeds trace forward; negative seeds trace backward and their arrays are reversed before drawing, so arrowheads still follow E. Reverse traces that end at a positive source are omitted to avoid duplicating internal source-to-sink connections. Negative incoming boundary branches remain, including all-negative configurations.

Absolute/relative tolerances are 2e-6, maximum step .045 m, maximum trace length 18 m, maximum 1600 solver steps. The derivative/accepted-point checks stop near a nonzero source, outside the view, or near a cancellation where direction is numerically ill-conditioned (`|E| < .002*sum |E_j|`, or absolute |E| < 1e-8 N/C). A numerical failure falls back to field arrows rather than presenting stale or invalid curves.

Seeding is illustrative and budget-limited, approximately scaled by source magnitude. It is not a calibrated flux-density construction. Finite paths and truncation do not change analytic E or force calculations. Lines never represent charged-particle trajectories. [MIT's field-line discussion](https://web.mit.edu/8.02t/www/802TEAL3D/visualizations/coursenotes/modules/guide02.pdf) supplies the conceptual reference; all graphics here are newly computed.

No force softening is used. Source positions stay at least .30 m apart, a UI constraint. Nonzero point-source fields are undefined exactly at their positions. Traces stop at .12 m display-exclusion disks, and probe values inside those disks are explicitly withheld. A merely masked point is not falsely called a mathematical singularity. A zero-charge marker creates no field, mask or singularity.

Line/shading data are cached by source state, not probe or selection changes. During dragging the plot shows live direction arrows without stale curves/shading; after movement settles the field curves are recomputed. The browser never advances charge positions on its own.

## Verification And Rebuild

Julia 1.10.12 independently evaluates fields at 256-bit BigFloat precision and pair forces by signed magnitude times a unit vector. Ten configurations produce 28 source/force rows and 1440 field samples. JavaScript force identities, charge-sign flips, inverse-square scaling, probe independence, cancellation, zero/singular cases and library-traced field directions are tested separately. CSV references have 17 significant digits; display fields are rounded without modifying stored values.

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. coulomb-lab.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

Node 22+, pnpm 11.25.0 and Python 3.11+ build the viewer. Julia uses Printf/Test standard libraries only. The browser bundle pins D3 7.9.0, Lucide 0.468.0 and ODEX 2.0.4; esbuild is 0.25.10. Initial dependency installation may need network access; cached installs can use `--offline`. Publication goes to `data/examples/coulomb-lab` inside this repo and `dist` outside it.

Optional `node test/viewer.cjs` uses Playwright (tested with 1.62.1); set `BROWSER_EXECUTABLE` for an existing compatible browser if needed. Ignored QA screenshots go to `qa/`. Original code is GPLv3-or-later; explanations and reference data are CC BY-SA 4.0. Bundled libraries retain their licenses in THIRD-PARTY.txt.

## Attach To Coulomb's Law

Deploy the static publication and updated `etc/computational-resources.json`, then upload `computational-resources.json` to the existing **CoulombsLaw filebox, article 60**. It selects `coulomb-lab`. Merge it with an existing manifest's IDs rather than replacing them (maximum four). No SQL migration, new service, production Julia install or article rerender is needed. The PR does not upload production attachments automatically.
