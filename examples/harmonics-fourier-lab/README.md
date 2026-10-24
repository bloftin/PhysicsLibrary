# Harmonics & Fourier Lab (FS01)

Companion to [Periodic Functions, Harmonics, and Why Fourier Series Exist](https://physicslibrary.org/encyclopedia/PeriodicFunctionsHarmonicsAndWhyFourierSeriesExist.html), FS01, article 1517.

The ready-to-open `index.html` works offline, without Julia, a web server, remote scripts, microphone permissions or server-side computation. It includes rotating harmonic vectors, a finite-sum plot, a 24-harmonic amplitude/phase mixer, unit-harmonic clocks, reference waveform overlays, optional Web Audio synthesis, CSV and WAV exports, and mathematical explanations. Sound starts only after a deliberate click, stops on page hide, and is separate from the slowed animation clock. Browser/OS policies can disable live audio; WAV export and the Julia-generated sound remain available.

## Mathematical Scope

`S_N(t) = A0 + sum(A_n cos(n omega0 t) + B_n sin(n omega0 t))`, where `omega0=2pi f0` and `T0=1/f0`.

The phasor chain displays vertical projections, with horizontal component `A_n sin(n theta)-B_n cos(n theta)` and vertical component `A_n cos(n theta)+B_n sin(n theta)`. Its endpoint's vertical coordinate equals `S_N-A0`. Circles are a mathematical phase visualization, not literal vibrating-string modes. The separate stack uses unit-amplitude reference cosines, not the mixture's coefficients. Graphs use normalized base cycles; physical time readouts and audio use the selected frequency in Hz (55 to 440).

Phase is defined by `R_n cos(n omega0 t - delta_n)`, with `delta_n=atan2(B_n,A_n)`. Positive 90 degrees gives a positive sine. The mean `A0` equals the conventional Fourier `a0/2`. Zero-amplitude phase is undefined. Harmonics above N retain their saved coefficients but are excluded from plots and sound. N is the highest retained harmonic, not the number of nonzero terms.

The period is `T0/gcd(nonzero harmonic numbers)`. Numerically, amplitudes at or below `1e-10` are treated as zero for period classification. A constant has no smallest positive period. A missing first harmonic need not shorten the period: 2 and 3 have gcd 1, while 2 and 4 have gcd 2. This resource uses integer harmonics only, not an irrational-frequency approximation.

Presets include the article's exact `1 + 2cos(theta) - .75sin(2theta) + .4cos(3theta)`; an odd square wave with `B_n=4/(pi n)` for odd n; triangle `B_n=8(-1)^((n-1)/2)/(pi n)^2` for odd n; and sawtooth `B_n=2(-1)^(n+1)/(pi n)`. Ideal discontinuous references take midpoint values at jumps. Finite sums are smooth; Gibbs overshoot is not claimed to disappear with N. These are synthesis previews, not derivations of coefficients or a general convergence guarantee.

## Sound And Julia

Web Audio's built-in `PeriodicWave` engine uses the cosine coefficients as `real` and sine coefficients as `imag`; normalization is explicitly disabled. DC is never sent to the speaker. Gain is at most `volume/sum(R_n)`, with volume initially .15 and at most .3 full-scale. That provides a conservative peak bound, not a measured or guaranteed headphone sound-pressure level. Start with low device volume. Live playback ramps gain at starts/stops; coefficient edits can change the sound abruptly. Terms at or above 45% of the actual audio sample rate are omitted from sound only. The plot retains them. Solo sound is explicitly labeled as the selected retained harmonic, not the full plotted sum.

Julia computes independent complex-exponential samples, analytic RMS values and gcd periods, and writes `julia-square.wav` directly as RIFF PCM. Both Julia and browser WAV export use 48 kHz mono 16-bit samples, 2 seconds, and linear 25 ms fades. A Julia audio-device package is not needed: play the generated WAV in a browser or ordinary audio player. The source can be adapted to an audio package locally, but nothing runs on Physics Library servers. Browser audio converts coefficients to Float32; WAV samples may differ from the independent Float64 Julia reference by one or two PCM counts.

## Reproduce

Julia 1.10.12, standard libraries only:

```sh
julia --startup-file=no --project=. -e 'using Pkg; Pkg.offline(true); Pkg.instantiate()'
julia --startup-file=no --project=. test/runtests.jl
julia --startup-file=no --project=. harmonics-fourier-lab.jl
```

Node 22+, pnpm 11.25.0 and Python 3.11+:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm test
pnpm run build
python build.py
python test/package_test.py
```

The archive includes both a ready-to-open viewer and all rebuildable sources. Builds publish to `data/examples/harmonics-fourier-lab` in this repository, or `dist` outside it. Dependency installation can use the local pnpm cache with `--offline`. Nothing is loaded from a CDN at runtime.

Optional browser QA additionally requires Playwright in the test environment (tested with 1.62.1): `node test/viewer.cjs`, with `BROWSER_EXECUTABLE` set if Playwright's browser is not installed. Playwright is not a viewer dependency. Screenshots are written to ignored `qa/`. Tests check presets, phase/DC and periods, all controls, animated canvas pixels, mobile/desktop layout, offline behavior, audio opt-in/stop, WAV downloads, and Web Audio's coefficient convention against a rendered tone. Numerical tests compare the browser with 1806 Julia samples and the independent WAV; package tests check licenses, hashes, manifest, links, and archive contents.

## Attach To FS01

After deploying the static files and catalog update, upload `computational-resources.json` to **FS01's filebox, article 1517**. It selects `harmonics-fourier-lab`. If another manifest exists, merge this ID into its `resources` array rather than replacing other resources (maximum four). No database migration, production Julia installation, new service, or article rerender is required. This PR does not attach the resource to the production article automatically.

Original software is GPLv3 or later. Explanation, figures, data, and original synthesized audio are CC BY-SA 4.0. Third-party licenses are included. Web Audio API references: [createPeriodicWave](https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/createPeriodicWave) and [resume](https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/resume).
