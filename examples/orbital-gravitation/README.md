# Orbital Motion from Universal Gravitation

This Julia computational resource follows a test spacecraft around an
Earth-mass central body under Newton's inverse-square gravitational law. It
starts at four Earth radii with a tangential launch speed from `0.70 v_c` to
`1.42 v_c`, where `v_c` is the local circular speed. The reviewed static
explorer has 37 saved launch-speed cases and 361 samples per case.

The explorer is intentionally a viewer, not a remote compute service. Its
controls select saved Julia outputs and its test-mass control changes only
derived force and total-energy readouts. It makes no network requests while
playing a path and does not execute Julia in the browser or on the server.

## Attach to the universal-gravitation article

1. Deploy the reviewed publication from `data/examples/orbital-gravitation`.
2. Extract `article-attachments.zip`.
3. Upload `computational-resources.json` through the article filebox. This
   attaches the explorer to the saved article outside its rendered LaTeX body.
4. Optionally add `article.tex` to the article body and `preamble.tex` to the
   preamble, then upload `reference-orbits.png` through the filebox.
5. Preview, save, and use the article's Computational Resources section to
   open the static explorer.

The attachment bundle is not automatically extracted by PhysicsLibrary. For
an article that already has a resource manifest, add `orbital-gravitation` to
its `resources` array without removing existing IDs. At most four resource IDs
are supported.

## Reproduce

Use Julia 1.10.12 and Python 3.10+ with Matplotlib:

```bash
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. motion.jl
python3 build.py
python3 verify.py
```

The Julia test checks the circular initial conditions, central acceleration,
negative/positive specific-energy classifications, Earth clearance for the
elliptical reference case, and numerical conservation of energy and angular
momentum. The Python verifier checks publication hashes, bounded inputs,
local-only assets, all 37 saved trajectories, and the source ZIP.

## Scope

This is a planar, ideal two-body model. It omits the Moon, other planets,
atmospheric drag, Earth oblateness, relativity, propulsion, collisions, and
mass change. Near-escape paths are shown only over the saved finite window.

Software is GPLv3-or-later. Article text, diagrams, plots and data retain
PhysicsLibrary's CC BY-SA terms. See `LICENSE.txt` and `COPYING`.
