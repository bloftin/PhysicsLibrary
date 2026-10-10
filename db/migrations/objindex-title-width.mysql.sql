-- Match the 255-character titles and canonical names stored by objects.
-- Keep the original 128-character index budget for utf8mb4/MyISAM and older
-- InnoDB tables. Prefix indexes narrow candidates; SQL still compares the
-- full stored strings, so titles and names are not truncated.
-- Verify the index names before applying; see etc/title-index-recovery.md.
ALTER TABLE objindex
  MODIFY COLUMN title VARCHAR(255) NOT NULL DEFAULT '',
  MODIFY COLUMN cname VARCHAR(255) NOT NULL DEFAULT '',
  DROP INDEX objindex_title_idx,
  ADD INDEX objindex_title_idx (title(128)),
  DROP INDEX objindex_cnameidx,
  ADD INDEX objindex_cnameidx (cname(128)),
  ALGORITHM=COPY;
