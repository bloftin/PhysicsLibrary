#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use DBI;
use Template;
use URI;
use URI::Escape qw(uri_escape_utf8);
use HTML::Parser;
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;
use Noosphere::Dispatch;

our ($dbh, $NoosphereCanonical, $NoosphereTitle, $NoosphereDescription, $request);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path=>"$root/stemplates", main_url=>'https://example.invalid',
    bug_url=>'https://example.invalid/bugs', access_admin=>100,
    en_tbl=>'objects', books_tbl=>'books', papers_tbl=>'papers', exp_tbl=>'lec',
    collab_tbl=>'collab', news_tbl=>'news', forum_tbl=>'forums', polls_tbl=>'polls',
    req_tbl=>'requests', user_tbl=>'users', cor_tbl=>'corrections', acl_tbl=>'acl',
    acl_tables=>{map {$_=>1} qw(objects books papers lec collab)},
);
my (@effects, @deletions);
sub getConfig { $config{$_[0]} }
sub getAddr { 'feedback@example.invalid' }
sub errorMessage { '<section class="error">'.$_[0].'</section>' }
sub loginExpired { 'Sign in' }
sub getUserGroupids { () }
sub lookupfield {
    my ($table, $field, $where) = @_;
    return 'Fixture owner' if $table eq 'users';
    return $dbh->selectrow_array("SELECT $field FROM $table WHERE $where");
}
sub dbLowLevelSelect {
    my ($db, $sql) = @_;
    my $rows = $db->selectall_arrayref($sql, {Slice=>{}});
    return (1, bless {rows=>$rows}, 'RestrictedRows');
}
sub dbSelect {
    my ($db, $query) = @_;
    return dbLowLevelSelect($db, "SELECT $query->{WHAT} FROM $query->{FROM} WHERE $query->{WHERE}");
}
sub getidbyname { $dbh->selectrow_array('SELECT uid FROM objects WHERE name=?', undef, $_[0]) // -1 }
sub nb { defined($_[0]) && length($_[0]) }
sub TeXtoUTF8 { $_[0] }
sub changeWatch { push @effects, 'watch' }
sub hitObject { push @effects, 'hit' }
sub renderGeneric { push @effects, 'render'; '<p>Readable fixture content</p>' }
sub renderEncyclopediaObj { renderGeneric() }
sub renderCollab { renderGeneric() }
sub getGenericAdmin { push @effects, 'full admin'; '<p>Ordinary admin controls</p>' }
sub getEncyclopediaAdminControls { getGenericAdmin() }
sub getEncyclopediaInteract { 'Ordinary interactions' }
sub getOwnerControls { 'Ordinary owner controls' }
sub getAuthorControls { 'Ordinary author controls' }
sub getWatchWidget { push @effects, 'watch widget'; '' }
sub get_lastseen { push @effects, 'discussion'; 0 }
sub get_lastmsg { 0 }
sub update_lastseen { push @effects, 'last seen' }
sub getMessages { 'Ordinary discussion' }
sub getPendingCorrections { 'None.' }
sub clearBox { $_[1] }
sub objectOwnerByUid { lookupfield($_[1], 'userid', "uid=$_[0]") }
sub objectExistsByUid { defined lookupfield($_[1], 'uid', "uid=$_[0]") }
# The deletion route is real; persistence is disposable and collection-scoped.
sub _delObject {
    my ($params, $owner) = @_;
    push @deletions, [$params->{from}, $params->{id}, $owner];
    $dbh->do("DELETE FROM $params->{from} WHERE uid=?", undef, $params->{id});
    return 1;
}
{
    package RestrictedRows;
    sub rows { scalar @{$_[0]{rows}} }
    sub fetchrow_hashref { shift @{$_[0]{rows}} }
    sub finish { }
    package Apache2::RequestUtil;
    sub request { $Noosphere::request }
    package RestrictedRequest;
    sub method { $_[0]{method} }
    sub header_in { $_[0]{headers}{$_[1]} }
    sub headers_out { $_[0] }
    sub set { $_[0]{out}{$_[1]} = $_[2] }
    sub add { $_[0]->set($_[1], $_[2]) }
    sub unparsed_uri { '/' }
}

# Load only the relevant real handlers, without deployment configuration.
for my $spec (
    ['GetObj', qw(getObjTableIsAllowed getObjIdIsValid getEncyclopediaCanonicalURL getObj)],
    ['ACL', qw(hasPermissionTo getPermissions)], ['DelObj', qw(delObject)],
) {
    my ($module, @names) = @$spec;
    open my $in, '<', "$root/lib/Noosphere/$module.pm" or die $!;
    my $source = do { local $/; <$in> };
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $sub;
        eval $sub;
        die $@ if $@;
    }
}
$dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError=>1, PrintError=>0});
$dbh->do('CREATE TABLE acl (tbl TEXT, objectid INTEGER, subjectid INTEGER,
    user_or_group TEXT, default_or_normal TEXT, _read INTEGER, _write INTEGER, _acl INTEGER)');
for my $table (qw(objects books papers lec collab)) {
    $dbh->do("CREATE TABLE $table (uid INTEGER PRIMARY KEY, userid INTEGER, title TEXT,
        name TEXT, data TEXT, preamble TEXT, authors TEXT)");
    for my $id (7, 8) {
        $dbh->do("INSERT INTO $table VALUES (?,2,?,?,?,?,?)", undef, $id,
            "PRIVATE-$table-title-$id", "Private${table}$id", "PRIVATE-$table-body-$id",
            "PRIVATE-$table-preamble-$id", "PRIVATE-$table-authors-$id");
        $dbh->do("INSERT INTO acl VALUES (?,?,0,'u','d',?,0,0)", undef, $table, $id, $id==8 ? 1 : 0);
    }
}
sub user {
    my ($uid, $access) = @_;
    return {uid=>$uid, ticket=>'a' x 64, data=>{active=>1, access=>$access // 0}};
}
my $admin = user(9, 100);
sub page {
    my ($table, $viewer, $extra) = @_;
    @effects = ();
    $NoosphereTitle = 'Object';
    return getObj({op=>'getobj', from=>$table, id=>7, %{$extra || {}}}, $viewer);
}
sub links {
    my ($html) = @_;
    my @links;
    my $parser = HTML::Parser->new(start_h=>[sub {
        my ($tag, $attr) = @_;
        push @links, {URI->new($attr->{href})->query_form} if $tag eq 'a' && defined $attr->{href};
    }, 'tagname, attr']);
    $parser->parse($html); $parser->eof;
    return @links;
}
sub fields {
    my ($html) = @_;
    my %fields;
    my $parser = HTML::Parser->new(start_h=>[sub {
        my ($tag, $attr) = @_;
        $fields{$attr->{name}} = $attr->{value} if $tag eq 'input' && defined $attr->{name};
    }, 'tagname, attr']);
    $parser->parse($html); $parser->eof;
    return \%fields;
}
sub reset_request {
    my ($method, $origin) = @_;
    $request = bless {method=>$method, headers=>{Origin=>$origin // 'https://example.invalid'}, out=>{}}, 'RestrictedRequest';
    $Noosphere::RequestFormStatus = undef;
}
my %handlers = (getobj=>\&getObj, delobj=>\&delObject);
my $acl_before = $dbh->selectall_arrayref('SELECT * FROM acl');
my %delete_links;
for my $table (qw(books papers lec objects)) {
    subtest "$table denied admin view" => sub {
        ok(!hasPermissionTo($table,7,$admin,'read'), 'real ACL denies admin read access');
        my $html = page($table, $admin, {watch=>'add', method=>'pdf', title=>'UNTRUSTED-TITLE'});
        like($html, qr/You don't have permission/, 'original denial retained');
        like($html, qr/<h2>Admin Controls<\/h2>/, 'admin management is discoverable');
        like($html, qr/pl-entry-section-admin/, 'shared admin styling retained');
        like($html, qr/Collection: <strong>\Q$table\E<\/strong>.*Object ID: <strong>7<\/strong>/s,
            'only collection and ID identify the target');
        unlike($html, qr/PRIVATE-|Private\Q$table\E|UNTRUSTED-TITLE/, 'private metadata and content are not rendered');
        unlike($html, qr/op=(?:edit|adminedit|adminclassify|acledit|postmsg|transfer)/, 'no read-dependent controls');
        is_deeply(\@effects, [], 'no rendering, watch changes, hits or discussion reads after denial');
        is($NoosphereCanonical, '', 'no private canonical name published');
        is($NoosphereDescription, '', 'no private search description published');
        is($NoosphereTitle, 'Object', 'private title not used as document title');
        my @actions = grep { ($_->{op} // '') eq 'delobj' } links($html);
        is(scalar @actions, 1, 'one minimal management action');
        is_deeply($actions[0], {op=>'delobj', from=>$table, id=>7, ask=>'yes'}, 'table-scoped confirmation URL');
        $delete_links{$table} = $actions[0];
        my $decorated = requestFormDecorate($html, $admin);
        like($decorated, qr/Delete object/, 'action survives normal response decoration');
        unlike($decorated, qr/PRIVATE-/, 'response decoration cannot expose the object');
    };
}
is_deeply($dbh->selectall_arrayref('SELECT * FROM acl'), $acl_before, 'management discovery does not change ACLs');
for my $table (qw(books papers lec objects collab)) {
    is(lookupfield($table, 'userid', 'uid=7'), 2, "$table owner is unchanged");
}
my $alias = page('objects', $admin, {id=>999, name=>'Privateobjects7'});
my ($alias_delete) = grep { ($_->{op} // '') eq 'delobj' } links($alias);
is_deeply($alias_delete, $delete_links{objects}, 'alias navigation uses resolved record identity, not requested ID');

for my $viewer (user(-1,100), user(0,100), user(3,99), {uid=>3},
        {uid=>9,data=>{active=>0,access=>100}}, user(9,'not-admin'), user(9,[])) {
    for my $table (qw(books papers lec objects)) {
        my $html = page($table, $viewer);
        like($html, qr/You don't have permission/, 'unauthorized viewer stays denied');
        unlike($html, qr/Admin Controls|op=delobj|PRIVATE-/, 'no admin action or private content for unauthorized viewer');
        is_deeply(\@effects, [], 'unauthorized denied view has no side effects');
    }
}
for my $threshold (undef, 0, 'invalid', []) {
    local $config{access_admin} = $threshold;
    unlike(page('books',$admin), qr/Admin Controls|op=delobj/, 'missing or invalid admin threshold fails closed');
}
my $collab = page('collab', $admin);
like($collab, qr/You don't have permission/, 'private collaboration stays denied to admin');
unlike($collab, qr/Admin Controls|op=delobj|PRIVATE-/, 'no new collaboration management or private content');
is_deeply(\@effects, [], 'private collaboration rendering remains blocked');
for my $table (qw(books papers lec objects collab)) {
    for my $viewer ($admin, user(3)) {
        my $html = page($table, $viewer, {id=>8});
        like($html, qr/Readable fixture content/, "$table ordinary readable view retained");
        unlike($html, qr/Restricted object administration|You don't have permission/, 'readable view does not use denied-object controls');
        ok(grep($_ eq 'render', @effects), 'ordinary rendering path still runs');
    }
    like(page($table,user(2)), qr/Readable fixture content.*Ordinary owner controls/s, "$table owner still has normal read access");
}
for my $params ({id=>999}, {id=>-2}, {from=>'unknown'}, {name=>'not-found'}) {
    unlike(page('books',$admin,$params), qr/Admin Controls|op=delobj|PRIVATE-/, 'invalid or missing object has no management action');
}

for my $table (qw(books papers lec objects)) {
    subtest "$table existing confirmation and authorization" => sub {
        for my $method (qw(GET HEAD)) {
            reset_request($method);
            my $html = dispatch(\%handlers, {%{$delete_links{$table}}}, $admin);
            is(scalar @deletions, 0, "$method navigation does not delete");
            ok(objectExistsByUid(7,$table), "$method leaves target intact");
            like($html, $method eq 'GET' ? qr/Confirm Action/ : qr/requires a submitted form/,
                "$method uses the existing safe navigation response");
        }
        reset_request('GET');
        my $confirmation = dispatch(\%handlers, {%{$delete_links{$table}}}, $admin);
        unlike($confirmation, qr/PRIVATE-/, 'confirmation does not expose private metadata');
        my $body = fields($confirmation);
        is($body->{from}, $table, 'confirmation preserves collection');
        is($body->{id}, 7, 'confirmation preserves object ID');
        ok($body->{_form_token}, 'confirmation has a session-bound CSRF token');
        reset_request('POST');
        my %no_token = %$body; delete $no_token{_form_token};
        dispatch(\%handlers, \%no_token, $admin);
        is(scalar @deletions, 0, 'POST without token cannot delete');
        reset_request('POST', 'https://other.invalid');
        dispatch(\%handlers, {%$body}, $admin);
        is(scalar @deletions, 0, 'cross-origin POST cannot delete');
        reset_request('POST');
        my $member = user(3);
        dispatch(\%handlers, {%$body}, $member);
        is(scalar @deletions, 0, 'another session cannot reuse admin token');
        reset_request('POST');
        my $denied = dispatch(\%handlers, {%$body, _form_token=>requestFormToken($member)}, $member);
        like($denied, qr/can't delete/, 'handler rejects non-owner even with a valid member token');
        is(scalar @deletions, 0, 'server authorization is independent of link visibility');
        reset_request('POST');
        dispatch(\%handlers, {%$body}, $admin);
        is_deeply(\@deletions, [[$table,7,2]], 'confirmed action reaches the existing delete handler with the correct owner');
        ok(!objectExistsByUid(7,$table), 'only confirmed target is deleted');
        ok(objectExistsByUid(8,$table), 'other object in same collection survives');
        for my $other (grep {$_ ne $table} qw(books papers lec objects collab)) {
            ok(objectExistsByUid(7,$other), "equal numeric ID in $other survives");
        }
        is($Noosphere::RequestFormStatus, 303, 'completion redirects with POST/redirect/GET');
        is($request->{out}{Location}, 'https://example.invalid/', 'existing completion destination retained');
        $dbh->do("INSERT INTO $table VALUES (7,2,'Restored fixture','RestoredFixture','Fixture','','')");
        @deletions = ();
    };
}
done_testing();
