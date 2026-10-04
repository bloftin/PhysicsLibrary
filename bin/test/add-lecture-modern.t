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
use Noosphere::TemplateNS;
use Noosphere::RequestForm;

my $root = "$FindBin::Bin/../..";
my $tt = Template->new({ INCLUDE_PATH => "$root/stemplates" });
my $inserts = 0;
my @file_calls;
sub getConfig {
    return { stemplate_path => "$root/stemplates", exp_tbl => 'lec', books_tbl => 'books',
        template_cmd_prefix => 'NS', siteaddrs => {},
        main_url => 'https://physicslibrary.org' }->{$_[0]};
}
sub readFile { open my $in, '<', $_[0] or die $!; return do { local $/; <$in> }; }
sub htmlescape { encode_entities($_[0] // '', '<>&') }
sub dwarn { }
sub getIsA {
    my ($table, $plural) = @_;
    return $plural ? {lec => 'Lectures', books => 'Books', papers => 'Papers'}->{$table} :
        {lec => 'Lecture', books => 'Book', papers => 'Paper'}->{$table};
}
sub errorMessage { $_[0] }
sub paddingTable { $_[0] }
sub makeBox { "$_[0]: $_[1]" }
sub insertGeneric { $inserts++; return 42 }
sub genericTempFileBoxHasFiles { 1 }

# Keep the real filebox fragment, but replace filesystem/upload work with fixtures.
sub filebox_html {
    my ($params) = @_;
    my $t = TemplateNS->new('filemanagerform.html');
    $t->setKeys(ferror => $params->{ferror} // '', fb_urls => $params->{fb_urls} // '',
        tempdir => $params->{tempdir} // 'tmp/demo', filelist => $params->{filelist} // '',
        filechanges => $params->{filechanges} // '',
        rmlist => $params->{rmlist} // ($params->{filelist} ? '<input type="checkbox" name="remove" value="notes.pdf" /><a href="/cache/tmp/demo/notes.pdf">notes.pdf</a><br />' : '[no files]'));
    return $t->expand();
}
sub handleFileManager {
    my ($template, $params, $upload) = @_;
    push @file_calls, [$params, $upload];
    return ($template, filebox_html($params));
}
{
    package XSLTemplate;
    sub new { bless {}, shift }
    sub addText { }
    sub setKeysIfUnset { }
    sub setKey { }
}
my $source = readFile("$root/lib/Noosphere/GenericObject.pm");
for my $name (qw(addGeneric checkAddGeneric)) {
    my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "missing $name" unless defined $body;
    eval $body;
    die $@ if $@;
}

sub render_form {
    my ($template, $vars) = @_;
    my $html = '';
    $tt->process($template, $vars, \$html) or die $tt->error();
    return $html;
}

sub form_contract {
    my ($html) = @_;
    my (@forms, @controls, @links, $text, $textarea, $skip);
    $text = '';
    my $p = HTML::Parser->new(api_version => 3);
    $p->handler(start => sub {
        my ($tag, $attr) = @_;
        $skip = $tag if $tag eq 'script' || $tag eq 'style';
        return if $skip;
        push @forms, {map { $_ => $attr->{$_} } qw(method action enctype accept-charset)} if $tag eq 'form';
        push @links, {map { $_ => $attr->{$_} // '' } qw(href target)} if $tag eq 'a';
        if ($tag eq 'input' || $tag eq 'textarea') {
            my $control = {tag => $tag, map { $_ => $attr->{$_} // '' }
                qw(name value size max cols rows multiple checked disabled required)};
            # The old invalid comments type already behaves as a text input in browsers.
            $control->{type} = lc($attr->{type} // 'text');
            $control->{type} = 'text' if $control->{type} eq 'comments';
            $control->{required} = exists $attr->{required} ? 1 : 0;
            push @controls, $control;
            $textarea = $control if $tag eq 'textarea';
        }
    }, 'tagname, attr');
    $p->handler(text => sub {
        return if $skip;
        my $value = decode_entities($_[0]);
        $text .= $value;
        $textarea->{value} .= $value if $textarea;
    }, 'text');
    $p->handler(end => sub {
        $skip = undef if $skip && $_[0] eq $skip;
        $textarea = undef if $_[0] eq 'textarea';
    }, 'tagname');
    $p->parse($html);
    $p->eof;
    $text =~ s/\s+//g;
    return {forms => \@forms, controls => \@controls, links => \@links, text => $text};
}

for my $case (
    ['empty', {}],
    ['filled', {title => 'Mechanics notes', authors => 'A. Author', keywords => 'pulleys, inertia',
        class => '45.20.Jj', comments => '2026, 25 pages', rights => 'Public domain',
        data => "A lecture on mechanics.\nWith exercises.", urls => "https://example.invalid/notes\nhttps://example.invalid/slides"}],
    ['validation error', {title => 'Retained title', error => 'Need an abstract.<br />Need at least one author.<br />Need a rights statement.<br />'}],
    ['uploaded files', {title => 'Uploaded lecture', filelist => 'notes.pdf', filechanges => 'yes', tempdir => 'tmp/demo'}],
    ['filebox error', {ferror => 'Problem getting the remote file<br/>', fb_urls => 'https://example.invalid/notes.pdf'}],
) {
    my ($name, $values) = @$case;
    subtest "$name preserves the original form" => sub {
        my $vars = {isa => 'Lecture', section => 'Lectures', op => 'addobj', to => 'lec',
            fmanager_flag => 1, %$values, fmanager => filebox_html($values)};
        my $old = form_contract(render_form('addgeneric.tt', $vars));
        my $new_html = render_form('addlecture.tt', $vars);
        my $new = form_contract($new_html);
        is_deeply($new->{forms}, $old->{forms}, 'POST action, multipart encoding and charset are unchanged');
        is_deeply($new->{controls}, $old->{controls}, 'every field, value, upload option and submit action is retained');
        is_deeply($new->{links}, $old->{links}, 'every guidance and file link is retained');
        is($new->{text}, $old->{text}, 'all original words and punctuation are retained');
        like($new_html, qr/\Q$vars->{fmanager}\E/, 'the original filebox fragment is embedded unchanged');
        like($new_html, qr/<header class="pl-modern-box-header"><h1>Add a Lecture<\/h1><\/header>/,
            'compact shared blue header replaces the legacy wrapper');
        my $user = {uid => 7, ticket => 'a' x 64, data => {active => 1}};
        my $decorated = requestFormDecorate($new_html, $user, '/?op=addobj;to=lec');
        like($decorated, qr/name="_form_token"/, 'multipart form still receives CSRF protection');
        my $protected = form_contract($decorated);
        is(scalar @{$protected->{forms}}, 1, 'filebox stays inside the single protected form');
    };
}

subtest 'lecture route and submission still use the existing handler' => sub {
    my $user = {uid => 7};
    my $params = {op => 'addobj', to => 'lec', title => 'Draft', data => '', authors => '', rights => '', filelist => '', urls => ''};
    like(addGeneric($params, $user), qr/class="pl-add-lecture"/, 'lecture GET selects the modern template');
    like(addGeneric({%$params, post => 'finished'}, $user), qr/Need an abstract\.<br \/>/,
        'original validation message remains visible');
    is($inserts, 0, 'invalid submission does not insert');
    my $upload = {filename => 'notes.pdf'};
    my $partial = addGeneric({%$params, filebox => 'upload'}, $user, $upload);
    like($partial, qr/value="Draft"/, 'partial upload retains title');
    is($file_calls[-1][1], $upload, 'upload reaches the unchanged file manager');
    is($inserts, 0, 'upload refresh does not finish the lecture');
    my $saved = addGeneric({%$params, post => 'finished', data => 'Abstract', authors => 'Author',
        rights => 'Public domain', urls => 'https://example.invalid/notes'}, $user);
    like($saved, qr/Lecture Added: Thank you for uploading your contribution/, 'valid submission still inserts and confirms');
    is($inserts, 1, 'valid submission inserts once');
    my $calls_before = scalar @file_calls;
    is(addGeneric($params, {uid => -1}), 'Must be logged in to add to the collection!', 'anonymous access stays blocked');
    is(scalar @file_calls, $calls_before, 'anonymous access does not reach file management');
    for my $table (qw(books papers)) {
        my $html = addGeneric({%$params, to => $table}, $user);
        unlike($html, qr/class="pl-add-lecture"/, "$table does not use the lecture template");
        like($html, qr/name="isbn"/, 'book ISBN option is unaffected') if $table eq 'books';
    }
};

subtest 'quoted and markup-like draft values round-trip safely' => sub {
    my %fields = map { $_ => qq{A "quoted" <tag> & value\n</textarea><script>alert(1)</script>} }
        qw(title authors keywords class comments rights data urls);
    my $html = render_form('addlecture.tt', {isa => 'Lecture', op => 'addobj', to => 'lec', %fields});
    my $contract = form_contract($html);
    my %values = map { $_->{name} => $_->{value} } @{$contract->{controls}};
    is($values{$_}, $fields{$_}, "$_ draft value is preserved as text") for sort keys %fields;
    unlike($html, qr/<script>alert\(1\)<\/script>/, 'draft values cannot inject executable markup');
    ok(!grep($_->{required}, @{$contract->{controls}}),
        'browser validation does not block partial filebox submissions');
    is(scalar @{$contract->{forms}}, 1, 'form still renders without a filebox');
    unlike($html, qr/Manage This Object's Filebox/, 'disabled filebox remains absent');
    for my $name (qw(title authors keywords class comments rights data urls)) {
        like($html, qr/<label for="lecture-\Q$name\E">/, "$name has an associated label");
    }
};

subtest 'book form preserves all original text and input options' => sub {
    for my $case (
        ['empty', {}],
        ['filled', {title => 'Mechanics book', authors => 'A. Author', keywords => 'inertia',
            class => '45.20.Jj', isbn => '978-0-123456-47-2', comments => '2026, 200 pages',
            rights => 'Public domain', data => "A textbook on mechanics.\nWith exercises.",
            urls => "https://example.invalid/book\nhttps://example.invalid/appendix"}],
        ['validation error', {title => 'Draft book', isbn => '978-0-123456-47-2',
            error => 'Need an abstract.<br />Need at least one author.<br />Need a rights statement.<br />'}],
        ['uploaded files', {filelist => 'notes.pdf', filechanges => 'yes', tempdir => 'tmp/demo'}],
        ['filebox error', {ferror => 'Problem getting the remote file<br/>', fb_urls => 'https://example.invalid/book.pdf'}],
        ['cover images', {filelist => 'coverimage.png;coverimage_big.png', filechanges => 'yes',
            rmlist => '<input type="checkbox" name="remove" value="coverimage.png" /><a href="/cache/tmp/demo/coverimage.png">coverimage.png</a><br /><input type="checkbox" name="remove" value="coverimage_big.png" /><a href="/cache/tmp/demo/coverimage_big.png">coverimage_big.png</a><br />'}],
    ) {
        my ($state, $values) = @$case;
        my $vars = {isa => 'Book', section => 'Books', op => 'addobj', to => 'books',
            fmanager_flag => 1, %$values, fmanager => filebox_html($values)};
        my $html = render_form('addbook.tt', $vars);
        is_deeply(form_contract($html), form_contract(render_form('addgeneric.tt', $vars)),
            "$state retains every word, link, field, value and submission option");
        like($html, qr/\Q$vars->{fmanager}\E/, "$state embeds the original filebox unchanged");
        my $user = {uid => 7, ticket => 'a' x 64, data => {active => 1}};
        my $protected = form_contract(requestFormDecorate($html, $user, '/?op=addobj;to=books'));
        is(scalar @{$protected->{forms}}, 1, "$state keeps filebox in the protected form");
        is(scalar grep($_->{name} eq '_form_token', @{$protected->{controls}}), 1,
            "$state receives a single CSRF field");
    }
    my %fields = map { $_ => q{A "quoted" <tag> & </textarea><script>alert(1)</script>} }
        qw(title authors keywords class isbn comments rights data urls);
    my $html = render_form('addbook.tt', {isa => 'Book', op => 'addobj', to => 'books', %fields});
    my $contract = form_contract($html);
    my %values = map { $_->{name} => $_->{value} } @{$contract->{controls}};
    for my $name (sort keys %fields) {
        is($values{$name}, $fields{$name}, "$name draft value round-trips safely");
        like($html, qr/<label for="book-\Q$name\E">/, "$name has an associated label");
    }
    unlike($html, qr/<script>alert\(1\)<\/script>/, 'book values cannot inject executable markup');
    ok(!grep($_->{required}, @{$contract->{controls}}), 'partial book uploads are not blocked by browser validation');
    unlike($html, qr/Manage This Object's Filebox/, 'book filebox respects the existing display flag');
};

subtest 'book handler preserves draft, validation and submission flow' => sub {
    $inserts = 0;
    my $user = {uid => 7};
    my $params = {op => 'addobj', to => 'books', title => 'Draft book', isbn => '978-0-123456-47-2',
        data => '', authors => '', rights => '', filelist => '', urls => ''};
    like(addGeneric($params, $user), qr/class="pl-add-book"/, 'books route selects the dedicated modern template');
    like(addGeneric({%$params, post => 'finished'}, $user), qr/Need an abstract\.<br \/>/,
        'book validation messages are unchanged');
    my $upload = {filename => 'book.pdf'};
    my $partial = addGeneric({%$params, filebox => 'upload'}, $user, $upload);
    is($file_calls[-1][1], $upload, 'book upload is passed to the existing file manager');
    like($partial, qr/name="isbn"[^>]*value="978-0-123456-47-2"/, 'upload refresh keeps the ISBN');
    like(addGeneric({%$params, filebox => 'remove', remove => 'notes.pdf'}, $user),
        qr/value="Draft book"/, 'file removal refresh keeps the title');
    is($inserts, 0, 'invalid, upload and removal submissions do not finish the book');
    my $saved = addGeneric({%$params, post => 'finished', data => 'Abstract', authors => 'Author',
        rights => 'Public domain', urls => 'https://example.invalid/book'}, $user);
    like($saved, qr/Book Added: Thank you for uploading your contribution/, 'valid book submission confirms insertion');
    like($saved, qr/from=books&id=42/, 'success link still opens the new book');
    is($inserts, 1, 'book is inserted exactly once');
    my $calls_before = scalar @file_calls;
    is(addGeneric($params, {uid => -1}), 'Must be logged in to add to the collection!', 'anonymous book creation stays blocked');
    is(scalar @file_calls, $calls_before, 'anonymous book access does not reach file management');
    unlike(addGeneric({%$params, to => 'papers'}, $user), qr/class="pl-add-book"/, 'paper creation keeps its legacy template');
};

my ($menu_background) = readFile("$root/stemplates/sidebar.tt") =~ /\.pl-sidebar-body\s*\{\s*background:\s*(#[\da-f]+)/i;
ok(defined $menu_background, 'sidebar menu background is defined');
like(readFile("$root/stemplates/addlecture.tt"),
    qr/\.pl-add-lecture-filebox\s*\{\s*background:\s*\Q$menu_background\E;\s*border: 1px solid #cbd6de;.*?padding: \.75rem;/,
    'lecture filebox stands out with the menu background, border and inner spacing');
like(readFile("$root/stemplates/addbook.tt"),
    qr/\.pl-add-book-filebox\s*\{\s*background:\s*\Q$menu_background\E;\s*border: 1px solid #cbd6de;.*?padding: \.75rem;/,
    'book filebox matches the menu background, border and inner spacing');

done_testing();
