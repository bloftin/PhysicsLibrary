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

my $source = read_file("$root/lib/Noosphere/Orphan.pm");
like($source, qr/Template->new\(\{ INCLUDE_PATH => '\/var\/www\/pp\/stemplates' \}\)/,
    'orphanage uses a dedicated presentation template');
like($source, qr/\$tt->process\('orphanage\.tt'/,
    'orphanage renders the dedicated template');
like($source, qr/qhtmlescape\(\$row->\{'title'\}\)/,
    'orphaned article titles are escaped before presentation');
like($source, qr/qhtmlescape\(\$title\)/,
    'adoptable article titles are escaped before presentation');
like($source, qr/orphaned_total\s*=>\s*scalar\(\@orphaned_rows\)/,
    'template receives the orphaned article total');
like($source, qr/adoptable_total\s*=>\s*scalar\(\@adoptable_rows\)/,
    'template receives the adoptable article total');

my $template = read_file("$root/stemplates/orphanage.tt");
like($template, qr/<h1>Orphanage<\/h1>/,
    'template provides the page heading');
like($template, qr/Orphaned Articles/,
    'template separates fully orphaned articles');
like($template, qr/Available for Adoption/,
    'template separates articles still owned but eligible for adoption');
like($template, qr/\[% article\.adopthref %\]/,
    'template keeps the existing adoption action');
like($template, qr/All articles currently have homes/,
    'template retains the empty state');

SKIP: {
    eval { require Template; 1 } or skip 'Template Toolkit is not installed locally', 4;
    my $tt = Template->new({ INCLUDE_PATH => "$root/stemplates" });
    my $html = '';
    ok($tt->process('orphanage.tt', {
        orphaned => [{title => 'Unowned article', titlehref => '/?op=getobj', owner => 'Previous owner unknown', adopthref => '/?op=adopt'}],
        adoptable => [{title => 'Available article', titlehref => '/?op=getobj', owner => 'Currently maintained by editor', adopthref => '/?op=adopt'}],
        orphaned_total => 1, adoptable_total => 1,
    }, \$html), 'template renders representative orphanage rows') or diag($tt->error());
    like($html, qr/Unowned article/, 'rendered output includes orphaned row');
    like($html, qr/Available article/, 'rendered output includes adoptable row');
    like($html, qr/Adopt article/, 'rendered output includes adoption controls');
}

done_testing();
