CREATE TABLE IF NOT EXISTS wordidx_state (
  objectid int(11) NOT NULL,
  tbl varchar(16) NOT NULL,
  indexed_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (objectid, tbl)
) ENGINE=InnoDB;
