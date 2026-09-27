# Render-stage logging

`render_stage_logging` in `lib/Noosphere/Config.pm` defaults to `1` while
investigating runaway render memory. It instruments cache builds, article and
collaboration preparation, cross-referencing, converter dispatch and pipe
capture, and HTML postprocessing. Serving an already-valid article cache does
not start a trace. This is diagnostics, not a memory limit or recovery watchdog.

## Deployment

After merging, from the production checkout:

```bash
cd /var/www/pp
git switch main
git pull --ff-only
perl -Ilib -c lib/Noosphere/RenderLog.pm
prove bin/test/render-stage-logging.t bin/test/cache-render-claim.t
sudo httpd -t && sudo systemctl reload httpd
```

No database migration, cron entry, timer, or separately installed script is
needed. Gracefully retiring workers may still use the old code until their
current requests finish. Do not force a known problematic article to rerender
just to test logging; use an ordinary new-entry preview or let normal cache
builds occur.

Records use `warn`, independent of the legacy `dwarn` debug level. In mod_perl
they go to Apache's error log, normally `/var/log/httpd/error_log` on this host.
CLI renders write them to stderr, so the existing renderall cron redirection
puts them in `/var/www/pp/log/renderall-cron.log`. Existing log rotation applies;
watch disk usage while tracing is enabled, especially on a large rebuild.

```bash
sudo grep -a 'PL_RENDER ' /var/log/httpd/error_log | tail -80
sudo grep -a 'PL_RENDER ' /var/www/pp/log/renderall-cron.log | tail -80
```

## Interpreting a trace

Each single-line record contains:

- `trace`: correlation ID, shared by nested stages of one operation.
- `pid`, `table`, `object`, `method`: which process and render are involved.
- `stage`, `span`, `event`: named stage, unique nested span, and `begin`, `end`,
  or `error`. Repeated link-resolution calls have separate span numbers.
- `elapsed_ms`: time since this trace began; `stage_ms`: time in this stage.
- `rss_kb`, `peak_rss_kb`, `vm_kb`: current resident memory, process-lifetime
  resident high-water mark, and virtual memory from `/proc/self/status`.
  Missing procfs values appear as `NA`. Values describe the Perl/Apache process,
  not its converter children; correlate with the health monitor for those.

For example, to follow article 376 or a PID found in the OOM log:

```bash
sudo grep -a 'PL_RENDER .* object=376 ' /var/log/httpd/error_log | tail -100
sudo grep -a 'PL_RENDER .* pid=20149 ' /var/log/httpd/error_log | tail -100
```

PIDs are reused across boots. Narrow by date, then copy the full `trace` value
from a relevant line and filter with `grep -aF 'trace=VALUE '` to isolate it.
Preparation and conversion invoked separately by a preview caller may have
separate trace IDs; cached article builds retain one ID across both.

A `begin` without its matching `end`/`error` identifies an unfinished stage,
not proof that the named function caused the problem: work may still be running,
or the process may have been killed, restarted, or its log rotated. Look at the
deepest open span together with kernel OOM events and monitor snapshots. A large
RSS increase between adjacent lines narrows where memory grew. No heartbeat is
emitted inside a stuck function, and a killed process cannot log a final sample.
An `end` means the call returned, not that rendering succeeded; functions that
report failure by returning `0` still log `end`. Exceptions log `error` without
recording the exception payload.

Stages include `cache.cleanup`, `cache.filebox`, `cache.prepare`, `xref.terms`,
`xref.index_query`, `xref.index_fetch`, `xref.matches`, `xref.disambiguate`,
`xref.classification`, `xref.graph`, `xref.math_title`, `external.make4ht`,
`external.capture`, `html.read`, `html.decode`, `html.tidy`, and
`html.generated_css`. Records omit article text, titles, command arguments,
request URLs, and credentials. Metadata is sanitized and length-limited.

Set `render_stage_logging` to `0` and reload Apache to stop tracing once the
investigation is complete. No render limits, cache semantics, or converter
timeouts are changed by this feature.
