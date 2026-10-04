#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use HTML::Parser;
use HTML::Entities qw(encode_entities decode_entities);
use URI::Escape qw(uri_escape);
use Noosphere::TemplateNS;
use Noosphere::RequestForm;

my $root = "$FindBin::Bin/../..";
my $tt = Template->new({ INCLUDE_PATH => ["$root/stemplates", "$FindBin::Bin/fixtures"] });
our ($dbh, $stats, $AllowCache);
my ($render_count, $insert_count, $insert_ok, $duplicate) = (0, 0, 1, 0);
my (@file_calls, @effects, @insert_values);
sub getConfig {
    return {template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
        template_cmd_prefix => 'NS', siteaddrs => {}, en_tbl => 'objects',
        classification_supported => 1, main_url => 'https://physicslibrary.org',
        projname => 'Physics Library', typestrings => {1 => 'Definition', 2 => 'Theorem', 10 => 'Proof'}}->{$_[0]};
}
sub readFile { open my $in, '<', $_[0] or die $!; return do {local $/; <$in>}; }
sub htmlescape { encode_entities($_[0] // '', '<>&') }
sub qhtmlescape { encode_entities($_[0] // '', q{<>&"'}) }
sub urlescape { uri_escape($_[0]) }
sub normalize { $_[0] }
sub swaptitle { $_[0] }
sub uniquename { 'DraftArticle' }
sub htmlToLatin1 { $_[0] }
sub normalizeEncyclopediaSourceParams { }
sub normalizePronunciation { $_[1] }
sub blank { !defined($_[0]) || $_[0] !~ /\S/ }
sub nb { !blank($_[0]) }
sub isAttachmentType { $_[0] eq 'Proof' }
sub objectExistsByName { $duplicate }
sub objectExistsByAny { $_[0] eq 'ParentArticle' }
sub getidbyname { 116 }
sub classstring { '45.20.Jj' }
sub getRequestFiller { '' }
sub gettypebox { '' }
sub getUnfilledReqsEscaped { {'-1' => '[none]', 90 => 'Conservation of energy', 91 => 'Another request'} }
sub getPreferredRenderMethod { $_[0] || 'make4ht' }
sub renderEnPreview {
    $render_count++;
    return mathBox('Draft article', '<p id="rendered-equation">E = K + U</p>');
}
sub errorMessage { '<p class="error">'.$_[0].'</p>' }
sub nextval { 1362 }
sub getScore { 1 }
sub THEOREM { 2 }
sub classify { push @effects, 'classify'; return 1 }
sub moveTempFilesToBox { push @effects, 'move files' }
sub indexTitle { push @effects, 'index title' }
sub deleteSynonyms { }
sub createSynonyms { }
sub changeUserScore { }
sub addWatchIfAllowed { }
sub installDefaultACL { }
sub xrefTitleInvalidate { }
sub symmetricRelated { }
sub addAuthorEntry { }
sub fillReq { push @effects, 'fill request' }

{
    package EntryTestDB;
    sub new { bless {}, shift }
    sub prepare { $_[0] }
    sub execute { shift; $insert_count++; @insert_values = @_; return $insert_ok }
    package EntryTestStats;
    sub new { bless {}, shift }
    sub invalidate { push @effects, $_[1] }
    package XSLTemplate;
    sub new { bless {keys => {}}, shift }
    sub addText { }
    sub setKey { $_[0]->{keys}{$_[1]} = $_[2] }
    sub setKeys { }
    sub setKeysIfUnset { }
}
$dbh = EntryTestDB->new;
$stats = EntryTestStats->new;

sub filebox_html {
    my ($params) = @_;
    my $box = TemplateNS->new('filemanagerform.html');
    $box->setKeys(ferror => $params->{ferror} // '', fb_urls => $params->{fb_urls} // '',
        tempdir => 'tmp/demo', filelist => $params->{filelist} // '', filechanges => '',
        rmlist => $params->{filelist} ? '<input type="checkbox" name="remove" value="diagram.svg" /><a href="/cache/tmp/demo/diagram.svg">diagram.svg</a>' : '[no files]');
    return $box->expand;
}
sub handleFileManager {
    my ($template, $params, $upload) = @_;
    push @file_calls, [$params, $upload];
    return ($template, filebox_html($params));
}

my $source = readFile("$root/lib/Noosphere/Encyclopedia.pm");
my ($math_box) = readFile("$root/lib/Noosphere/Layout.pm") =~ /(^sub mathBox\b.*?)(?=^sub |\z)/ms;
die 'Missing mathBox' unless defined $math_box;
eval $math_box;
die $@ if $@;
for my $name (qw(addEncyclopedia refreshAddEncyclopedia previewEncyclopedia checkEncyclopediaEntry insertEncyclopedia)) {
    my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless defined $body;
    eval $body;
    die $@ if $@;
}

sub render_form {
    my ($file, $vars) = @_;
    my $html = '';
    $tt->process($file, $vars, \$html) or die $tt->error;
    return $html;
}
sub contract {
    my ($html) = @_;
    my (@forms, @controls, @links, $text, $active, $skip, $option);
    $text = '';
    my $p = HTML::Parser->new(api_version => 3);
    $p->handler(start => sub {
        my ($tag, $attr) = @_;
        $skip = $tag if $tag eq 'style' || $tag eq 'script';
        return if $skip;
        push @forms, {map { $_ => $attr->{$_} } qw(method action enctype accept-charset)} if $tag eq 'form';
        push @links, {map { $_ => $attr->{$_} // '' } qw(href target)} if $tag eq 'a';
        if ($tag eq 'input' || $tag eq 'textarea' || $tag eq 'select') {
            my $control = {tag => $tag, map { $_ => $attr->{$_} // '' }
                qw(name value size maxlength cols rows multiple)};
            $control->{type} = lc($attr->{type} // 'text');
            $control->{$_} = exists $attr->{$_} ? 1 : 0 for qw(checked disabled required);
            push @controls, $control;
            $active = $control if $tag eq 'textarea' || $tag eq 'select';
        }
        if ($tag eq 'option') {
            $option = {value => $attr->{value}, selected => exists $attr->{selected} ? 1 : 0, text => ''};
            push @{$active->{options}}, $option;
        }
    }, 'tagname, attr');
    $p->handler(text => sub {
        return if $skip;
        my $value = decode_entities($_[0]);
        $text .= $value;
        $active->{value} .= $value if $active && $active->{tag} eq 'textarea';
        $option->{text} .= $value if $option;
    }, 'text');
    $p->handler(end => sub {
        $skip = undef if $skip && $_[0] eq $skip;
        $active = undef if $_[0] eq 'textarea' || $_[0] eq 'select';
        $option = undef if $_[0] eq 'option';
    }, 'tagname');
    $p->parse($html); $p->eof;
    $_->{text} =~ s/^\s+|\s+$//g for map { @{$_->{options} // []} } @controls;
    $text =~ s/\s+//g;
    $text =~ s/^AddanEncyclopediaEntry//;
    return {forms => \@forms, controls => \@controls, links => \@links, text => $text};
}
my $params = {op => 'adden', id => '', type => 'Definition', title => 'Draft article', parent => '',
    self => 'on', request => 90, class => '45.20.Jj', synonyms => 'Draft', defines => 'Energy',
    related => '', keywords => 'energy, mechanics', pronounce => 'energy', version => 0,
    preamble => "\\usepackage{amsmath}\n", data => "\\section{Energy}\nE = K + U"};
my $user = {uid => 7, prefs => {method => 'make4ht'}, data => {preamble => '\\usepackage{amsmath}'}};
my %base = (params => $params, parent => '', type => 'Definition',
    type_hash => getConfig('typestrings'), fillreq => getUnfilledReqsEscaped(),
    classification_supported => 1, preamble => $params->{preamble}, data => $params->{data},
    id => '', op => 'adden', fmanager_flag => 1, fmanager => filebox_html({}));
for my $case (
    ['initial', {}], ['preview', {preview => 1, showpreview => renderEnPreview()}],
    ['validation messages', {preview => 1, error => 'Need a title!<br />Need some content!<br />'}],
    ['uploaded files', {fmanager => filebox_html({filelist => 'diagram.svg'})}],
    ['filebox errors', {fmanager => filebox_html({ferror => 'Upload failed<br />', fb_urls => 'https://example.invalid/diagram.svg'})}],
    ['no classification or filebox', {classification_supported => 0, fmanager_flag => 0}],
    ['corrections fragment', {corrections_flag => 1, corrections => '<p id="corrections">Existing corrections</p>'}],
) {
    my ($name, $overrides) = @$case;
    subtest "$name preserves the original form contract" => sub {
        my %vars = (%base, %$overrides);
        my $old = contract(render_form('addencyclopedia-legacy.tt', \%vars));
        my $html = render_form('addencyclopedia.tt', \%vars);
        my $new = contract($html);
        is_deeply($new->{forms}, $old->{forms}, 'POST, multipart encoding, charset and action unchanged');
        is_deeply($new->{controls}, $old->{controls}, 'all controls, values, dimensions, type/request options and actions unchanged');
        is_deeply($new->{links}, $old->{links}, 'all guidance and file links preserved');
        is($new->{text}, $old->{text}, 'all original wording and punctuation preserved');
        like($html, qr/\Q$vars{fmanager}\E/, 'raw filebox preserved') if $vars{fmanager_flag};
        my $protected = requestFormDecorate($html, {uid => 7, ticket => 'a' x 64, data => {active => 1}}, '/?op=adden');
        is(scalar(() = $protected =~ /name="_form_token"/g), 1, 'one CSRF token on the single form');
        is(scalar @{contract($protected)->{forms}}, 1, 'no nested forms');
    };
}
subtest 'draft values and request titles are escaped without losing content' => sub {
    my $value = qq{A "quote" <tag> & value\n</textarea><script>alert(1)</script>};
    my %draft = map { $_ => $value } qw(title parent class synonyms defines related keywords pronounce);
    my $html = render_form('addencyclopedia.tt', {%base, params => \%draft, parent => $value,
        preamble => $value, data => $value, fillreq => {'-1' => '[none]', 90 => $value}});
    my %controls = map {$_->{name} => $_} @{contract($html)->{controls}};
    is($controls{$_}{value}, $value, "$_ round-trips") for qw(title parent class synonyms defines related keywords pronounce preamble data);
    is($controls{request}{options}[1]{text}, $value, 'request title is preserved as text');
    unlike($html, qr/<script>alert\(1\)<\/script>/, 'draft and request values cannot inject markup');
    ok(!grep($_->{required}, values %controls), 'partial filebox actions not blocked by new browser validation');
    like($html, qr/for="entry-$_"/, "$_ has an associated label") for qw(type title parent self request class synonyms defines related keywords pronounce preamble data);
};
subtest 'real creation and preview handlers preserve the workflow' => sub {
    @file_calls = (); $render_count = 0; $insert_count = 0;
    like(addEncyclopedia({%$params}, {uid => -1}), qr/You can't post anonymously/, 'anonymous creation blocked');
    is(scalar @file_calls, 0, 'anonymous request does not access filebox');
    my $initial = addEncyclopedia({%$params}, $user);
    like($initial, qr/<h1>Add an Encyclopedia Entry<\/h1>/, 'initial handler selects modern form');
    unlike($initial, qr/name="post"/, 'save still only appears after preview');
    unlike($initial, qr/Add to the Encyclopedia/, 'no duplicate legacy wrapper');
    my $preview = addEncyclopedia({%$params, preview => 'preview'}, $user);
    like($preview, qr/id="rendered-equation"/, 'preview output passed through unchanged');
    like($preview, qr/name="post" value="save changes"/, 'preview retains save action');
    is($render_count, 1, 'renderer called once with no redundant work');
    is($insert_count, 0, 'preview does not insert');
    is($AllowCache, 0, 'preview disables request caching');
    my $bad = addEncyclopedia({%$params, title => '', data => '', preview => 'preview'}, $user);
    like($bad, qr/role="alert">Need a title!<br\s*\/>Need some content!/, 'actual preview validation messages reach visible form');
    is($render_count, 1, 'invalid preview does not invoke renderer');
    my $warning = addEncyclopedia({%$params, class => '', preview => 'preview'}, $user);
    like($warning, qr/Please classify your entry.*PACS search/s, 'non-blocking classification warning restored');
    like($warning, qr/id="rendered-equation"/, 'warning does not suppress preview');
    my $unsafe = addEncyclopedia({%$params, related => '<script>alert(1)</script>', preview => 'preview'}, $user);
    like($unsafe, qr/Cannot find related object '&lt;script&gt;/, 'reflected related-object error escaped');
    unlike($unsafe, qr/<script>alert\(1\)<\/script>/, 'error cannot inject markup');
    my $upload = {filename => 'diagram.svg'};
    for my $action (qw(upload remove)) {
        my $html = addEncyclopedia({%$params, filebox => $action, filelist => 'diagram.svg'}, $user, $upload);
        like($html, qr/value="Draft article"/, "$action retains metadata");
        like($html, qr/\\section\{Energy\}/, "$action retains LaTeX source");
        is($file_calls[-1][1], $upload, "$action forwards upload argument unchanged");
    }
    my $legacy = XSLTemplate->new;
    is(previewEncyclopedia($legacy, {%$params}, $user), renderEnPreview(), 'legacy scalar callers still receive only rendered HTML');
    ok(exists $legacy->{keys}{error}, 'legacy XSL error key still populated');
    my $saved = addEncyclopedia({%$params, post => 'save changes'}, $user);
    like($saved, qr/<h1>Added<\/h1>/, 'successful insertion returns modern Added page');
    like($saved, qr/Thank you for your addition to Physics Library\. Click/, 'original thank-you wording preserved');
    like($saved, qr/href="https:\/\/physicslibrary.org\/\?op=getobj&amp;from=objects&amp;name=DraftArticle">here<\/a>/, 'original article destination retained and escaped');
    is($insert_count, 1, 'submission inserts exactly once');
    is($insert_values[4], $params->{preamble}, 'preamble reaches insertion unchanged');
    is($insert_values[5], $params->{data}, 'article source reaches insertion unchanged');
    ok(grep($_ eq 'move files', @effects), 'files still moved after insertion');
    ok(grep($_ eq 'index title', @effects), 'title still indexed');
    ok(grep($_ eq 'fill request', @effects), 'request still fulfilled');
    ok(grep($_ eq 'latestadds', @effects), 'latest additions still invalidated');
    $insert_ok = 0;
    my $failed = addEncyclopedia({%$params, post => 'save changes'}, $user);
    like($failed, qr/Couldn't insert your item/, 'database failure still returns error');
    unlike($failed, qr/pl-entry-added/, 'no false success on insertion failure');
    $duplicate = 1;
    my $before = $insert_count;
    like(addEncyclopedia({%$params, post => 'save changes'}, $user), qr/Something strange happened/, 'duplicate guard preserved');
    is($insert_count, $before, 'duplicate does not insert');
    $duplicate = 0; $insert_ok = 1;
};
my $safe_added = render_form('addedencyclopedia.tt', {project_name => '<Physics & Library>', entry_url => '/?name="quote"&from=objects'});
like($safe_added, qr/&lt;Physics &amp; Library&gt;/, 'confirmation project name escaped');
like($safe_added, qr/name=&quot;quote&quot;&amp;from=objects/, 'confirmation URL escaped');
like(readFile("$root/stemplates/addencyclopedia.tt"), qr/pl-add-entry-filebox \{ background: #f1f4f7/, 'filebox uses menu background');

# Browser fixtures render real templates without a live database or TeX compiler.
if (my $dir = $ENV{ADD_ENTRY_TEST_DIR}) {
    my ($menu, $sidebar) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    for my $fixture (
        ['initial', render_form('addencyclopedia.tt', \%base)],
        ['preview', render_form('addencyclopedia.tt', {%base, preview => 1, showpreview => renderEnPreview()})],
        ['error', addEncyclopedia({%$params, title => '', data => '', preview => 'preview'}, $user)],
        ['uploaded', render_form('addencyclopedia.tt', {%base, fmanager => filebox_html({filelist => 'diagram.svg'})})],
        ['added', render_form('addedencyclopedia.tt', {project_name => 'Physics Library', entry_url => '/?op=getobj&from=objects&name=DraftArticle'})],
    ) {
        my $page = '';
        $tt->process('view.tt', {title => 'Add an Encyclopedia Entry', site_name => 'Physics Library',
            content => $fixture->[1], sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$fixture->[0].html" or die $!;
        print {$out} $page;
        close $out;
    }
}
done_testing();
