-- Match the article title and canonical-name widths without changing data.
ALTER TABLE objindex
  ALTER COLUMN title TYPE VARCHAR(255),
  ALTER COLUMN cname TYPE VARCHAR(255);
