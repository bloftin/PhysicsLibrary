CREATE TABLE IF NOT EXISTS password_reset_tokens (
  uid int(11) NOT NULL default '0',
  token_hash char(64) NOT NULL default '',
  created datetime default NULL,
  expires datetime default NULL,
  used_at datetime default NULL,
  PRIMARY KEY (token_hash),
  KEY password_reset_tokens_uid_idx (uid)
) ENGINE=MyISAM;
