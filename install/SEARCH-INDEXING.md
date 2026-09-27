# Search result indexing

Internal search results should not compete with published content in external
search engines. The shared `applyIndexingPolicy` in `lib/Noosphere.pm` sets
`X-Robots-Tag: noindex, follow` and the page template adds the equivalent robots
meta tag for:

- `op=listobj` listings for encyclopedia objects, papers, books, and lectures,
  including unfiltered, sorted, and paginated listings without a `q` parameter.
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
