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

my ($browse_handler) = $source =~ /^(sub pacsBrowse \{.*?)(?=^# the generic MSC browser)/ms;
die 'pacsBrowse not found' unless defined $browse_handler;

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

my @leaves = Noosphere::pacsBrowseLeaves('msc', 'classification', 'clinks', 'objects', '02.30.Xx');
is(scalar @leaves, 1, 'entries in a broad PACS node are returned');
is($leaves[0]->{uid}, 1140, 'object id is retained');
is($leaves[0]->{domain}, 'objects', 'domain is retained');
is($leaves[0]->{title}, 'math-title(Calculus of Variations: The Euler--Lagrange equation)',
	'title is prepared for the browse template');
like($Noosphere::last_query, qr/msc\.id = '02\.30\.Xx'/, 'query matches the selected category');
like($Noosphere::last_query, qr/clinks\.a = msc\.uid/, 'query expands the selected category through its descendants');
like($Noosphere::last_query, qr/classification\.tbl = 'objects'/, 'query scopes entries to the requested table');
like($Noosphere::last_query, qr/limit 101/, 'broad subject pages bound the article list');

Noosphere::pacsBrowseLeaves('msc', 'classification', 'clinks', 'objects', '01.65. g');
like($Noosphere::last_query, qr/msc\.id = '01\.65\.\+g'/, 'PACS plus signs survive Apache space decoding');

Noosphere::pacsBrowseLeaves('msc', 'classification', 'clinks', 'objects', "02.30.Xx'");
like($Noosphere::last_query, qr/msc\.id = '02\.30\.Xx'''/, 'category ids are SQL-escaped');

my @invalid = Noosphere::pacsBrowseLeaves('msc', 'classification', 'clinks', 'users', '02.30.Xx');
is(scalar @invalid, 0, 'unsupported browse domains do not query');

open my $template, '<', "$FindBin::Bin/../../stemplates/pacsbrowse.tt" or die $!;
my $template_source = do { local $/; <$template> };
close $template;

like($template_source, qr/pacsnode\.count/, 'template renders per-node entry counts');
like($template_source, qr{href="/browse/\[% domain %\]/"}, 'top link uses the current browse domain');
unlike($template_source, qr/pacs_leaves\.first\s*\]\]\/domain/, 'leaf top link does not stringify a hash');
like($template_source, qr/domain == 'objects'/, 'object subject browse has encyclopedia navigation');
like($template_source, qr{<a href="/encyclopedia">Alphabetical index</a>}, 'object subject browse links to alphabetical index');
like($template_source, qr{<a href="/\?op=listobj&amp;from=objects">Browse and search</a>}, 'object subject browse links to browse and search');
like($template_source, qr/Find a classification topic/, 'subject browser provides a classification search');
like($template_source, qr/pl-subject-browser-node/, 'subject browser renders a structured category list');
like($template_source, qr/Up one level/, 'subject browser provides parent navigation');
like($template_source, qr/one of its subcategories/, 'subject browser explains descendant article results');
like($template_source, qr/pacs_leaves_limited/, 'subject browser explains bounded broad-subject results');
like($source, qr/# leaf level.*?\$upstr\s*=\s*defined \$upid \? "\$upid\/" : '';/s,
	'leaf subject pages preserve their immediate parent in the up-one-level path');
like($browse_handler, qr/elsif \(defined lookupfield\(\$scheme, 'id', "parent='" \. sq\(\$id\) \. "'"\)\)/,
	'PACS categories expand based on actual child records rather than identifier spelling');
unlike($browse_handler, qr/elsif \(\$id =~ \/XX\$\/io\)/,
	'PACS browsing does not assume only XX-suffixed categories can have children');

done_testing();
