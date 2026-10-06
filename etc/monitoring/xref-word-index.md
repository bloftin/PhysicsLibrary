# Cross-reference word index

New title creation invalidates cached articles through the `wordidx` table. The
index update runs outside Apache requests so adding or editing an article does
not perform a large database write on the request path. The `wordidx_state`
marker records each article whose current source text has been indexed.

Before running the worker, create the marker table:

```sh
mariadb -u ec2-user -p pp < db/migrations/xref-word-index-state.sql
```

Install the bounded background worker:

```sh
sudo install -D -m 0644 etc/systemd/physicslibrary-xref-index.service \
  /etc/systemd/system/physicslibrary-xref-index.service
sudo install -D -m 0644 etc/systemd/physicslibrary-xref-index.timer \
  /etc/systemd/system/physicslibrary-xref-index.timer
sudo systemctl daemon-reload
sudo systemctl enable --now physicslibrary-xref-index.timer
```

It indexes at most one article lacking a current index marker every two minutes.
The initial pass therefore rebuilds the legacy corpus once; later it processes
only new or edited articles. Successful indexing also invalidates that article's
cached renders, so titles added while its source index was missing can become
automatic links on the next render. Existing render claims are not cleared.
A systemd timer is used instead of an additional
cron entry so the worker has explicit CPU and I/O limits, journal logs, and
missed-run recovery after a reboot. It does not replace the existing `renderall`
cron job, which renders cache rows after cross-reference invalidation.

Tokens longer than the dictionary's 32-character column are excluded, without
truncation, from both source indexing and the new-title invalidation word list.
This prevents oversized URL fragments from blocking the oldest pending article.
Other indexing errors still leave the article pending and now produce a nonzero
service exit status; investigate repeated failures instead of treating an active
timer as proof of progress.

Confirm the timer is waiting for its next run and inspect recent worker output:

```sh
systemctl status physicslibrary-xref-index.timer --no-pager
sudo journalctl -u physicslibrary-xref-index.service -n 30 --no-pager
```

Check the backlog or process a small manual batch:

```sh
sudo -u apache perl -Ilib bin/update-xref-word-index --limit 10
sudo -u apache perl -Ilib bin/update-xref-word-index --apply --limit 10
```

## Recover a missed link after a stalled backfill

After deploying the code, use a targeted batch to repair the blocked article
and the affected source article without waiting for the full initial backlog.
For the article 392 URL-token failure and the missing link from article 1410:

```sh
cd /var/www/pp
git switch main
git pull --ff-only
prove bin/test/xref-word-index.t bin/test/xref-word-index-worker.t
sudo systemctl stop physicslibrary-xref-index.timer physicslibrary-xref-index.service
sudo -u apache perl -Ilib bin/update-xref-word-index --apply --object 392
sudo -u apache perl -Ilib bin/update-xref-word-index --apply --object 1410
sudo systemctl start physicslibrary-xref-index.timer
sudo journalctl -u physicslibrary-xref-index.service -n 20 --no-pager
```

Run the manual commands one at a time and inspect errors. The timer remains
installed and enabled; restarting it resumes the remaining bounded backfill.
The script runs from the checkout, so it does not need to be separately installed.
Restart Apache during deployment to load the shared word-list change in its
Perl interpreter; this worker fix does not change any Apache resource limits.

Index repair invalidates renders but does not synchronously compile articles.
Let the existing bounded `renderall` job process the invalid caches, or view the
affected article through the normal rendering workflow. The `--object` option
selects only articles missing their current index marker; it is not a force
reindex command.
