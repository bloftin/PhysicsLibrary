#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use HTML::Parser;
use Template;
use URI;
use Noosphere::EntryInteractions;

our ($dbh, $AllowCache);
our ($validation_error, $validation_warning, $revision_fails) = ('', '', 0);
my $root = "$FindBin::Bin/../..";
my $record = {uid => 209, userid => 2, title => 'Vector triple product'};
my (@revisions, @queries, @events);
my $permitted = 1;
my $user = {uid => 2, data => {access => 0}};
sub getConfig {
    return {template_path => "$root/stemplates", en_tbl => 'objects', collab_tbl => 'collab',
        generic_schema => {objects => {}}, access_admin => 100}->{$_[0]};
}
sub hasPermissionTo { $permitted }
sub errorMessage { $_[0] }
sub dbSelect { push @queries, $_[1]; return (1, bless {}, 'RevisionTestRows'); }
sub checkEncyclopediaEntry { push @events, 'validate'; return ($validation_error, $validation_warning); }
sub reviseEncyclopedia {
    push @revisions, [@_]; push @events, 'revise';
    die "Revision failed\n" if $revision_fails;
}
sub editEnPreview { push @events, 'preview'; return $_[4]; }
sub editEnRefresh { push @events, 'refresh'; }
sub copyBoxFilesToTemp { push @events, 'copy files'; }
sub handleFileManager { push @events, 'file manager'; }
sub paddingTable { '<div class="legacy-padding">'.$_[0].'</div>' }
sub clearBox { '<div class="legacy-editor">'.$_[0].$_[1].'</div>' }
{
    package RevisionTestRows;
    sub fetchrow_hashref { return {%$record}; }
    sub finish { }
    package TemplateNS;
    sub new { bless {}, shift }
    package XSLTemplate;
    sub new { bless {keys => {}}, shift }
    sub addText { }
    sub setKey { $_[0]->{keys}{$_[1]} = $_[2]; }
    sub expand { '<form id="existing-editor">'.($_[0]->{keys}{error} || '').'</form>' }
}
open my $in, '<', "$root/lib/Noosphere/EditObj.pm" or die $!;
my $source = do {local $/; <$in>};
for my $name (qw(genericEditor editEncyclopedia)) {
    my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless $body;
    eval $body; die $@ if $@;
}
sub edit {
    @events = (); @queries = (); @revisions = ();
    return genericEditor({from => 'objects', id => 209, @_}, $user, undef);
}
my $saved = edit(post => 'Save');
like($saved, qr/<header class="pl-modern-box-header"><h1>Object Revised<\/h1><\/header>/, 'saved entry uses the compact shared blue heading');
like($saved, qr/Your object has been successfully revised\./, 'original success message retained');
like($saved, qr/<h2 id="pl-entry-revised-quick-links">Quick links:<\/h2>/, 'original quick links label retained with a semantic heading');
like($saved, qr/<nav aria-labelledby="pl-entry-revised-quick-links">/, 'quick links are an accessible navigation region');
unlike($saved, qr/legacy-padding|legacy-editor|bgcolor|<table|<br/, 'success no longer uses padded grey legacy boxes or spacer markup');
is(scalar @revisions, 1, 'save calls the existing revision function exactly once');
is_deeply($revisions[0][0], $record, 'revision receives the database record');
is($revisions[0][1]{post}, 'Save', 'revision receives the original submitted command');
is($revisions[0][2], $user, 'revision receives the original user');
is_deeply(\@events, ['validate', 'revise'], 'validation and revision still precede confirmation without rendering extra previews');
is(scalar @queries, 1, 'confirmation adds no database queries');
my @links;
HTML::Parser->new(start_h => [sub {
    my ($tag, $attrs) = @_;
    push @links, URI->new($attrs->{href}) if $tag eq 'a';
}, 'tagname, attr'])->parse($saved);
is(scalar @links, 4, 'all four original quick links retained');
for my $spec (
    ['getobj', 'view the object', {op => 'getobj', from => 'objects', id => 209}],
    ['edit', 'edit the object again', {op => 'edit', from => 'objects', id => 209}],
    ['edituserobjs', 'edit your other objects', {op => 'edituserobjs'}],
    ['editcors', 'your corrections', {op => 'editcors'}],
) {
    my ($op, $text, $expected) = @$spec;
    like($saved, qr/>\Q$text\E<\/a>/, "$op retains its original link wording");
    my ($url) = grep { my %q = $_->query_form; $q{op} eq $op } @links;
    ok($url, "$op quick link is present");
    is_deeply({$url->query_form}, $expected, "$op keeps its existing destination");
}
like($saved, qr/from=objects&amp;id=209/, 'link attributes are HTML escaped');
{
    local $validation_error = 'Please enter a title.';
    local $validation_warning = 'Original warning.';
    my $invalid = edit(post => 'Save');
    unlike($invalid, qr/pl-entry-revised/, 'invalid submissions do not display success');
    like($invalid, qr/Please enter a title\..*Original warning\./s, 'existing validation error and warning retained');
    is(scalar @revisions, 0, 'invalid entry is not revised');
    is_deeply(\@events, ['validate', 'preview', 'file manager'], 'invalid entry keeps the existing preview workflow');
}
{
    $AllowCache = 1;
    my $preview = edit(preview => 'Preview');
    unlike($preview, qr/pl-entry-revised/, 'preview is not presented as a completed save');
    is($AllowCache, 0, 'preview keeps its cache bypass');
    is(scalar @revisions, 0, 'preview never revises the entry');
    is_deeply(\@events, ['validate', 'preview', 'file manager'], 'preview workflow unchanged');
}
{
    local $revision_fails = 1;
    my $failed = eval { edit(post => 'Save') };
    is($@, "Revision failed\n", 'revision exceptions still propagate');
    ok(!defined $failed, 'failed revision does not return a success page');
}
my $initial = edit();
unlike($initial, qr/pl-entry-revised/, 'initial editor is not presented as a completed save');
is_deeply(\@events, ['refresh', 'copy files', 'file manager'], 'initial editor and filebox workflow unchanged');
$permitted = 0;
like(edit(post => 'Save'), qr/You can't edit that object!/, 'write permission still enforced before saving');
is(scalar @queries, 0, 'denied editor cannot fetch the object');
is(scalar @revisions, 0, 'denied editor cannot revise the object');
{
    local $user->{data}{access} = 100;
    like(edit(post => 'Save'), qr/<h1>Object Revised/, 'existing administrator override still works');
}
$permitted = 1;
my $safe = entryInteractionTemplate('revisedencyclopedia.tt', {
    view_url => '/?op=getobj&name="quoted"', edit_url => '/?op=edit&id=209',
    objects_url => '/?op=edituserobjs', corrections_url => '/?op=editcors',
});
like($safe, qr/href="\/\?op=getobj&amp;name=&quot;quoted&quot;"/, 'confirmation template escapes quotes and separators in URLs');
if (my $dir = $ENV{EDIT_CONFIRMATION_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu, $html) = ('', '', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>',
        features => $menu,
    }, \$sidebar) or die $tt->error;
    $tt->process('view.tt', {
        title => 'Object Revised', site_name => 'Physics Library', sidebar => $sidebar, content => $saved,
        header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>',
    }, \$html) or die $tt->error;
    open my $out, '>', "$dir/revised.html" or die $!;
    print {$out} $html;
    close $out;
}
done_testing();
