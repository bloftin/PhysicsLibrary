#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

our (@dictionary_inserts, @word_index_inserts, @dropped, $nextid, %words);

{
	package Noosphere;
	our $dbh;
	sub getPlainText { return $_[0]; }
	sub getwordlist { return qw(oscillation oscillation dynamics); }
	sub dropFromWordIndex { push @main::dropped, [@_]; }
	sub getwid { return $main::words{$_[0]}; }
	sub nextval { return ++$main::nextid; }
	sub sq { my $value = shift; $value =~ s/'/''/g; return $value; }
	sub dbInsert {
		my ($dbh, $args) = @_;
		if ($args->{INTO} eq 'words') {
			my ($uid, $word) = $args->{VALUES} =~ /^(\d+),'(.*)'$/;
			$main::words{$word} = $uid;
			push @main::dictionary_inserts, $args;
		} else {
			push @main::word_index_inserts, $args;
		}
		return (1, bless({}, 'XrefIndexStatement'));
	}
}
{
	package XrefIndexStatement;
	sub finish { return 1; }
}

sub load_sub {
	my ($file, $name) = @_;
	open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/$file" or die $!;
	my $source = do { local $/; <$in> };
	close $in;
	my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
	die "$name not found" unless defined $sub;
	eval "package Noosphere; our (\$dbh, \$DEBUG); $sub";
	die $@ if $@;
}

load_sub('Indexing.pm', 'wordIndexEntry');

$Noosphere::dbh = bless({}, 'XrefIndexDatabase');
Noosphere::wordIndexEntry('objects', {id => 116, data => 'ignored by test'});

is_deeply($dropped[0], [116, 'objects'], 'replaces the prior index for the article');
is(scalar(@dictionary_inserts), 2, 'creates each missing distinct dictionary word once');
is(scalar(@word_index_inserts), 2, 'creates one word-index row per distinct word');
is_deeply([sort values %words], [1, 2], 'allocates dictionary identifiers through the sequence');
like($word_index_inserts[0]->{VALUES}, qr/^\d+,116,'objects'$/, 'indexes the selected article and table');

my $worker = do {
	open my $in, '<', "$FindBin::Bin/../update-xref-word-index" or die $!;
	local $/; <$in>;
};
like($worker, qr/Noosphere::wordIndexEntry\(\$table, \$entry\)/,
	'background worker maintains the index outside article requests');
like($worker, qr/not exists \(select 1 from wordidx/i,
	'background worker selects only articles without an index row');

done_testing();
