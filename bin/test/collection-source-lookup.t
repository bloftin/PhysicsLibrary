#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Collection.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;

my ($function) = $source =~ /^(sub getSourceCollection \{.*?)(?=^sub |\z)/ms;
die "getSourceCollection not found" unless defined $function;

{
	package Noosphere;
	use strict;
	our $dbh;
	sub getConfig { return 'objindex'; }
	eval $function;
	die $@ if $@;
}

{
	package TestStatement;
	sub new { bless { row => $_[1], binds => undef }, $_[0] }
	sub execute { $_[0]->{binds} = [@_[1 .. $#_]]; return 1; }
	sub rows { return defined $_[0]->{row} ? 1 : 0; }
	sub fetchrow_arrayref { return $_[0]->{row}; }
	sub finish { $_[0]->{finished} = 1; }
}

{
	package TestDatabase;
	sub new { bless { statement => $_[1], query => undef }, $_[0] }
	sub prepare { $_[0]->{query} = $_[1]; return $_[0]->{statement}; }
}

$Noosphere::dbh = undef;
is(Noosphere::getSourceCollection('objects', undef), undef, 'missing object ID does not query the database');
is(Noosphere::getSourceCollection('objects', 'not-an-id'), undef, 'non-numeric object ID does not query the database');
is(Noosphere::getSourceCollection('objects; drop table objindex', 10), undef, 'invalid table name does not query the database');

my $statement = TestStatement->new(['physicslibrary']);
my $database = TestDatabase->new($statement);
$Noosphere::dbh = $database;
is(Noosphere::getSourceCollection('objects', 1248), 'physicslibrary', 'valid source collection is returned');
is($database->{query}, 'select source from objindex where tbl=? and objectid=?', 'query uses placeholders for record values');
is_deeply($statement->{binds}, ['objects', 1248], 'record values are bound to the source lookup');
ok($statement->{finished}, 'source lookup statement is finished');

done_testing();
