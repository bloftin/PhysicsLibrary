# Computational resources on articles

Keep the mathematical article type (Example, Topic, Definition, etc.). Julia is
the language of a resource, not a new article type. A compact Computational
Resources section appears below View style and above article metadata when an
encyclopedia entry's saved filebox contains `computational-resources.json`.
It is independent of the selected HTML/PDF/PNG/source renderer and its cache.
It does not modify the downloaded PDF; the oscillator's supplied article body
already includes a link for PDF readers.

For an author-facing collaboration/site documentation draft, see
`docs/computational-resources-author-guide.tex`. It is written as PL-friendly
LaTeX body text that can be pasted into a collaboration object.

For maintainer review and release checks, see
`docs/computational-resources-maintainer-checklist.md`.

The second worked resource is `examples/newton-constant-acceleration/`: a
Newton's second law Example with double integration, explicit initial conditions,
three saved force cases, and an offline explorer. Its README includes publication
steps; `data/examples/newton-constant-acceleration/article-attachments.zip`
contains the LaTeX draft, preamble, figure and filebox manifest.

## Publish the oscillator Example

1. Create an Example titled **Three Damping Regimes of a Harmonic Oscillator**
   under the appropriate existing harmonic-motion article. If already created,
   edit that entry instead of creating a duplicate.
2. Use `examples/julia-oscillator/preamble.tex` and `article.tex` in the editor's
   preamble and body fields.
3. Attach `data/examples/julia-oscillator/comparison.png` and
   `examples/julia-oscillator/computational-resources.json` through the existing
   filebox. Keep both filenames unchanged, then save the article normally.
4. View the saved article. Expect one Computational Resources section containing
   Damped Harmonic Motion, Julia 1.10.12, the explorer, ZIP, provenance, license
   and three CSV links. Follow them and confirm they load on the image host.
   The license notice should identify software files as GPLv3 and article/math
   materials as Physics Library CC BY-SA.
5. Check HTML and PDF views. The surrounding section should remain present in
   both. Preview/render the article itself using the normal make4ht/PDF tools.

No production article or account IDs are hardcoded. The integration uses the
article record selected by the existing read-permission path. Filebox edits
retain their existing authorization and CSRF checks. The section appears on
the saved article, not the editor's LaTeX-only preview. A plain page reload is
sufficient after saving the manifest; no rerender is required for this section.

To detach resources, remove `computational-resources.json` through the filebox
and save. The article and its other attachments remain unchanged.

## Attach one or more publications

The author-controlled manifest selects one to four reviewed catalog IDs:

```json
{
  "schema_version": 1,
  "resources": ["julia-oscillator"]
}
```

To attach several resources to the same article, list the catalog IDs in the
order they should appear:

```json
{
  "schema_version": 1,
  "resources": [
    "newton-constant-acceleration",
    "julia-oscillator"
  ]
}
```

This is useful when one article has a short starter computation, a deeper
simulation, and later perhaps a notebook export. Duplicates are ignored, unknown
IDs are omitted, and the uploaded manifest still cannot provide display text,
URLs or executable instructions. All public labels and links continue to come
from the reviewed catalog.

Maintainers add reviewed, prebuilt publications to
`etc/computational-resources.json` through a normal code review. Each entry has
title, language, version, reproducibility text, explorer/source/provenance/license
filenames, and zero to eight labeled CSV datasets. Filenames are relative to
`data/examples/<catalog-id>/`; links use the configured HTTPS `image_url` host,
with `/examples/` replacing `/images`. Publish the referenced static files in
that directory before attaching its ID to an article. Nothing is fetched or
computed by the server to inspect resources.

The initial catalog supports self-contained HTML explorers, ZIP projects,
TOML provenance, text licenses and CSV datasets. Computational source bundles
should carry a software license, while article-style exposition, mathematical
text, figures and result data should keep the Physics Library article license
unless a publication deliberately states otherwise. Additional languages can
use the same presentation. Other artifact formats should be added deliberately
with validation and tests, not by allowing arbitrary uploaded links or markup.

Unknown IDs and invalid catalog entries are omitted. A malformed, oversized or
unsupported manifest suppresses the section without breaking the article.
Manifest reads are capped at 8 KiB; the catalog is capped at 64 KiB. Resource
selection is not an endorsement of an article's claims or proof that its author
produced the computation. Source archives should only be run after review.

## Production checkout and tests

The `inclined-plane` publication adds a release-from-rest example with a moving
block, force vectors, three friction cases, and an accompanying LaTeX derivation.
Its author attachment bundle is `data/examples/inclined-plane/article-attachments.zip`;
setup and reproduction steps are in `examples/inclined-plane/README.md`.
It can share an article's manifest with the Newton and oscillator resources.

Preserve any local changes reported by `git status` before switching branches.

```bash
cd /var/www/pp
git status --short
git fetch origin
git switch codex/computational-resources
git pull --ff-only
sudo -u apache prove -v bin/test/computational-resources.t
sudo -u apache perl -Ilib -c lib/Noosphere/ComputationalResources.pm
python3 examples/julia-oscillator/verify.py
sudo apachectl configtest
sudo systemctl restart httpd
```

No database migration or Julia installation is needed. Unlike the preceding
static explorer PR, this change loads a Perl module, so restart httpd after a
successful configuration check.

Manual checks after publishing the oscillator:

- Signed out: the public article's resource links work without starting jobs.
- Switch HTML, PDF, PNG and source: resources remain in the surrounding page.
- An unrelated article has no resources heading or extra blank section.
- Remove the manifest and save: the section disappears. Restore and save it.
- Desktop and mobile: the links wrap without changing article layout.
- Adding a second approved catalog ID produces another resource in the same
  section; duplicate IDs do not produce duplicate entries.

For diagnosis, inspect the saved manifest in
`data/files/objects/ARTICLE_ID/computational-resources.json`, not a render cache
or an editor temporary directory. Verify it is a regular file readable by
apache, matches the schema above and selects an ID present in the catalog.
Existing files and cached TeX output are not deleted by this feature.
