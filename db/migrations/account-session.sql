CREATE TABLE IF NOT EXISTS account_sessions (
  token_hash char(64) NOT NULL,
  uid int(11) NOT NULL,
  created bigint NOT NULL,
  expires bigint NOT NULL,
  last_seen bigint NOT NULL,
  credential_stamp char(64) NOT NULL,
  PRIMARY KEY (token_hash),
  KEY account_sessions_uid_idx (uid),
  KEY account_sessions_expires_idx (expires)
) ENGINE=MyISAM;
