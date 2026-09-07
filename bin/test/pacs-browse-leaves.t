#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Msc.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;

my ($helper) = $source =~ /^(sub pacsBrowseLeaves \{.*?)(?=^sub |\z)/ms;
die 'pacsBrowseLeaves not found' unless defined $helper;

{
	package Noosphere;
	use strict;
	use warnings;
	our $dbh = 'dbh';
	our $last_query = '';
	our @rows = (
		{
			uid      => 1140,
			userid   => 1,
			username => 'bloftin',
			title    => 'Calculus of Variations: The Euler--Lagrange equation',
		},
	);

	sub sq {
		my $value = shift;
		$value =~ s/'/''/g;
		return $value;
	}

	sub dbLowLevelSelect {
		my ($dbh, $query) = @_;
		$last_query = $query;
		return (1, 'sth');
	}

	sub dbGetRows {
		return @rows;
	}

	sub mathTitleXSL {
		return "math-title($_[0])";
	}

	eval $helper;
	die $@ if $@;
}

my @leaves = Noosphere::pacsBrowseLeaves('msc', 'classification', 'objects', '02.30.Xx');
is(scalar @leaves, 1, 'directly classified entries are returned for a broad PACS node');
is($leaves[0]->{uid}, 1140, 'object id is retained');
is($leaves[0]->{domain}, 'objects', 'domain is retained');
is($leaves[0]->{title}, 'math-title(Calculus of Variations: The Euler--Lagrange equation)',
	'title is prepared for the browse template');
like($Noosphere::last_query, qr/msc\.id = '02\.30\.Xx'/, 'query matches the selected category directly');
like($Noosphere::last_query, qr/classification\.tbl = 'objects'/, 'query scopes entries to the requested table');

Noosphere::pacsBrowseLeaves('msc', 'classification', 'objects', '01.65. g');
like($Noosphere::last_query, qr/msc\.id = '01\.65\.\+g'/, 'PACS plus signs survive Apache space decoding');

Noosphere::pacsBrowseLeaves('msc', 'classification', 'objects', "02.30.Xx'");
like($Noosphere::last_query, qr/msc\.id = '02\.30\.Xx'''/, 'category ids are SQL-escaped');

my @invalid = Noosphere::pacsBrowseLeaves('msc', 'classification', 'users', '02.30.Xx');
is(scalar @invalid, 0, 'unsupported browse domains do not query');

open my $template, '<', "$FindBin::Bin/../../stemplates/pacsbrowse.tt" or die $!;
my $template_source = do { local $/; <$template> };
close $template;

like($template_source, qr/pacsnode\.count/, 'template renders per-node entry counts');
like($template_source, qr/pacs_leaves\.0\.domain/, 'leaf top link uses the leaf domain');
unlike($template_source, qr/pacs_leaves\.first\s*\]\]\/domain/, 'leaf top link does not stringify a hash');

done_testing();
