# Early Apache 404s for scanner requests

The live HTTP and HTTPS virtual hosts include
`/var/www/pp/etc/httpd-scanner-404.conf` before routing and redirects. It returns
`404` with the fixed ten-byte body `Not found.` for PHP-style endpoint paths and
the existing known credential/CMS scanner targets. HEAD has no body. There is no
redirect or application error-page subrequest, so Noosphere is not invoked.

PhysicsLibrary has no PHP endpoints. The extension rule applies to URL paths,
not query strings: search terms and `op=downloadfile` parameters containing
`.php` remain valid. The existing, narrowly matched `p=php/` traversal-query guard
is retained, now returning the same 404. Private-storage 403 rules and crawler
user-agent policy are unchanged. Unknown URLs in general are not blocked.

## Deploy

1. Pull the merged change into `/var/www/pp`. The new include file must exist
   **before** enabling the updated virtual host configuration.
2. Identify the installed configurations using `sudo httpd -S` and
   `sudo httpd -t -D DUMP_INCLUDES`. Back up the active configuration files outside
   the included `conf.d` directory. If the installed files are copies rather than
   links to the repository, review/apply the changes from both
   `etc/httpd-physicslibrary.conf` and `etc/httpd-physicslibrary-le-ssl.conf`.
   Preserve local certificates, paths, and other custom settings. Do not enable
   the obsolete single/multi/example configurations alongside the live ones.
3. Confirm each live virtual host has exactly one mandatory scanner include,
   before its redirect/rewrite rules. The patch replaces the duplicated HTTPS
   scanner guards; do not leave the old copies ahead of the new include.
4. Validate and gracefully reload only on success:

   ```sh
   sudo apachectl configtest && sudo systemctl reload httpd
   ```

5. Check both schemes and all public hosts. For example:

   ```sh
   curl -i https://physicslibrary.org/wp-login.php
   curl -i http://physicslibrary.org/index.php
   curl -I https://physicslibrary.org/random.php
   curl -i https://aux.physicslibrary.org/phpmyadmin/
   curl -i https://images.physicslibrary.org/.env
   ```

   Expect `404`, `Not found.` (except HEAD), and no `Location` or login cookies.
   Also verify the homepage, login, native search, an encyclopedia article,
   sitemap, an authorized download, and a computational resource still work.
   Review access-log bytes and timings for scanner requests. Historical AWStats
   totals will not shrink; the savings affect new requests only. Apache still
   accepts the connection and logs the rejection; this is not network-level
   filtering or a guarantee of protection against connection exhaustion.

Rollback: restore the backed-up active virtual host files, run the configuration
check, then gracefully reload. Do not remove the include file while active
configurations still reference it.

## Regression Tests

```sh
prove bin/test/httpd-memory-guard.t bin/test/httpd-scanner-404.t
```

Static tests check placement in all five live virtual host blocks and scanner
versus legitimate URL boundaries. The second suite also starts a disposable,
loopback-only Apache/mod_perl server when available. It asserts a tiny 404 and
no Perl-handler invocation for GET, HEAD, and POST, including encoded paths and
hosts with HTTP redirects. Allowed paths are positive controls for the handler.
Run tests as an unprivileged account, without `sudo`. They do not load site
configuration, credentials, certificates, or databases.

To select a non-system Apache build, set `SCANNER_TEST_HTTPD` to the executable
and `SCANNER_TEST_MODULES` to its matching module directory. Any needed runtime
library paths can be supplied through `LD_LIBRARY_PATH`. Without Apache/mod_perl,
the integration subtest is explicitly skipped while static tests still run.

References: [Apache rewrite status flags](https://httpd.apache.org/docs/2.4/rewrite/flags.html#flag_r)
and [inline ErrorDocument responses](https://httpd.apache.org/docs/2.4/mod/core.html#errordocument).
