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

like($source, qr/\bpacssearch\.tt\b/, 'PACS search uses its dedicated template');
like($source, qr/term\s*=>\s*qhtmlescape\(\$term\)/, 'search term is escaped for the template');
like($source, qr/results\s*=>\s*\\\@results/, 'search results are passed to the template');
like($template, qr/Search Subjects/, 'template has a modern search heading');
like($template, qr/Browse by subject/, 'template returns to the subject browser');
like($template, qr/pl-pacs-search-result/, 'template renders structured results');
like($template, qr/No classifications match this search/, 'template has an empty search state');

done_testing();
