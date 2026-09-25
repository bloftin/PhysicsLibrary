#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

sub read_file {
	open my $fh, '<', $_[0] or die $!;
	local $/;
	return <$fh>;
}

my $root = "$FindBin::Bin/../..";
my $source = read_file("$root/lib/Noosphere/Msc.pm");
my $template = read_file("$root/stemplates/pacssearch.tt");

my ($condition_helper) = $source =~ /^(sub pacsSearchCondition \{.*?)(?=^# Search PACS labels)/ms;
die 'pacsSearchCondition not found' unless defined $condition_helper;

{
	package Noosphere;
	use strict;
	use warnings;

	sub sq {
		my $value = shift;
		$value =~ s/'/''/g;
		$value =~ s/\\/\\\\/g;
		return $value;
	}

	eval $condition_helper;
	die $@ if $@;
}

is(
	Noosphere::pacsSearchCondition('quantum mechanics', 'matched_msc'),
	"(matched_msc.comment like '%quantum%' or matched_msc.id='quantum') and (matched_msc.comment like '%mechanics%' or matched_msc.id='mechanics')",
	'classification conditions search the requested MSC alias',
);
is(
	Noosphere::pacsSearchCondition("-O'Reilly", 'msc'),
	"msc.comment not like '%O''Reilly%'",
	'negative classification terms are SQL-escaped',
);

like($source, qr/\bpacssearch\.tt\b/, 'PACS search uses its dedicated template');
like($source, qr/term\s*=>\s*qhtmlescape\(\$term\)/, 'search term is escaped for the template');
like($source, qr/results\s*=>\s*\\\@results/, 'search results are passed to the template');
like($source, qr/article_results\s*=>\s*\\\@article_results/, 'classified article results are passed to the template');
like($source, qr/\$clinks\.a = matched_msc\.uid/, 'article search expands matching PACS classifications through their descendants');
like($source, qr/\$class\.tbl = 'objects'/, 'article search is limited to encyclopedia entries');
like($source, qr/limit 101/, 'article search has a bounded result set');
like($template, qr/Search Subjects/, 'template has a modern search heading');
like($template, qr/Browse by subject/, 'template returns to the subject browser');
like($template, qr/pl-pacs-search-result/, 'template renders structured results');
like($template, qr/No classifications match this search/, 'template has an empty search state');
like($template, qr/Articles in Matching Classifications/, 'template distinguishes classified articles from PACS labels');
like($template, qr/pl-pacs-search-article/, 'template renders classified articles as a separate result list');
like($template, qr/first 100 matching articles/, 'template explains the article result cap');

done_testing();
