# Cross-reference word index

New title creation invalidates cached articles through the `wordidx` table.  The
index update runs outside Apache requests so adding or editing an article does
not perform a large database write on the request path.

Install the bounded background worker:

```sh
sudo install -D -m 0644 etc/systemd/physicslibrary-xref-index.service \
  /etc/systemd/system/physicslibrary-xref-index.service
sudo install -D -m 0644 etc/systemd/physicslibrary-xref-index.timer \
  /etc/systemd/system/physicslibrary-xref-index.timer
sudo systemctl daemon-reload
sudo systemctl enable --now physicslibrary-xref-index.timer
```

It indexes at most one previously unindexed article every two minutes.  Check
the backlog or process a small manual batch with:

```sh
sudo -u apache perl -Ilib bin/update-xref-word-index --limit 10
sudo -u apache perl -Ilib bin/update-xref-word-index --apply --limit 10
```
