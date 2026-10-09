-- Additive, optional native-search index. Run in the site's database.
-- No changes to the legacy content, ACL, wordidx, or render-cache tables.
-- Stopwords are disabled for this index only, not for other server indexes.
SET @previous_search_stopwords = @@SESSION.innodb_ft_enable_stopword;
SET SESSION innodb_ft_enable_stopword = OFF;
CREATE TABLE IF NOT EXISTS search_documents (
  tbl varchar(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  objectid bigint NOT NULL,
  source_modified varchar(32) CHARACTER SET ascii NOT NULL DEFAULT '',
  source_version bigint NOT NULL DEFAULT 0,
  parser_version int NOT NULL,
  status varchar(16) CHARACTER SET ascii NOT NULL,
  indexed_at datetime NOT NULL,
  body_text mediumtext NOT NULL,
  search_text mediumtext NOT NULL,
  PRIMARY KEY (tbl, objectid),
  FULLTEXT KEY search_documents_text (search_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SET SESSION innodb_ft_enable_stopword = @previous_search_stopwords;
