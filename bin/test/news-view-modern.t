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

our ($dbh, $reader, $NoosphereCanonical, $NoosphereTitle);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
    main_url => 'https://physicslibrary.org', siteaddrs => {}, template_cmd_prefix => 'NS',
    bug_url => 'https://example.invalid/issues',
    news_tbl => 'news', en_tbl => 'objects', cor_tbl => 'corrections', user_tbl => 'users',
    collab_tbl => 'collab', forum_tbl => 'forums', polls_tbl => 'polls', req_tbl => 'requests',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec',
    msgstylesel => {threaded => 'Threaded', flat => 'Flat'},
    msgordersel => {asc => 'Oldest first', desc => 'Newest first'},
    msgexpandsel => {0 => '0', 1 => '1', 2 => '2'},
);
my $record = {uid => 10, userid => 1, title => 'Community <News> & Updates',
    created => '2009-01-25 15:21:16',
    intro => '<p>Original <strong>news introduction</strong>.</p>',
    body => '<p>Original news body with <a href="https://example.invalid/report">the original report link</a>.</p>'};
my (@messages, @queries, @seen, @toggles, @hits);
our ($query_ok, $read_allowed) = (1, 1);
sub getConfig { $config{$_[0]} }
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub htmlescape { requestFormEscape($_[0]) }
sub dwarn { }
sub getAddr { 'feedback@example.invalid' }
sub nb { defined($_[0]) && length($_[0]) }
sub TeXtoUTF8 { $_[0] }
sub hasPermissionTo { $_[3] eq 'read' ? $read_allowed : $_[2]->{uid} == 2 }
sub lookupfield { '<News editor> & Contributor' }
sub changeWatch { }
sub hitObject { push @hits, [@_] }
sub get_lastseen { 7 }
sub get_lastmsg { 12 }
sub update_lastseen { push @seen, [@_] }
sub getWatchWidget { '<a href="#existing-hidden-widget">Watch entry</a>' }
sub toggleWatch { push @toggles, [@_] }
sub hasWatch { 0 }
sub _object_exists { 1 }
sub _userfields_by_id { {username => 'Comment author'} }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub nicifyTimestamp { $_[0] }
sub stdmsg { $_[0] }
sub getreplies { '' }
sub errorMessage { $_[0] }
sub clearBox { die 'news used a legacy box'; }
sub makeBox { die 'news used a legacy box'; }
sub getPager { '<a href="/?op=getobj&amp;from=news&amp;id=10&amp;offset=10">Next messages</a>' }
sub hashToFormVars {
    my $vars = shift;
    return join '', map {'<input type="hidden" name="'.$_.'" value="'.requestFormEscape($vars->{$_}).'" />'} sort keys %$vars;
}
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    my @rows = $q->{FROM} eq 'news' ? ({%$record}) : @messages;
    return ($query_ok, bless {rows => \@rows}, 'NewsViewRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
{
    package NewsViewRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[0] }
    sub finish { }
}
for my $spec (
    ['GetObj', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj renderNews getNewsInteract getOwnerControls getAuthorControls)],
    ['News', qw(formatnewsitem_full)],
    ['Messages', qw(getMessages printmessage printMsgHeaderLine printMsgExpanded getWatchBox getWatchString)],
    ['Util', qw(getSelectBox)],
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
my $template_new = Template->can('new');
{
    no warnings qw(redefine once);
    *Template::new = sub { $template_new->($_[0], {INCLUDE_PATH => "$root/stemplates"}) };
}
sub user {
    return {uid => $_[0], ticket => 'a' x 64, data => {active => 1, access => $_[1] || 0},
        prefs => {pagelength => 20, msgstyle => 'threaded', msgexpand => 1, msgorder => 'desc'}};
}
sub page {
    my ($user, $params) = @_;
    @queries = (); @seen = (); @hits = ();
    return getObj({op => 'getobj', from => 'news', id => 10, %{$params || {}}}, $user);
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {
        push @links, URI->new($_[1]->{href}) if $_[0] eq 'a' && defined $_[1]->{href};
    }, 'tagname, attr'])->parse($_[0]);
    return @links;
}
my %fixtures;
my $html = page(user(-1));
$fixtures{reader} = $html;
like($html, qr/<header class="pl-modern-box-header"><h1>Community &lt;News&gt; &amp; Updates<\/h1><\/header>/, 'headline uses shared compact blue header and escapes text');
is(scalar(() = $html =~ /<h1\b/g), 1, 'only one generated story headline');
like($html, qr/posted by <a href="https:\/\/physicslibrary.org\/\?op=getuser&amp;id=1">&lt;News editor&gt; &amp; Contributor<\/a> on 2009-01-25 15:21:16/, 'byline, author profile link and original timestamp preserved safely');
like($html, qr/\Q$record->{intro}\E/, 'introduction HTML retained unchanged');
like($html, qr/\Q$record->{body}\E/, 'body HTML and original links retained unchanged');
for my $title ('Discussion', 'Interact') {
    like($html, qr/<h2>\Q$title\E<\/h2>/, "$title uses modern interaction section");
}
like($html, qr/No messages\./, 'empty discussion still readable');
unlike($html, qr/<center|<NS:template|newsbox\.html|newsobj\.html/, 'modern news route has no legacy wrappers/placeholders');
unlike($html, qr/Owner Controls|Author Controls|Admin Controls|existing-hidden-widget/, 'no additional controls that legacy news did not display');
my ($post) = grep { my %q = $_->query_form; ($q{op} || '') eq 'postmsg' } links($html);
ok($post, 'post action retained');
is_deeply({$post->query_form}, {op => 'postmsg', from => 'news', id => 10}, 'post action targets same news item');
is_deeply($seen[0], ['news', 10, -1, 12], 'reading preserves news discussion last-seen update');
is_deeply($hits[0], [10, 'news', 'hits'], 'reading preserves news hit counter');
is($NoosphereCanonical, '', 'news does not accidentally acquire an encyclopedia canonical URL');
is(scalar @queries, 3, 'no additional object/discussion database queries');
like($queries[1]->{WHERE}, qr/objectid = 10 and tbl='news'/, 'discussion remains scoped to news object');
for my $uid (1, 2, 3) {
    my $signed = page(user($uid, 100));
    like($signed, qr/<h2>Interact<\/h2>/, "signed-in reader $uid keeps post action");
    unlike($signed, qr/Owner Controls|Author Controls|Admin Controls|existing-hidden-widget/, 'no new visible privileged or watch-entry actions');
}
for my $body (undef, '', 'null') {
    local $record->{body} = $body;
    my $short = page(user(-1));
    like($short, qr/\Q$record->{intro}\E/, 'intro-only story retained');
    unlike($short, qr/class="pl-news-body"/, 'missing or SQL-null-text body has no empty placeholder');
    $fixtures{'intro-only'} = $short;
}
{
    local $record->{userid} = -1;
    like(page(user(-1)), qr/>nobody<\/a>/, 'unowned news attribution unchanged');
}
{
    local $record->{title} = 'AVeryLongUnbrokenNewsHeadline' x 12;
    local $record->{body} = '<p>'.('LongUnbrokenBodyText' x 40).'</p><table style="width:900px"><tr><td>Original wide table</td></tr></table>';
    $fixtures{long} = page(user(-1));
}
@messages = ({uid => 12, userid => 3, threadid => 12, objectid => 10, tbl => 'news',
    replyto => -1, created => '2026-10-04 12:00:00', subject => 'Original discussion subject',
    body => '<p>Original discussion body</p>'});
$html = page(user(1), {msgstyle => 'flat', msgexpand => 2, msgorder => 'asc'});
$fixtures{discussion} = $html;
like($html, qr/name="msgstyle" id="pl-entry-msgstyle".*value="flat" selected/s, 'selected discussion style retained');
like($html, qr/name="msgexpand" id="pl-entry-msgexpand".*value="2" selected/s, 'selected expansion retained');
like($html, qr/name="msgorder" id="pl-entry-msgorder".*value="asc" selected/s, 'selected ordering retained');
like($html, qr/Original discussion body.*Next messages/s, 'original message HTML and pager retained');
like($html, qr/name="from" value="news"/, 'discussion options and watch submit stay on news route');
like($html, qr/<form method="post".*name="watch_12".*name="watch" value="toggle watches"/s, 'watch form and existing mutation fields retained');
my $decorated = requestFormDecorate($html, user(1));
my ($depth, $nested, $tokens) = (0, 0, 0);
HTML::Parser->new(
    start_h => [sub {
        my ($tag, $attrs) = @_;
        $nested++ if $tag eq 'form' && $depth++;
        $tokens++ if $tag eq 'input' && ($attrs->{name} || '') eq '_form_token' && $depth;
    }, 'tagname, attr'],
    end_h => [sub { $depth-- if $_[0] eq 'form'; }, 'tagname'],
)->parse($decorated);
is($nested, 0, 'discussion forms do not nest');
is($depth, 0, 'discussion forms close correctly');
is($tokens, 1, 'only mutation form gets response-time CSRF protection');
@toggles = ();
page(user(1), {watch => 'toggle watches', watch_12 => 1});
is_deeply(\@toggles, [['messages', 12, 1]], 'selected news discussion watch still toggles');
my $collapsed = page(user(1), {msgexpand => 0});
like($collapsed, qr/Original discussion subject/, 'collapsed discussion links preserved');
unlike($collapsed, qr/Original discussion body/, 'collapsed preference respected');
{
    local $read_allowed = 0;
    @hits = ();
    like(page(user(-1)), qr/don't have permission/, 'object read permission still enforced');
    is(scalar @hits, 0, 'denied reads do not hit or render news');
}
{
    local $query_ok = 0;
    like(page(user(-1)), qr/Object not found/, 'missing news still uses existing error');
}
like(getNewsInteract($record), qr/<center>.*op=postmsg/s, 'legacy interaction callers remain compatible');

if (my $dir = $ENV{NEWS_VIEW_TEST_DIR}) {
    my $tt = Template->new;
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu}, \$sidebar) or die $tt->error;
    for my $name (sort keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'News preview', site_name => 'Physics Library', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page;
        close $out;
    }
}
done_testing();
