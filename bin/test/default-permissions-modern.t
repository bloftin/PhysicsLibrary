#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use HTML::TreeBuilder;
use HTML::Parser;
use Noosphere::RequestForm;

our $dbh;
my $root = "$FindBin::Bin/../..";
our @rules = (
    {uid => 10, subjectid => -1, default_or_normal => 'd', user_or_group => 'u', _read => 1, _write => 0, _acl => 0},
    {uid => 11, subjectid => 4, default_or_normal => 'n', user_or_group => 'g', _read => 1, _write => 1, _acl => 1},
);
my (@writes, @queries, %fixtures, @deleted_objects, @installed_objects);
our $hasdef = 1;
our $allowed = 1;
sub getConfig { +{template_path => "$root/stemplates", dacl_tbl => 'acl_default', main_url => 'https://physicslibrary.org',
    index_tbl => 'objindex', acl_tables => {objects => 1}}->{$_[0]} }
sub loginExpired { 'Login Expired' }
sub errorMessage { $_[0] }
sub getPermissions { +{acl => $allowed} }
sub getAdminGroupHash { +{4 => 'Trusted <editors> & colleagues', 5 => 'LongGroupName' x 25} }
sub hasDefaultDefaultRule { $hasdef }
sub getSubjectName { $_[0]->{default_or_normal} eq 'd' ? '[anyone]' : 'Trusted <editors> & colleagues' }
sub getSubjectId { $_[0] eq 'missing' ? -1 : 4 }
sub globalInstallDefaultACL { push @writes, ['global', @_]; return 3; }
sub addACL_default { push @writes, ['add', @_]; }
sub updateACL_default { push @writes, ['update', @_]; }
sub deleteACL_default { push @writes, ['delete', @_]; }
sub getAccessRuleEditor { 'legacy table' }
sub dbSelect {
    push @queries, $_[1];
    my @rows = $_[1]{FROM} eq 'objindex' ? ({tbl => 'objects', objectid => 209}, {tbl => 'objects', objectid => 210}) : @rules;
    return (1, bless {rows => [map {+{%$_}} @rows]}, 'ACLRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub sqq { "'$_[0]'" }
sub deleteObjectACL { push @deleted_objects, [@_]; }
sub installDefaultACL { push @installed_objects, [@_]; }
{
    package ACLRows;
    sub fetchrow_hashref { shift @{$_[0]->{rows}} }
    package XSLTemplate;
    sub new { bless {}, shift }
    sub addText { }
    sub setKey { }
    sub setKeys { }
    sub expand { 'legacy object editor' }
}
for my $name (qw(ACLEditor renderDefaultPermissions getDefaultACLRules)) {
    open my $fh, '<', "$root/lib/Noosphere/ACL.pm" or die $!;
    my $source = do {local $/; <$fh>};
    my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
    die "Missing $name" unless $body;
    eval $body; die $@ if $@;
}
sub render { ACLEditor({from => 'acl_default', @_}, {uid => 1, ticket => 'a' x 64}) }
sub tree { HTML::TreeBuilder->new(ignore_unknown => 0)->parse_content($_[0]) }
my $html = render();
$fixtures{populated} = $html;
my $dom = tree($html);
is($dom->look_down(_tag => 'h1')->as_text, 'Editing default Access Control List', 'original title retained in page heading');
ok($dom->look_down(_tag => 'header', class => 'pl-modern-box-header'), 'shared compact blue header');
unlike($html, qr/<font|<center|<NS:template/, 'legacy wrappers removed');
like($html, qr/Trusted &lt;editors&gt; &amp; colleagues/, 'subject names and group names escaped');
for my $name (qw(gselbox subjectid_new uog_new read_new write_new acl_new addrule combineall replaceall
    subjectid_10 default_10 uog_10 read_10 write_10 acl_10 update_10 delete_10
    subjectid_11 default_11 uog_11 read_11 write_11 acl_11 update_11 delete_11)) {
    ok($dom->look_down(name => $name), "$name control retained");
}
for my $pair ([op => 'acledit'], [from => 'acl_default'], [id => '']) {
    is($dom->look_down(name => $pair->[0])->attr('value'), $pair->[1], 'route field retained');
}
ok(!$dom->look_down(name => 'default_new'), 'cannot add another default rule when one exists');
ok($dom->look_down(name => 'read_new')->attr('checked'), 'new rule defaults to read');
ok($dom->look_down(name => 'write_new')->attr('checked'), 'new rule defaults to write');
ok(!$dom->look_down(name => 'acl_new')->attr('checked'), 'new rule does not default to ACL access');
ok($dom->look_down(name => 'default_10')->attr('checked'), 'default flag retained');
ok(!$dom->look_down(name => 'write_10')->attr('checked'), 'existing disabled write retained');
ok($dom->look_down(name => 'acl_11')->attr('checked'), 'existing ACL grant retained');
like($html, qr/this\.form\.elements\.uog_new\[1\]\.checked=true/, 'group quick-select retains group radio selection');
for my $text ('each new object you create', 'wiki-like', 'conflicting rules will be overwritten', 'completely new access control list') {
    like($html, qr/\Q$text\E/, 'original explanation or warning retained');
}
$dom->delete;
my ($depth, $nested, $tokens) = (0, 0, 0);
my $decorated = requestFormDecorate($html, {uid => 1, ticket => 'a' x 64, data => {active => 1}});
HTML::Parser->new(start_h => [sub {
    $nested++ if $_[0] eq 'form' && $depth++;
    $tokens++ if $_[0] eq 'input' && ($_[1]{name} || '') eq '_form_token';
}, 'tagname, attr'], end_h => [sub { $depth-- if $_[0] eq 'form' }, 'tagname'])->parse($decorated);
is($nested, 0, 'no nested forms'); is($depth, 0, 'form closes'); is($tokens, 1, 'response-time CSRF protection retained');
is(getDefaultACLRules(1), 'legacy table', 'legacy rules API retains HTML output');
is($queries[-1]{WHERE}, 'userid=1', 'default rule query scoped to signed-in user');
{
    local @rules = (); local $hasdef = 0;
    $fixtures{empty} = render(subjectid_new => '"><script>unsafe</script>');
    like($fixtures{empty}, qr/No existing rules/, 'empty state');
    like($fixtures{empty}, qr/name="default_new" checked/, 'first rule defaults to general public');
    like($fixtures{empty}, qr/&quot;&gt;&lt;script&gt;/, 'submitted subject escaped');
    like($fixtures{empty}, qr/subject selection above to be ignored/, 'default explanation retained');
}
@writes = ();
$fixtures{combined} = render(combineall => 'combine');
is_deeply($writes[0], ['global', 1, 0], 'combine does not request deletion of special rules');
like($fixtures{combined}, qr/ACL updated \(combined\) for 3 objects/, 'combine feedback');
render(replaceall => 'replace');
is_deeply($writes[1], ['global', 1, 1], 'replace explicitly requests deletion');
render(addrule => 'add rule', default_new => 'on', read_new => 'on', write_new => 'on', acl_new => '', uog_new => 'u');
is($writes[2][0], 'add', 'new rule dispatched');
is($writes[2][2]{subjectid}, -1, 'default rule ignores subject selection');
render(update_11 => 'update', subjectid_11 => 4, default_11 => '', uog_11 => 'g', read_11 => 'on', write_11 => 'on', acl_11 => 'on');
is($writes[3][0], 'update', 'owned rule update dispatched');
is($writes[3][2], 11, 'owned rule identifier retained');
render(delete_10 => 'delete');
is_deeply($writes[4], ['delete', 10], 'owned deletion dispatched');
$fixtures{invalid} = render(addrule => 'add rule', subjectid_new => 'missing', uog_new => 'u');
like($fixtures{invalid}, qr/That is not a valid subject name or ID!/, 'validation feedback preserved');
my $writes_before = @writes;
like(render(update_99 => 'update', replaceall => 'replace'), qr/don't have permissions/, 'foreign rule rejected before any mutation');
is(scalar @writes, $writes_before, 'foreign-rule request performs no mutation');
for my $uid (undef, -1, 0, '1 OR 1=1', "1\n", []) {
    is(ACLEditor({from => 'acl_default', addrule => 1, replaceall => 1}, {uid => $uid}), 'Login Expired', 'invalid viewer rejected');
}
is(scalar @writes, $writes_before, 'invalid viewers perform no mutation');
{
    local $allowed = 0;
    like(ACLEditor({from => 'objects', id => 7}, {uid => 1}), qr/permissions to modify the ACL/, 'object permission gate remains unchanged');
}
{
    open my $fh, '<', "$root/lib/Noosphere/ACL.pm" or die $!;
    my $source = do {local $/; <$fh>};
    my ($body) = $source =~ /(^sub globalInstallDefaultACL\b.*?)(?=^sub |\z)/ms;
    eval "no warnings 'redefine'; $body"; die $@ if $@;
    is(globalInstallDefaultACL(1, 0), 2, 'real combine processes owned objects');
    is(scalar @deleted_objects, 0, 'real combine preserves existing object ACLs');
    is(scalar @installed_objects, 2, 'real combine installs default rules');
    is($queries[-1]{WHERE}, "userid=1 and tbl in ('objects')", 'global application remains owner scoped');
    is(globalInstallDefaultACL(1, 1), 2, 'real replace processes owned objects');
    is_deeply(\@deleted_objects, [['objects', 209], ['objects', 210]], 'real replace removes only selected objects ACLs');
}
if (my $dir = $ENV{ACL_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu}, \$sidebar) or die $tt->error;
    for my $name (keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Default permissions preview', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page; close $out;
    }
}
done_testing();
