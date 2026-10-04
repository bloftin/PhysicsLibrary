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
use Noosphere::TemplateNS;
use Noosphere::RequestForm;
use Digest::SHA qw(hmac_sha256_hex);

my $root = "$FindBin::Bin/../..";
our $dbh;
my (%headers, @queries, @deletes, @added, @group_deleted, $saved_prefs);
my $method = 'GET';
our @groups = ({groupid => 12, groupname => 'Physics <editors> & colleagues',
    description => 'Our trusted <group>'});
our @watch_rows = (
    {uid => 20, tbl => 'objects', objectid => 209},
    {uid => 21, tbl => 'objects', objectid => 999},
    {uid => 22, tbl => 'messages', objectid => 8},
);
my $record = {uid => 1, active => 1, username => 'Example <member>', forename => 'Ada',
    surname => 'Example', email => 'member@example.invalid', city => 'Denver',
    state => 'CO', country => 'USA', homepage => 'https://example.invalid/?a=1&b=2',
    sig => 'Regards <friends>', bio => '<p>Original <strong>biography</strong>.</p>',
    preamble => '\usepackage{amsmath}', score => 50, access => 10,
    joined => '2004-11-09', last => '2026-10-04', prefs => 'hideemail=on'};
my %config = (template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
    siteaddrs => {}, template_cmd_prefix => 'NS', main_url => 'https://physicslibrary.org',
    projname => 'Physics Library',
    user_tbl => 'users', groups_tbl => 'groups', watch_tbl => 'watches',
    index_tbl => 'objindex', dbms => 'MariaDB', access_admin => 100,
    access_seehiddenemail => 200);
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub getConfig { $config{$_[0]} }
sub htmlescape {
    my $s = defined $_[0] ? $_[0] : '';
    $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g;
    return $s;
}
sub qhtmlescape { my $s = htmlescape($_[0]); $s =~ s/"/&quot;/g; return $s; }
sub loginExpired { 'Login Expired' }
sub errorMessage { $_[0] }
sub SECRET { 'synthetic-settings-test-key' }
sub getUserData { +{%$record} }
sub getUserPrefs { +{%{$saved_prefs || $config{defaults}}} }
sub setUserPrefs { $saved_prefs = {%{$_[1]}} }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub getMethods { qw(make4ht png src pdf l2h) }
sub getMemberCount { 2 }
sub lookupfield { 1 }
sub addGroup { push @added, [@_]; }
sub deleteAllUsersFromGroup { push @group_deleted, ['members', @_]; }
sub deleteGroup { push @group_deleted, ['group', @_]; }
sub tabledesc { $_[0] eq 'objects' ? 'Encyclopedia' : 'Messages' }
sub lookuptitle { $_[1] == 999 ? '' : 'Original <object> & title' }
sub getop { $_[0] eq 'messages' ? ('getmsg', '') : ('getobj', $_[0]) }
sub getPager { '<a href="/?op=watches&amp;offset=40&amp;total=100">Next page</a>' }
sub getrowcount { 7 }
sub getCorrectionsReceivedCount { 3 }
sub getCorrectionsFiledCount { 2 }
sub urlescape { $_[0] }
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    my $rows = $q->{FROM} eq 'groups' ? \@groups :
        $q->{FROM} eq 'users' ? [$record] : \@watch_rows;
    return (1, bless {rows => $rows}, 'SettingsRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub dbLowLevelSelect {
    push @queries, $_[1];
    return (1, bless {rows => \@watch_rows}, 'SettingsRows');
}
sub dbDelete { push @deletes, $_[1]; return (1, bless {}, 'SettingsRows'); }
{
    package SettingsRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[0] }
    sub finish { }
    package Apache2::RequestUtil;
    sub request { bless {}, 'SettingsRequest' }
    package SettingsRequest;
    sub method { $method }
    sub headers_out { $_[0] }
    sub set { $headers{$_[1]} = $_[2]; }
}

# Use the real preference inventory without loading deployment configuration.
my $source_config = readFile("$root/lib/Noosphere/Config.pm");
my ($schema) = $source_config =~ /"prefs_schema"=>\s*(\{.*?\}),\s*# preferences groupings/s;
my ($groupings) = $source_config =~ /prefs_groupings=>\s*(\[.*?\]),\s*# help blurbs/s;
die 'Missing preference inventory' unless $schema && $groupings;
$config{prefs_schema} = eval $schema; die $@ if $@;
$config{prefs_groupings} = eval $groupings; die $@ if $@;
$config{defaults} = {map {$_ => $config{prefs_schema}{$_}[2]} keys %{$config{prefs_schema}}};
for my $spec (
    ['UserData', qw(getSettings renderSettingsPage editUserPrefs changePrefs
        profileEditableFields profileUserValid profileFormToken editUserData validUserId parsePrefs getUser)],
    ['Groups', qw(_validGroupUserId _validGroupId _groupAdminId _userOwnsGroup groupEditor getAdminGroups)],
    ['Watches', qw(validWatchUserId listWatches)],
    ['Notices', qw(contextLink)],
    ['Util', qw(getPrefsWidget getFormWidget getSelectBox getSelectBoxOrdered)],
) {
    my ($module, @names) = @$spec;
    my $source = readFile("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval(($name eq 'getFormWidget' ? "no warnings 'numeric'; " : '').$body); die $@ if $@;
    }
}
sub viewer {
    my ($uid, $access) = @_;
    return {uid => $uid, ticket => 'a' x 64, data => {%$record, access => $access || 0},
        prefs => {%{$config{defaults}}, pagelength => 20}};
}
sub tree { my $dom = HTML::TreeBuilder->new(ignore_unknown => 0); $dom->parse_content($_[0]); return $dom; }
sub heading {
    my ($html, $title) = @_;
    my $dom = tree($html);
    my @h = $dom->look_down(_tag => 'h1');
    is(scalar @h, 1, 'one page heading');
    is($h[0]->as_text, $title, 'original title in shared compact header');
    ok($dom->look_down(_tag => 'header', class => 'pl-modern-box-header'), 'shared blue header');
    unlike($html, qr/<NS:template|<center|<font|<html>/, 'no legacy layout wrappers or unexpanded placeholders');
    $dom->delete;
}
sub protected_form {
    my ($html, $op) = @_;
    my $decorated = requestFormDecorate($html, viewer(1));
    my ($depth, $nested, $tokens) = (0, 0, 0);
    HTML::Parser->new(
        start_h => [sub {
            $nested++ if $_[0] eq 'form' && $depth++;
            $tokens++ if $_[0] eq 'input' && ($_[1]{name} || '') eq '_form_token' && $depth;
        }, 'tagname, attr'],
        end_h => [sub { $depth-- if $_[0] eq 'form'; }, 'tagname'],
    )->parse($decorated);
    is($nested, 0, "$op forms do not nest");
    is($depth, 0, "$op forms close");
    is($tokens, 1, "$op keeps response-time form protection");
}
my %fixtures;
my $html = getSettings({}, viewer(1));
$fixtures{settings} = $html;
heading($html, 'Your Settings');
for my $op (qw(edituser editprefs acledit groupedit watches)) {
    like($html, qr/op=\Q$op\E/, "$op menu link retained");
}
like($html, qr/op=getuser&amp;id=1/, 'view link follows signed-in user, not fixed id');
for my $text ('Here you can configure, tweak, and toggle', 'Includes bio and default preamble.',
    'free-form access, a-la Wiki', 'trusted associates', 'Manage in one place') {
    like($html, qr/\Q$text\E/, 'original settings explanation retained');
}
$html = editUserData({}, viewer(1));
$fixtures{edituser} = $html;
heading($html, 'Edit User Info for Example <member>');
protected_form($html, 'edituser');
is($headers{'Cache-Control'}, 'no-store', 'own-profile form remains uncached');
like($html, qr/name="profile_token" value="[a-f0-9]{64}"/, 'dedicated profile token retained');
unlike($html, qr/name="(?:email|password|uid|active|access)"/, 'account controls remain read-only or absent');
like($html, qr/member\@example.invalid/, 'read-only email retained');
my $dom = tree($html);
for my $field (profileEditableFields()) {
    my $input = $dom->look_down(name => $field);
    ok($input, "$field remains editable");
    my $value = $input->tag eq 'textarea' ? $input->as_text : $input->attr('value');
    is($value, $record->{$field}, "$field retains original value");
}
$dom->delete;
like($html, qr/\*Allowed tags:.*&lt;CITE&gt;.*&lt;EM&gt;/s, 'complete allowed-tags note retained');
is(editUserData({}, viewer(-1)), 'Login Expired', 'own-profile editor still requires sign-in');
$html = editUserPrefs({}, viewer(1));
$fixtures{editprefs} = $html;
heading($html, 'Edit Preferences for Example <member>');
protected_form($html, 'editprefs');
$dom = tree($html);
my %expected;
for my $group (@{$config{prefs_groupings}}) {
    my @keys = grep {$_ ne 'neverlogout'} @{$group->[1]};
    next unless @keys;
    like($html, qr/\Q$group->[0]\E/, 'original preference group retained');
    for my $key (@keys) {
        $expected{$key} = 1;
        my $input = $dom->look_down(name => $key);
        ok($input, "$key preference retained");
        my $info = $config{prefs_schema}{$key};
        if ($info->[1] eq 'select') {
            my @options = $input->look_down(_tag => 'option');
            is_deeply([sort map {$_->attr('value')} @options], [sort keys %{$info->[3]}], "$key options unchanged");
        } else {
            is(defined($input->attr('checked')) ? 1 : 0, $info->[2] eq 'on' ? 1 : 0, "$key checkbox value retained");
        }
    }
}
unlike($html, qr/neverlogout|<legend>Security/, 'obsolete unlimited session option remains omitted');
$dom->delete;
my $prefs_user = viewer(1);
$html = editUserPrefs({submit => 'Update', pagelength => '050', hideemail => 'on',
    msgstyle => 'flat', method => 'pdf'}, $prefs_user);
is($saved_prefs->{pagelength}, '050', 'changed selector saves through existing preference handler');
is($saved_prefs->{hideemail}, 'on', 'checked preference saves on');
is($saved_prefs->{usesig}, 'off', 'unchecked preference remains off');
like($html, qr/value="050" selected/, 'saved preferences redisplayed');
is(editUserPrefs({}, viewer(-1)), 'Login Expired', 'preferences still require sign-in');
$html = groupEditor({}, viewer(1));
$fixtures{groupedit} = $html;
heading($html, 'Editing your groups');
protected_form($html, 'groupedit');
for my $field (qw(groupname_new groupdesc_new selected_12 addgroup delgroup op)) {
    like($html, qr/name="\Q$field\E"/, "group $field action or field retained");
}
like($html, qr/Physics &lt;editors&gt; &amp; colleagues/, 'group title escaped');
like($html, qr/Our trusted &lt;group&gt;/, 'group description safely displayed');
like($html, qr/op=memberedit&amp;gid=12/, 'group membership link preserved');
like($html, qr/2 members/, 'member count retained');
groupEditor({addgroup => 'add group', groupname_new => 'New group', groupdesc_new => 'New description'}, viewer(1));
is_deeply($added[0], [1, 'New group', 'New description'], 'group addition uses current user and original fields');
groupEditor({delgroup => 'delete selected', selected_12 => 1}, viewer(2));
is(scalar @group_deleted, 0, 'non-owner group deletion rejected');
groupEditor({delgroup => 'delete selected', selected_12 => 1}, viewer(1));
is_deeply(\@group_deleted, [['members', 12], ['group', 12]], 'group owner deletion unchanged');
{
    local @groups = ();
    $fixtures{'groups-empty'} = groupEditor({}, viewer(1));
    like($fixtures{'groups-empty'}, qr/\[none\]/, 'empty group state retained');
}
for my $guest (-1, 0) {
    @queries = (); @added = ();
    is(groupEditor({addgroup => 1, delgroup => 1, selected_12 => 1}, viewer($guest)), 'Login Expired', 'guest cannot access group editor');
    is(scalar @queries, 0, 'guest group request does not query');
    is(scalar @added, 0, 'guest group request cannot mutate');
}
$html = listWatches({offset => 20, total => 100}, viewer(1));
$fixtures{watches} = $html;
heading($html, 'Your Watches');
protected_form($html, 'watches');
like($html, qr/Original &lt;object&gt; &amp; title/, 'watch titles escaped');
like($html, qr/\[object objects:999 has been deleted\]/, 'deleted-object fallback retained');
like($html, qr/op=getmsg&id=8/, 'message watch uses correct message route');
like($html, qr/name="del_20"/, 'watch checkbox retains original deletion id');
like($html, qr/name="offset" value="20"/, 'watch offset retained');
like($html, qr/name="total" value="100"/, 'watch total retained');
like($html, qr/Next page/, 'watch pager retained');
like($html, qr/delete selected.*delete all/s, 'both watch deletion actions retained');
@deletes = ();
listWatches({delsel => 1, del_20 => 1, del_200 => 1}, viewer(1));
is_deeply([sort map {$_->{WHERE}} @deletes], ['uid=20 and userid=1', 'uid=200 and userid=1'],
    'selected-watch deletion is scoped to signed-in owner');
@deletes = (); @queries = ();
listWatches({delall => 1, offset => 20}, viewer(1));
like($queries[0], qr/where userid=1 limit 20, 20/, 'delete all retains existing current-page scope');
ok(!grep($_->{WHERE} !~ /and userid=1$/, @deletes), 'all page deletions retain ownership constraint');
for my $guest (-1, 0) {
    @queries = (); @deletes = ();
    is(listWatches({delsel => 1, del_20 => 1, delall => 1}, viewer($guest)), 'Login Expired', 'guest watches are blocked');
    is(scalar @queries, 0, 'guest watches do not query');
    is(scalar @deletes, 0, 'guest watches do not mutate');
}
subtest 'watch deletion ownership with a real database' => sub {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'Integration requires DBI and DBD::SQLite';
    my $db = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1});
    $db->do('CREATE TABLE watches (uid INTEGER PRIMARY KEY, userid INTEGER)');
    $db->do('INSERT INTO watches VALUES (20, 1), (21, 1), (22, 2), (200, 2)');
    no warnings 'redefine';
    local *dbDelete = sub {
        my ($unused, $q) = @_;
        return ($db->do("DELETE FROM watches WHERE $q->{WHERE}"), bless {}, 'SettingsRows');
    };
    listWatches({delsel => 1, del_20 => 1, del_200 => 1}, viewer(1));
    is_deeply($db->selectcol_arrayref('SELECT uid FROM watches ORDER BY uid'), [21, 22, 200],
        'own selected watch deleted while forged other-user selection remains');
    listWatches({delall => 1}, viewer(1));
    is_deeply($db->selectcol_arrayref('SELECT uid FROM watches ORDER BY uid'), [22, 200],
        'page deletion cannot remove watches owned by another user');
    $db->disconnect;
};
{
    local @watch_rows = ();
    $fixtures{'watches-empty'} = listWatches({}, viewer(1));
    like($fixtures{'watches-empty'}, qr/No watches\./, 'empty watch state retained');
    unlike($fixtures{'watches-empty'}, qr/<form/, 'empty watches have no delete form');
}
$html = getUser({id => 1}, viewer(-1));
$fixtures{profile} = $html;
heading($html, 'User Info for Example <member>');
unlike($html, qr/E-mail Address:|member\@example.invalid/, 'guest profile has no email information');
like($html, qr/\Q$record->{bio}\E/, 'original biography HTML retained');
like($html, qr/https:\/\/example.invalid\/\?a=1&amp;b=2/, 'homepage URL escaped and linked');
for my $label ('User ID:', 'Name:', 'From:', 'Joined On:', 'Last Logged in:', 'Access Level:', 'Score:',
    'Message Count (7)', 'Object Count (7)', 'Corrections Filed (2)', 'Corrections Received (3)') {
    like($html, qr/\Q$label\E/, 'profile label and count retained');
}
unlike($html, qr/admin edit/, 'guest has no score edit link');
$html = getUser({id => 1}, viewer(1, 100));
$fixtures{'profile-admin'} = $html;
like($html, qr/href="\/\?op=editscore&amp;user=1"/, 'admin score action now has a working local URL');
{
    local $record->{homepage} = 'javascript:alert("http")';
    my $plain = getUser({id => 1}, viewer(-1));
    unlike($plain, qr/href="javascript:/, 'non-HTTP homepage is not a clickable URL');
    like($plain, qr/Note: if you want a hyperlink/, 'non-URL homepage explanation retained');
    local $record->{active} = 0;
    $fixtures{'profile-inactive'} = getUser({id => 1}, viewer(-1));
    like($fixtures{'profile-inactive'}, qr/This account has been deactivated/, 'inactive profile notice retained');
}
{
    local $record->{username} = 'VeryLongUnbrokenUsername' x 14;
    local $record->{bio} = '<p>'.('LongBiographyWord' x 50).'</p><table style="width:900px"><tr><td>Original wide biography</td></tr></table>';
    $fixtures{'profile-long'} = getUser({id => 1}, viewer(-1));
}
if (my $dir = $ENV{SETTINGS_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu}, \$sidebar) or die $tt->error;
    for my $name (sort keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Settings preview', site_name => 'Physics Library',
            content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page; close $out;
    }
}
done_testing();
