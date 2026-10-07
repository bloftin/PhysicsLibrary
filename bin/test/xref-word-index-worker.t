#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $worker = "$FindBin::Bin/../update-xref-word-index";
my $harness = <<'PERL';
use strict;
use warnings;
BEGIN {
	$INC{'Noosphere.pm'} = 1;
	$INC{'Noosphere/DB.pm'} = 1;
	$INC{'Noosphere/Indexing.pm'} = 1;
}
{
	package Noosphere;
	our $dbh;
	sub getConfig { return $_[0] eq 'cache_tbl' ? 'cache' : 'objects'; }
	sub dbConnect { return bless {}, 'WorkerDatabase'; }
	sub wordIndexEntry {
		print "INDEX $_[1]->{uid}\n";
		die "index failed\n" if $ENV{XREF_TEST_FAILURE} eq 'index';
	}
	sub markWordIndexCurrent { print "CURRENT $_[0]\n"; }
}
{
	package WorkerDatabase;
	sub prepare { return bless {next => 0}, 'WorkerStatement'; }
	sub begin_work { print "BEGIN\n"; return 1; }
	sub commit { print "COMMIT\n"; return 1; }
	sub rollback { print "ROLLBACK\n"; return 1; }
	sub disconnect { return 1; }
	sub do {
		my ($self, $sql, $attr, @bind) = @_;
		print "SQL $sql\nBIND @bind\n";
		return undef if $ENV{XREF_TEST_FAILURE} eq 'cache';
		return $ENV{XREF_TEST_FAILURE} eq 'no-cache' ? '0E0' : 1;
	}
}
{
	package WorkerStatement;
	sub execute { return 1; }
	sub fetchrow_hashref {
		return undef if $_[0]->{next}++;
		return {uid => 1410, data => 'The center of mass relation is'};
	}
	sub finish { return 1; }
}
my $script = shift @ARGV;
do $script;
die $@ if $@;
PERL

sub run_worker {
	my ($failure, @args) = @_;
	local $ENV{XREF_TEST_FAILURE} = $failure;
	open my $out, '-|', $^X, '-e', $harness, $worker, @args or die $!;
	my $output = do { local $/; <$out> };
	close $out;
	return ($? >> 8, $output);
}

my ($status, $output) = run_worker('', '--apply');
is($status, 0, 'successful backfill exits successfully');
like($output, qr/INDEX 1410\nSQL update cache set valid=0, touched=CURRENT_TIMESTAMP where tbl=\? and objectid=\?\nBIND objects 1410\nCURRENT 1410\nCOMMIT/,
	'worker invalidates only the indexed article before recording its current marker');
unlike($output, qr/SQL .*build=/, 'backfill preserves active render claims');

($status, $output) = run_worker('no-cache', '--apply');
is($status, 0, 'an article without cached renders can still be indexed');
like($output, qr/CURRENT 1410\nCOMMIT/, 'zero matching cache rows is not a database failure');

for my $failure (qw(index cache)) {
	($status, $output) = run_worker($failure, '--apply');
	is($status, 1, "$failure failure is visible to systemd");
	like($output, qr/ROLLBACK/, "$failure failure rolls back the transaction");
	unlike($output, qr/^(?:CURRENT|COMMIT)\b/m, "$failure failure does not mark the index current");
}

($status, $output) = run_worker('');
is($status, 0, 'dry run exits successfully');
like($output, qr/1 unindexed article\(s\) selected/, 'dry run reports the selected backlog');
unlike($output, qr/BEGIN|INDEX|SQL|CURRENT|COMMIT/, 'dry run changes neither index nor renders');

done_testing();
