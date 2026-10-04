#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use URI;
use URI::Escape qw(uri_escape_utf8);
use HTML::Parser;
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;

our ($dbh, $reader, $NoosphereTitle, $NoosphereCanonical);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    en_tbl => 'objects', news_tbl => 'news', forum_tbl => 'forums', collab_tbl => 'collab',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec', cor_tbl => 'corrections',
    polls_tbl => 'polls', req_tbl => 'requests', user_tbl => 'users',
    msgstylesel => {threaded => 'Threaded', flat => 'Flat'},
    msgordersel => {asc => 'Oldest first', desc => 'Newest first'},
    msgexpandsel => {-1 => 'all', 0 => 'none', 1 => '1', 2 => '2', 3 => '3'},
);
my $forum = {uid => 0, userid => 1, title => 'LaTeX <Help> & "Forum"', data => '<p>General LaTeX questions, and Noosphere LaTeX questions in specific.</p>'};
our @messages = (
    {uid => 395, threadid => 395, replyto => -1, userid => 1, subject => 'Physics <tips> & tricks', body => "Original message.\n\\begin{figure}[h]\n<script>alert(1)</script>\nhttp://example.invalid/notes", created => '2025-03-04 05:31:13'},
    {uid => 396, threadid => 395, replyto => 395, userid => 2, subject => 'First reply', body => 'First reply body', created => '2025-03-04 06:31:13'},
    {uid => 397, threadid => 395, replyto => 395, userid => 3, subject => 'Second reply', body => 'Second reply body', created => '2025-03-04 07:31:13'},
    {uid => 398, threadid => 395, replyto => 396, userid => 3, subject => 'Nested reply', body => 'Nested reply body', created => '2025-03-04 06:45:13'},
    {uid => 400, threadid => 400, replyto => -1, userid => 2, subject => 'Newest thread', body => 'Newest thread body', created => '2025-03-05 05:31:13'},
);
$_->{tbl} = 'forums', $_->{objectid} = 0 for @messages;
my (@queries, @toggles, @seen, @watch_changes);
our ($allowed, $failure) = (1, '');
sub getConfig { $config{$_[0]} }
sub getAddr { 'feedback@example.invalid' }
sub dwarn { }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub TeXtoUTF8 { $_[0] }
sub errorMessage { $_[0] }
sub hasPermissionTo { return $allowed if $_[3] eq 'read'; return $_[2]{uid} == 2; }
sub hitObject { }
sub lookupfield { 'Forum owner' }
sub _object_exists { 1 }
sub _userfields_by_id { {username => 'User <'.$_[0].'> & Editor'} }
sub nicifyTimestamp { $_[0] }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub htmlescape { requestFormEscape($_[0]) }
sub get_lastseen { 394 }
sub get_lastmsg { 400 }
sub update_lastseen { push @seen, [@_] }
sub hasWatch { $_[0] eq 'messages' && $_[1] == 395 }
sub addWatch { push @watch_changes, ['add', @_] }
sub delWatchByInfo { push @watch_changes, ['remove', @_] }
sub toggleWatch { push @toggles, [@_] }
sub hashToFormVars {
    my ($vars, $excluded) = @_;
    my %excluded = map {$_ => 1} @{$excluded || []};
    return join '', map {'<input type="hidden" name="'.$_.'" value="'.requestFormEscape($vars->{$_}).'" />'}
        grep {!$excluded{$_}} sort keys %$vars;
}
sub getPager { '<a href="/?op=getobj&amp;from=forums&amp;id=0&amp;offset=1">Next messages</a>' }
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    my @rows;
    if ($q->{FROM} eq 'forums') { @rows = ({%$forum}); }
    elsif ($q->{WHERE} =~ /^replyto = (\d+)$/) {
        return (0, undef) if $failure eq 'reply';
        my $parent = $1;
        @rows = sort {$a->{created} cmp $b->{created}} grep {$_->{replyto} == $parent} @messages;
    } else {
        die "Unexpected query $q->{WHERE}" unless $q->{WHERE} =~ /^objectid = 0 and tbl='forums'/;
        return (0, undef) if $failure eq ($q->{'ORDER BY'} ? 'list' : 'count');
        @rows = grep {$q->{WHERE} !~ /replyto = -1/ || $_->{replyto} == -1} @messages;
        @rows = sort {$a->{created} cmp $b->{created}} @rows;
        @rows = reverse @rows if exists $q->{DESC};
        splice @rows, 0, $q->{OFFSET} if $q->{OFFSET};
        splice @rows, $q->{LIMIT} if defined($q->{LIMIT}) && @rows > $q->{LIMIT};
    }
    return (1, bless {rows => [map {{%$_}} @rows], pos => 0}, 'ForumThreadRows');
}
{
    package ForumThreadRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub finish { $_[0]->{finished} = 1 }
}
for my $spec (
    ['GetObj', qw(getObj getObjTableIsAllowed getObjIdIsValid getEncyclopediaCanonicalURL getOwnerControls getAuthorControls)],
    ['Forums', qw(renderForum)],
    ['Messages', qw(getMessages printmessage forumMessageRow getreplies _r_getmessages getWatchString)],
    ['Watches', qw(validWatchObjectArgs validWatchUserId changeWatch getWatchWidget)],
    ['Util', qw(getSelectBox stdmsg tohtmlascii)],
    ['DB', qw(dbGetRows)],
) {
    my ($module, @names) = @$spec;
    open my $in, '<', "$root/lib/Noosphere/$module.pm" or die $!;
    my $source = do {local $/; <$in>};
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval "no warnings 'uninitialized'; $body";
        die $@ if $@;
    }
}
sub user {
    {uid => $_[0], ticket => 'a' x 64, data => {active => 1},
        prefs => {pagelength => 20, msgstyle => 'threaded', msgexpand => 1, msgorder => 'desc'}};
}
sub page {
    my ($user, @params) = @_;
    @queries = (); @seen = (); @toggles = (); @watch_changes = ();
    getObj({op => 'getobj', from => 'forums', id => 0, @params}, $user);
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {push @links, URI->new($_[1]{href}) if $_[0] eq 'a'}, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub query { return {$_[0]->query_form}; }
my $guest = page(user(-1));
like($guest, qr/<h1>Forum: LaTeX &lt;Help&gt; &amp; &quot;Forum&quot;<\/h1>/, 'forum zero uses escaped compact blue header');
like($guest, qr/Welcome to the LaTeX &lt;Help&gt; &amp; &quot;Forum&quot; forum!/, 'complete welcome text retained');
like($guest, qr/<p>General LaTeX questions, and Noosphere LaTeX questions in specific\.<\/p>/, 'existing formatted description retained');
like($guest, qr/back to forums top/, 'forum index navigation retained');
like($guest, qr/<h2>Interact<\/h2>.*<h2>Discussion<\/h2>/s, 'interact and discussion use matching modern sections');
unlike($guest, qr/<center|bgcolor=|name="watch_|Toggle watches|<h2>Owner Controls|<h2>Author Controls/, 'guest has no legacy boxes, member watches, or private owner actions');
like($guest, qr/Newest thread.*Physics &lt;tips&gt; &amp; tricks/s, 'newest-first root ordering retained');
like($guest, qr/Original message\.<br \/>.*\\begin\{figure\}/s, 'expanded root body retains source formatting');
like($guest, qr/&lt;script&gt;alert\(1\)&lt;\/script&gt;/, 'message body keeps safe standard rendering');
like($guest, qr/First reply.*Nested reply.*Second reply/s, 'thread hierarchy and chronological replies retained');
unlike($guest, qr/First reply body|Nested reply body|Second reply body/, 'default expansion shows root bodies but collapsed replies');
is_deeply($seen[0], ['forums', 0, -1, 400], 'reading still updates last-seen state');
my ($post) = grep {(query($_)->{op} || '') eq 'postmsg' && !query($_)->{replyto}} links($guest);
is_deeply(query($post), {op => 'postmsg', from => 'forums', id => 0}, 'new-post action keeps forum zero');
my ($reply) = grep {(query($_)->{replyto} || '') eq '395'} links($guest);
is_deeply(query($reply), {op => 'postmsg', id => 0, replyto => 395}, 'root reply action targets existing compose page');
like($guest, qr/class="pl-entry-discussion-options" method="get"/, 'discussion options stay read-only GET');
like($guest, qr/Next messages/, 'pagination retained');
$reader = user(999);
my $owner = page(user(1));
is($reader->{uid}, 999, 'discussion reader state restored after request');
like($owner, qr/<h2>Owner Controls<\/h2>/, 'owner controls modernized');
for my $op (qw(edit rerender linkpolicy acledit creategroup transfer delobj abandon)) {
    my ($link) = grep {(query($_)->{op} || '') eq $op} links($owner);
    ok($link, "owner $op action retained");
    is(query($link)->{id}, 0, "$op keeps forum zero") if $link;
    is(query($link)->{ask}, 'yes', "$op keeps confirmation") if $link && $op =~ /^(delobj|abandon)$/;
}
like($owner, qr/name="watch_395".*Physics &lt;tips&gt;.*\(watching\)/s, 'member retains labeled thread watch checkbox and state');
unlike($owner, qr/name="watch_39[678]"/, 'only root threads get watch checkboxes');
like($owner, qr/aria-label="New message"/, 'unread highlighting retained for members');
like(page(user(2)), qr/<h2>Author Controls<\/h2>/, 'permitted writer gets modern author controls');
unlike(page(user(3)), qr/<h2>Author Controls|<h2>Owner Controls/, 'ordinary member gets no owner actions');
page(user(1), watch => 'toggle watches', watch_395 => 1);
is_deeply(\@toggles, [['messages', 395, 1]], 'batch watch action retained');
page(user(1), watch => 'add');
is_deeply(\@watch_changes, [['add', 'forums', 0, 1]], 'forum watch add retained');
my $decorated = requestFormDecorate($owner, user(1));
my ($depth, $nested, $tokens) = (0, 0, 0);
HTML::Parser->new(start_h => [sub {
    my ($tag, $attrs) = @_;
    $nested++ if $tag eq 'form' && $depth++;
    $tokens++ if $tag eq 'input' && ($attrs->{name} || '') eq '_form_token';
}, 'tagname, attr'], end_h => [sub {$depth-- if $_[0] eq 'form'}, 'tagname'])->parse($decorated);
is($nested, 0, 'forum and thread watch forms do not nest');
is($depth, 0, 'forum forms are balanced');
is($tokens, 2, 'forum and thread watch forms each receive CSRF protection');
my $collapsed = page(user(1), msgexpand => 0);
unlike($collapsed, qr/Original message\.|Newest thread body|First reply body/, 'none expansion hides all bodies');
like($collapsed, qr/Nested reply/, 'none expansion retains entire thread hierarchy');
my $two = page(user(1), msgexpand => 2);
like($two, qr/First reply body|Second reply body/, 'depth two expands direct replies');
unlike($two, qr/Nested reply body/, 'depth two leaves grandchildren collapsed');
my $all = page(user(1), msgexpand => -1);
like($all, qr/Nested reply body/, 'all expansion includes deepest body');
my ($top) = grep {(query($_)->{op} || '') eq 'getmsg' && query($_)->{id} == 395} links($all);
ok($top, 'expanded descendants keep Top navigation');
my $flat = page(user(1), msgstyle => 'flat', msgexpand => 1, msgorder => 'asc');
like($flat, qr/Original message\..*First reply body.*Nested reply body.*Second reply body.*Newest thread body/s, 'flat view orders all messages oldest-first');
my $flat_count = () = $flat =~ /class="pl-forum-message-heading"/g;
is($flat_count, 5, 'flat view does not duplicate descendants recursively');
my $paging = page(user(1), offset => 1, msgorder => 'asc');
like($paging, qr/Newest thread body/, 'offset selects next root');
unlike($paging, qr/Original message\./, 'offset does not repeat previous page root');
{
    local @messages;
    like(page(user(1)), qr/No messages\./, 'empty forum state retained');
}
for my $fail ('count', 'list') {
    local $failure = $fail;
    like(page(user(1)), qr/Query error\./, "$fail failure handled without dereferencing a missing statement");
}
{
    local $failure = 'reply';
    like(page(user(1)), qr/Original message\./, 'failed child query does not hide root message');
}
{
    local $allowed = 0;
    unlike(page(user(1), watch => 'add'), qr/General LaTeX|Original message/, 'existing parent ACL denial hides forum and discussion');
    is(scalar @toggles + scalar @watch_changes, 0, 'denied user cannot change watches');
}
if (my $dir = $ENV{FORUM_THREAD_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    for my $case (['forum-guest', $guest], ['forum-owner', $decorated], ['forum-all', $all],
        ['forum-collapsed', $collapsed], ['forum-flat', $flat]) {
        my $html = '';
        $tt->process('view.tt', {title => 'LaTeX Help Forum', site_name => 'Physics Library',
            content => $case->[1], sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$html) or die $tt->error;
        open my $out, '>', "$dir/$case->[0].html" or die $!;
        print {$out} $html; close $out;
    }
}
done_testing();
