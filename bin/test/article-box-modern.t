#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Template;
use lib "$FindBin::Bin/../../lib";
use Noosphere::TemplateNS;

my $root = "$FindBin::Bin/../..";
{
    package Noosphere;
    our ($content, @render_calls);
    sub getConfig {
        return {stemplate_path => "$FindBin::Bin/../../stemplates", template_cmd_prefix => 'NS',
            siteaddrs => {}, main_url => 'https://physicslibrary.org', en_tbl => 'objects'}->{$_[0]};
    }
    sub readFile { open my $in, '<', $_[0] or die $!; return do {local $/; <$in>}; }
    sub htmlescape { my $s = $_[0] // ''; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; return $s; }
    sub urlescape { return $_[0]; }
    sub nb { return defined($_[0]) && length($_[0]); }
    sub getPreferredRenderMethod { return 'make4ht'; }
    sub getRenderedContentHtml { push @render_calls, [@_]; return $content; }
    sub isWorldWriteable { return 1; }
    sub mathTitle { return $_[0]; }
    sub getAuthorCount { return 2; }
    sub getPastOwnerCount { return 1; }
    sub getUpArrow { return '<a href="'.$_[0].'" title="Parent article"><img src="/images/uparrow.png" alt="[parent]"></a>'; }
    sub getTypeString { return 'Definition'; }
    sub getEncyclopediaMetadata { return '<p id="metadata">Existing article metadata</p>'; }
    sub getViewStyleWidget { return '<form><label>View style: <select name="method"><option>'.$_[1].'</option></select></label></form>'; }
    sub makeBox { return $_[1]; }
    sub getEncyclopediaInteract { return ''; }
    sub getComputationalResources { return [{title => 'Energy explorer', explorer => '/examples/energy/'}]; }
    sub getAddr { return 'feedback@example.invalid'; }
    sub errorMessage { return '<p class="error">'.$_[0].'</p>'; }
}
for my $spec (['Layout.pm', 'mathBox'], ['Encyclopedia.pm', 'renderEncyclopediaObj']) {
    my ($file, $name) = @$spec;
    my $source = Noosphere::readFile("$root/lib/Noosphere/$file");
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless defined $sub;
    eval "package Noosphere; $sub";
    die $@ if $@;
}
my $new = Template->can('new');
{
    no warnings qw(redefine once);
    *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$root/stemplates"}) };
}
my $rec = {uid => 1360, title => 'Conservation of Mechanical Energy', type => 1,
    userid => 1, username => 'bloftin', parentid => -1};
my $user = {uid => 1, prefs => {method => 'make4ht'}};
my $body = '<p id="article-body">Kinetic energy + potential energy = constant.</p>'.
    '<table class="tabular"><tr><td class="td11">E</td><td>K + U</td></tr></table>';
$Noosphere::content = $body;
my $default_html;
for my $method (qw(make4ht l2h png pdf src)) {
    @Noosphere::render_calls = ();
    my $html = Noosphere::renderEncyclopediaObj($rec, {from => 'objects', id => 1360, method => $method}, $user);
    $default_html = $html if $method eq 'make4ht';
    like($html, qr/<section class="pl-article-box">/, "$method uses the modern article box");
    like($html, qr/<h1 class="pl-article-title">Conservation of Mechanical Energy<\/h1>/, 'entry title has a semantic heading');
    like($html, qr/<span class="pl-article-type">\(Definition\)<\/span>/, 'article type is preserved');
    like($html, qr/\Q$body\E/, 'rendered body and mathematical tables are passed through unchanged');
    like($html, qr/op=getuser&amp;id=1/, 'owner link is preserved');
    like($html, qr/op=authorlist.*op=ownerhistory/s, 'author and owner history links are preserved');
    like($html, qr/op=preamble&amp;id=1360/, 'preamble link is preserved');
    like($html, qr/<select name="method"><option>$method/, 'view style control is still connected');
    like($html, qr/id="metadata"/, 'metadata is retained');
    like($html, qr/href="\/examples\/energy\/"/, 'computational resources remain available');
    is(scalar @Noosphere::render_calls, 1, 'article is fetched only once');
    is($Noosphere::render_calls[0][2], $method, 'renderer selection is unchanged');
    unlike($html, qr/<header[^>]*>.*?<table.*?<\/header>/s, 'header has no layout table');
    unlike($html, qr/bgcolor="#000000"/i, 'old black table frame is removed');
}
my $parent_html = Noosphere::renderEncyclopediaObj({%$rec, parentid => 116},
    {from => 'objects', id => 1360}, $user);
like($parent_html, qr/pl-article-parent.*op=getobj&amp;from=objects&amp;id=116/s, 'attachment parent link is retained');
like($parent_html, qr/title="Parent article"/, 'parent control remains named');
my $long_title = 'ConservationOfMechanicalEnergyWithAnUnbrokenTitleThatMustWrapOnANarrowScreen';
my $long_html = Noosphere::renderEncyclopediaObj({%$rec, title => $long_title},
    {from => 'objects', id => 1360}, $user);
like($long_html, qr/\Q$long_title\E/, 'long titles are not truncated');
my $math_title = 'Energy <img src="/images/equation.png" alt="E = mc squared">';
like(Noosphere::renderEncyclopediaObj({%$rec, title => $math_title}, {from => 'objects'}, $user),
    qr/\Q$math_title\E/, 'established mathematical title HTML is preserved');
my $preview = Noosphere::mathBox('Preview', $body);
like($preview, qr/<header class="pl-article-box-header">Preview<\/header>/, 'plain preview titles still work');
like($preview, qr/\Q$body\E/, 'preview body is unchanged');
my $box = TemplateNS->new('mathbox.html');
$box->setKeys(title => 'Preview', content => $body, ratingsbar => '<span>Existing rating</span>');
like($box->expand, qr/Existing rating/, 'optional ratings content is retained');
$Noosphere::content = '';
like(Noosphere::renderEncyclopediaObj($rec, {from => 'objects'}, $user),
    qr/Missing cached output/, 'missing-output behavior remains intact');

my $tt = Template->new;
my $page = '';
ok($tt->process('getobj.tt', {renderObj => $default_html, watch => '<a>Watch</a>',
    author => '<a>Edit</a>', corrections => '<p>Corrections</p>', messages => '<p>Discussion</p>'}, \$page),
    'outer object template renders with the modern box') or diag($tt->error);
like($page, qr/cellspacing="0"/, 'outer object layout removes the header alignment gap');
like($page, qr/Watch.*Edit.*Corrections.*Discussion/s, 'surrounding object controls remain intact');
like($default_html, qr/background: #003399.*padding: \.15rem \.5rem/s, 'header matches the compact original-blue style');
like($default_html, qr/overflow-wrap: anywhere/, 'long title wrapping is scoped to the heading');
like($default_html, qr/table\.tabular.*border-collapse: collapse/s, 'mathematical table styling is retained');

# Optional fixtures for browser QA without invoking a renderer or production cache.
if (my $dir = $ENV{ARTICLE_BOX_TEST_DIR}) {
    for my $fixture (['default', $default_html], ['long', $long_html], ['parent', $parent_html], ['preview', $preview]) {
        open my $out, '>', "$dir/article-box-$fixture->[0].html" or die $!;
        print {$out} $fixture->[1];
        close $out;
    }
}
done_testing();
