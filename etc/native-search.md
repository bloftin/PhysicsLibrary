# Native library search (PR1)

The header now sends `op=search&q=...` to a server-rendered search page. Root
Google-style bookmarks with `q`, `cx`, `cof`, `ie`, and `sa` use the same handler.
Explicit operations such as `listobj` and `getobj` retain their own behavior.
The header no longer loads Google scripts. Google indexing is a separate concern:
search pages remain `noindex, follow`, and article links use canonical URLs.

## Scope and ranking

Search defaults to the encyclopedia, with Papers, Books, Lectures, and All
library collections available. Only publicly readable library objects appear,
even when logged in. Private objects are excluded before counting and pagination,
using the sitemap's conservative anonymous ACL policy. This is not a private
workspace search.

Encyclopedia matching uses title, synonyms, defines, and keywords. Other library
collections use title, authors, and keywords. All query terms must match metadata;
quoted terms require a contiguous phrase after common punctuation normalization.
Percent and underscore are literal, not SQL wildcards. One- and two-character
alphanumeric terms match whole words to keep acronyms such as EM useful.

The ranking tiers, in descending order, are:

1. Exact normalized title.
2. Exact synonym, then exact defined-concept label in `objindex`.
3. Title phrase, then all terms in the title.
4. Defined-concept phrase, then synonym or resource-author phrase.
5. Keyword phrase, then terms distributed across metadata.

Ties use title, collection, and UID for stable pagination. Each object appears
once, regardless of how many concept labels or classifications match. Body-only
terms, fuzzy spelling, transliteration, stemming, and semantic expansion are
intentionally left for a measured full-text follow-up. Authors on encyclopedia
articles are not searched in this first version.

## How metadata steers search

- **Title:** the primary concept name; direct title matches take priority.
- **Synonyms:** genuine alternate names, spellings, or abbreviations for the same
  concept. For example, a plural Atwood-machine title can have the synonym
  `Atwood machine`.
- **Defines:** named concepts explained inside an article that deserve their own
  index entries. For example, an article can define `center of mass relation`
  without that phrase being its title. These are also cross-linking targets.
- **Keywords:** topical terms that aid discovery, not arbitrary unrelated search
  bait. Matching keywords is deliberately weaker than matching a concept title.
- **PACS:** an explicit subject filter. A parent category includes its descendants
  through the existing `catlinks` transitive closure, with namespace checks.
  PACS is stored in the legacy `msc` namespace/table; it is not a new namespace.

The page shows matching metadata and related PACS subjects. Clicking a subject
shows all public entries in that subject within the selected collection; adding
text to the form intersects the query with that subject. No automatic subject
guess silently excludes an exact title result. Edits to primary metadata become
searchable immediately without an index rebuild. Exact synonym/defines tiers use
the normal concept index maintained by the existing article editing workflow.

## Krowne's architecture

Source: Aaron Krowne, [An Architecture for Collaborative Math and Science Digital
Libraries](https://aux.physicslibrary.org/files/papers/142/An%20Architecture%20for%20Collaborative%20Math%20and%20Science%20Digital%20Libraries%20-%20Krowne.pdf),
Chapter 12, *Information Access*. Page references below are printed thesis pages,
not PDF viewer page numbers (the PDF has 22 preceding pages).

- Pages 229-232 describe ESSEX and a separate query-repair service, rather than a
  complete search index copied into every Apache process.
- Table 12.1, page 234, gives title weight 10; defines and authors 5; synonyms 3;
  keywords 2; related terms and body 1. Concept labels outrank incidental body
  mentions. PR1 preserves that distinction with explicit ranking tiers, not an
  identical implementation of the historical numerical formula.
- Page 237 describes a query-repair lexicon built from concept labels and
  classification metadata. This informs a later spelling-suggestion feature;
  PR1 does not implement or silently apply corrections.
- Pages 238-239 describe classifications, namespace-aware ancestor/descendant
  links, and title/synonym/defines concept-index entries. PR1 reuses these tables.

The thesis explicitly favored a dedicated indexing service over its contemporary
DBMS for full-text search. PR1 is deliberately narrower: current-size metadata
queries, not a reimplementation of ESSEX or a claim that SQL scans replace a
large full-text engine. A future full-text index should be built outside request
workers, benchmarked, and updated independently of LaTeX rendering.

## Operational limits

No schema migration, service, API key, search-result writes, rendering, or
cross-reference rebuild is required. Query text is limited to 256 Unicode
characters and eight terms/phrases. The page fetches at most 20 objects, 201
classification rows, and five subject suggestions. Offset is limited to 2000.
There are four SQL calls for a normal populated query, five with a PACS filter;
the count and result queries do not load article source or preambles into Perl.

These limits bound application allocations, not database scan time. Normalized
`LIKE` matching still scans metadata; measure it on production-sized MariaDB
data before extending this to more collections or full text. Slow requests over
0.5 seconds emit `PL_SEARCH slow` with duration, collection, query length, and
result count, but not the user's search text. DB failures return a sanitized
503 page. Invalid input and unknown PACS codes return 400 rather than silently
running an unfiltered query.

## Validation and rollout

```sh
prove bin/test/native-search.t bin/test/header-polish.t bin/test/noindex-routes.t
# Optional portable fixture benchmark, not production timing:
NATIVE_SEARCH_BENCH=1 prove -v bin/test/native-search.t
# Optional browser QA; requires Playwright and a local Chromium/Edge browser:
NATIVE_SEARCH_QA_DIR=tmp/native-search-qa prove bin/test/native-search.t
node bin/test/native-search-browser.cjs
```

The focused fixture test uses DBI/SQLite, Template Toolkit, and XML::LibXML. It
checks ranking, literal query binding, Unicode, public ACLs, pagination, PACS
descendants, generic collections, real view dispatch for old URLs, and failure
states. SQLite's ASCII-only LOWER is replaced in the fixture to emulate Unicode
lowercasing. It does not substitute for testing the production MariaDB collation
and Apache/mod_perl deployment.

After normal deployment and refreshing Apache's loaded Perl modules, check:

```sh
curl --max-time 10 -sS -o /dev/null \
  -w 'HTTP %{http_code}; %{time_total}s\n' \
  'https://physicslibrary.org/?op=search&q=Vector+Triple+Product'
curl --max-time 10 -sSI \
  'https://physicslibrary.org/?op=search&q=Calculus+of+Variations'
sudo grep -a 'PL_SEARCH ' /var/log/httpd/error_log | tail -20
```

Confirm the direct article is first, quoted titles work, a known synonym resolves
its article, resource-author searches work, and PACS `02-XX` includes descendants.
Check `X-Robots-Tag: noindex, follow`, then compare CPU, available memory, and
request time against the existing health snapshots. Keep canonical/sitemap work
for external search engines separate; native search does not guarantee Google
indexing. Rollback is a normal revert of this PR and refresh of loaded modules.
