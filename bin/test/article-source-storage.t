#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";

sub read_file {
    my ($path) = @_;
    open my $in, '<', $path or die "Cannot read $path: $!";
    return do { local $/; <$in> };
}

for my $schema (qw(db/schema.mysql.sql db/schema.new.mysql.sql)) {
    my $source = read_file("$root/$schema");
    my ($objects) = $source =~ /CREATE\s+TABLE\s+objects\s*\((.*?)\)\s*TYPE=/is;
    ok(defined($objects), "$schema declares the objects table");
    like($objects || '', qr/\bdata\s+mediumtext\s+not\s+null\b/i,
        "$schema provisions MEDIUMTEXT for encyclopedia source");
}

my $migration = read_file("$root/db/migrations/objects-data-mediumtext.sql");
like($migration, qr/ALTER\s+TABLE\s+objects\s+MODIFY\s+COLUMN\s+data\s+MEDIUMTEXT\s+NOT\s+NULL/i,
    'migration expands existing encyclopedia source storage');
unlike($migration, qr/\b(?:DROP|DELETE|TRUNCATE)\b/i,
    'migration preserves existing article source');

my $install = read_file("$root/install/INSTALL");
like($install, qr/objects-data-mediumtext\.sql/,
    'install guide documents the article-source migration');

done_testing();
