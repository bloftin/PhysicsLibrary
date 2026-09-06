#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use Encode qw(decode FB_CROAK);
use XML::LibXML;

# Exercise the real wrapper builder without Apache, a database, or make4ht.
my $dir = tempdir(CLEANUP => 1);
my @warnings;
sub getConfig { return $_[0] eq 'cache_root' ? $dir : 'physicslibrary.html'; }
sub dwarn { push @warnings, $_[0]; }
open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Latex.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;
for my $name (qw(postProcess_make4htIndex make4ht_document_style decodeRenderedHTML escapeNonAsciiAsHTMLEntities)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name not found" unless defined $sub;
    eval $sub;
    die $@ if $@;
}
sub write_fixture {
    my ($name, $text) = @_;
    open my $out, '>:encoding(UTF-8)', "$dir/$name" or die $!;
    print {$out} $text;
    close $out;
}
sub wrapper {
    open my $in, '<', "$dir/physicslibrary.html" or die $!;
    return do { local $/; <$in> };
}

my $body = <<'HTML';
<h2>Table formatting</h2>
<p><span id="textcolor1">Nominal</span>, <span id="textcolor3">Critical</span></p>
<p><span id="textcolor5">E = mc<sup>2</sup></span></p>
<p><a href="https://example.org"><span id="textcolor9">Reference</span></a></p>
<table class="tabular"><tr><td id="TBL-16-3-2">Caution</td><td id="TBL-16-4-2">Nominal</td></tr></table>
<p class="crosslinks">Print navigation</p>
<p class="special">Escaped CSS content</p>
<div class="selector"><span data-label="a&amp;b">Child selector</span></div>
HTML
write_fixture('TestTableFormatting.html', '<html><head><link href="TestTableFormatting.css" rel="stylesheet" /></head><body>' . $body . '</body></html>');
my $css = <<'CSS';
p { margin-top: 0; margin-bottom: 0; }
td { padding: 8px; }
span#textcolor1{color:#00FF00}
span#textcolor3{color:#FF0000}
span#textcolor5{color:#0000FF}
span#textcolor9{color:#FF00FF}
#TBL-16-3-2{background-color:#FFFF00}
#TBL-16-4-2{background-color:#00FF00}
@media print { .crosslinks { visibility: hidden; } }
.selector > span[data-label="a&b"] { color: #008080; }
.special::before { content: "</style><script>alert(1)</script> & ]]>"; }
CSS
$css .= '.special::after { content: "' . chr(0x3b1) . '"; }';
write_fixture('TestTableFormatting.css', $css);

is(postProcess_make4htIndex('https://example.org/cache', $dir, 'TestTableFormatting.html'), 1,
    'wrapper builds with generated CSS');
my $html = wrapper();
like($html, qr/span#textcolor3\{color:#FF0000\}/, 'text color is retained');
like($html, qr/span#textcolor5\{color:#0000FF\}/, 'math color is retained');
like($html, qr/span#textcolor9\{color:#FF00FF\}/, 'explicit link color is retained');
like($html, qr/#TBL-16-3-2\{background-color:#FFFF00\}/, 'cell background is retained');
like($html, qr/<div class="pl-make4ht-content"><style[^>]+pl-make4ht-generated-css.*\@scope \{/s,
    'generated stylesheet is scoped to its own content wrapper');
like($html, qr/\@media print \{ .crosslinks/, 'nested media rule retained');
like($html, qr/\.selector > span\[data-label="a&b"\]/, 'CSS selectors and ampersands preserved');
unlike($html, qr{</style><script>}i, 'CSS cannot close the HTML style element');
like($html, qr/\\3b1 /, 'Unicode CSS uses CSS escapes');
unlike($html, qr/[^\x00-\x7f]/, 'cached output remains ASCII');
like($html, qr/max-width: 52em/, 'existing article typography retained');
like($html, qr/<h2>Table formatting/, 'article body retained');
my $xml = eval { XML::LibXML->load_xml(string => "<content>$html</content>") };
ok($xml, 'style and content parse as collaboration XML') or diag($@);
if ($xml) {
    my ($style) = $xml->findnodes('//style[@class="pl-make4ht-generated-css"]');
    like($style->textContent, qr/data-label="a&b"/, 'XML parsing preserves CSS syntax');
}

# Optional artifact for browser verification, outside the production cache.
if (my $artifact = $ENV{MAKE4HT_CSS_TEST_PAGE}) {
    open my $out, '>', $artifact or die $!;
    print {$out} '<!DOCTYPE html><html><head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1" /></head><body>';
    print {$out} '<nav><p id="outside">Site navigation</p><table><tr><td id="outside-cell">Site cell</td></tr></table><span data-label="a&amp;b" id="outside-span">Outside color</span></nav>';
    print {$out} $html;
    print {$out} '<div class="pl-make4ht-content" id="other-document"><span id="textcolor3">Another document</span></div></body></html>';
    close $out;
}

write_fixture('TestTableFormatting.css', 'span#textcolor3{color:#800080}');
postProcess_make4htIndex('https://example.org/cache', $dir, 'TestTableFormatting.html');
like(wrapper(), qr/color:#800080/, 'rerender picks up updated stylesheet');
unlike(wrapper(), qr/color:#FF0000/, 'rerender replaces previous stylesheet');
unlink "$dir/TestTableFormatting.css" or die $!;
is(postProcess_make4htIndex('https://example.org/cache', $dir, 'TestTableFormatting.html'), 1,
    'missing CSS does not prevent rendering');
unlike(wrapper(), qr/pl-make4ht-generated-css/, 'missing CSS produces no empty style block');
write_fixture('TestTableFormatting.css', '');
is(make4ht_document_style($dir, 'TestTableFormatting.html'), '', 'empty CSS is optional');
is_deeply(\@warnings, [], 'normal and missing-CSS paths do not warn');
done_testing();
