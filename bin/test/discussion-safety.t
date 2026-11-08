#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use DBI;
use Noosphere::DiscussionSafety;
use Noosphere::EntryInteractions;

our ($dbh, $stats, $reader, $request, $RequestFormStatus, $RequestFormValidated);
my $root = "$FindBin::Bin/../..";
my %config = (
    en_tbl => 'objects', books_tbl => 'books', papers_tbl => 'papers', exp_tbl => 'lec',
    forum_tbl => 'forums', news_tbl => 'news', polls_tbl => 'polls', req_tbl => 'requests',
    cor_tbl => 'corrections', collab_tbl => 'collab', user_tbl => 'users',
    message_tbl => 'messages', msg_tbl => 'messages', watch_tbl => 'watches',
    lseen_tbl => 'lastmsg', olinks_tbl => 'objlinks', notice_tbl => 'notices', index_tbl => 'objindex',
    acl_tbl => 'acl', gmember_tbl => 'group_members', groups_tbl => 'groups',
    acl_tables => {map {$_ => 1} qw(objects books papers lec collab)}, access_admin => 100,
    main_url => 'https://example.invalid', template_path => "$root/stemplates",
    latest_messages => 3, message_maxcols => 80,
);
my (@sent, @invalidated, @scores);
sub getConfig { $config{$_[0]} }
sub errorMessage { $_[0] }
sub dwarn { }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub sq { my $v = $dbh->quote($_[0]); return substr($v, 1, -1); }
sub mdhm { $_[0] }
sub htmlescape { requestFormEscape($_[0]) }
sub lookupfield { $dbh->selectrow_array("SELECT $_[1] FROM $_[0] WHERE $_[2]") }
sub getUserGroupids { @{$dbh->selectcol_arrayref('SELECT groupid FROM group_members WHERE userid=?', {}, $_[0])} }
sub dbLowLevelSelect {
    my ($db, $sql) = @_;
    return (1, bless {rows => $db->selectall_arrayref($sql, {Slice => {}}), pos => 0}, 'DiscussionRows');
}
sub dbSelect {
    my ($db, $q) = @_;
    my $sql = "SELECT $q->{WHAT} FROM $q->{FROM}";
    $sql .= " WHERE $q->{WHERE}" if defined $q->{WHERE};
    $sql .= ' ORDER BY '.$q->{'ORDER BY'} if $q->{'ORDER BY'};
    $sql .= ' DESC' if $q->{'ORDER BY'} && exists $q->{DESC};
    $sql .= ' LIMIT '.$q->{LIMIT} if defined $q->{LIMIT};
    $sql .= ' OFFSET '.$q->{OFFSET} if $q->{OFFSET};
    return dbLowLevelSelect($db, $sql);
}
sub dbGetRows { @{$_[0]->{rows}} }
sub dbInsert {
    my ($db, $q) = @_;
    my $v = $q->{VALUES};
    $v =~ s/now\(\)/CURRENT_TIMESTAMP/g;
    my $rv = $db->do("INSERT INTO $q->{INTO} ($q->{COLS}) VALUES ($v)");
    return ($rv, bless {rows => []}, 'DiscussionRows');
}
sub dbDelete {
    my ($db, $q) = @_;
    return ($db->do("DELETE FROM $q->{FROM} WHERE $q->{WHERE}"), bless {rows => []}, 'DiscussionRows');
}
sub nextval { 1 + $dbh->selectrow_array('SELECT COALESCE(MAX(uid),0) FROM messages') }
sub changeUserScore { push @scores, [@_] }
sub getScore { 1 }
sub userPref { 'on' }
sub paddingTable { $_[0] }
sub makeBox { join ': ', @_ }
sub fileNotice { push @sent, [@_] }
sub delrows { $dbh->do("DELETE FROM $_[0] WHERE $_[1]") }
sub deleteFileBox { }
sub declassify { }
sub deleteTitle { }
sub irUnindex { }
sub deleteObjectACL { }
sub deletecacheflags { }
{
    package DiscussionRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub finish { 1 }
    package DiscussionStats;
    sub invalidate { push @invalidated, $_[1] }
    package Apache2::RequestUtil;
    sub request { $Noosphere::request }
    package DiscussionRequest;
    sub method { $_[0]->{method} }
    sub header_in { $_[0]->{headers}{$_[1]} }
    sub headers_out { $_[0] }
    sub set { $_[0]->{out}{$_[1]} = $_[2] }
}
# Load actual legacy handlers without their production bootstrap/configuration.
for my $spec (
    ['DB', qw(dbSelectRowBound dbExecuteBound dbRunBound)],
    ['ACL', qw(hasPermissionTo getPermissions)],
    ['Messages', qw(postMessage getPostForm submit_message getLatestMessages getLatestMessagesXML getLatestMessages_data getreplies _r_getmessages)],
    ['Watches', qw(validWatchObjectArgs validWatchUserId addWatch addWatchIfAllowed hasWatch getWatches updateWatches updateEventWatches delWatchByInfo delWatch showWatchers)],
    ['Notices', qw(deleteNotices)],
    ['UserData', qw(validUserId userCreatedObjects)],
    ['DelObj', qw(_delObject)],
) {
    open my $in, '<', "$root/lib/Noosphere/$spec->[0].pm" or die $!;
    my $source = do {local $/; <$in>};
    for my $name (@$spec[1 .. $#$spec]) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body;
        die $@ if $@;
    }
}
sub user { {uid => $_[0], ticket => 'a' x 64, data => {active => 1, access => $_[1] || 0}, prefs => {msgwatch => 'on', usesig => 'off'}} }
sub fixture {
    $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1, PrintError => 0});
    for my $table (discussionTables()) {
        $dbh->do("CREATE TABLE $table (uid INTEGER PRIMARY KEY, userid INTEGER, title TEXT, published INTEGER DEFAULT 1)");
        $dbh->do("INSERT INTO $table (uid,userid,title) VALUES (7,2,'$table title')");
    }
    $dbh->do('CREATE TABLE users (uid INTEGER PRIMARY KEY, username TEXT)');
    $dbh->do("INSERT INTO users VALUES (2,'Owner'),(3,'Former member'),(4,'Reader')");
    $dbh->do('CREATE TABLE messages (uid INTEGER PRIMARY KEY, tbl TEXT, objectid INTEGER, threadid INTEGER, replyto INTEGER DEFAULT -1, visible INTEGER DEFAULT 1, userid INTEGER, subject TEXT, body TEXT, created TEXT DEFAULT CURRENT_TIMESTAMP)');
    $dbh->do('CREATE TABLE acl (tbl TEXT, objectid INTEGER, default_or_normal TEXT, user_or_group TEXT, subjectid INTEGER, _read INTEGER, _write INTEGER, _acl INTEGER)');
    $dbh->do('CREATE TABLE groups (groupid INTEGER PRIMARY KEY)');
    $dbh->do('CREATE TABLE group_members (userid INTEGER, groupid INTEGER)');
    $dbh->do('CREATE TABLE watches (uid INTEGER PRIMARY KEY, tbl TEXT, objectid INTEGER, userid INTEGER)');
    $dbh->do('CREATE TABLE lastmsg (tbl TEXT, objid INTEGER, userid INTEGER, lastmsg INTEGER)');
    $dbh->do('CREATE TABLE objlinks (srctbl TEXT, srcid INTEGER, desttbl TEXT, destid INTEGER)');
    $dbh->do('CREATE TABLE notices (uid INTEGER PRIMARY KEY, userid INTEGER, title TEXT, data TEXT)');
    $dbh->do('CREATE TABLE objindex (tbl TEXT, objectid INTEGER, userid INTEGER, type INTEGER)');
    for my $table (qw(objects books papers lec collab)) {
        $dbh->do("INSERT INTO acl VALUES (?,7,'d','u',-1,1,0,0)", {}, $table);
    }
    my $id = 100;
    for my $table (qw(objects books papers lec)) {
        $id++;
        message($id, $table, 7, $id, -1);
        message($id + 10, $table, 7, $id, $id);
    }
    $stats = bless {}, 'DiscussionStats';
    $request = bless {method => 'POST', headers => {Origin => 'https://example.invalid'}}, 'DiscussionRequest';
    $RequestFormValidated = 0;
    $RequestFormStatus = undef;
    @sent = (); @scores = (); @invalidated = ();
}
sub message {
    my ($id, $table, $object, $thread, $parent, $visible) = @_;
    $dbh->do('INSERT INTO messages (uid,tbl,objectid,threadid,replyto,visible,userid,subject,body) VALUES (?,?,?,?,?,?,3,?,?)',
        {}, $id, $table, $object, $thread, $parent, defined($visible) ? $visible : 1, "Subject $id", "Body $id");
}
sub post {
    my ($viewer, %params) = @_;
    return submit_message({op => 'postmsg', subject => 'New subject', body => 'New body', post => 1,
        _form_token => requestFormToken($viewer), %params}, $viewer);
}
sub count { $dbh->selectrow_array("SELECT COUNT(*) FROM $_[0]".($_[1] ? " WHERE $_[1]" : '')) }
subtest 'table-qualified destinations and stored reply ancestry' => sub {
    fixture();
    for my $table (qw(objects books papers lec)) {
        ok(discussionParentReadable($table, 7, user(-1)), "$table: public parent");
        my ($dest) = discussionPostDestination({from => $table, id => 7}, user(4));
        is($dest->{from}, $table, "$table: new thread destination retained");
        like(post(user(4), from => $table, id => 7), qr/Thank you for posting/, "$table: root posted");
        my $row = $dbh->selectrow_hashref('SELECT * FROM messages ORDER BY uid DESC LIMIT 1');
        is_deeply([@$row{qw(tbl objectid replyto threadid)}], [$table, 7, -1, $row->{uid}], "$table: canonical root identity");
    }
    my ($dest, $parent) = discussionPostDestination({from => 'books', id => 999, replyto => 113}, user(4));
    is_deeply([@$dest{qw(from id)}, $parent->{uid}], ['papers', 7, 113], 'reply uses stored table/id, never supplied values');
    like(post(user(4), from => 'books', id => 999, replyto => 113), qr/Thank you for posting/, 'reply submit resolves stored destination too');
    my $reply = $dbh->selectrow_hashref('SELECT * FROM messages ORDER BY uid DESC LIMIT 1');
    is_deeply([@$reply{qw(tbl objectid threadid replyto)}], ['papers', 7, 103, 113], 'reply remains in correct paper thread');
    my $before = count('messages');
    for my $table ("books WHERE 1=1", 'users', 'acl', 'messages', undef, []) {
        unlike(post(user(4), from => $table, id => 7), qr/Thank you for posting/, 'unallowlisted target rejected');
    }
    for my $id (undef, -1, '7 OR 1=1', '7;DELETE', [], 2147483648) {
        unlike(post(user(4), from => 'books', id => $id), qr/Thank you for posting/, 'invalid parent id rejected');
    }
    unlike(post(user(4), from => 'books', id => 999), qr/Thank you for posting/, 'missing parent rejected');
    unlike(post(user(-1), from => 'books', id => 7), qr/Thank you for posting/, 'anonymous post rejected');
    is(count('messages'), $before, 'rejected requests write no messages');
    $dbh->do("INSERT INTO forums (uid,userid) VALUES (0,2)");
    ok(discussionParentReadable('forums', 0, user(-1)), 'forum zero remains supported');
    message(130, 'books', 7, 102, 103);
    message(131, 'books', 999, 131, -1);
    message(132, 'books', 7, 102, 132);
    message(133, 'books', 7, 102, 134);
    message(134, 'books', 7, 102, 133);
    message(135, 'books', 7, 102, 8888);
    message(136, 'books', 7, 136, -1, 0);
    for my $id (130 .. 136) {
        ok(!discussionMessageReadable($id, user(4)), "invalid/orphan/cyclic/hidden message $id denied");
        unlike(post(user(4), replyto => $id), qr/Thank you for posting/, "cannot reply to $id");
    }
    ok(discussionMessageReadable(113, user(4)), 'valid nested reply remains readable');
    for my $id (200 .. 328) {
        message($id, 'objects', 7, 200, $id == 200 ? -1 : $id - 1);
    }
    ok(discussionMessageReadable(327, user(4)), 'bounded 128-message ancestor chain supported');
    ok(!discussionMessageReadable(328, user(4)), 'overlong ancestor traversal fails closed');
    unlike(post(user(4), replyto => 327), qr/Thank you for posting/, 'cannot create a reply that would exceed the readable depth');
    is(getreplies(user(4), 327, 0, 1, undef, 1), '', 'renderer cannot expose descendants beyond the readable depth');
};
subtest 'privacy follows live parent ACL, including feeds and watches' => sub {
    fixture();
    addWatch('books', 7, 3);
    addWatch('messages', 102, 3);
    is(count('watches'), 2, 'public parent/thread can be watched');
    $dbh->do("UPDATE acl SET _read=0 WHERE tbl='books'");
    ok(!discussionMessageReadable(112, user(3)), 'revoked reader cannot view nested reply');
    is(showWatchers({from => 'books', id => 7}, user(3)), 'Discussion not available.', 'revoked reader cannot enumerate parent watchers');
    is(showWatchers({from => 'messages', id => 102}, user(3)), 'Discussion not available.', 'revoked reader cannot enumerate thread watchers');
    ok(discussionMessageReadable(112, user(2)), 'owner still reads private discussion');
    for my $action (qw(preview quote spell post)) {
        is(postMessage({from => 'books', id => 7, replyto => 112, $action => 1, body => 'draft'}, user(3)),
            'Discussion not available.', "$action cannot expose private reply context");
    }
    addWatch('books', 7, 4);
    addWatch('messages', 112, 4);
    is(count('watches'), 2, 'revoked/missing parent cannot gain new watches');
    updateWatches(7, 'books', 112, 'messages', 2, 'Private subject', 'Private body', {});
    updateWatches(102, 'messages', 112, 'messages', 2, 'Private subject', 'Private body', {});
    updateEventWatches(7, 'books', 2, 'Private event', 'Private body', {});
    is(scalar @sent, 0, 'stale parent/thread watchers receive no message or event notices');
    like(post(user(2), replyto => 112), qr/Thank you for posting/, 'owner may still reply privately');
    is(scalar @sent, 0, 'direct reply notification also respects revoked read access');
    $dbh->do("INSERT INTO objlinks VALUES ('notices',501,'messages',112)");
    ok(!discussionNoticeReadable(501, user(3)), 'old notice preview suppressed after access revoked');
    ok(discussionNoticeReadable(501, user(2)), 'owner can read existing message notice');
    ok(discussionNoticeReadable(502, user(3)), 'non-discussion notices unaffected');
    $dbh->do("INSERT INTO acl VALUES ('papers',7,'n','u',-1,0,0,0)");
    $dbh->do("INSERT INTO groups VALUES (9)");
    $dbh->do("INSERT INTO group_members VALUES (-1,9)");
    $dbh->do("INSERT INTO acl VALUES ('lec',7,'n','g',9,0,0,0)");
    message(120, 'collab', 7, 120, -1, 0);
    $dbh->do('UPDATE collab SET published=0');
    ok(discussionMessageReadable(120, user(2)), 'owner can read legacy unpublished collaboration thread');
    message(121, 'books', 999, 121, -1);
    message(138, 'objects', 7, 101, 139);
    message(139, 'objects', 7, 101, 138);
    my $sql = discussionPublicWhere('messages');
    my $ids = $dbh->selectcol_arrayref("SELECT uid FROM messages WHERE $sql ORDER BY uid");
    is_deeply($ids, [101,111,138,139], 'public SQL excludes private/deleted/anonymous-denied/unpublished parents before pagination');
    unlike(getLatestMessagesXML(), qr/Subject (?:102|103|104|112|113|114|120|121)/, 'XML feed excludes inaccessible subjects');
    unlike(getLatestMessages(1), qr/Subject (?:102|103|104|112|113|114|120|121)/, 'homepage excludes inaccessible subjects');
    local $config{latest_messages} = 100;
    unlike(getLatestMessagesXML(), qr/Subject (?:138|139)/, 'full-chain check also suppresses cyclic public feed rows');
    unlike(getLatestMessages(1), qr/Subject (?:138|139)/, 'full-chain check suppresses cyclic homepage rows');
    $dbh->do('DELETE FROM objects WHERE uid=7');
    is(count('messages', $sql), 0, 'deleted parent removed from public feed immediately');
    $dbh->do('DROP TABLE books');
    ok(!discussionParentReadable('books', 7, user(2)), 'database error fails closed');
};
subtest 'private authorship still prevents unsafe account deletion' => sub {
    fixture();
    $dbh->do('UPDATE acl SET _read=0');
    is(count('messages', discussionPublicWhere('messages')), 0, 'no authored messages are public');
    is(userCreatedObjects(3), 8, 'account deletion safety counts private messages as well');
};
subtest 'posting and moderation require actual POST, same origin, session token and admin' => sub {
    fixture();
    my $admin = user(2,100);
    my $before = count('messages');
    for my $method (qw(GET HEAD PUT DELETE)) {
        $request->{method} = $method;
        post(user(4), from => 'books', id => 7);
        removeDiscussionMessage({op => 'removemsg', id => 102}, $admin);
        is(count('messages'), $before, "$method does not create messages");
        is(lookupfield('messages','body','uid=102'), 'Body 102', "$method does not remove content");
    }
    $request->{method} = 'GET';
    my $confirmation = removeDiscussionMessage({op => 'removemsg', id => 102}, $admin);
    like($confirmation, qr/pl-confirm-action__header\{background:#003399/, 'moderation reuses blue-header confirmation');
    like($confirmation, qr/Replies will be kept/, 'confirmation explains irreversible content removal');
    like($confirmation, qr/name="_form_token"/, 'confirmation includes session token');
    $request->{method} = 'POST';
    for my $viewer (user(-1), user(4), user(2,99)) {
        like(removeDiscussionMessage({op => 'removemsg', id => 102, _form_token => requestFormToken($viewer)}, $viewer),
            qr/Only administrators/, 'non-admin cannot remove content');
    }
    for my $token (undef, 'bad', requestFormToken(user(5))) {
        removeDiscussionMessage({op => 'removemsg', id => 102, _form_token => $token}, $admin);
        post(user(4), from => 'books', id => 7, _form_token => $token);
        is(lookupfield('messages','body','uid=102'), 'Body 102', 'bad/session-mismatched token does not moderate');
        is(count('messages'), $before, 'bad/session-mismatched token does not post');
    }
    $request->{headers}{Origin} = 'https://other.invalid';
    removeDiscussionMessage({op => 'removemsg', id => 102, _form_token => requestFormToken($admin)}, $admin);
    post(user(4), from => 'books', id => 7);
    is(lookupfield('messages','body','uid=102'), 'Body 102', 'cross-origin removal denied');
    is(count('messages'), $before, 'cross-origin post denied');
    $request->{headers}{Origin} = 'https://example.invalid';
    $dbh->do("INSERT INTO notices VALUES (501,3,'Subject 102','Body 102')");
    $dbh->do("INSERT INTO objlinks VALUES ('notices',501,'messages',102),('notices',501,'books',7)");
    removeDiscussionMessage({op => 'removemsg', id => 102, _form_token => requestFormToken($admin)}, $admin);
    is(lookupfield('messages','subject','uid=102'), '[Removed message]', 'admin removal replaces subject');
    is(lookupfield('messages','body','uid=102'), '[Message content removed by an administrator.]', 'admin removal replaces body');
    is(lookupfield('messages','body','uid=112'), 'Body 112', 'reply content preserved');
    ok(discussionMessageReadable(112, user(4)), 'reply thread remains navigable');
    is(count('notices'), 0, 'notice containing removed content deleted');
    is(count('objlinks'), 0, 'all links from deleted notice cleaned up');
    is($RequestFormStatus, 303, 'post/redirect/get after moderation');
    is($request->{out}{Location}, '/?op=getmsg&id=102', 'redirect back to same message');
    ok(grep($_ eq 'latest_messages', @invalidated), 'public message cache invalidated');
    local $config{access_admin};
    like(removeDiscussionMessage({id => 101}, $admin), qr/Only administrators/, 'missing admin threshold fails closed');
};
subtest 'deletion removes only the selected table/id discussion state' => sub {
    fixture();
    my $n = 500;
    for my $table (qw(objects books papers lec)) {
        my $id = {objects => 101, books => 102, papers => 103, lec => 104}->{$table};
        $dbh->do("INSERT INTO watches (tbl,objectid,userid) VALUES (?,7,3),(?,7,4),('messages',?,3),('messages',?,4)", {}, $table,$table,$id,$id+10);
        $dbh->do('INSERT INTO lastmsg VALUES (?,7,3,999)', {}, $table);
        $dbh->do('INSERT INTO notices VALUES (?,3,?,?)', {}, ++$n, "Subject $id", "Body $id");
        $dbh->do("INSERT INTO objlinks VALUES ('notices',?,'messages',?),('notices',?,?,7)", {}, $n,$id,$n,$table);
    }
    $dbh->do("INSERT INTO notices VALUES (900,3,'Unrelated notice','Preserve me')");
    $dbh->do("INSERT INTO objlinks VALUES ('objects',900,'messages',102)");
    ok(_delObject({from => 'books', id => 7}, 2), 'normal object deletion calls shared cleanup');
    is(count('messages', "tbl='books'"), 0, 'all book thread/reply rows removed');
    is(count('watches', "tbl='books' OR (tbl='messages' AND objectid IN (102,112))"), 0, 'all book parent/thread watchers removed, not just owner');
    is(count('lastmsg', "tbl='books'"), 0, 'book unread markers removed');
    is(count('notices'), 4, 'only notices linked to deleted discussion removed; non-notice source IDs cannot delete unrelated notices');
    is(count('objlinks'), 6, 'unrelated notice context links preserved');
    for my $table (qw(objects papers lec)) {
        is(count('messages', "tbl='$table'"), 2, "$table: messages at identical numeric id preserved");
        is(count('watches', "tbl='$table'"), 2, "$table: parent watches preserved");
        is(count('lastmsg', "tbl='$table'"), 1, "$table: unread state preserved");
    }
    my $messages = count('messages');
    ok(!_delObject({from => 'books', id => 999}, 2), 'missing object deletion aborts cleanup');
    is(count('messages'), $messages, 'unsuccessful deletion leaves discussion state alone');
};
subtest 'resource UI remains off and audit is read-only' => sub {
    fixture();
    open my $in, '<', "$root/lib/Noosphere/GetObj.pm" or die $!;
    my $source = do {local $/; <$in>};
    like($source, qr/if \(!\$is_generic_library_item\) \{.*?getMessages/s, 'generic discussion enablement reserved for PR2');
    open $in, '<', "$root/db/audits/discussion-integrity.mysql.sql" or die $!;
    my $sql = do {local $/; <$in>};
    $sql =~ s/^\s*--.*$//mg;
    unlike($sql, qr/\b(?:UPDATE|DELETE|INSERT|ALTER|DROP|REPLACE|TRUNCATE)\b/i, 'audit only reads existing data');
    message(130, 'books', 999, 130, -1);
    message(131, 'papers', 7, 102, 102);
    message(132, 'lec', 7, 104, 133);
    message(133, 'lec', 7, 104, 132);
    my @results = map {$dbh->selectall_arrayref($_, {Slice => {}})} grep {/\S/} split /;/, $sql;
    is_deeply([map {$_->{uid}} @{$results[1]}], [130], 'audit finds orphan without reporting healthy equal-ID parents');
    ok(grep($_->{uid} == 131, @{$results[2]}), 'audit finds mismatched table/thread');
    is($results[3][0]{uid}, 132, 'audit finds two-message cycle');
    is(count('messages'), 12, 'audit leaves every message unchanged');
};
done_testing();
