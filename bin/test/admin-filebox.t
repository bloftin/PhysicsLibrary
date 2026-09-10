#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);
use File::chdir;
use File::Copy::Recursive qw(rmove);
use File::Remove qw(remove);
use Cwd qw(getcwd);
use HTML::Entities qw(encode_entities);

our ($dbh, $stats);
my $root = tempdir(CLEANUP => 1);
my $schema = {
    title => ['Title', 'text', '', 32],
    name => ['Canonical Name', 'text', '', 32],
    data => ['Data', 'tbox', '', 10, 80],
    preamble => ['Preamble', 'tbox', '', 6, 80],
    self => ['Contains own proof', 'check', 'off'],
};
my $record = {uid => 42, userid => 7, version => 3, title => 'Original title',
    name => 'Example', data => 'Original body', preamble => '', self => 1};
my $admin = {uid => 9, data => {access => 100}};
my (@updates, @snapshots, @invalidations, @events);
my $selects = 0;

sub getConfig {
    return {
        en_tbl => 'objects', en_schema => $schema,
        generic_schema => {books => {title => $schema->{title}}},
        access_editobj => 100, cache_root => "$root/cache", file_root => "$root/files",
        cache_url => '/cache', file_url => '/files', main_url => 'https://physicslibrary.org',
        stemplate_path => "$FindBin::Bin/../../stemplates", template_cmd_prefix => 'NS',
        siteaddrs => {}, projname => 'Physics Library',
    }->{$_[0]};
}
sub getMethods { return qw(make4ht pdf png src l2h); }
sub nb { defined($_[0]) && $_[0] =~ /\S/; }
sub blank { !nb($_[0]); }
sub inset { my $value = shift; return scalar grep { $_ eq $value } @_; }
sub dwarn { }
sub humanReadableCmp { $_[0] cmp $_[1]; }
sub htmlescape { encode_entities($_[0] // '', '<>&'); }
sub qhtmlescape { encode_entities($_[0] // '', '<>&"'); }
sub sq { my $s = shift; $s =~ s/'/''/g; return $s; }
sub paddingTable { $_[0]; }
sub makeBox { "<h2>$_[0]</h2>$_[1]"; }
sub errorMessage { "<p class=\"error\">$_[0]</p>"; }
sub noAccess { 'ACCESS DENIED'; }
sub readFile { open my $in, '<', $_[0] or die $!; local $/; return <$in>; }
sub dbSelect { $selects++; return (1, bless({}, 'AdminFileboxStatement')); }
sub dbUpdate { push @updates, $_[1]; return (1, bless({}, 'AdminFileboxStatement')); }
sub snapshot {
    push @snapshots, [@_];
    push @events, 'snapshot';
    is(readFile("$root/files/objects/42/original.txt"), 'original',
        'snapshot precedes replacement of live files');
}
sub handleEncyclopediaChange {
    push @invalidations, [@_];
    push @events, 'invalidate';
}
sub adminEditNote { push @events, 'notice'; return 1; }
sub makeObjLink { }
sub changeUserScore { }
sub getScore { 1; }
{ package AdminFileboxStatement;
  sub fetchrow_hashref { return $record; }
  sub finish { }
}
{ package AdminFileboxStats;
  sub invalidate { }
}
$stats = bless({}, 'AdminFileboxStats');

# Use the real templates and file manager, with isolated files and database stubs.
require Noosphere::TemplateNS;
require Noosphere::Filebox;
for my $spec (
    ['Admin.pm', qw(adminObjectEditor getAdminMetadataEditor adminUpdateObjectMetadata)],
    ['Util.pm', qw(makeTempCacheDir removeTempCacheDir getFormWidget)],
) {
    my ($file, @subs) = @$spec;
    my $source = readFile("$FindBin::Bin/../../lib/Noosphere/$file");
    for my $name (@subs) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name not found" unless defined $sub;
        eval $sub;
        die $@ if $@;
    }
}

sub put_file {
    open my $out, '>', $_[0] or die $!;
    print {$out} $_[1];
    close $out;
}
sub form_params {
    return {op => 'adminedit', from => 'objects', id => 42,
        (map { $_ => $record->{$_} } keys %$schema), self => 'on', @_};
}
make_path("$root/files/objects/42", "$root/cache");
put_file("$root/files/objects/42/original.txt", 'original');

my $params = {op => 'adminedit', from => 'objects', id => 42};
my $html = adminObjectEditor($params, $admin, {});
like($html, qr/enctype="multipart\/form-data"/, 'Qwik-edit accepts uploads');
like($html, qr/Manage This Object's Filebox/, 'existing filebox widget is present');
like($html, qr/name="upload"/, 'upload control is present');
like($html, qr/name="fb_urls"/, 'URL grab control is present');
like($html, qr/value="remove"/, 'remove control is present');
like($html, qr/value="Original title"/, 'initial metadata comes from the record');
my $stage = $params->{tempdir};
ok(-f "$root/cache/$stage/original.txt", 'existing files are staged on entry');
like($html, qr{href="/cache/\Q$stage\E/original.txt"}, 'file links open the staged copy');
is(scalar(@updates), 0, 'opening the editor does not save');

put_file("$root/upload.txt", 'new upload');
$params = form_params(tempdir => $stage, filebox => 'upload', title => 'Draft title',
    data => 'Draft <body>', remark => 'Keep </textarea> remark');
delete $params->{self};
$html = adminObjectEditor($params, $admin, {filename => 'new.txt', tempfile => "$root/upload.txt"});
ok(-f "$root/cache/$stage/new.txt", 'upload reaches staging');
ok(!-e "$root/files/objects/42/new.txt", 'upload does not alter live filebox');
like($html, qr/value="Draft title"/, 'upload preserves edited title');
like($html, qr/Draft &lt;body&gt;/, 'upload preserves and escapes edited body');
like($html, qr/Keep &lt;\/textarea&gt; remark/, 'upload preserves and escapes remark');
unlike($html, qr/name="self" checked/, 'unchecked metadata stays unchecked');
like($html, qr{href="/cache/\Q$stage\E/new.txt"}, 'new upload has a working staging URL');
is($params->{filechanges}, 'yes', 'file changes survive the next post');
is(scalar(@updates), 0, 'upload does not commit metadata');

$params->{filebox} = 'remove';
$params->{remove} = 'original.txt';
$html = adminObjectEditor($params, $admin, {});
ok(!-e "$root/cache/$stage/original.txt", 'remove affects staged copy');
ok(-f "$root/files/objects/42/original.txt", 'remove leaves live files intact');
like($html, qr/value="Draft title"/, 'remove preserves edited title');

delete $params->{filebox};
delete $params->{remove};
$params->{submit} = 'submit';
$params->{remark} = '';
$html = adminObjectEditor($params, $admin, {});
like($html, qr/must enter a remark/, 'submit still requires an edit remark');
like($html, qr/value="Draft title"/, 'missing remark redisplays the draft');
ok(-f "$root/cache/$stage/new.txt", 'missing remark preserves staged files');
is(scalar(@updates), 0, 'missing remark prevents commit');

$params->{remark} = 'Update figure and body';
$params->{remove} = 'new.txt';
$html = adminObjectEditor($params, $admin, {});
like($html, qr/Update Successful/, 'metadata and files can be submitted together');
ok(-f "$root/files/objects/42/new.txt", 'submit commits uploaded file');
ok(!-e "$root/files/objects/42/original.txt", 'submit commits file removal');
ok(!-d "$root/cache/$stage", 'successful submit cleans staging');
is(scalar(@snapshots), 1, 'combined edit creates one revision snapshot');
is(scalar(@invalidations), 1, 'combined edit invalidates rendered content');
like(join(' ', map { $_->{SET} } @updates), qr/title='Draft title'/, 'metadata changes are saved');
like(join(' ', map { $_->{SET} } @updates), qr/self=0/, 'unchecked metadata is saved');

# A file-only change must also create a revision and invalidate cached rendering.
put_file("$root/files/objects/42/original.txt", 'original');
$params = {op => 'adminedit', from => 'objects', id => 42};
adminObjectEditor($params, $admin, {});
$stage = $params->{tempdir};
@updates = (); @snapshots = (); @invalidations = ();
put_file("$root/replacement.txt", 'replacement');
$params = form_params(tempdir => $stage, submit2 => 'submit and go to home', remark => 'Replace figure');
$html = adminObjectEditor($params, $admin, {filename => 'new.txt', tempfile => "$root/replacement.txt"});
is(readFile("$root/files/objects/42/new.txt"), 'replacement', 'attachment submitted with main button is committed');
is_deeply([map { $_->{SET} } @updates], ['version=version+1'], 'file-only edit increments version without an empty SQL SET');
is(scalar(@invalidations), 1, 'file-only edit invalidates rendered content');
like($html, qr/url=\//, 'submit-and-home still redirects home');

$params = {op => 'adminedit', from => 'objects', id => 42};
adminObjectEditor($params, $admin, {});
$stage = $params->{tempdir};
remove_tree("$root/cache/$stage");
@updates = ();
$params = form_params(tempdir => $stage, filechanges => 'yes', submit => 'submit',
    title => 'Expired stage draft', remark => 'Keep draft');
$html = adminObjectEditor($params, $admin, {});
like($html, qr/temporary file area expired/, 'expired stage blocks the save');
like($html, qr/value="Expired stage draft"/, 'expired stage preserves text edits');
ok(-f "$root/cache/$params->{tempdir}/original.txt", 'expired stage is rebuilt from live files');
is(scalar(@updates), 0, 'expired stage cannot overwrite metadata or files');
is(readFile("$root/files/objects/42/new.txt"), 'replacement', 'expired stage preserves live attachments');

$stage = $params->{tempdir};
$params = form_params(tempdir => $stage, submit => 'submit', remark => 'Broken upload');
$html = adminObjectEditor($params, $admin, {filename => 'missing.txt', tempfile => "$root/missing"});
like($html, qr/Problem saving uploaded file/, 'upload error is shown in filebox');
is(scalar(@updates), 0, 'upload error prevents metadata commit');

$params = form_params(tempdir => $stage, submit => 'submit', remark => 'No changes');
$html = adminObjectEditor($params, $admin, {});
ok(!-d "$root/cache/$stage", 'unchanged staging is cleaned after submit');
is(scalar(@updates), 0, 'unchanged files and metadata do not create a revision');

my $before_selects = $selects;
$html = adminObjectEditor({from => 'objects', id => 42, filebox => 'remove'}, {data => {access => 99}}, {});
is($html, 'ACCESS DENIED', 'admin permission is enforced before file operations');
is($selects, $before_selects, 'denied request does not even query the object');
$html = adminObjectEditor(form_params(tempdir => '../objects/42', filebox => 'remove'), $admin, {});
like($html, qr/Invalid temporary file area/, 'tempdir traversal is rejected');
$html = adminObjectEditor({from => 'objects', id => '42 OR 1=1'}, $admin, {});
like($html, qr/Invalid object/, 'invalid object id is rejected');

$html = adminObjectEditor({from => 'books', id => 42}, $admin, {});
unlike($html, qr/Manage This Object's Filebox/, 'generic metadata editor is unchanged');
like($html, qr/Editing metadata/, 'generic metadata title is retained');

{
    no warnings qw(redefine once);
    local *wget = sub {
        my ($url, $dest) = @_;
        return 0 if $url =~ /missing/;
        put_file("$dest/grabbed.txt", 'downloaded');
        return 1;
    };
    $params = {op => 'adminedit', from => 'objects', id => 42};
    adminObjectEditor($params, $admin, {});
    $stage = $params->{tempdir};
    $params = form_params(tempdir => $stage, filebox => 'upload',
        fb_urls => "https://example.invalid/figure\nhttps://example.invalid/missing", remark => 'URL grab');
    $html = adminObjectEditor($params, $admin, {});
    ok(-f "$root/cache/$stage/grabbed.txt", 'URL grab uses the staged filebox');
    ok(!-e "$root/files/objects/42/grabbed.txt", 'URL grab does not publish immediately');
    like($html, qr/Problem getting https:\/\/example.invalid\/missing/, 'URL grab failure is displayed');
    like($html, qr/URL grab<\/textarea>/, 'URL grab preserves the remark');
}

my $template = templateFromText('');
my @manager = handleFileManager($template, {from => 'objects', id => 42}, {});
is(scalar(@manager), 2, 'existing file manager return contract is preserved');
like($manager[1], qr{href="/files/objects/42/original.txt"}, 'unstaged file manager keeps live file URLs');

{
    $record = undef; # the selected object disappeared
    $html = adminObjectEditor({from => 'objects', id => 42}, $admin, {});
    like($html, qr/Object not found/, 'missing object cannot create a filebox');
}

done_testing();
