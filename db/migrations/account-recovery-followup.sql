ALTER TABLE password_reset_tokens
  ADD COLUMN credential_stamp char(64) DEFAULT NULL;
