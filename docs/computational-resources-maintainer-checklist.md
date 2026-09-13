# Computational Resources Maintainer Checklist

This checklist is for reviewing a new static computational resource before it is
listed in `etc/computational-resources.json` and attached to a Physics Library
article. It complements the author-facing guide in
`docs/computational-resources-author-guide.tex`.

Computational resources are reviewed publication artifacts, not a live execution
service. A page view, filebox upload, article save, rerender, or explorer control
must not run submitted code on the server.

## Intake Questions

Before adding a catalog entry, confirm:

- The resource supports an existing or planned article and does not replace the
  mathematical exposition.
- The article type remains mathematical, such as Example, Topic, Definition or
  Proof. Julia, Python, Sage or another tool is the resource language, not the
  article type.
- The supplied files are static artifacts suitable for `data/examples/<id>/`.
- The author explains what was computed, which parameters were fixed, which
  parameters varied, and what limitations apply.
- A reader can understand the article without enabling JavaScript or running the
  source project.

## Catalog Id And Files

Choose a stable catalog id:

- lower-case ASCII letters, digits and hyphens only;
- starts with a letter or digit;
- short enough to read comfortably in URLs;
- descriptive of the publication, not of a temporary branch or ticket.

Place static publication files under:

```text
data/examples/<catalog-id>/
```

The first supported file set is:

- `index.html` for the static explorer;
- a source archive such as `<catalog-id>.zip`;
- `provenance.toml`;
- `LICENSE.txt`;
- zero to eight CSV datasets;
- optional static images used by the explorer.

Do not list arbitrary external URLs in the catalog. Links are derived from the
configured image host and the local files under `data/examples/<catalog-id>/`.

## Manifest

The author-facing filebox manifest should be small and boring:

```json
{
  "schema_version": 1,
  "resources": ["catalog-id"]
}
```

The manifest filename must be exactly:

```text
computational-resources.json
```

The manifest selects reviewed catalog ids only. It must not contain display
HTML, external URLs, labels, scripts or executable instructions.

## Review The Source Bundle

Before approving a source archive:

- Extract it locally in a disposable directory.
- Confirm it contains the source, tests, environment/runtime notes and license.
- Confirm it does not contain secrets, production configuration, database dumps,
  private keys, session tokens, passwords or hidden credential files.
- Confirm the build/test instructions do not require Physics Library production
  credentials.
- Run the included tests when practical.
- Confirm any generated data can be reproduced from the supplied source or that
  the limitation is clearly documented.
- Confirm large binary outputs are intentional and reasonably sized.

The reviewed source archive may contain code for readers to run locally. It
must not create a path for the Physics Library web server to execute that code
in response to traffic.

## Review The Explorer

For an HTML explorer:

- Open it directly from disk without a development server.
- Test desktop and narrow mobile widths.
- Disable JavaScript and confirm there is still a useful fallback when the
  resource claims one.
- Confirm controls operate on saved data, not by posting jobs to the site.
- In browser developer tools, move controls and confirm no unexpected network
  requests are made.
- Confirm there are no forms, polling loops, remote fonts, trackers or embedded
  third-party scripts.
- Confirm link text and headings fit without horizontal page scrolling.

Static image requests for local saved assets are expected. POST requests,
render-route calls, filebox calls, login/account calls, or server-side compute
jobs are not expected.

## Provenance And Reproducibility

The provenance file should record enough information for later review:

- language and version;
- operating system or build environment when relevant;
- important package versions;
- source hashes and generated artifact hashes;
- command lines or scripts used to create the publication;
- date or release identifier.

For numerical work, prefer independent checks: analytic comparisons, conserved
or monotone quantities, boundary/initial conditions, regression tests, or
duplicate implementations of key formulas.

## Licensing

Use a software license for executable source. For Physics Library computational
bundles, the recommended default is GPLv3 or later.

Keep article-like material under the normal Physics Library article terms unless
a resource deliberately states otherwise:

- mathematical exposition and article text: Physics Library CC BY-SA;
- plots and explanatory figures: Physics Library CC BY-SA;
- result CSV data: Physics Library CC BY-SA by default;
- source code, build scripts, browser scripts and tests: GPLv3 or later.

The `LICENSE.txt` shipped in the publication and source archive should say this
plainly.

## Catalog Entry Review

Each entry in `etc/computational-resources.json` should contain only reviewed
metadata:

```json
{
  "title": "Damped Harmonic Motion",
  "language": "Julia",
  "version": "1.10.12",
  "reproducibility": "Short plain-text summary.",
  "explorer": "index.html",
  "source": "julia-oscillator.zip",
  "provenance": "provenance.toml",
  "license": "LICENSE.txt",
  "datasets": [
    {"label": "Underdamped", "file": "underdamped.csv"}
  ]
}
```

Check that:

- every referenced file exists under `data/examples/<catalog-id>/`;
- file names are plain relative names, not paths or URLs;
- title, language, version and reproducibility text are concise;
- dataset labels are human-readable;
- duplicate catalog ids are not introduced;
- the section still renders when unrelated articles have no manifest.

## Local Checks

For the existing integration, run:

```bash
prove -v bin/test/computational-resources.t
perl -Ilib -c lib/Noosphere/ComputationalResources.pm
python3 examples/julia-oscillator/verify.py
```

For a new resource, add a resource-specific verification script when possible.
It should verify local links, hashes, archive contents, size limits and the
absence of live execution hooks.

Also run:

```bash
git diff --check
```

## Production Checks

After checkout on production:

```bash
cd /var/www/pp
git status --short
git fetch origin
git switch <branch>
git pull --ff-only
sudo -u apache prove -v bin/test/computational-resources.t
sudo -u apache perl -Ilib -c lib/Noosphere/ComputationalResources.pm
python3 examples/julia-oscillator/verify.py
sudo apachectl configtest
sudo systemctl restart httpd
```

If a PR only changes static files and documentation, restart may not be needed.
If it changes Perl modules, templates loaded by Apache, or the catalog used by
the running app, restart after a successful config test.

Manual production checks:

- Open the static explorer on `images.physicslibrary.org`.
- Open the saved article signed out.
- Confirm the Computational Resources section appears after saving the manifest.
- Switch HTML, PDF, page images and source views.
- Open explorer, source ZIP, provenance, license and CSV links.
- Open an unrelated article and confirm no empty resources section appears.
- Remove the manifest from a test article and save; the section should disappear.

## Things To Reject Or Defer

Reject or defer a resource if it requires:

- executing uploaded code on the web server;
- arbitrary external URLs supplied by article authors;
- production credentials or private configuration;
- remote scripts, trackers or third-party embedded code;
- unbounded downloads or unusually large files without a clear reason;
- unexplained numerical results;
- a license that conflicts with the source or article materials;
- a manifest that tries to override reviewed catalog metadata.

When a resource needs something outside the first static catalog model, add a
new validation path and tests deliberately. Do not loosen the existing catalog
rules just to make one publication fit.
