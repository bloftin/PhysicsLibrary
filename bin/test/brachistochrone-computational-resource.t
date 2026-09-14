#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use JSON::PP;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::ComputationalResources;

my $repo = "$FindBin::Bin/../..";
my $dir = tempdir(CLEANUP => 1);
my %config = (base_dir => $dir, file_root => "$dir/files", en_tbl => 'objects',
    image_url => 'https://images.example.test/images');
{
    no warnings 'redefine';
    *Noosphere::getConfig = sub { $config{$_[0]} };
}
make_path("$dir/etc", "$dir/files/objects/17");
sub readfile { open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>; }
sub writefile { open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1]; close $fh or die $!; }
writefile("$dir/etc/computational-resources.json", readfile("$repo/etc/computational-resources.json"));
writefile("$dir/files/objects/17/computational-resources.json",
          readfile("$repo/examples/brachistochrone-cycloid/computational-resources.json"));

my $catalog = decode_json(readfile("$repo/etc/computational-resources.json"));
ok(exists $catalog->{resources}{'brachistochrone-cycloid'}, 'brachistochrone catalog id registered');
my $entry = $catalog->{resources}{'brachistochrone-cycloid'};
is($entry->{language}, 'Julia', 'Julia language declared');
is($entry->{version}, '1.10.12', 'Julia LTS version declared');
is(scalar @{$entry->{datasets}}, 6, 'six reviewed brachistochrone datasets cataloged');

my $result = Noosphere::getComputationalResources({uid => 17});
is(scalar @$result, 1, 'CV17 filebox manifest resolves one reviewed resource');
is($result->[0]{title}, 'Brachistochrone Cycloid and Travel Time', 'catalog title resolved');
is($result->[0]{explorer}, 'https://images.example.test/examples/brachistochrone-cycloid/index.html', 'explorer URL uses static image host');
is(scalar @{$result->[0]{datasets}}, 6, 'all six dataset links are exposed');

my @files = ($entry->{explorer}, $entry->{source}, $entry->{provenance}, $entry->{license},
             map { $_->{file} } @{$entry->{datasets}});
for my $name (@files) {
    ok(-f "$repo/data/examples/brachistochrone-cycloid/$name", "published asset exists: $name");
}
my $license = readfile("$repo/data/examples/brachistochrone-cycloid/LICENSE.txt");
like($license, qr/GNU General Public License, version 3/, 'software license is GPLv3');
like($license, qr/Creative\s+Commons\s+Attribution-ShareAlike/, 'math/data license remains Physics Library CC BY-SA');

done_testing();
