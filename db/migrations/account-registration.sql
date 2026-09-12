CREATE TABLE account_registration_tokens (
  token_hash char(64) NOT NULL,
  username varchar(32) NOT NULL,
  email varchar(128) NOT NULL,
  created bigint NOT NULL,
  expires bigint NOT NULL,
  used_at bigint DEFAULT NULL,
  PRIMARY KEY (token_hash),
  KEY account_registration_expires_idx (expires)
) ENGINE=MyISAM;
