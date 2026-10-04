#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Encode qw(encode);
use URI::Escape qw(uri_unescape);
use Noosphere::Snapshots;
use Noosphere::RequestForm;

my $root = "$FindBin::Bin/../..";
my $base = tempdir(CLEANUP => 1);
my %config = (base_dir => $base, template_path => "$root/stemplates");
{
    package Noosphere;
    sub getConfig { return $config{$_[0]}; }
}
sub read_file {
    open my $fh, '<', "$root/$_[0]" or die $!;
    return do { local $/; <$fh> };
}
sub archive {
    my ($name, $size, $time) = @_;
    open my $fh, '>', "$base/data/snapshots/$name" or die $!;
    truncate($fh, $size) or die $!;
    close $fh;
    utime($time, $time, "$base/data/snapshots/$name") or die $!;
}

is_deeply(Noosphere::snapshotArchiveCatalog(), { available => 0, archives => [] },
    'missing storage has a distinct unavailable state');
make_path("$base/data/snapshots");
is_deeply(Noosphere::snapshotArchiveCatalog(), { available => 1, archives => [] },
    'empty directory is available, with no archives');
like(Noosphere::getSnapshots({}, {uid => 0}), qr/No snapshot archives are available yet/,
    'empty state renders in the normal page');

archive('PlanetPhysics-snapshot_2011-04-01.tar.gz', 12 * 1024 * 1024, 1786758300);
archive('Older.zip', 2048, 1600000000);
archive('Newer.tar.xz', 1024, 1800000000);
archive('A same time.tgz', 0, 1800000000);
archive('Bad<script>&".tar.gz', 10, 1700000000);
my $unicode = encode('UTF-8', "snapshot-\x{3bb}.tar.gz");
archive($unicode, 10, 1700000000);
archive('.hidden.zip', 10, 1800000000);
archive('notes.txt', 10, 1800000000);
archive("bad\nname.zip", 10, 1800000000);
archive('back\\slash.zip', 10, 1800000000);
make_path("$base/data/snapshots/directory.zip");
make_path("$base/data/snapshots/subdirectory");
open my $nested, '>', "$base/data/snapshots/subdirectory/nested.zip" or die $!;
close $nested;

my $catalog = Noosphere::snapshotArchiveCatalog();
my @rows = @{$catalog->{archives}};
is($catalog->{available}, 1, 'readable archive directory is available');
is(scalar @rows, 6, 'only supported, non-hidden top-level archive files are listed');
is_deeply([map {$_->{name}} @rows[0,1]], ['A same time.tgz', 'Newer.tar.xz'],
    'newest archives first, with deterministic filename ordering for ties');
my ($historical) = grep { $_->{name} =~ /^PlanetPhysics/ } @rows;
is($historical->{bytes}, 12 * 1024 * 1024, 'raw size retained');
is($historical->{size}, '12.0 MiB', 'archive size is human-readable');
is($historical->{format}, 'TAR.GZ', 'archive type retained');
like($historical->{modified}, qr/^2026-08-15 .* UTC$/, 'filesystem timestamp labelled in UTC');
is(uri_unescape($historical->{url}),
    '/?op=downloadfile&path=snapshots/PlanetPhysics-snapshot_2011-04-01.tar.gz',
    'download uses the existing authenticated handler');
is(Noosphere::snapshotArchiveSize(0), '0 B', 'zero-byte sizes are stable');
is(Noosphere::snapshotArchiveSize(1024**3), '1.0 GiB', 'large archive sizes are compact');
my ($unicode_row) = grep { $_->{name} =~ /\x{3bb}/ } @rows;
ok($unicode_row, 'UTF-8 filename decoded for display');
is(uri_unescape($unicode_row->{url}), '/?op=downloadfile&path=snapshots/' . $unicode,
    'UTF-8 filename bytes survive URL escaping');

my $anonymous = Noosphere::getSnapshots({path => '../', directory => '/'}, {uid => 0});
like($anonymous, qr/6 archives available/, 'listing count is visible');
like($anonymous, qr/Sign in to download an archive/, 'anonymous visitor receives sign-in guidance');
like($anonymous, qr/Bad&lt;script&gt;&amp;&quot;\.tar\.gz/, 'archive names are HTML-escaped');
unlike($anonymous, qr/<script>/, 'filenames cannot inject markup');
like($anonymous, qr/path=snapshots%2FBad%3Cscript%3E%26%22\.tar\.gz/,
    'unsafe filename characters are URL-encoded');
like($anonymous, qr/op=downloadfile&amp;path=/, 'download query is HTML-escaped');
unlike($anonymous, qr/notes\.txt|nested\.zip|directory\.zip|bad\nname/,
    'non-archives and nested files are not rendered');
like($anonymous, qr/PlanetPhysics-snapshot/, 'request parameters cannot choose a directory');
my $member = Noosphere::getSnapshots({}, {uid => 1});
unlike($member, qr/Sign in to download an archive/, 'signed-in visitors get a direct download listing');
like($member, qr/class="pl-snapshot-download"/, 'download controls are present');
like($member, qr/Last modified <time datetime="[^"]+Z">/, 'timestamp has semantic UTC markup');
unlike($member, qr/<iframe|paddingTable/, 'native listing avoids an external frame or legacy title offset');

subtest 'symlinks stay outside the catalog' => sub {
    my $outside = tempdir(CLEANUP => 1);
    open my $file, '>', "$outside/external.tar.gz" or die $!;
    close $file;
    plan skip_all => 'symlinks unavailable on this filesystem'
        unless symlink("$outside/external.tar.gz", "$base/data/snapshots/link.tar.gz");
    is(scalar @{Noosphere::snapshotArchiveCatalog()->{archives}}, 6,
        'symlinked files are never listed');
    my $linked = tempdir(CLEANUP => 1);
    make_path("$linked/data");
    symlink("$base/data/snapshots", "$linked/data/snapshots") or die $!;
    local $config{base_dir} = $linked;
    is(Noosphere::snapshotArchiveCatalog()->{available}, 0,
        'symlinked snapshot directory is rejected');
    my $html = Noosphere::getSnapshots({}, {uid => 0});
    like($html, qr/temporarily unavailable/, 'unavailable storage has a friendly message');
    unlike($html, qr/\Q$linked\E/, 'unavailable state exposes no filesystem path');
};

my $dispatch = read_file('lib/Noosphere/Dispatch.pm');
like($dispatch, qr/'snapshots'\s*=>\s*\\&getSnapshots/, 'read-only handler is registered');
my ($non_template) = $dispatch =~ /%NONTEMPLATE\s*=\s*\((.*?)\);/s;
unlike($non_template, qr/'snapshots'/, 'route keeps the main site template and sidebar');
like(read_file('lib/Noosphere/Docs.pm'), qr/use Noosphere::Snapshots;/,
    'normal module loading includes the handler');
ok(grep($_ eq 'snapshots', Noosphere::requestFormReadRoutes()), 'route allows read-only navigation');
like(read_file('stemplates/mainmenu.tt'), qr{href="/\?op=snapshots"},
    'sidebar opens the main-site landing page');
like(read_file('lib/Noosphere.pm'), qr/elsif\s*\(\$uid\s*<=\s*0\)/,
    'existing anonymous snapshot-download check is unchanged');

done_testing();
