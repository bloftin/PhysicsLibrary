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
only new or edited articles. Check the backlog or process a small manual batch:

```sh
sudo -u apache perl -Ilib bin/update-xref-word-index --limit 10
sudo -u apache perl -Ilib bin/update-xref-word-index --apply --limit 10
```
