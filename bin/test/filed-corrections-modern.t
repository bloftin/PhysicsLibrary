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
    en_tbl => 'objects', cor_tbl => 'corrections', user_tbl => 'users',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec', collab_tbl => 'collab',
    news_tbl => 'news', forum_tbl => 'forums', polls_tbl => 'polls', req_tbl => 'requests',
    correction_types => {'Meta/Minor' => 1, 'Erratum' => 2},
    msgstylesel => {threaded => 'Threaded', flat => 'Flat'},
    msgordersel => {asc => 'Oldest first', desc => 'Newest first'},
    msgexpandsel => {0 => '0', 1 => '1', 2 => '2'},
);
our $record = {uid => 89, objectid => 202, userid => 1, ownerid => 2,
    title => 'Replace <all> & "objects"', username => 'Filer <One>', type => 1,
    filed => '2026-09-26 04:33:49', data => '<p>Original correction <em>text</em>.</p>'};
our @rows = map {{%$record, uid => 89 + $_, objtitle => 'Reference <frames>',
    username => 'Owner <Two>', fromid => 2, closed => $_ ? '2026-10-04 12:00:00' : undef,
    accepted => $_ == 4 ? undef : $_ == 1 ? 1 : $_ == 2 ? 0 : 2}} 0..4;
my (@queries, @messages, @seen, @toggles, @hits);
my $pager = {};
our ($failure, $deny_read) = ('', 0);
sub getConfig { $config{$_[0]} }
sub readFile { open my $in, '<', $_[0] or die $!; return do {local $/; <$in>}; }
sub dwarn { }
sub getAddr { 'feedback@example.invalid' }
sub htmlescape { requestFormEscape($_[0]) }
sub ymd { substr($_[0], 0, 10) }
sub errorMessage { $_[0] }
sub nb { defined($_[0]) && length($_[0]) }
sub TeXtoUTF8 { $_[0] }
sub stdmsg { $_[0] }
sub hasPermissionTo {
    my ($table, $id, $user, $mode) = @_;
    return !$deny_read if $mode eq 'read';
    return $user->{uid} == 3 if $mode eq 'write';
    return 0;
}
sub dbSelect {
    my ($db, $query) = @_;
    push @queries, $query;
    my @result;
    if ($query->{FROM} eq 'corrections') { @result = ({%$record}); }
    elsif ($query->{FROM} eq 'corrections,users,objects') {
        return (0, undef) if $failure eq 'detail';
        @result = ({%$record}) unless $failure eq 'missing';
    }
    elsif ($query->{FROM} eq 'corrections,objects,users') {
        my $count = $query->{WHAT} eq 'count(*) as cnt';
        return (0, undef) if $failure eq ($count ? 'count' : 'list');
        @result = $count ? ({cnt => scalar @rows}) : @rows;
    } elsif ($query->{FROM} eq 'messages') {
        @result = $query->{WHAT} eq 'count(*) as cnt' ? ({cnt => scalar @messages}) : @messages;
    } else { die "Unexpected query: $query->{FROM}"; }
    return (1, bless {rows => \@result}, 'FiledCorrectionRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub getPager { $pager = $_[0]; return '<a href="/?op='.$pager->{op}.'&amp;offset=10">Next</a>'; }
sub getownerid { 2 }
sub getfieldsbyid {
    return (title => 'Reference <frames> & motion') if $_[1] eq 'objects';
    return (uid => $_[0], username => 'Editor <'.$_[0].'>');
}
sub lookupfield { 'Filer <One>' }
sub changeWatch { }
sub hitObject { push @hits, [@_] }
sub get_lastseen { 7 }
sub get_lastmsg { 10 }
sub update_lastseen { push @seen, [@_] }
sub getWatchWidget { '<a href="/?op=getobj&amp;from=corrections&amp;id=89&amp;watch=1">Watch correction</a>' }
sub _object_exists { 1 }
sub _userfields_by_id { {username => 'Message author'} }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub nicifyTimestamp { $_[0] }
sub getreplies { '' }
sub hasWatch { 0 }
sub toggleWatch { push @toggles, [@_] }
sub hashToFormVars {
    my ($vars) = @_;
    return join '', map {'<input type="hidden" name="'.$_.'" value="'.requestFormEscape($vars->{$_}).'" />'} sort keys %$vars;
}
sub clearBox { die 'Modern corrections must not use legacy boxes'; }
sub makeBox { clearBox(@_) }
{
    package FiledCorrectionRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[0] }
    sub finish { }
}

# Load the real handlers without loading production database configuration.
for my $spec (
    ['Corrections', qw(editFiledCorrections renderCorrection getCorrectionInteract)],
    ['GetObj', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj getOwnerControls getAuthorControls)],
    ['Messages', qw(getMessages printmessage printMsgHeaderLine printMsgExpanded getWatchBox getWatchString)],
    ['Util', qw(getSelectBox)],
) {
    my ($module, @names) = @$spec;
    open my $in, '<', "$root/lib/Noosphere/$module.pm" or die $!;
    my $source = do {local $/; <$in>};
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body;
        die $@ if $@;
    }
}
my $new = Template->can('new');
{
    no warnings qw(redefine once);
    *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$root/stemplates"}) };
}
sub user {
    return {uid => $_[0], ticket => 'a' x 64, data => {active => 1, access => 0},
        prefs => {pagelength => 20, msgstyle => 'threaded', msgexpand => 1, msgorder => 'desc'}};
}
sub page {
    @queries = (); @seen = (); @hits = ();
    return getObj({op => 'getobj', from => 'corrections', id => 89, %{$_[1] || {}}}, user($_[0]));
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {
        push @links, URI->new($_[1]->{href}) if $_[0] eq 'a' && defined $_[1]->{href};
    }, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub query { return {$_[0]->query_form}; }
sub action {
    my ($html, $op) = @_;
    return grep { (query($_)->{op} || '') eq $op } links($html);
}

for my $uid (-1, 0) {
    like(editFiledCorrections({}, user($uid)), qr/Must be logged in/, 'filed list requires a signed-in user');
    is(scalar @queries, 0, 'guest does not query private corrections');
}
my $list = editFiledCorrections({}, user(1));
like($list, qr/<h1[^>]*>Corrections You&#39;ve Filed<\/h1>/, 'filed list uses compact shared heading');
like($list, qr/5 corrections you've filed/, 'filed total displayed');
for my $i (0, 1) {
    like($queries[$i]->{WHERE}, qr/^corrections.userid=1 and objects.uid=corrections.objectid and users.uid=objects.userid$/, 'query stays filer-scoped and joins the recipient');
}
is($queries[1]->{LIMIT}, 10, 'half the user page-length preference retained');
ok(exists $queries[1]->{DESC}, 'newest-first default retained');
for my $status (qw(Pending Accepted Rejected Retracted Closed)) {
    like($list, qr/>$status<\/span>/, "$status has an explicit label");
}
like($list, qr/Replace &lt;all&gt; &amp; &quot;objects&quot;/, 'correction title escaped');
like($list, qr/Reference &lt;frames&gt;/, 'parent title escaped');
like($list, qr/Filed 2026-09-26 to .*id=2.*Owner &lt;Two&gt;/, 'recipient and filed date preserved and escaped');
my @retract = action($list, 'retractcor');
is(scalar @retract, 1, 'only pending filed corrections can be retracted');
is_deeply(query($retract[0]), {op => 'retractcor', id => 202, correct => 89, continue => 'editfiledcors'}, 'list retraction retains the continuation and correction context');
is(scalar(action($list, 'rejectcor')), 0, 'filed list does not expose owner actions');
editFiledCorrections({total => 5, offset => 10, asc => 1}, user(1));
ok(exists $queries[-1]->{ASC}, 'oldest-first request retained');
is($queries[-1]->{OFFSET}, 10, 'list offset retained');
is_deeply($pager, {op => 'editfiledcors', total => 5, offset => 10, asc => 1}, 'pager keeps route and ordering');
my $empty;
{
    local @rows = ();
    $empty = editFiledCorrections({}, user(1));
    like($empty, qr/No filed corrections/, 'empty filed list remains readable');
    like($empty, qr/0 corrections you've filed/, 'empty total remains zero');
}
for my $kind ('count', 'list') {
    local $failure = $kind;
    like(editFiledCorrections({}, user(1)), qr/Error with query/, "$kind failure reports a readable error");
}
for my $spec (['detail', qr/Error with query/], ['missing', qr/Couldn't find that record/]) {
    local $failure = $spec->[0];
    like(renderCorrection({id => 89}, user(1)), $spec->[1], 'detail lookup failure stays readable');
}
{
    no warnings 'redefine';
    local *makeBox = sub { return $_[0].': '.$_[1]; };
    like(getCorrectionInteract($record), qr/Interact:.*op=correct.*op=postmsg/s, 'legacy interaction callers retain their original wrapper');
}

my %pages;
for my $uid (-1, 1, 2, 3, 4) {
    my $html = $pages{$uid} = page($uid);
    like($html, qr/Viewing Correction to &#39;Reference &lt;frames&gt; &amp; motion&#39;/, 'parent heading escaped');
    like($html, qr/Replace &lt;all&gt; &amp; &quot;objects&quot;/, 'detail title escaped');
    like($html, qr/Filer &lt;One&gt;/, 'filer escaped');
    like($html, qr/Original correction <em>text<\/em>/, 'existing correction formatting retained');
    like($html, qr/Meta\/Minor/, 'type label retained');
    like($html, qr/<h2>Discussion<\/h2>.*No messages.*<h2>Interact<\/h2>/s, 'modern discussion and interaction sections include empty state');
    like($html, qr/Watch correction/, 'common watch widget retained');
    unlike($html, qr/<center|<h2>(Owner|Author) Controls/, 'detail does not expose generic ownership actions or legacy boxes');
    is(scalar(action($html, 'retractcor')), $uid == 1 ? 1 : 0, 'retraction visible only to filer');
    is(scalar(action($html, 'rejectcor')), $uid == 2 || $uid == 3 ? 1 : 0, 'rejection visible only to parent owner or writer');
    is(scalar(action($html, 'sendobj')), $uid == 2 ? 1 : 0, 'transfer visible only to parent owner');
    is_deeply($seen[0], ['corrections', 89, $uid, 10], 'discussion read tracking preserved');
    is_deeply($hits[0], [89, 'corrections', 'hits'], 'correction hit tracking preserved');
    my ($correct) = action($html, 'correct');
    is_deeply(query($correct), {op => 'correct', from => 'objects', id => 202}, 'new correction targets parent article');
    my ($post) = action($html, 'postmsg');
    is_deeply(query($post), {op => 'postmsg', from => 'corrections', id => 89}, 'post message targets this correction');
}
my ($resolve) = action($pages{2}, 'edit');
is_deeply(query($resolve), {op => 'edit', from => 'objects', id => 202, correct => 89}, 'resolve action edits parent and closes the right correction');
my ($transfer) = action($pages{2}, 'sendobj');
is_deeply(query($transfer), {op => 'sendobj', from => 'objects', id => 202, user => 2, touser => 1}, 'transfer retains owner and filer');
my ($detail_retract) = action($pages{1}, 'retractcor');
is_deeply(query($detail_retract), {op => 'retractcor', id => 202, correct => 89, continue => 'viewcor'}, 'detail retraction returns to correction');
my $closed;
for my $spec ([1, 0, 'object owner', 2], [0, 5, 'former object owner', 5], [2, 0, 'correction filer', 1]) {
    local $record = {%$record, closed => '2026-10-04 12:00:00', accepted => $spec->[0], closedbyid => $spec->[1], comment => '<p>Closing <strong>comment</strong>.</p>'};
    $closed = page(2);
    like($closed, qr/Comment from \Q$spec->[2]\E .*id=$spec->[3].*Editor &lt;$spec->[3]&gt;/, 'closing comment attributed to the right person');
    like($closed, qr/Closing <strong>comment<\/strong>/, 'closing comment formatting retained');
    is(scalar(action($closed, 'rejectcor')), 0, 'closed correction has no resolution actions');
    is(scalar(action($closed, 'retractcor')), 0, 'closed correction has no retract action');
    local $record->{comment} = '';
    like(page(2), qr/No comment from \Q$spec->[2]\E/, 'explicit empty closing comment retained');
}
{
    local $deny_read = 1;
    like(page(1), qr/don't have permission/, 'detail read ACL enforced before rendering');
    is(scalar @queries, 1, 'denied reader does not query detail or discussion');
}
@messages = ({uid => 10, userid => 7, threadid => 10, objectid => 89, tbl => 'corrections',
    replyto => -1, created => '2026-10-04 12:00:00', subject => 'Discussion subject',
    body => '<p>Existing discussion message</p>'});
my $discussion = page(1, {msgstyle => 'flat', msgexpand => 2, msgorder => 'asc'});
like($discussion, qr/class="pl-entry-discussion-options" method="get"/, 'display options use a separate GET form');
for my $field (['msgstyle', 'flat'], ['msgexpand', 2], ['msgorder', 'asc']) {
    like($discussion, qr/name="$field->[0]".*value="$field->[1]" selected/s, 'discussion display preference retained');
}
like($discussion, qr/name="from" value="corrections"/, 'discussion options retain correction table');
like($discussion, qr/name="id" value="89"/, 'discussion options retain correction id');
like($discussion, qr/Existing discussion message.*Next/s, 'message text and pagination retained');
my $decorated = requestFormDecorate($discussion, user(1));
my ($depth, $nested, $tokens) = (0, 0, 0);
HTML::Parser->new(start_h => [sub {
    my ($tag, $attrs) = @_;
    $nested++ if $tag eq 'form' && $depth++;
    $tokens++ if $tag eq 'input' && ($attrs->{name} || '') eq '_form_token' && $depth;
}, 'tagname, attr'], end_h => [sub {$depth-- if $_[0] eq 'form'}, 'tagname'])->parse($decorated);
is($nested, 0, 'discussion forms do not nest');
is($depth, 0, 'discussion forms are balanced');
is($tokens, 1, 'only watch mutation form receives the CSRF token');
page(1, {watch => 'toggle watches', watch_10 => 1});
is_deeply(\@toggles, [['messages', 10, 1]], 'watch toggles remain scoped to discussion message');
unlike(page(1, {msgexpand => 0}), qr/Existing discussion message/, 'collapsed discussion stays collapsed');

if (my $dir = $ENV{FILED_CORRECTIONS_TEST_DIR}) {
    my $tt = Template->new;
    my ($menu, $sidebar) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body">My Articles</div></section>', features => $menu}, \$sidebar) or die $tt->error;
    my $stress;
    {
        local $record = {%$record, title => 'LongCorrectionTitle' x 12,
            data => '<p>'.('LongContentWord' x 30).'</p><table style="width:1400px"><tr><td>Wide correction table</td></tr></table>'};
        local $messages[0]->{body} = '<table style="width:1400px"><tr><td>Wide discussion table</td></tr></table>';
        $stress = page(2, {msgstyle => 'flat', msgexpand => 2});
    }
    for my $case (['filed', $list], ['empty', $empty], ['pending', $pages{2}], ['closed', $closed], ['discussion', $discussion], ['stress', $stress]) {
        my $html = '';
        $tt->process('view.tt', {title => 'Corrections preview', site_name => 'Physics Library', sidebar => $sidebar,
            content => $case->[1], header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$html) or die $tt->error;
        open my $out, '>', "$dir/$case->[0].html" or die $!;
        print {$out} $html;
        close $out;
    }
}
done_testing();
