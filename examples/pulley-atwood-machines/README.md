# Pulleys and Atwood Machines

This static interactive resource accompanies [Pulleys and Atwood Machines](https://physicslibrary.org/encyclopedia/PulleysAndAtwoodMachines.html) (object 1359). It reproduces the article's fixed-pulley Atwood example (3 kg and 5 kg) and its hanging-mass/movable-pulley example (4 kg driving a 6 kg load). Balanced cases and reversed masses are included. Sliders change the masses and gravity; the browser evaluates the exact ideal-system equations without contacting a server.

For the fixed pulley, positive acceleration means `m2` moves downward:

```text
a = (m2-m1)g/(m1+m2),  T = 2m1m2g/(m1+m2)
Delta y1 + Delta y2 = 0   (both y coordinates point downward)
```

For the movable pulley, positive acceleration means the load `m2` moves upward and the free mass `m1` moves downward:

```text
a_load = (2m1-m2)g/(4m1+m2),  a_free = 2a_load
T = m1(g-2a_load),  Delta y_free + 2 Delta y_load = 0
```

The free mass passes over an additional ideal fixed redirecting pulley. All runs begin from rest; the display stops before a body reaches the pulley or floor. The model assumes one taut, massless, inextensible rope, frictionless massless pulleys, and uniform gravity. It does not model pulley inertia, axle friction, slack, collisions, or a real rope's elasticity. The graph uses downward-positive displacements for both masses, whereas the movable-load acceleration readout uses upward positive, as in the article.

## Reproduce

With Node.js 20+, Python 3.11+, and Julia 1.10+:

```sh
node --test test/model.test.cjs
julia --startup-file=no --project=. test/runtests.jl
node build-reference.cjs
python3 build.py
python3 verify.py
NODE_PATH=/path/to/playwright node test/viewer.cjs
```

`build-reference.cjs` generates the committed CSV using the same exact model as the offline browser. Julia has an independent implementation and can produce a numerically equivalent CSV with `julia --startup-file=no --project=. atwood.jl`. Minor decimal-format differences are expected. The Julia tests check Newton's equations and the rope constraints. `build.py` publishes static assets under `data/examples/pulley-atwood-machines` and packages the complete project. No Julia process runs on the Physics Library server.

## Attach to the article

1. Merge and deploy the static publication and catalog entry.
2. Upload `computational-resources.json` to object 1359's filebox using an authorized editor. Preserve any existing resource IDs in its manifest (maximum four).
3. Reload the article. Its Computational Resources section should link the explorer, Julia project, CSV, provenance, and license. Check both modes and all four presets on desktop and mobile.

Manifest attachment is a separate production step, not performed by this PR. No database migration, background job, or Julia installation on the web server is needed. The static image host serves `https://images.physicslibrary.org/examples/pulley-atwood-machines/`.

Software is GPLv3-or-later. Mathematical text and reference data retain the site's CC BY-SA article terms. See `LICENSE.txt`.
