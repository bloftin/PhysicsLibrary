-- Encyclopedia article source can exceed the 64 KiB limit of TEXT.
-- MEDIUMTEXT supports up to 16 MiB and leaves existing source unchanged.
ALTER TABLE objects MODIFY COLUMN data MEDIUMTEXT NOT NULL;
