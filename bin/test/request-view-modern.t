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
use Noosphere::TemplateNS;

our ($dbh, $reader, $NoosphereTitle, $NoosphereCanonical);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", main_url => 'https://physicslibrary.org', access_admin => 100,
    en_tbl => 'objects', news_tbl => 'news', forum_tbl => 'forums', collab_tbl => 'collab',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec', cor_tbl => 'corrections',
    polls_tbl => 'polls', req_tbl => 'requests', user_tbl => 'users',
    msgstylesel => {threaded => 'Threaded', flat => 'Flat'},
    msgordersel => {asc => 'Oldest first', desc => 'Newest first'},
    msgexpandsel => {0 => 'none', 1 => '1', 2 => '2'},
);
our $request = {uid => 40, userid => 1, creatorid => 441, createname => 'bci1 <Editor>',
    title => 'integral <equation> & "applications"', data => "An entry that defines integral equations.\n<script>not HTML</script>",
    created => '2009-04-14 10:59:14', fulfilled => '2009-04-17 19:01:20', closed => '2009-04-18 10:00:00'};
our @context = ({desttbl => 'objects', destid => 642}, {desttbl => 'papers', destid => 142});
our @messages;
our ($failure, $read_allowed) = ('', 1);
my (@queries, @finished, @hits, @seen, @toggles);
sub getConfig { $config{$_[0]} }
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub errorMessage { $_[0] }
sub dwarn { }
sub getAddr { 'feedback@example.invalid' }
sub hasPermissionTo { $_[3] eq 'read' ? $read_allowed : $_[2]{uid} == 2 }
sub lookupfield { $_[1] eq 'title' ? 'Linked <article> & "context"' : 'Request owner' }
sub changeWatch { }
sub hitObject { push @hits, [@_] }
sub get_lastseen { 10 }
sub get_lastmsg { 12 }
sub update_lastseen { push @seen, [@_] }
sub getWatchWidget { $_[1]{uid} > 0 ? '<a href="#request-watch">Watch request</a>' : '' }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub TeXtoUTF8 { $_[0] }
sub _object_exists { 1 }
sub _userfields_by_id { {username => 'Comment author'} }
sub hasWatch { 0 }
sub toggleWatch { push @toggles, [@_] }
sub getreplies { '' }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub nicifyTimestamp { $_[0] }
sub htmlescape { requestFormEscape($_[0]) }
sub clearBox { die 'Request used a legacy presentation box'; }
sub getPager { '<a href="/?op=getobj&amp;from=requests&amp;id=40&amp;offset=10">Next messages</a>' }
sub hashToFormVars {
    my $vars = shift;
    return join '', map {'<input type="hidden" name="'.$_.'" value="'.requestFormEscape($vars->{$_}).'" />'} sort keys %$vars;
}
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    my (@rows, $kind);
    if ($q->{FROM} eq 'requests') { $kind = 'object'; @rows = ({%$request}); }
    elsif ($q->{FROM} eq 'requests,users') { $kind = 'detail'; @rows = ({%$request}); }
    elsif ($q->{FROM} eq 'objlinks') { $kind = 'context'; @rows = @context; }
    else { $kind = 'messages'; @rows = @messages; }
    return (0, undef) if $failure eq $kind;
    @rows = () if $failure eq 'missing';
    return (1, bless {rows => [map {{%$_}} @rows], pos => 0, kind => $kind}, 'RequestViewRows');
}
{
    package RequestViewRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub finish { push @finished, $_[0]->{kind} }
}
for my $spec (
    ['GetObj', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj getOwnerControls getAuthorControls)],
    ['Requests', qw(getReq getReqInteract printContextLinks)],
    ['Messages', qw(getMessages printmessage printMsgHeaderLine printMsgExpanded getWatchBox getWatchString)],
    ['Util', qw(getSelectBox stdmsg tohtmlascii)], ['DB', qw(dbGetRows)],
) {
    my ($module, @names) = @$spec;
    my $source = readFile("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        # These unchanged legacy helpers emit warnings for optional captures and nonnumeric IDs.
        my $legacy_warnings = $name eq 'tohtmlascii' || $name eq 'getObj' ? 'no warnings qw(uninitialized numeric); ' : '';
        eval $legacy_warnings . $body;
        die $@ if $@;
    }
}
sub user { {uid => $_[0], ticket => 'a' x 64, data => {active => 1, access => $_[1] || 0},
    prefs => {pagelength => 20, msgstyle => 'threaded', msgexpand => 1, msgorder => 'desc'}} }
sub page {
    my ($u, @params) = @_;
    @queries = (); @finished = (); @seen = (); @hits = ();
    getObj({op => 'getobj', from => 'requests', id => 40, @params}, $u);
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {push @links, URI->new($_[1]{href}) if $_[0] eq 'a'}, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub query { return {$_[0]->query_form}; }
sub action { my ($html, $op) = @_; my ($url) = grep {(query($_)->{op} || '') eq $op} links($html); return $url ? query($url) : undef; }
my %fixtures;
my $html = page(user(-1));
$fixtures{confirmed} = $html;
like($html, qr/<header class="pl-modern-box-header"><h1>Viewing Request<\/h1>/, 'request uses shared compact blue header');
like($html, qr/Title: integral &lt;equation&gt; &amp; &quot;applications&quot;/, 'title and original label safely displayed');
like($html, qr/Request by:.*bci1 &lt;Editor&gt;.*2009-04-14 10:59:14.*filled \(confirmed\).*2009-04-17 19:01:20/s, 'creator, dates and confirmed status retained');
like($html, qr/An entry that defines integral equations\..*<br \/>.*&lt;script&gt;not.*HTML&lt;\/script&gt;/s, 'original plain-text conversion and newlines retained');
unlike($html, qr/<script>|<NS:template|###NSTAG###|<center/, 'unsafe text and legacy wrappers absent');
is_deeply(action($html, 'oldreqs'), {op => 'oldreqs'}, 'confirmed request returns to completed list');
is_deeply(action($html, 'getuser'), {op => 'getuser', id => 441}, 'requester profile link points to creator');
my @context_urls = grep {(query($_)->{op} || '') eq 'getobj'} links($html);
is_deeply([map {query($_)} @context_urls], [{op => 'getobj', from => 'objects', id => 642}, {op => 'getobj', from => 'papers', id => 142}], 'all fulfillment context links preserved');
like($html, qr/Linked &lt;article&gt; &amp; &quot;context&quot;/, 'context titles escaped');
is_deeply(action($html, 'addreq'), {op => 'addreq'}, 'add request action retained');
is_deeply(action($html, 'adden'), {op => 'adden', request => 40, title => $request->{title}}, 'fill action preserves title and request ID');
is_deeply(action($html, 'updatereq'), {op => 'updatereq', request => 40}, 'update action retains selected request');
is_deeply(action($html, 'postmsg'), {op => 'postmsg', from => 'requests', id => 40}, 'post action retains request context');
like($html, qr/<h2>Discussion<\/h2>.*No messages\..*<h2>Interact<\/h2>/s, 'discussion and interact use modern headers');
unlike($html, qr/Admin Controls|Owner Controls|Author Controls|Watch request/, 'guest has no new privileged or watch controls');
is_deeply($seen[0], ['requests', 40, -1, 12], 'discussion last-seen update retained');
is_deeply($hits[0], [40, 'requests', 'hits'], 'hit counter retained');
is($NoosphereCanonical, '', 'request has no encyclopedia canonical');
ok(grep($_ eq 'detail', @finished), 'detail statement released');
ok(grep($_ eq 'context', @finished), 'context statement released');
for my $uid (1, 2, 3) {
    my $reader_page = page(user($uid));
    like($reader_page, qr/Watch request/, "request watch retained for reader $uid");
    unlike($reader_page, qr/Owner Controls|Author Controls|Admin Controls/, "no additional controls for reader $uid");
}
unlike(page(user(3, 100)), qr/Admin Controls/, 'confirmed request cannot be administered');
{
    local $request->{closed};
    $html = page(user(3, 100));
    $fixtures{unconfirmed} = $html;
    like($html, qr/filled \(unconfirmed\)/, 'unconfirmed status retained');
    is_deeply(action($html, 'reqlist'), {op => 'reqlist'}, 'unconfirmed request returns to open list');
    like($html, qr/pl-entry-section-admin.*<h2>Admin Controls<\/h2>/s, 'admin controls retain red shared header');
    for my $op ('confirmreq', 'denyreq', 'deletereq') {
        is_deeply(action($html, $op), {op => $op, id => 40}, "$op keeps original confirmation route");
    }
    unlike(page(user(3, 99)), qr/Admin Controls|confirmreq|denyreq|deletereq/, 'non-admin cannot see administration');
    local $request->{fulfilled};
    $html = page(user(3, 100));
    $fixtures{opened} = $html;
    like($html, qr/>opened<\/dd>/, 'opened status retained');
    unlike($html, qr/2009-04-17|Context:|Request context|confirmreq|denyreq/, 'open request has no fulfillment metadata or confirmation actions');
    ok(action($html, 'deletereq'), 'admin retains open-request delete action');
    is(scalar(grep {$_->{FROM} eq 'objlinks'} @queries), 0, 'open request does not query context');
}
{
    local @context;
    unlike(page(user(-1)), qr/Context:|Request context/, 'no empty context heading');
    ok(grep($_ eq 'context', @finished), 'empty context statement released');
}
{
    local $failure = 'detail';
    is(getReq({id => 40}, user(-1)), 'Error with query', 'detail query failure handled');
}
{
    local $failure = 'missing';
    is(getReq({id => 40}, user(-1)), "Couldn't find record!", 'missing detail handled');
}
{
    local $failure = 'context';
    unlike(page(user(-1)), qr/Context:/, 'failed optional context query does not crash view');
}
{
    local $read_allowed = 0;
    unlike(page(user(-1)), qr/Title:|Request by:|An entry that defines/, 'object ACL still protects request contents');
    is(scalar @hits, 0, 'denied read does not count a hit');
}
is(page(user(-1), id => '40 OR 1=1'), 'Invalid object id.', 'invalid ID rejected before request handler');
is(scalar @queries, 0, 'invalid ID never reaches DB');
@messages = ({uid => 12, userid => 3, threadid => 12, objectid => 40, tbl => 'requests', replyto => -1,
    created => '2026-10-04 12:00:00', subject => 'Original request discussion', body => 'Existing discussion body'});
$html = page(user(3), msgstyle => 'flat', msgexpand => 2, msgorder => 'asc');
$fixtures{discussion} = $html;
like($html, qr/name="msgstyle" id="pl-entry-msgstyle".*value="flat" selected/s, 'discussion style preserved');
like($html, qr/name="msgexpand" id="pl-entry-msgexpand".*value="2" selected/s, 'discussion expansion preserved');
like($html, qr/name="msgorder" id="pl-entry-msgorder".*value="asc" selected/s, 'discussion ordering preserved');
like($html, qr/Existing discussion body.*Next messages/s, 'existing discussion body and pagination retained');
like($html, qr/name="from" value="requests"/, 'discussion forms preserve request table');
my $decorated = requestFormDecorate($html, user(3));
my ($depth, $nested, $tokens) = (0, 0, 0);
HTML::Parser->new(start_h => [sub {
    $nested++ if $_[0] eq 'form' && $depth++;
    $tokens++ if $_[0] eq 'input' && ($_[1]{name} || '') eq '_form_token';
}, 'tagname, attr'], end_h => [sub {$depth-- if $_[0] eq 'form'}, 'tagname'])->parse($decorated);
is($nested, 0, 'discussion forms never nest');
is($depth, 0, 'discussion forms close correctly');
is($tokens, 1, 'message-watch mutation retains CSRF token');
page(user(3), watch => 'toggle watches', watch_12 => 1);
is_deeply(\@toggles, [['messages', 12, 3]], 'message watch toggle preserved');
unlike(page(user(3), msgexpand => 0), qr/Existing discussion body/, 'collapsed discussion respected');
{
    local $request->{title} = 'VeryLongUnbrokenRequestTitle' x 20;
    local $request->{createname} = 'VeryLongUnbrokenUsername' x 15;
    local $request->{data} = "One line\n\n" . 'VeryLongUnbrokenRequestText' x 20;
    $fixtures{long} = page(user(3, 100));
}
like(printContextLinks(40), qr/href=.*getobj.*objects.*642/, 'legacy context helper callers retain links');

if (my $dir = $ENV{REQUEST_VIEW_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    for my $name (sort keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Request view preview', site_name => 'Physics Library', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page; close $out;
    }
}
done_testing();
