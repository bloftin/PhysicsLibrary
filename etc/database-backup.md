# Private database backups

`bin/backup-db` is an operator-invoked SQL backup, not an offline encyclopedia
snapshot. `bin/make_browsable_snapshot.pl` copies cached l2h HTML/TeX/images and
builds an offline article index. That archive cannot restore the live database,
accounts, permissions, mail, or the ID-allocation sequence tables.

## Run

From the deployed checkout:

```sh
cd /var/www/pp
df -h /var/backups
sudo bash bin/backup-db --allow-write-lock
```

Requires Bash, MariaDB client tools (`mariadb-dump` or the MariaDB `mysqldump`
alias), gzip and the normal GNU/Linux coreutils/util-linux commands. No Perl/DBI,
application configuration, new daemon, or Pandoc is needed. The script uses
existing local Unix socket authentication. If access is denied, stop and arrange
authorized local database-admin access; do not add inline credentials to commands
or paste configuration/passwords into a ticket. It ignores client option files
so inherited `--force` or exclusions cannot silently omit tables. Remote database
connections and credential provisioning are intentionally outside this utility.

The default private directory is `/var/backups/physicslibrary` (owner-only 0700).
Each run creates a unique private subdirectory, including:

- `dump.sql.gz`: completed compressed SQL, schema and data, routines, events,
  triggers, binary values, and sequence table state.
- `dump.sql.gz.sha256`: SHA-256 with a relative filename for copying/verifying.
- `dump.stderr`: private diagnostics from the dump client.

It uses `--lock-all-tables`, because the legacy database has both MyISAM and
InnoDB tables. This takes a global read lock: **writes across the database server
may wait**, and lock acquisition may wait for existing work. Plan a quiet window;
the default dump timeout is 900 seconds with a ten-second forced-kill grace.
`--single-transaction` alone is not a consistent MyISAM backup. There is no
automatic stop/restart of Apache, MariaDB, timers, or editors.

Optional non-secret settings:

```sh
sudo bash bin/backup-db --allow-write-lock --database pp \
  --output-dir /var/backups/physicslibrary --timeout 1800
# Only if the server uses a nondefault Unix socket:
sudo bash bin/backup-db --allow-write-lock --socket /path/to/mariadb.sock
```

Output must be absolute, owned by the running user, and mode 0700. The script
rejects paths inside the checkout, `/var/www`, `/usr/share/nginx/html`, or the
standard database data directory, including resolved symlinks. Never use another
configured public directory. Existing directory permissions are not changed.
Concurrent runs using the same output directory are rejected. There is no
retention/deletion policy; monitor disk space and archive old backups deliberately.

Any dump, compression, gzip integrity, SQL completion-footer, or checksum error
exits nonzero. A failed dump remains `.partial` and is never published as
`dump.sql.gz`. Inspect diagnostics locally; never restore partial files or use
`--force`/table exclusions to pretend the full backup succeeded. The script does
not inspect, repair, reset, or otherwise modify content tables.

## Verify and retain

In the completed run's directory:

```sh
gzip -t dump.sql.gz
sha256sum -c dump.sql.gz.sha256
```

Copy the dump and checksum to private off-instance storage, verify there too,
and apply your normal encryption/access-control policy. The dump is not encrypted
by gzip; it contains sensitive accounts and private site content. Checks confirm
successful export and file integrity, **not restore correctness**. Perform a
restore drill using a separate isolated MariaDB instance. Never test-import into
production `pp`: the SQL includes statements replacing tables, and may include
routine/event definers. Use a compatible MariaDB client/server and keep restored
events disabled until reviewed. Count key tables and check ID allocation in that
isolated restore before relying on it for recovery.

This is only a database backup. Uploaded files, article version archives, site
configuration, and other filesystem state need separate protected backups. The
live filebox and database are not captured atomically by this script.

## A crashed sequence table

Error 145 for `books_uid_seq` blocks a complete backup and may block creating
books. The schema defines this as a MyISAM auto-increment table. `nextval()` in
`lib/Noosphere/Util.pm` inserts a row to allocate a book ID, then prunes older
rows. It is not expendable just because there are few rows: its high-water state
matters. The error does not prove corruption in the `books` content table or
identify when/why the crash occurred.

Start with diagnostics in an authorized local session:

```sql
SELECT TABLE_NAME, ENGINE, AUTO_INCREMENT
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='pp' AND TABLE_NAME='books_uid_seq';
CHECK TABLE pp.books_uid_seq;
SELECT MAX(uid) AS highest_book_uid FROM pp.books;
```

Do not drop/recreate/truncate the sequence, blindly run `--auto-repair`, or use
`myisamchk` while MariaDB is running. Before any repair that writes to the table,
preserve the damaged state using the established consistent physical-backup
workflow. A straightforward maintenance option is to stop MariaDB cleanly and
copy the entire data directory privately, then restart it; plan downtime and
account for filesystem space and all services using that database. Never treat
a live ordinary filesystem copy as a consistent database backup. This utility
does not create physical backups or coordinate that maintenance.

After diagnostics confirm MyISAM and the damaged state is preserved, a DBA can
try `REPAIR TABLE pp.books_uid_seq QUICK` first (index-only repair), followed by
`CHECK TABLE`. If that fails, investigate before broader repair. Compare
`MAX(val)` and `AUTO_INCREMENT` in the repaired sequence to `MAX(uid)` in `books`
and any prior sequence state: allocation must not collide with existing IDs or
reuse previously allocated IDs. Do not lower the sequence counter. Re-run the
complete backup only after the repaired table and sequence state are verified.
Check MariaDB/kernel logs and free disk space for the underlying cause.

References:
[MariaDB dump](https://mariadb.com/docs/server/clients-and-utilities/backup-restore-and-import-clients/mariadb-dump),
[MariaDB REPAIR TABLE](https://mariadb.com/docs/server/reference/sql-statements/table-statements/repair-table).
