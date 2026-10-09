#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Encode qw(encode);
use Template;
use lib "$FindBin::Bin/../../lib";
use Noosphere::ArticleMetadata;

my $prose = 'The vector triple product relates three vectors through two cross products and a useful algebraic identity.';
sub description { return Noosphere::getArticleDescription($_[0], $_[1] // 'make4ht'); }
is(description('<p>'.$prose.'</p>'), $prose, 'description comes from rendered article prose');
is(description('<p>'.$prose.'</p>', 'l2h'), $prose, 'legacy HTML rendering is supported');
for my $method (qw(src pdf png unknown)) {
    is(description('<p>'.$prose.'</p>', $method), '', "$method does not describe source/view controls as article prose");
}
is(description(undef), '', 'missing content has no invented description');
is(description([]), '', 'non-string input is ignored');
is(description('<p>Just a title</p>'), '', 'tiny fragments do not become generic snippets');
for my $failure (
    'Rendering failed. make4ht exited with status 256.',
    'This entry needs to be rendered, but on-demand rendering is temporarily disabled while Physics Library is under heavy load.',
    'Rendering is already in progress or could not be completed. Please try again shortly.',
    'Missing cached output! Please contact an admin.',
) {
    is(description('<p>'.$failure.'</p>'), '', 'rendering placeholders are never advertised as an article description');
}
my $article = '<html><head><title>Navigation title</title><style>secret css</style></head><body>'.
    '<h1>Vector Triple Product</h1><h2>Introduction</h2>'.
    '<div class="tableofcontents"><a>Unrelated contents</a></div>'.
    '<nav>Next previous home</nav><form>View style</form>'.
    '<!-- hidden comment --><script>secret()</script><pre>Compiler output</pre>'.
    '<p>'.$prose.'</p></body></html>';
is(description($article), $prose, 'headings, table of contents, navigation, scripts, styles and compiler/source blocks are excluded');
is(description('<div hidden>Hidden text</div><span aria-hidden="true">More hidden text</span>'.
    '<div style="display: none"><p>Nested hidden text</p></div><p>'.$prose.'</p>'),
    $prose, 'hidden content and nested hidden descendants are excluded');
is(description('<div class="math"><span>large math source</span></div>'.
    '<math><mrow>formula</mrow></math><p>'.$prose.'</p>'), $prose, 'math markup is not treated as prose');
is(description('<div hidden><img src="x"><br><input value="private"><span>Hidden</span></div>'.
    '<p>'.$prose.'</p>'), $prose, 'void elements cannot leave the parser stuck in a hidden region');
is(description('<p>The vector <em>triple</em> product relates three vectors through two cross products and a useful algebraic identity.</p>'),
    $prose, 'inline formatting preserves word boundaries');
is(description('<p>The vector triple product relates three vectors</p><p>through two cross products and a useful algebraic identity.</p>'),
    $prose, 'paragraph boundaries insert spaces');
is(description("<p>The vector triple product relates three vectors\nthrough two cross products and a useful algebraic identity.</p>"),
    $prose, 'line breaks are normalized without merging words');
is(description((' ' x 20000).'<p>'.$prose.'</p>'), $prose,
    'leading generated whitespace does not exhaust the prose budget');
my $entities = 'Energy & momentum are linked; "radiation pressure" depends on the intensity of the incident wave.';
is(description('<p>Energy &amp; momentum are linked; &quot;radiation pressure&quot; depends on the intensity of the incident wave.</p>'),
    $entities, 'HTML entities are decoded once');
my $unicode = 'Caf'.chr(0xe9).' physics: '.chr(0x3b1).' and '.chr(0x3b2).' describe parameters in this example of conserved mechanical energy.';
is(description('<p>'.$unicode.'</p>'), $unicode, 'decoded Unicode prose is retained');
is(description(encode('UTF-8', '<p>'.$unicode.'</p>')), $unicode, 'UTF-8 byte content is decoded');
my $long = description('<p>'.($prose.' ') x 10000 .'</p>');
ok(length($long) <= 200, 'large articles produce a bounded description');
like($long, qr/\.\.\.\z/, 'clipped descriptions end with an ellipsis');
unlike($long, qr/alge\.\.\./, 'clipping does not split a trailing ordinary word');
is(description('<script>'.('x' x 70000).'</script><p>'.$prose.'</p>'), '', 'only a bounded input window is parsed');
is(description('<p>'.$prose.'</p><script>'.('x' x 70000)), $prose, 'malformed trailing script does not contribute text');

my $tt = Template->new({INCLUDE_PATH => "$FindBin::Bin/../../stemplates"});
for my $canonical ('', 'https://physicslibrary.org/encyclopedia/VectorTripleProduct.html') {
    my $html = '';
    ok($tt->process('view.tt', {canonical_url => $canonical,
        article_description => $entities.' <not markup>'}, \$html), 'shared page template renders') or diag($tt->error);
    if ($canonical) {
        like($html, qr{<head>.*<meta name="description" content="Energy &amp; momentum.*&quot;radiation pressure&quot;.*&lt;not markup&gt;" />.*</head>}s,
            'one description is safely escaped in the document head');
        is(scalar(() = $html =~ /name="description"/g), 1, 'exactly one description is emitted');
    } else {
        unlike($html, qr/name="description"/, 'non-article pages cannot acquire an article description');
    }
}
my $html = '';
$tt->process('view.tt', {canonical_url => 'https://example.invalid/Article.html'}, \$html) or die $tt->error;
unlike($html, qr/name="description"/, 'no empty description is emitted');
done_testing();
