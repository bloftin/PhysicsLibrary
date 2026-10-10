# Long article titles and missing title-index rows

Articles and resource titles allow 255 characters, but the historical
`objindex.title` and `objindex.cname` columns allowed only 128. A long article
can be stored successfully while its title-index insert fails. Alphabetical
browsing, latest additions, canonical-name lookup, and attachment parent
lookup depend on that index. Resubmitting an apparently missing article can
create another object, especially because name-existence checks also use the
missing index. This is separate from the Pandoc full-text index.

## Inspect and back up

Do not delete or resubmit articles to repair this problem. Keep one reviewed
object ID and inspect the original rows and index entries first:

```sql
SHOW CREATE TABLE objindex;
SHOW INDEX FROM objindex;
SELECT o.uid, o.name, o.title, o.parentid, o.synonyms, o.defines,
       CHAR_LENGTH(o.title) AS title_chars,
       CHAR_LENGTH(o.name) AS name_chars
FROM objects o
WHERE NOT EXISTS (
  SELECT 1 FROM objindex i
  WHERE i.tbl='objects' AND i.objectid=o.uid AND i.type=1
)
ORDER BY o.uid;
SELECT * FROM objindex WHERE tbl='objects' AND objectid=1454;
```

Take and verify a fresh database backup with `sudo bash bin/backup-db
--allow-write-lock`. Schedule the ALTER during a quiet maintenance window:
it rebuilds/locks the table and MySQL/MariaDB DDL commits implicitly. Allow
disk space for a copy of the table and its indexes. `ALGORITHM=COPY` explicitly
rebuilds lookup indexes rather than relying on an in-place width/prefix change.

## Widen the index columns

For the stock MySQL/MariaDB schema, verify that the two index names are
`objindex_title_idx` and `objindex_cnameidx` and that both columns are currently
`VARCHAR(128) NOT NULL DEFAULT ''`. If names, character sets, collations, or
column defaults were customized, review/adapt the migration to preserve them
before applying; do not blindly run it against a different schema.

```bash
sudo mariadb pp < db/migrations/objindex-title-width.mysql.sql
sudo mariadb pp -e "SHOW COLUMNS FROM objindex WHERE Field IN ('title','cname');"
```

Both fields should now allow 255 characters. Only the lookup indexes retain
a 128-character prefix, preserving the historical index-byte budget even for
utf8mb4 MyISAM tables. Values are stored in full and comparisons still use
the complete names. No Apache restart or full-text migration is needed.

PostgreSQL installations use `db/migrations/objindex-title-width.pg.sql`.

## Repair one reviewed missing primary row

After the width migration, the following example restores only the missing
primary title row for object 1454. Confirm its current title, owner, canonical
name, and parent first. This English title sorts under `E`, and this site's
source nickname is `PP`; do not reuse those values blindly for other entries.
Pause article edits during repair. The NOT EXISTS guard makes sequential
retries harmless but is not a concurrency lock against other writers.

```sql
INSERT INTO objindex
  (objectid,tbl,userid,title,cname,type,source,ichar)
SELECT o.uid,'objects',o.userid,o.title,o.name,1,'PP','E'
FROM objects o
WHERE o.uid=1454 AND NOT EXISTS (
  SELECT 1 FROM objindex i
  WHERE i.tbl='objects' AND i.objectid=o.uid AND i.type=1
);
UPDATE storage SET valid=0
WHERE _key IN ('latestadds','latestmods','unclassified_objects');
```

This does not change article source, files, canonical names, parent links,
ownership, ACLs, scores, watches, or existing synonym/defined-term rows. It
does not restore deleted objects or choose which duplicate should survive.
Audit duplicate canonical names separately:

```sql
SELECT name,COUNT(*) AS copies,GROUP_CONCAT(uid ORDER BY uid) AS object_ids
FROM objects GROUP BY name HAVING COUNT(*)>1;
```

If an expected shortcut such as `EM24E12` still fails, inspect `synonyms` and
`defines` on the retained object and its type-2/type-3 `objindex` rows. Repairing
the primary row cannot invent a missing shortcut. With the migration applied,
editing the retained entry through its numeric object ID and saving it rebuilds
its title, synonyms, and defined terms using the existing workflow; this may
record a new version and should be done deliberately. Do not run `indexTitle`
alone as a repair: it deletes all index rows for that object, including aliases.

Never shrink these columns as a rollback while longer values exist. Restore
from a tested backup in a maintenance window if rollback is required.
