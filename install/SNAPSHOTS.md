# Snapshot Downloads

The main-menu Snapshots link opens `/?op=snapshots` inside the normal site
layout. It lists readable archive files directly in `BASE_DIR/data/snapshots`,
newest modified first. Supported extensions are `.tar.gz`, `.tar.bz2`,
`.tar.xz`, `.tgz`, `.tar`, and `.zip`. Hidden files, subdirectories and symlinks
are not listed. Dates are filesystem modification times in UTC, not snapshot
creation dates.

On the current deployment this is `/var/www/pp/data/snapshots`. Keep the
directory searchable and the intended archive files readable by Apache. An
empty directory produces an empty state; missing or inaccessible storage
produces an unavailable message without revealing filesystem paths.

Downloads use the existing `op=downloadfile` handler and still require sign-in.
The old `https://aux.physicslibrary.org/snapshots/` directory and its download
redirects remain unchanged. No database migration, new scheduled job, archive
regeneration, or Apache configuration change is required for this page.

Deploy the merged code and restart Apache using the site's usual deployment
procedure to load the new Perl module. Check the Snapshots link both signed
out and signed in; the list should be public, while an anonymous download
should still return the Sign In Required response.
