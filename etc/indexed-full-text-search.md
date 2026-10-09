# Indexed native full-text search (PR3)

## Scope

This extends PR1 with an optional MariaDB/InnoDB FULLTEXT sidecar. It indexes
public encyclopedia prose from the original LaTeX, and the descriptions/abstracts
of public books, papers, and lectures. It does not index uploaded PDFs, private
collaborations, drafts, messages, or mail. Pandoc's LaTeX/HTML readers produce
plain text without running TeX, make4ht, Ghostscript, ESSEX, or article rendering.
Indexing does not touch rendering caches or the cross-reference word index.

The background worker runs separately from Apache, with a nonblocking database
advisory lock, a five-document default batch, and bounded input/output. There is
no new search daemon and no full-corpus allocation in an Apache worker. Modern
MariaDB FULLTEXT provides the inverted index; the existing metadata query remains
as a fallback and a stronger ranking tier. This preserves Krowne's distinction
between named concepts and incidental body mentions, not his historical ESSEX
implementation. See [native-search.md](native-search.md) for that architecture.

## Matching and freshness

- Exact titles, synonyms, defined concepts, title phrases, authors, and keywords
  retain PR1's ranking tiers. Body-only matches come last, ranked by MariaDB's
  relevance score. Ties use title, collection, and UID.
- All query atoms must match; quotes require a contiguous phrase after common
  punctuation normalization. A generated positive Boolean query retrieves index
  candidates; literal checks on those candidates enforce phrases and short words.
  User-supplied Boolean operators, SQL wildcards, and regexes are not interpreted.
- Stopwords are disabled for this index only when it is created. The worker
  requires InnoDB's default token limits of 3 and 84 characters. Queries consisting
  entirely of one/two-character or overlong words use metadata only. Mixed queries
  can match short words in prose, verified after longer indexed terms select
  candidates. No stemming, typo repair, semantic expansion, or PDF extraction yet.
- Current anonymous ACLs, object existence, article revision, and modification
  time are checked before counts and pagination, even when logged in. Private or
  deleted content cannot be exposed by an old index copy. Pruning removes those
  copies in bounded batches; it need not run for search privacy to take effect.
- New/edited metadata is immediately searchable through PR1. New/edited prose
  appears after the next worker pass. Older article revisions do not supply body
  hits/snippets. Resource editing updates `modified` and removes its old search
  document, including same-second edits; invalidation failures are logged without
  aborting the content edit. The worker rechecks unchanged documents daily as a
  repair sweep. Out-of-band SQL edits must update `modified`/article `version`,
  or explicitly reindex the object.
- The worker re-reads public content after conversion and defers changed records.
  Search also checks live ACLs/revisions to cover changes racing the final write.
  Failed conversions retry after an hour; oversized documents retain metadata
  search and a visible `oversize` operational status. Neither blocks the queue.
- Results stay at 20 per page. Snippet queries return at most 20 windows of 360
  characters, not entire bodies. Plain-text windows are HTML-escaped and then
  highlighted. Search still returns `noindex, follow` and canonical article links.

## Prerequisites

Keep `NATIVE_FULLTEXT_ENABLED` off until these steps are complete. Deploying this
PR alone keeps metadata-only search working, without referencing a missing table.

1. Use MariaDB with InnoDB FULLTEXT support and DBD::mysql (tested with MariaDB
   10.6.23). PostgreSQL deployments keep metadata-only search.
2. Install a trusted Pandoc build supporting `--sandbox` (2.15 or newer), available
   to `apache`; set the non-secret `SEARCH_PANDOC` option to its absolute executable
   path if not `/usr/bin/pandoc`. No Lua filters, preambles, external includes,
   network fetches, or rendering tools are supplied to it. Test the parser before
   enabling the worker. Old builds fail the readiness check without writing.
3. Confirm UTF-8 content/connection settings. The worker uses `SET NAMES utf8mb4`;
   index columns use `utf8mb4_unicode_ci`. Search explicitly handles UTF-8 bindings
   and snippet bytes on the legacy undecoded mysql connection too. Existing
   mojibake in source data is not repaired by this PR.
4. In an authorized database session, check:

```sql
SELECT VERSION(), @@innodb_ft_min_token_size, @@innodb_ft_max_token_size;
SHOW VARIABLES LIKE 'character_set%';
```

Expected token sizes are 3 and 84. Do not change global settings or rebuild other
indexes as part of this rollout. Apply `db/search-documents.mysql.sql` in the site
database using the normal database-administration workflow. It creates only the
new sidecar, temporarily disables session stopwords for that index's creation,
and restores the prior session setting. `CREATE TABLE IF NOT EXISTS` is rerunnable;
it does not repair a pre-existing table with a different schema or stopword setup.
The site's worker account needs SELECT on library/ACL tables, and SELECT/INSERT/
UPDATE/DELETE on `search_documents`. Queries use the current configured names.

## Backfill and operation

From `/var/www/pp`, inspect a dry run, then a small applied batch:

```sh
sudo -u apache perl -Ilib bin/update-search-index --limit 5
sudo -u apache perl -Ilib bin/update-search-index --apply --limit 5
sudo -u apache perl -Ilib bin/update-search-index --status
```

Dry runs do not invoke Pandoc or write. `--status` reports stored index counts by
collection/status and oldest/newest indexing times, not live searchable totals.
Applied runs report `ready`, `oversize`, or `failed` IDs and a summary, never body
text. Source and output are capped at 262,144 bytes per document. Pandoc gets a
15-second timeout (TERM then KILL after two seconds) and private temporary files.
The unit additionally limits CPU to 20%, memory to 256 MB, file size to 4 MB, and
duration to 180 seconds. Unparseable/custom-macro content may lose text; compare
representative documents against their displayed articles. No raw-source fallback
or automatic render is used.

Install and start the supplied opt-in timer using the normal unit workflow:

```sh
sudo install -m 0644 etc/systemd/physicslibrary-search-index.service /etc/systemd/system/
sudo install -m 0644 etc/systemd/physicslibrary-search-index.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now physicslibrary-search-index.timer
sudo journalctl -u physicslibrary-search-index.service -n 30 --no-pager
```

At five documents per two-minute pass, 1,300 articles alone take roughly nine
hours to backfill; all collections take longer. For a supervised initial backfill,
run successive bounded `--apply --limit 20` batches, checking health between them.
Maximum accepted batch size is 50; avoid an unbounded loop. The lock prevents
timer/manual overlap. An explicit object bypasses the normal freshness/cooldown
selection and permits a targeted retry:

```sh
sudo -u apache perl -Ilib bin/update-search-index --apply --collection objects --object 209
sudo -u apache perl -Ilib bin/update-search-index --apply --collection papers --object 142
```

Check `ready` coverage and investigate `failed`/`oversize` entries. Do not enable
full text until the backfill and representative searches are verified. Then set
the non-secret `NATIVE_FULLTEXT_ENABLED => 1` in the existing site configuration
and refresh Apache's loaded modules using the normal deployment procedure. Search
and the indexer never perform that restart themselves. Confirm:

```sh
curl --max-time 10 -sSI 'https://physicslibrary.org/?op=search&q=Calculus+of+Variations'
sudo grep -a 'PL_SEARCH ' /var/log/httpd/error_log | tail -20
sudo tail -n 10 /var/log/physicslibrary/health.tsv
```

Exact titles must stay first. Test a term found only in article prose, a quoted
phrase, a PACS filter, and an abstract-only resource match. Compare CPU, available
memory, worker occupancy, and latency. Enabled search with a missing/broken table
returns a sanitized 503, not misleading partial full-text results. Disable the
flag to restore metadata-only search immediately, then refresh loaded modules;
stop the timer if needed. Leaving the additive table in place is harmless.

## Validation

```sh
prove bin/test/native-search.t bin/test/search-index.t bin/test/noindex-routes.t
# Parser cases require a Pandoc with --sandbox support:
SEARCH_TEST_PANDOC=/usr/bin/pandoc prove -v bin/test/search-index.t
# Dedicated disposable database only, ending in _test; test tables are dropped:
FULLTEXT_TEST_DSN='dbi:mysql:database=pl_search_test;mysql_socket=/path/to/test.sock' \
  SEARCH_TEST_PANDOC=/usr/bin/pandoc prove -v bin/test/full-text-search-mariadb.t
# Optional real-engine synthetic benchmark and browser fixture:
FULLTEXT_TEST_DSN='dbi:mysql:database=pl_search_test;mysql_socket=/path/to/test.sock' \
  SEARCH_TEST_PANDOC=/usr/bin/pandoc FULLTEXT_BENCH=1 \
  FULLTEXT_SEARCH_QA_DIR=tmp/native-search-qa prove -v bin/test/full-text-search-mariadb.t
NATIVE_SEARCH_QA_DIR=tmp/native-search-qa prove bin/test/native-search.t
node bin/test/native-search-browser.cjs
```

The real-engine test covers the actual FULLTEXT query plan, literal phrase and
short-token checks, ranking, UTF-8/collations, current ACLs, edit/delete races,
bounded pruning, same-second resource invalidation, real CLI status/dry-run/lock/
parsing, and feature-off behavior. Engine tests skip without an explicitly supplied
disposable DSN; portable SQLite metadata tests do not validate MariaDB FULLTEXT.
A local 1,500-document synthetic MariaDB run measured approximately 0.08 seconds
for count/page/snippets. This is not production latency or a production memory
benchmark. CLI status and health snapshots remain important during rollout.

References: [MariaDB FULLTEXT overview](https://mariadb.com/docs/server/ha-and-performance/optimization-and-tuning/optimization-and-indexes/full-text-indexes/full-text-index-overview),
[Pandoc sandbox](https://pandoc.org/MANUAL.html#option--sandbox).
