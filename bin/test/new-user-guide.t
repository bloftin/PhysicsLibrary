#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use Test::More;
use Template;
use XML::LibXML;
use XML::LibXSLT;
use HTML::Parser;

my $root = "$FindBin::Bin/../..";
sub getConfig { {template_path => "$root/stemplates", collab_tbl => 'collab', acl_tbl => 'acl'}->{$_[0]} }
sub read_file { open my $in, '<', "$root/$_[0]" or die $!; return do {local $/; <$in>}; }
our $dbh;
{
    package GuideTestDB;
    sub new { bless {}, shift }
    sub prepare { die 'documentation index database path'; }
}
$dbh = GuideTestDB->new;
for my $spec (['Docs.pm', 'getNewUserGuide'], ['Collab.pm', 'siteDoc']) {
    my ($file, $name) = @$spec;
    my ($body) = read_file("lib/Noosphere/$file") =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless defined $body;
    eval $body;
    die $@ if $@;
}
my $html = siteDoc({guide => 'newuser'}, {uid => -1});
like($html, qr/<h1>PhysicsLibrary New User Guide<\/h1>/, 'anonymous reader gets the local guide without a database query');
like($html, qr/<header class="pl-modern-box-header">/, 'guide uses the shared compact blue heading');
unlike($html, qr/paddingTable|Add to the Encyclopedia/, 'guide has no old spacing wrapper');
for my $guide ('', 'unknown', '../newuser', 'license') {
    eval { siteDoc({guide => $guide}, {uid => -1}) };
    like($@, qr/documentation index database path/, "$guide keeps the existing documentation index path, not dynamic file access");
}
my (%ids, @links);
my $parser = HTML::Parser->new(api_version => 3);
$parser->handler(start => sub {
    my ($tag, $attr) = @_;
    $ids{$attr->{id}}++ if defined $attr->{id};
    push @links, $attr->{href} if $tag eq 'a';
}, 'tagname, attr');
$parser->parse($html); $parser->eof;
is($ids{$_}, 1, "$_ section has one stable anchor") for qw(getting-started alternate metadata preview files mathworld);
for my $link (grep { /^#/ } @links) {
    ok($ids{substr($link, 1)}, "$link navigation reaches a guide section");
}
like($html, qr/alternate entry should add something substantially different/, 'alternate-entry guidance is present');
like($html, qr/canonical entry names/, 'related-entry metadata convention explained');
like($html, qr/, 01\.30\.Pp/, 'classification examples retained');
like($html, qr/Preview does not publish/, 'preview and submission distinguished');
like($html, qr/Multiple files can be selected together/, 'current filebox workflow explained');
like($html, qr/href="\/\?op=license"/, 'guide links current site license');
unlike($html, qr/aux\.planetphysics\.org/, 'guide does not depend on the unavailable historical host');
for my $file (qw(stemplates/addencyclopedia.tt stemplates/addencyclopedia.xsl)) {
    my $source = read_file($file);
    unlike($source, qr/aux\.planetphysics\.org\/doc\/newuser\.html/, "$file no longer links the old new-user page");
    my @anchors = $source =~ /href="\/\?op=sitedoc;guide=newuser#([\w-]+)"/g;
    ok(@anchors >= 2, "$file links the local guide");
    ok($ids{$_}, "$file #$_ destination exists") for @anchors;
}
my $xml = XML::LibXML->new;
ok(eval {
    $xml->parse_string('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">'.
        read_file('stemplates/addencyclopedia.xsl').'</xsl:stylesheet>'); 1;
}, 'legacy creation XSL remains well-formed') or diag($@);
my $xslt = XML::LibXSLT->new;
my $sheet = $xslt->parse_stylesheet($xml->parse_string(read_file('stemplates/sitedoc.xsl')));
for my $items ('', '<docitem><uid>28</uid><title>Existing style guide</title><abstract>Existing guidance</abstract></docitem>') {
    my $output = $sheet->output_string($sheet->transform($xml->parse_string("<sitedoc><items>$items</items></sitedoc>")));
    like($output, qr/href="\/\?op=sitedoc;guide=newuser"/, 'documentation center links the new guide even without collaborative docs');
    like($output, qr/Aaron Krowne's PlanetMath/, 'historical thesis link remains');
    like($output, qr/Existing style guide/, 'existing collaborative documentation remains') if $items;
}

if (my $dir = $ENV{NEW_USER_GUIDE_TEST_DIR}) {
    my $tt = Template->new({ INCLUDE_PATH => "$root/stemplates" });
    my ($sidebar, $menu, $page) = ('', '', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu}, \$sidebar) or die $tt->error;
    $tt->process('view.tt', {title => 'PhysicsLibrary New User Guide', site_name => 'Physics Library',
        content => $html, sidebar => $sidebar,
        header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
    open my $out, '>', "$dir/guide.html" or die $!;
    print {$out} $page;
    close $out;
}
done_testing();
