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

The sitemap queries article IDs and names, not LaTeX source or rendered caches.
It uses the same canonical URL helper as article views and removes duplicate
URLs. For ACL-controlled articles, it requires a world-readable default rule
and conservatively excludes conflicting defaults and matching anonymous read
denials. Private or unnamed articles are omitted. Search/listing pages, synonym
aliases, old versions, papers, books, lectures, and cache assets are not included.
It does not include `lastmod`: no render, hit, or generation timestamp is passed
off as a significant article modification date.

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
