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
use constant ACT_VOTE => 1;

our ($dbh, $reader, $NoosphereCanonical, $NoosphereTitle);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
    template_cmd_prefix => 'NS', main_url => 'https://physicslibrary.org', siteaddrs => {},
    bug_url => 'https://example.invalid/issues', action_tbl => 'actions',
    polls_tbl => 'polls', news_tbl => 'news', en_tbl => 'objects', cor_tbl => 'corrections',
    collab_tbl => 'collab', forum_tbl => 'forums', user_tbl => 'users', req_tbl => 'requests',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec',
    msgstylesel => {threaded => 'Threaded', flat => 'Flat'},
    msgordersel => {asc => 'Oldest first', desc => 'Newest first'},
    msgexpandsel => {0 => 'none', 1 => '1', 2 => '2'},
);
our $poll = {uid => 7, userid => 1, title => 'Focus <for> PhysicsLibrary & Friends',
    options => 'Books,Docs,Collaboration', start => '2026-08-15 00:00:00',
    finish => '2026-09-12 00:00:00', opened => 0};
our %counts = (Books => 0, Docs => 1, Collaboration => 1);
our ($failure, $read_allowed, $already_voted) = ('', 1, 0);
my (@queries, @finished, @hits, @seen, @toggles, @insertions, @scores, @messages);
sub getConfig { $config{$_[0]} }
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub dwarn { }
sub errorMessage { $_[0] }
sub getAddr { 'feedback@example.invalid' }
sub hasPermissionTo { $_[3] eq 'read' ? $read_allowed : $_[2]{uid} == 2 }
sub lookupfield { 'Poll editor' }
sub changeWatch { }
sub hitObject { push @hits, [@_] }
sub get_lastseen { 10 }
sub get_lastmsg { 12 }
sub update_lastseen { push @seen, [@_] }
sub getWatchWidget { '<a href="#existing-hidden-widget">Watch entry</a>' }
sub nb { defined($_[0]) && length($_[0]) }
sub TeXtoUTF8 { $_[0] }
sub _object_exists { 1 }
sub _userfields_by_id { {username => 'Comment author'} }
sub hasWatch { 0 }
sub toggleWatch { push @toggles, [@_] }
sub getreplies { '' }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub nicifyTimestamp { $_[0] }
sub stdmsg { $_[0] }
sub htmlescape { requestFormEscape($_[0]) }
sub sq { my $s = $_[0]; $s =~ s/'/''/g; $s }
sub nextval { 99 }
sub getScore { 1 }
sub changeUserScore { push @scores, [@_] }
sub paddingTable { $_[0] }
sub makeBox { $_[1] }
sub clearBox { die 'Poll used a legacy presentation box'; }
sub getPager { '<a href="/?op=getobj&amp;from=polls&amp;id=7&amp;offset=10">Next messages</a>' }
sub hashToFormVars {
    my $vars = shift;
    return join '', map {'<input type="hidden" name="'.$_.'" value="'.requestFormEscape($vars->{$_}).'" />'} sort keys %$vars;
}
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    my (@rows, $kind);
    if ($q->{FROM} eq 'polls') {
        $kind = $q->{WHAT} eq '*' ? 'object' : 'poll';
        return (0, undef) if $failure eq $kind;
        @rows = $failure eq 'missing' ? () : ({%$poll});
    } elsif ($q->{WHAT} eq 'count(uid) as ct') {
        $kind = 'count';
        return (0, undef) if $failure eq 'count';
        my ($option) = $q->{WHERE} =~ /data='(.*)'$/;
        $option =~ s/''/'/g;
        @rows = $failure eq 'count-row' ? () : ({ct => $counts{$option} || 0});
    } elsif ($q->{FROM} eq 'actions') {
        $kind = 'prior-vote';
        @rows = $already_voted ? ({uid => 98}) : ();
    } else {
        $kind = 'messages';
        @rows = @messages;
    }
    return (1, bless {rows => \@rows, kind => $kind}, 'PollViewRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub dbInsert {
    push @insertions, $_[1];
    $counts{Docs}++;
    return (1, bless {rows => [], kind => 'insert'}, 'PollViewRows');
}
{
    package PollViewRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[0] }
    sub finish { push @finished, $_[0]->{kind} }
}
for my $spec (
    ['GetObj', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj getOwnerControls getAuthorControls)],
    ['Polls', qw(viewPoll getOptionCount vote checkVote)],
    ['Messages', qw(getMessages printmessage printMsgHeaderLine printMsgExpanded getWatchBox getWatchString)],
    ['Util', qw(getSelectBox ymd)],
) {
    my ($module, @names) = @$spec;
    my $source = readFile("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body;
        die $@ if $@;
    }
}
sub user {
    {uid => $_[0], ticket => 'a' x 64, data => {active => 1},
        prefs => {pagelength => 20, msgstyle => 'threaded', msgexpand => 1, msgorder => 'desc'}};
}
sub page {
    my ($user, @params) = @_;
    @queries = (); @finished = (); @seen = (); @hits = ();
    getObj({op => 'getobj', from => 'polls', id => 7, @params}, $user);
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {push @links, URI->new($_[1]{href}) if $_[0] eq 'a'}, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub query { return {$_[0]->query_form}; }
my %fixtures;
my $html = page(user(-1));
$fixtures{closed} = $html;
like($html, qr/<header class="pl-modern-box-header"><h1>Viewing Poll<\/h1>/, 'poll uses shared compact blue header');
like($html, qr/Focus &lt;for&gt; PhysicsLibrary &amp; Friends/, 'question is safely escaped');
like($html, qr/Closed.*2026-08-15 to 2026-09-12/s, 'status and original date range visible');
like($html, qr/<caption>Results<\/caption>/, 'results table has a caption');
like($html, qr/<th scope="row">Books<\/th>.*?>0<\/td>.*?>0\.0%/s, 'zero-count response retained');
like($html, qr/<th scope="row">Docs<\/th>.*?>1<\/td>.*?>50\.0%/s, 'counts and percentages are correct');
like($html, qr/width: 50\.0000%;/, 'visual bar represents its share of all votes');
like($html, qr/2 people voted total\./, 'original total wording retained');
unlike($html, qr/Vote in poll/, 'closed poll does not advertise voting');
my ($index) = grep {(query($_)->{op} || '') eq 'viewpolls'} links($html);
ok($index, 'all-polls navigation available');
my ($post) = grep {(query($_)->{op} || '') eq 'postmsg'} links($html);
is_deeply(query($post), {op => 'postmsg', from => 'polls', id => 7}, 'post action targets same poll');
like($html, qr/<h2>Discussion<\/h2>.*<h2>Interact<\/h2>/s, 'discussion and interact use modern sections');
like($html, qr/No messages\./, 'empty discussion retained');
unlike($html, qr/<center|votingbar\.png|<NS:template|###NSTAG###|&nbsp;/, 'legacy layout and template placeholders removed');
unlike($html, qr/Owner Controls|Author Controls|existing-hidden-widget/, 'no new privileged or entry-watch controls exposed');
is_deeply($seen[0], ['polls', 7, -1, 12], 'last-seen update retained');
is_deeply($hits[0], [7, 'polls', 'hits'], 'hit counter retained');
is($NoosphereCanonical, '', 'poll receives no encyclopedia canonical URL');
is(scalar @queries, 7, 'no extra queries beyond existing poll, vote counts, and discussion');
is(scalar(grep {$_ eq 'count'} @finished), 3, 'vote-count statements are released');
ok(grep($_ eq 'poll', @finished), 'poll statement released');
like($queries[1]{WHAT}, qr/start<=CURRENT_TIMESTAMP and finish>CURRENT_TIMESTAMP/, 'open status uses database clock and existing list boundaries');
for my $uid (1, 2, 3) {
    unlike(page(user($uid)), qr/Owner Controls|Author Controls|existing-hidden-widget/,
        "reader $uid retains only existing poll actions");
}
{
    local $poll->{opened} = 1;
    my $open = page(user(3));
    $fixtures{open} = $open;
    like($open, qr/>Open<\/span>/, 'open status displayed');
    my ($vote) = grep {(query($_)->{op} || '') eq 'getpoll'} links($open);
    is_deeply(query($vote), {op => 'getpoll', id => 7}, 'open poll keeps existing vote form route');
}
{
    local %counts;
    my $empty = page(user(-1));
    $fixtures{zero} = $empty;
    is(scalar(() = $empty =~ />0\.0%/g), 3, 'zero-vote poll has no divide-by-zero or missing options');
    like($empty, qr/0 people voted total\./, 'zero-vote total retained');
}
{
    local %counts = (Books => 1, Docs => 1, Collaboration => 1);
    like(page(user(-1)), qr/>33\.3%/, 'fractional share rounded to one decimal');
}
{
    local $poll->{title} = 'VeryLongUnbrokenQuestion' x 20;
    local $poll->{options} = 'VeryLongUnbrokenResponse' x 15 . ',<script> & "quote"';
    my $long = page(user(-1));
    $fixtures{long} = $long;
    like($long, qr/&lt;script&gt; &amp; &quot;quote&quot;/, 'response labels safely escaped');
    unlike($long, qr/<script>/, 'response cannot inject markup');
}
{
    local $poll->{options} = '';
    like(page(user(-1)), qr/No poll responses are available\./, 'empty option list has a readable state');
}
for my $fail ('poll', 'count', 'count-row', 'missing') {
    local $failure = $fail;
    like(page(user(-1)), qr/Poll query failed|temporarily unavailable|Object not found/,
        "$fail failure handled without dereferencing missing rows");
}
{
    local $failure = 'missing';
    is(viewPoll({id => 7}, user(-1)), 'Could not find poll!', 'direct missing poll handled');
}
@queries = ();
is(viewPoll({id => '7 OR 1=1'}, user(-1)), 'Invalid poll id.', 'direct handler rejects invalid id');
is(scalar @queries, 0, 'invalid id never reaches database');
{
    local $read_allowed = 0;
    unlike(page(user(-1)), qr/Focus &lt;for&gt;|<caption>Results/, 'object ACL still protects poll contents');
    is(scalar @hits, 0, 'denied read does not count a hit');
}
@messages = ({uid => 12, userid => 3, threadid => 12, objectid => 7, tbl => 'polls', replyto => -1,
    created => '2026-10-04 12:00:00', subject => 'Original poll discussion', body => 'Existing discussion body'});
$html = page(user(3), msgstyle => 'flat', msgexpand => 2, msgorder => 'asc');
$fixtures{discussion} = $html;
like($html, qr/name="msgstyle" id="pl-entry-msgstyle".*value="flat" selected/s, 'discussion style retained');
like($html, qr/name="msgexpand" id="pl-entry-msgexpand".*value="2" selected/s, 'expansion choice retained');
like($html, qr/name="msgorder" id="pl-entry-msgorder".*value="asc" selected/s, 'order choice retained');
like($html, qr/Existing discussion body.*Next messages/s, 'message body and paging retained');
like($html, qr/name="from" value="polls"/, 'discussion forms retain poll context');
my $decorated = requestFormDecorate($html, user(3));
my ($depth, $nested, $tokens) = (0, 0, 0);
HTML::Parser->new(start_h => [sub {
    $nested++ if $_[0] eq 'form' && $depth++;
    $tokens++ if $_[0] eq 'input' && ($_[1]{name} || '') eq '_form_token';
}, 'tagname, attr'], end_h => [sub {$depth-- if $_[0] eq 'form'}, 'tagname'])->parse($decorated);
is($nested, 0, 'discussion forms do not nest');
is($depth, 0, 'discussion forms close correctly');
is($tokens, 1, 'watch mutation retains CSRF protection');
@toggles = ();
page(user(3), watch => 'toggle watches', watch_12 => 1);
is_deeply(\@toggles, [['messages', 12, 3]], 'discussion watch toggle preserved');
unlike(page(user(3), msgexpand => 0), qr/Existing discussion body/, 'collapsed discussion respected');

is(checkVote({id => 7, option => 'Docs'}, user(3)), '', 'eligible vote still accepted');
like(checkVote({id => 7}, user(3)), qr/You must select an option/, 'selection required');
like(checkVote({id => 7, option => 'Docs'}, user(-1)), qr/You must be logged in/, 'guest cannot vote');
{
    local $already_voted = 1;
    like(checkVote({id => 7, option => 'Docs'}, user(3)), qr/can't vote in this poll twice/, 'repeat-vote guard preserved');
}
@insertions = (); @scores = ();
my $voted = vote({id => 7, option => 'Docs'}, user(3));
is(scalar @insertions, 1, 'existing vote handler records one vote');
is($insertions[0]{VALUES}, "99,1,7,3,'Docs'", 'vote record retains poll, user, and choice');
is_deeply($scores[0], [3, 1], 'vote score retained');
like($voted, qr/3 people voted total\./, 'after voting the modern results show updated counts');

if (my $dir = $ENV{POLL_VIEW_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    for my $name (sort keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Poll preview', site_name => 'Physics Library', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page; close $out;
    }
}
done_testing();
