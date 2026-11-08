# Login-flow diagnostics

These opt-in diagnostics investigate intermittent sign-in without logging
credentials. They do not change authentication, cookie scope, session lifetime,
origin checks, or the recent stale-response fix. No schema migration is needed.
They are not a confirmed fix for the homepage login report.

## Enable Temporarily

After deploying this change, add this setting inside the existing `%base_config`
hash in the server's private `lib/Noosphere/baseconf.pm`:

```perl
LOGIN_FLOW_LOGGING => 1,
```

Do not publish or paste the rest of that file. The example configuration keeps
this option at `0` (disabled), and an absent option is also disabled.

Validate the Apache configuration, then restart Apache during a suitable window
so every mod_perl worker loads the same version. A restart interrupts active
requests; this is not a reason to increase worker limits.

```bash
sudo httpd -t
sudo systemctl restart httpd
```

Try one ordinary homepage login, recording the UTC time, then:

```bash
sudo grep -a 'PL_LOGIN ' /var/log/httpd/error_log | tail -80
```

Avoid repeatedly submitting credentials or making a test account just to
produce records. A normal attempt is sufficient. No access-log configuration
change, request-body logging, packet capture, HAR, or cookie export is needed.

## What Is Recorded

Only generated trace IDs, process IDs, elapsed milliseconds, HTTP status codes,
fixed method/route/operation/content-type/cookie categories, body-advertised
and field-presence booleans, and allowlisted stage/outcome names are emitted.

No username, user ID, password, password length, password hash, session token,
token digest, CSRF token, IP address, URL/query, redirect destination, raw request
header, request body, or exception/SQL text is emitted by `PL_LOGIN`.
Existing Apache/application logs are separate and may contain other data; share
only the `PL_LOGIN` lines for this investigation.

`route=home` means the original request was `/` or `/?`, not merely that an
operation's URL started with `/`. `op=login`, `op=logout`, `op=none`, and
`op=other` distinguish otherwise identical `POST /` access-log records.
Elapsed time starts when the authentication trace is created, after initial
routing and database connection; use the access log for whole-request timing.

`cookie=present` means the existing parser supplied a session candidate.
`cookie=unusable` means its cookie name was received but the parser rejected it
(for example, duplicate or oversized cookie values). `cookie=absent` means the
session cookie name was not received. This says nothing about other cookies.

Traces cover login/logout operations, the literal homepage, root POSTs with a
query string, and dynamic requests carrying a session cookie. Anonymous article
and other ordinary anonymous view GETs are not traced. Cookie-bearing dynamic
requests can be frequent, so monitor existing error-log rotation/disk usage.

## Interpret One Attempt

A successful login POST should show these stages in the same trace:

```text
stage=request event=begin
stage=credentials event=accepted
stage=session_issue event=accepted
stage=session_cookie event=set
stage=response event=303
```

The subsequent GET has a **new trace ID** and possibly a different PID. Match by
the recorded attempt time and request order, without treating adjacent records
as proof they came from the same browser on a busy site. No cross-request cookie
fingerprint or correlation cookie is created. On that GET:

- `cookie=present` and `stage=session_check event=accepted` mean the server
  received and accepted a session.
- `cookie=absent` means that request did not send the session cookie name. The
  previous `session_cookie=set` only proves the application called its cookie
  setter, not that Apache delivered it or the browser stored it.
- `cookie=unusable` points to cookie parsing rather than password verification.
- `stage=session_check event=unmatched` includes missing/revoked/expired rows,
  idle expiry, and inactive/deleted accounts; it is not a database exception.
- `stage=session_check event=invalidated` means credential/access binding or
  absolute session lifetime checks invalidated the row.
- `stage=session_lookup event=error` or `stage=session_touch event=error`
  identifies a database check/activity-update exception. Authentication still
  fails closed. `session_revoke/error` identifies invalidation cleanup failure.

For the POST itself, `credentials/rejected` means no matching verified active
account; `credentials/missing` means fields were empty or invalid, and
`credentials/error` distinguishes a caught verification/lookup exception.
`session_issue/rejected` is distinct from `session_issue/error`.
`origin/rejected` precedes the existing 403 response.

A body-bearing `POST /` with `op=none user_field=0 passwd_field=0` can help identify
lost/unparsed form fields, but may also be an unrelated form or bot. The log does
not label such a request as a login without evidence. A confirmed logout records
`op=logout stage=logout event=confirmed`; its normal 200 is not a failed login.

The access log's `**%T/%D**` suffix reports whole seconds / microseconds, not
milliseconds. A duration such as `**0/37766**` is about 38 ms. A slow unrelated
edit/render POST does not establish a slow sign-in.

## Disable

Set `LOGIN_FLOW_LOGGING => 0,` (or remove the option) in the private configuration
and restart Apache during a suitable window. There are no diagnostic tables,
client cookies, browser storage keys, or scheduled tasks to remove.
