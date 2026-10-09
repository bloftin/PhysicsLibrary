# Search result indexing

Internal search results should not compete with published content in external
search engines. The shared `applyIndexingPolicy` in `lib/Noosphere.pm` sets
`X-Robots-Tag: noindex, follow` and the page template adds the equivalent robots
meta tag for:

- `op=listobj` listings for encyclopedia objects, papers, books, and lectures,
  including unfiltered, sorted, and paginated listings without a `q` parameter.
- The Papers, Books, and Lectures landing aliases `op=browse;from=papers`,
  `op=browse;from=books`, and `op=browse;from=lec`, which use those listings.
- `op=search`, `oldsearch`, `adv_search`, and `pacssearch`.
- `op=getrefs` reference-list utility pages; their links remain followable.
- Google Custom Search results using the front-page template (`sa=Search`).

The policy uses parsed operations, not raw query-string patterns, so parameter
ordering and the site's ampersand/semicolon separators do not affect it.
Individual `getobj` pages, friendly encyclopedia article URLs, the ordinary
homepage, alphabetical indexes, and subject browsing retain their existing
indexing behavior. This is not access control or bot rate limiting; users can
still browse/search, and crawlers can follow links to the published content.

## Deployment and verification

After merging, pull main and run `prove bin/test/noindex-routes.t`. That test
requires the site's Template Toolkit dependency. Deploy the Perl/template change
with a syntax check and a brief Apache stop/start; this interrupts requests:

```bash
sudo httpd -t && sudo systemctl stop httpd && sudo systemctl start httpd
curl --max-time 10 -sSI 'https://physicslibrary.org/?from=objects&offset=910&op=listobj&total=1119&sort=created_desc'
curl --max-time 10 -sSI 'https://physicslibrary.org/?op=listobj;from=papers'
curl --max-time 10 -sSI 'https://physicslibrary.org/?op=listobj;from=books'
curl --max-time 10 -sSI 'https://physicslibrary.org/?op=listobj;from=lec'
curl --max-time 10 -sSI 'https://physicslibrary.org/?cx=d7c37e2bb0d444808&cof=FORID%3A10&ie=UTF-8&q=polar&sa=Search'
curl --max-time 10 -sSI 'https://physicslibrary.org/'
```

The five search/list responses should include `X-Robots-Tag: noindex, follow`.
The plain homepage should not. Check an existing published article as a second
positive control. No database migration, scheduled job, or cache rebuild is
needed.

## Google Search Console

Do not add robots.txt disallows for these search routes: Google must fetch the
response to see `noindex`. Existing search results are not removed immediately;
Google needs to recrawl them. Use URL Inspection to verify the response and
monitor the Page Indexing report. For urgent removal, use Search Console's
temporary removal tool for specific unwanted URLs, not a broad homepage prefix
that could hide published content too.

Google's documentation:
https://developers.google.com/search/docs/crawling-indexing/block-indexing

## Canonical encyclopedia URLs

Successful encyclopedia article views declare one absolute `rel="canonical"`
link in the document head, including the friendly URL itself. ID links, name
links, legacy paths, and view-style/discussion parameters all identify the same
preferred URL:

```html
<link rel="canonical" href="https://physicslibrary.org/encyclopedia/VectorTripleProduct.html" />
```

The URL uses the configured `main_url` and the resolved article's stored `name`,
not the request hostname or supplied name/URL. Missing articles, permission
failures, unnamed records, other object types, and helper/listing pages do not
declare an encyclopedia canonical. Metadata is scoped to each mod_perl request.
This adds no database query, redirect, rendering task, migration, or scheduled
job; existing article links and view styles continue to work.

After pulling main, run these checks and deploy with the Apache stop/start
shown above:

```bash
prove bin/test/canonical-article-urls.t bin/test/noindex-routes.t
curl --max-time 10 -fsS 'https://physicslibrary.org/encyclopedia/VectorTripleProduct.html' | grep 'rel="canonical"'
curl --max-time 10 -fsS 'https://physicslibrary.org/?op=getobj&from=objects&id=209&method=l2h' | grep 'rel="canonical"'
curl --max-time 10 -fsS 'https://physicslibrary.org/encyclopedia/ScalarTripleProduct.html' | grep 'rel="canonical"'
```

Both Vector Triple Product responses should declare the same friendly URL;
Scalar Triple Product should declare its own. No article cache rebuild is
needed because the canonical is in the outer page template, not rendered LaTeX.
Google must recrawl before its stored user-declared canonical reflects this
change. Canonical annotations express a preference, not an indexing guarantee,
and do not establish why an article was previously excluded. In Search Console,
use URL Inspection's live test to check the delivered HTML, then monitor the
indexed inspection's user-declared/Google-selected canonical after recrawling.

Google's canonical URL guidance:
https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls

## Article XML sitemap

`https://physicslibrary.org/sitemap.xml` serves a UTF-8 XML sitemap of preferred
encyclopedia article URLs. `robots.txt` advertises that address using the
configured `main_url`, not the request's Host header.

The sitemap queries article IDs, names, and stored modification dates, not
LaTeX source or rendered caches.
It uses the same canonical URL helper as article views and removes duplicate
URLs. For ACL-controlled articles, it requires a world-readable default rule
and conservatively excludes conflicting defaults and matching anonymous read
denials. Private or unnamed articles are omitted. Search/listing pages, synonym
aliases, old versions, papers, books, lectures, and cache assets are not included.
`lastmod`, when available, uses the article's stored `modified` date. Article
creation and content edits already write this field; rendering, hits, and
sitemap generation do not replace it. Unknown, zero, invalid, or future dates
are omitted. Dates are emitted as `YYYY-MM-DD` because the historical database
timestamp has no reliable timezone contract. A date later than today's UTC
date is conservatively omitted until that day, rather than inventing a timezone.

New public articles appear, and deleted or newly private articles disappear,
on the next sitemap fetch. No migration, cron job, systemd unit, generated file,
or article rerender is required. The response bypasses login, statistics,
templates, and rendering. GET and HEAD are supported. Database/generation
failures return HTTP 503 instead of a partial sitemap or homepage. Responses
use `no-store` so a previously public URL is not kept in a cached sitemap.
The single-file implementation checks the 50,000-URL / 50 MiB protocol limits
and returns 503 rather than silently truncating; add sitemap-index splitting
before the encyclopedia reaches those limits.

After pulling main:

```bash
prove bin/test/article-sitemap.t bin/test/canonical-article-urls.t bin/test/noindex-routes.t
sudo httpd -t && sudo systemctl stop httpd && sudo systemctl start httpd
curl --max-time 10 -fsSI 'https://physicslibrary.org/sitemap.xml'
curl --max-time 10 -fsS 'https://physicslibrary.org/robots.txt' | grep '^Sitemap:'
curl --max-time 10 -fsS 'https://physicslibrary.org/sitemap.xml' > /tmp/physicslibrary-sitemap.xml
perl -MXML::LibXML -e 'my $d = XML::LibXML->load_xml(location => shift); my $x = XML::LibXML::XPathContext->new($d); $x->registerNs(s => "http://www.sitemaps.org/schemas/sitemap/0.9"); my @urls = $x->findnodes("/s:urlset/s:url"); print scalar(@urls), " article URLs\n";' /tmp/physicslibrary-sitemap.xml
grep -E 'VectorTripleProduct.html|ScalarTripleProduct.html' /tmp/physicslibrary-sitemap.xml
```

The HEAD response should be HTTP 200 with `application/xml;charset=UTF-8`, not
HTML or a `noindex` header. Both example URLs should be present if their
articles are public. The test uses the site's existing XML::Writer/XML::LibXML
dependencies; optional isolated SQL integration also requires DBI/DBD::SQLite,
but the production sitemap does not require SQLite.

In Google Search Console, select the Physics Library property, open **Sitemaps**,
submit `https://physicslibrary.org/sitemap.xml`, and check its fetch status and
discovered URL count. In Bing Webmaster Tools, select the site, open **Sitemaps**,
and submit the same URL. For Vector Triple Product and Scalar Triple Product,
use Google's URL Inspection live test and request indexing after verifying
their article responses and canonicals. Sitemap discovery helps crawlers find
preferred URLs; it does not guarantee inclusion or an immediate recrawl.

References:

- [Google: Build and submit a sitemap](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)
- [Bing: Sitemaps](https://www.bing.com/webmasters/help/sitemaps-3b5cf6ed)
- [Sitemaps protocol and limits](https://www.sitemaps.org/protocol.html)

## Article descriptions

HTML article views (`make4ht` and `l2h`) now include an escaped description in
the document head, drawn from the prose already fetched for that view. The
extractor runs before ownership, editing, and preamble controls are appended.
It uses HTML::Parser, inspects at most 65,536 characters of existing content,
and limits descriptions to 200 characters. It excludes navigation, headings,
scripts, styles, source/compiler blocks, hidden content, and math markup.
Incomplete parser tails are not flushed as text. Image-only, PDF, source,
short, and known rendering-placeholder views omit the description.

There is no additional database query, cache read, render, external request,
schema change, or scheduled job. Missing and permission-denied articles cannot
emit a prose description. Request-local metadata prevents one article's text
from leaking to another article, a search page, or the homepage under mod_perl.
The body, title, canonical URL, and existing viewing controls are unchanged.
Google may choose a different snippet; descriptions are not an indexing promise.

Validate after a deliberate deployment when the server is healthy:

```bash
prove bin/test/article-metadata.t bin/test/article-sitemap.t bin/test/canonical-article-urls.t bin/test/noindex-routes.t bin/test/article-box-modern.t
curl --max-time 10 -fsS 'https://physicslibrary.org/encyclopedia/VectorTripleProduct.html' | grep -E 'rel="canonical"|name="description"'
curl --max-time 10 -sSI 'https://physicslibrary.org/?op=getrefs&from=objects&id=209' | grep -Ei '^HTTP/|^X-Robots-Tag:'
```

The article should be 200 with its canonical and, for a prose HTML view, a
description. The reference list should send `X-Robots-Tag: noindex, follow`.
Keep it crawlable so engines can observe that directive; do not add a robots
disallow for it. If an article fetch hangs or fails, investigate availability
before asking search engines to crawl more pages.

## External coverage follow-up

The article sitemap was introduced on October 3, 2026. During the October 8
audit it was only about six days old; that is not evidence of an indexing
failure. Deployment time, sitemap submission time, and the last successful
crawler fetch can differ. Canonical/noindex changes also require recrawling.

The audit visibly found Vector Triple Product's canonical article on
DuckDuckGo, along with its BACK CAB alias and an old user-object listing.
That confirms visibility on that engine, not that all duplicate signals have
settled. A direct Bing coverage query encountered a verification challenge, so
Bing's article coverage was not independently confirmed. DuckDuckGo says its
traditional link results are largely sourced from Bing, making Bing Webmaster
Tools useful, but a DuckDuckGo result does not replace Bing URL Inspection.
Live site requests also timed out during an Apache availability incident;
cached search results cannot establish the site's current response headers.
After the owner's Apache restart, a bounded live recheck succeeded: robots.txt
advertised the sitemap, the sitemap returned 200 XML with 1,266 canonical
article URLs (including both triple-product examples), and Vector Triple
Product returned 200 with its self-canonical and no noindex header. It had no
description yet, which is addressed here. Those counts are an audit snapshot,
not a fixed expected total for future deployments.

Owner follow-up, once availability is stable:

1. In Google Search Console and Bing Webmaster Tools, verify the exact HTTPS
   property, submit `/sitemap.xml` if it has not already been submitted, and
   record the last successful fetch, errors, and discovered URL count.
2. Inspect Vector Triple Product and Scalar Triple Product individually.
   Compare the live fetch with the indexed/crawled version, its crawl date,
   allowed indexing, and selected versus declared canonical. Request indexing
   for these examples after confirming their healthy responses, not the whole
   site repeatedly.
3. Recheck the existing coverage report after a recrawl. Separate duplicate
   aliases and intentionally noindexed utility pages from genuinely excluded
   canonical articles. Keep a small dated sample instead of interpreting a
   `site:` search as a complete indexing inventory.
4. Review crawler access failures and Apache saturation alongside coverage.
   Do not remove crawl throttling, broadly allow `/cache/` or `/files/`, add
   automatic restarts, or trigger mass rendering as an SEO workaround.

No API key, automatic submission service, IndexNow registration, or old sitemap
ping endpoint is added by this change. Google and Bing dashboard submissions
and inspection require the site owner's account; they were not performed by
this PR. This is infrastructure for clearer discovery and snippets, not a
diagnosis that every excluded article lacks quality or a guarantee of indexing.

Additional primary references:

- [Google: Search snippets and meta descriptions](https://developers.google.com/search/docs/appearance/snippet)
- [Google: Troubleshoot crawling errors](https://developers.google.com/search/docs/crawling-indexing/troubleshoot-crawling-errors)
- [Google: Sitemap lastmod and retired ping endpoint](https://developers.google.com/search/blog/2023/06/sitemaps-lastmod-ping)
- [DuckDuckGo: Sources of search results](https://duckduckgo.com/duckduckgo-help-pages/results/sources)
- [Bing: Webmaster guidelines](https://www.bing.com/webmasters/help/webmaster-guidelines-30fba23a)
