# Discussion safety foundation (issue 100, PR 1)

Books, papers and lectures still do not display discussions or post controls.
This change prepares the shared message infrastructure; it does not restore
encyclopedia corrections, ratings or a new forum type on library records.

## Existing data audit

Back up normally, then run the read-only audit against the stock table names:

```bash
sudo mariadb --table pp < db/audits/discussion-integrity.mysql.sql
```

If table names have been customized, review/adapt this audit first. It reports
counts and IDs only, not message bodies, subjects or user identities. It does
not reassign or delete any records. Review every orphan, mismatched root/reply
or cycle manually before PR 2. The SQL reports self/two-node cycles; runtime
ancestor validation also rejects longer cycles and chains deeper than 128.
The renderer caps each subtree at 1,000 nodes and 128 ancestor levels as an
additional corruption safeguard. New replies cannot exceed the readable depth.

## Policy

- Discussions are addressed by `(table, object ID)`. Replies derive that pair
  from the stored parent message; submitted `from`/`id` cannot move a reply.
- Posting, preview, quote, message views and new watches require a live,
  readable parent. Object write permission is not required to participate.
- Stored thread roots and ancestor links must agree on table, object ID and
  thread ID. Cyclic/mismatched chains fail closed, rather than being repaired.
- Global feeds, chronological listings and public profile message listings use
  conservative anonymous-read ACL filtering before counts/pagination. A private
  parent's messages do not become public merely because `visible=1` was saved.
  Rows also get a bounded full-ancestry check before rendering. Corrupt chains
  skipped after SQL pagination can shorten a page or leave an overstated count;
  review the audit rather than automatically rewriting historical threads.
- Authorized members can still read unpublished collaboration discussions;
  those discussions remain excluded from global listings.
- New message notifications recheck recipient access. Existing message-linked
  notices and watch titles are not displayed after access is lost. This cannot
  recall a notice or email already read or delivered outside the application.
- Resource deletion removes only the corresponding messages, all resource/thread
  watches, unread markers and message-linked notices, and invalidates the latest
  message cache. Numeric IDs shared by other tables are not touched.

## Moderation

On an individual message view, administrators with parent read access have a
`Remove message content` action. GET displays a confirmation; the update needs
a same-origin CSRF-protected POST. Ordinary uploaders/owners are not moderators
of other users' comments.

Removal permanently replaces only that message's subject/body with a removal
marker, removes message-linked notice previews, and invalidates the latest-message
cache. It keeps IDs, parent, root, replies, unread state and thread watches.
There is no restore operation or automatic removal. Use a backup if content
must later be recovered. Do not test removal on real messages just to verify
deployment.

## Deployment and verification

No schema migration is needed. Deploy the code and validate/restart Apache so
all mod_perl workers use the same version. The restart interrupts active requests.
Run the audit and review its results; retain current UI suppression until PR 2.

Verify a public thread, an ACL-restricted parent, and reply/preview/watch flows.
Test with a book, paper, lecture and encyclopedia entry sharing a numeric ID in
a non-production fixture, including deletion and notifications. The focused
automated suite is `bin/test/discussion-safety.t`; keep the existing entry,
forum, profile, notices, watch and request-form suites in the regression run.
