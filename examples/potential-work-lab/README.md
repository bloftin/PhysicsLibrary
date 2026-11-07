# Charge, Potential & Work Lab (E01)

Companion to [Electric Charge, Electric Potential, and Voltage](https://physicslibrary.org/encyclopedia/ElectricChargeElectricPotentialAndVoltage.html), article **1572**, alias E01.

Open the published `data/examples/potential-work-lab/index.html`, or `index.html` at the root of the source ZIP. All computation is offline in the browser; no production Julia installation, server, remote assets or audio permission. The archive includes the already-built viewer and source, pinned environments, licenses, tests, CSVs and provenance hashes.

## Model

Main quantities: `deltaV=V(B)-V(A)`, `deltaU=q*deltaV`, `Welectric=-deltaU`. For quasistatic transport `Wexternal=deltaU`; arbitrary external work also depends on kinetic-energy change. The ideal meter initially has red=A, black=B and reads `V(A)-V(B)`, **opposite** to the A-to-B voltage change. Swapping its leads does not reverse the path.

Prescribed stationary point sources: `V=k*sum(Q/r)+C`, `E=k*sum(Q*r_vector/r^3)`, with the unshifted zero at infinity. This is a plane through a physical 3D field, not logarithmic 2D electrostatics. `k=1/(4*pi*8.8541878188e-12)` uses rounded 2022 CODATA epsilon0, not an exact defining constant. Test charge never modifies source fields and has no self-field in this model.

Uniform-field patch: rails x=-1 and x=1 mark a physical spacing d. **Each map unit is d/2 meters**, on both axes. `V=deltaV_rails*(x+1)/2+C`, `Ex=-deltaV_rails/d`. The ideal patch extends across the plotted region; rails are not finite electrodes whose edge effects or surface charges are calculated. Point-source coordinates instead use meters. All actual path lengths, field values, energies and work use SI.

Presets reproduce the article's E=200 V/m, d=.050 m, q=+2 nC case (electric work +20 nJ), +5 V with +2 microC (deltaU +10 microJ), the -4 microC/-3 V worked example (deltaU +12 microJ), and an electron crossing +3 V (deltaU -3 eV). Positive and negative single sources, dipole, equal positive sources and no source field complete nine cases.

## Interaction

Move A/B and the bent-path waypoint H with pointer/touch or numeric coordinates. Source positions and nC values are also editable. Main test q accepts nC, microC or multiples of the exact elementary charge `e=1.602176634e-19 C`; changing units preserves the physical q. Its macroscopic control is continuous, unlike the integer electron-transfer illustration. Sources are held stationary. The animated marker traverses a prescribed path at constant path-fraction rate, **not** physical time or acceleration.

Straight and via-H routes are piecewise linear. The path profile plots potential or potential energy against fraction of total path length. Their different intermediate profiles can have the same net work. Set B=A with via-H for a closed out-and-back path. Duplicate vertices and zero-length paths are valid.

Colors and equipotential contours always represent **V-C** so a common reference shift does not recolor the same field. Numeric potentials and the V/U profile include C. The signed color span is explicitly selected and clipped, not automatically rescaled with q or source changes. Profile vertical scale is automatic and labeled. E and test-force arrows show direction only. Neutral q has no force arrow; no field direction is drawn at a null.

No softening: point-source V/E are singular at nonzero sources. A .16 m display mask withholds endpoint quantities near a source and rejects paths intersecting its disk using exact point-to-segment minimum distances. It is not an artificial conducting radius. A valid endpoint difference can remain available when a connecting path is rejected; the unsafe integral, profile, traversal and CSV are withheld. Neutral sources create no singularity or exclusion. Source separation is at least .40 m; marker positions bounded to +/-2.3 map units; test q +/-10 microC; source Q +/-5 nC; reference C +/-1000 V; rail voltage +/-100 V; gap .01-.2 m.

Independent numerical line integrals use [ODEX 2.0.4](https://github.com/littleredcomputer/odex-js), the Hairer/Wanner Gragg-Bulirsch-Stoer port. Each segment integrates `E dot dr/dt` from parameter t=0 to 1, absolute/relative tolerance 1e-12, max step .05. The result is **volts**, then multiplied by q to avoid accuracy loss for elementary-charge energies. This is independently compared with the analytic endpoint result, not just a second copy of q*deltaV. Numerical failure is labeled instead of reported as agreement.

## Charge And Battery Illustrations

Transfer -20 to +20 electrons between two initially neutral bodies. One body's loss is the other's gain; algebraic total charge remains zero. This is imbalance bookkeeping, not conductor polarization or Coulomb dynamics. The main test charge also reports signed q/e and its energy change in eV.

Battery: prescribed EMF 0-24 V, internal r=0-1000 ohms, load R=1-1e6 ohms and finite meter Rm in parallel. `Rp=1/(1/R+1/Rm)`, `I=EMF/(r+Rp)`, `Vterminal=I*Rp`. The comparison without the meter keeps the load connected. Current includes both branches and power balance includes internal, load **and meter** dissipation. r=0 is the ideal-source limit. No inductive dynamics, battery chemistry, discharge state or practical wiring instructions.

## Rebuild And Verify

Julia 1.10.12 independently evaluates nine cases at 256-bit BigFloat precision: **1170** path/field/energy samples and **9** endpoint events, rounded to 17 significant figures in CSV. Julia standard libraries only; the JavaScript tests compare samples, field gradients, conservation, reference/sign invariants, path integrals, zero/singular cases and DC power balances.

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. potential-work-lab.jl
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

Node 22+, pnpm 11.25.0 and Python 3.11+. D3 7.9.0, Lucide 0.468.0, ODEX 2.0.4 and esbuild 0.25.10 are pinned. Cached installs support `--offline`. Publication goes to `data/examples/potential-work-lab` in this repository, `dist` outside it. Optional `node test/viewer.cjs` uses Playwright and `BROWSER_EXECUTABLE` for a local browser. QA output is ignored.

## Deploy And Attach

Deploy static files and the updated `etc/computational-resources.json`. Upload/merge this folder's `computational-resources.json` into **article 1572's existing filebox**; it selects `potential-work-lab`. Preserve other resource IDs, maximum four. No SQL migration, new daemon, server Julia install, Apache change or article rerender is required. This PR does not change production attachments automatically.

Original code GPLv3-or-later; explanations/data CC BY-SA 4.0; bundled dependency licenses in THIRD-PARTY.txt. Scientific sources: the E01 article and [NIST 2022 CODATA](https://physics.nist.gov/cuu/pdf/wall_2022.pdf). No external graphics or copied simulator code.
