# Minimum-Effort Interception of a Moving Target

This publication accompanies [the existing Physics Library article](https://physicslibrary.org/encyclopedia/MinimumEffortInterceptionOfAMovingTarget.html).
It does not replace or edit the article. The single-integrator vehicle begins at
`x(0)=0`, while the target starts at `d>0` and moves at constant `V>0`:

```text
x'(t)=u(t), target(t)=d+Vt, J=integral_0^T u(t)^2/2 dt.
```

For each trial arrival time `T`, the constant-speed path minimizes effort under
the endpoint constraint. It has `u=V+d/T` and `J(T)=(d+VT)^2/(2T)`. The global
minimum occurs at `T*=d/V`, `u*=2V`, `x(T*)=2d`, `J*=2dV`. The browser evaluates
these exact formulas locally as visitors change `d`, `V`, or the trial time. It
does not run Julia in the browser or on the server. The independent Julia source
generates three reference trajectories, including the article's `100 m, 10 m/s`
example. The resource is a one-dimensional quadratic-control model, not a fuel
or thrust simulation.

## Reproduce

With Julia 1.10.12 and Python 3.11+:

```bash
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. interception.jl
python3 build.py
python3 verify.py
```

The Julia source uses only standard libraries. `build.py` reads reviewed files
and creates the static publication under `data/examples/minimum-effort-interception`.
Production serves HTML, CSS, JS, CSV and ZIP as static files; it never invokes
the Julia code. `verify.py` checks the Julia CSV against the analytical solution,
source hashes, and ZIP contents.

## Attach to the existing article

1. Merge and deploy the static publication and the catalog entry in this PR.
2. Upload `computational-resources.json` from this directory to object 1324's
   filebox, using the normal article editor. Do not replace an existing resource
   manifest without preserving its other resource IDs (limit four).
3. Reload the article and check its Computational Resources section, then open
   the explorer and try the sliders, trial time, play/scrub, and CSV download.
   Check desktop and mobile. The resource section is outside the rendered LaTeX
   body, so no article rerender or database migration is needed.

The filebox attachment is an authorized production step, not performed by this
PR. No new executable server route, scheduled job or Julia installation is needed.
The site's static image host serves the published files at
`https://images.physicslibrary.org/examples/minimum-effort-interception/`.

Software is GPLv3-or-later. Mathematical text and reference data retain the
site's CC BY-SA article terms. See `LICENSE.txt`.
