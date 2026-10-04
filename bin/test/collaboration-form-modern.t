#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use XML::LibXML;
use XML::LibXSLT;
use HTML::TreeBuilder;
use HTML::Parser;
use HTML::Entities qw(encode_entities);
use Template;
use Noosphere::TemplateNS;
use Noosphere::RequestForm;

our ($dbh, $AllowCache);
my $root = "$FindBin::Bin/../..";
my (@queries, @sql, @file_calls, %fixtures);
our ($rendered, $renders, $inserts, $updates, $copied) = ('<p id="preview-equation">F = ma</p>', 0, 0, 0, 0);
our %record = (title => 'Existing <draft>', data => '\\begin{document}Existing\\end{document}', version => 3, _lock => 0);
sub getConfig { +{collab_tbl => 'collab', template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
    template_cmd_prefix => 'NS', siteaddrs => {}, main_url => 'https://physicslibrary.org'}->{$_[0]} }
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub htmlescape { encode_entities($_[0] // '', '<>&') }
sub loginExpired { 'Login Expired' }
sub errorMessage { $_[0] }
sub getPreferredRenderMethod { $_[0] }
sub makeTempCacheDir { 'tmp/new-collaboration' }
sub copyBoxFilesToTemp { $copied++; $_[1]{tempdir} = 'tmp/existing-collaboration'; }
sub renderCollabPreview { $renders++; $rendered }
sub insertCollab { $inserts++; 'inserted collaboration' }
sub updateCollab { $updates++; 'updated collaboration' }
sub collabMain { 'collaboration workspace' }
sub lookupfield { push @queries, [@_]; $record{$_[1]} || 0 }
sub handleFileManager {
    my ($template, $params, $upload) = @_;
    push @file_calls, [@_];
    my $box = TemplateNS->new('filemanagerform.html');
    $box->setKeys(tempdir => $params->{tempdir}, filelist => 'diagram.svg', filechanges => '',
        ferror => '', fb_urls => '', rmlist => '<label><input type="checkbox" name="remove" value="diagram.svg"/> diagram.svg</label>');
    $template->setKey('fmanager', $box->expand);
}
my $legacy = readFile("$FindBin::Bin/fixtures/editcollab-legacy.xsl");
my $modern = readFile("$root/stemplates/editcollab.xsl");
my $engine = XML::LibXSLT->new;
sub stylesheet {
    my $fragment = shift;
    my $wrapper = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="html"/>'
        . '<xsl:template match="NSXSLT"><xsl:apply-templates select="editcollab"/></xsl:template>'
        . $fragment;
    for my $name (qw(paddingtable makebox mathbox)) {
        $wrapper .= '<xsl:template name="'.$name.'"><xsl:param name="title"/><xsl:param name="content"/><xsl:copy-of select="$content"/></xsl:template>';
    }
    return $engine->parse_stylesheet(XML::LibXML->load_xml(string => $wrapper.'</xsl:stylesheet>'));
}
my $style = stylesheet($modern);
my $xsl_source = readFile("$root/lib/Noosphere/XSLTemplate.pm");
for my $name (qw(XSLTemplate::addText XSLTemplate::setKey XSLTemplate::setKeys XSLTemplate::isProtected getXSLKeyMap)) {
    my ($body) = $xsl_source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless $body;
    # The legacy key map treats absent keys as protected without warnings enabled.
    eval(($name eq 'XSLTemplate::isProtected' ? "no warnings 'uninitialized'; " : '').$body); die $@ if $@;
}
{
    package XSLTemplate;
    sub new { bless {TEXT => '', SET_KEYS => {}, KEY_MAP => Noosphere::getXSLKeyMap($modern)}, shift }
    sub expand {
        my $self = shift;
        my $xml = '<NSXSLT>'.$self->{TEXT}.'<globals><main_url>https://physicslibrary.org</main_url></globals></NSXSLT>';
        my $doc = XML::LibXML->load_xml(string => $xml);
        return $style->output_string($style->transform($doc));
    }
    package CollabDB;
    sub do { push @sql, $_[1]; }
}
$dbh = bless {}, 'CollabDB';
my $source = readFile("$root/lib/Noosphere/Collab.pm");
for my $name (qw(editCollab checkCollab)) {
    my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless $body; eval $body; die $@ if $@;
}
my $user = {uid => 1, ticket => 'a' x 64, data => {active => 1}, prefs => {cmethod => 'make4ht'}};
my %draft = (new => 1, from => 'collab', title => 'Safe <draft> & "title"', abstract => 'Comment <tag> & detail',
    data => '\\documentclass{article}\\begin{document}A < B & C\\end{document}', tempdir => 'tmp/draft', version => '', id => '');
sub form { editCollab({%draft, @_}, $user, 'upload fixture', \%record) }
sub tree { HTML::TreeBuilder->new(ignore_unknown => 0)->parse_content($_[0]) }
sub contract {
    my $dom = tree($_[0]);
    my @controls;
    for my $input ($dom->look_down(sub { $_[0]->tag =~ /^(?:input|textarea)$/ })) {
        next unless $input->attr('name');
        push @controls, [map {$_ // ''} $input->tag, $input->attr('name'), $input->attr('type'),
            $input->tag eq 'textarea' ? $input->as_text : $input->attr('value'), $input->attr('multiple')];
    }
    my $f = $dom->look_down(_tag => 'form');
    my $attributes = [map {$f->attr($_)} qw(method action enctype accept-charset)];
    $dom->delete;
    return [$attributes, \@controls];
}
for my $mode (qw(edit preview filebox update)) {
    for my $new (0, 1) {
        next if $mode eq 'update' && $new;
        my $t = XSLTemplate->new;
        $t->addText('<editcollab>'); $t->setKeys(%draft, mode => $mode, new => $new);
        $t->addText('<preview><content><p>Preview content</p></content></preview>');
        handleFileManager($t, \%draft, undef) if $mode eq 'filebox';
        $t->addText('</editcollab>');
        my $old = stylesheet($legacy);
        my $doc = XML::LibXML->load_xml(string => '<NSXSLT>'.$t->{TEXT}.'<globals><main_url>https://physicslibrary.org</main_url></globals></NSXSLT>');
        my $old_html = $old->output_string($old->transform($doc));
        my $html = $t->expand;
        is_deeply(contract($html), contract($old_html), "$mode new=$new retains exact form fields, values, buttons and upload contract");
        $fixtures{"$mode-$new"} = $html;
        like($html, qr/<header class="pl-modern-box-header">/, 'compact shared-style blue header');
        unlike($html, qr/name="(?:title|data)" value="[^"\n]*<draft>/, 'submitted content escaped');
        my ($depth, $nested, $tokens) = (0, 0, 0);
        HTML::Parser->new(start_h => [sub {
            $nested++ if $_[0] eq 'form' && $depth++;
            $tokens++ if $_[0] eq 'input' && ($_[1]{name} || '') eq '_form_token';
        }, 'tagname, attr'], end_h => [sub { $depth-- if $_[0] eq 'form' }, 'tagname'])->parse(requestFormDecorate($html, $user));
        is($nested, 0, 'no nested forms'); is($depth, 0, 'closed form'); is($tokens, 1, 'CSRF decoration retained');
    }
}
my $html = editCollab({new => 1, from => 'collab'}, $user);
like($html, qr/tmp\/new-collaboration/, 'new form creates and retains temporary directory');
$fixtures{blank} = $html;
is($copied, 0, 'new form does not copy existing document files');
is($inserts, 0, 'opening new form does not insert a document');
is(editCollab({new => 1}, {uid => -1}), 'Login Expired', 'guest cannot create collaborations');
@queries = ();
$html = form(preview => 'preview', title => '', data => '');
like($html, qr/Document is empty!/, 'failed preview displays document validation');
like($html, qr/A title is required\./, 'failed preview displays title validation');
like($html, qr/name="data"/, 'failed preview returns to editable source');
is($renders, 0, 'invalid preview does not invoke renderer');
is(scalar @queries, 0, 'new document validation does not query empty existing-object id');
$fixtures{invalid} = $html;
$html = form(preview => 'preview');
like($html, qr/id="preview-equation"/, 'valid preview keeps rendered content');
is($renders, 1, 'valid preview renders once');
is($AllowCache, 0, 'preview disables response cache');
$fixtures{preview} = $html;
{
    local $rendered = '';
    $fixtures{'preview-error'} = form(preview => 'preview');
    like($fixtures{'preview-error'}, qr/Error rendering your LaTeX!/, 'empty preview displays original rendering-failure message');
}
$html = form(filebox => 'upload');
like($html, qr/Manage This Object's Filebox/, 'filebox fragment retained');
like($html, qr/type="file"/, 'upload field retained');
like($html, qr/name="remove"/, 'file deletion selector retained');
is($file_calls[-1][2], 'upload fixture', 'uploads passed to existing file manager');
$fixtures{filebox} = $html;
is(form(save => 'finish and save'), 'inserted collaboration', 'valid new save dispatches existing insertion');
is($inserts, 1, 'new save inserts once');
$html = form(save => 'finish and save', title => '');
like($html, qr/A title is required/, 'invalid save stays on form');
is($inserts, 1, 'invalid save does not insert');
@sql = ();
is(form(abort => 'abort'), 'collaboration workspace', 'new abort returns to workspace');
is(scalar @sql, 0, 'new abort does not issue update with an empty object id');
{
    local $record{version} = 5;
    $html = form(new => 0, id => 7, version => 3, save => 'finish and save');
    like($html, qr/more recent copy/, 'existing revision conflict preserved');
    local $record{_lock} = 1; local $record{lockuser} = 2;
    $html = form(new => 0, id => 7, version => 5, preview => 'preview');
    like($html, qr/someone else has checked out/, 'existing lock validation preserved in preview');
    $fixtures{conflict} = $html;
}
@sql = ();
is(form(new => 0, id => 7, version => 3, abort => 'abort'), 'collaboration workspace', 'existing abort returns to workspace');
like($sql[0], qr/set _lock=0 where uid=7/, 'existing abort releases the lock');
$html = form(new => 0, id => 7, version => 3, save => 'finish and save');
like($html, qr/name="revcomment"/, 'existing save still requests revision comment');
is(form(new => 0, id => 7, version => 3, save => 'commit', revcomment => 'Revision'), 'updated collaboration', 'revision commit dispatches existing update');
is($updates, 1, 'existing update called once');
if (my $dir = $ENV{COLLAB_FORM_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu}, \$sidebar) or die $tt->error;
    for my $name (keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Collaboration form preview', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!; print {$out} $page; close $out;
    }
}
done_testing();
