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
    template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    stemplate_path => "$root/stemplates", siteaddrs => {}, template_cmd_prefix => 'NS',
    en_tbl => 'objects', cor_tbl => 'corrections', user_tbl => 'users',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec',
    collab_tbl => 'collab', news_tbl => 'news', forum_tbl => 'forums',
    polls_tbl => 'polls', req_tbl => 'requests', access_admin => 100,
    classification_supported => 1,
    msgstylesel => {threaded => 'Threaded', flat => 'Flat'},
    msgordersel => {asc => 'Oldest first', desc => 'Newest first'},
    msgexpandsel => {0 => '0', 1 => '1', 2 => '2'},
);
my $record = {uid => 209, userid => 2, type => 3, name => 'Vector"&Triple', title => 'Vector <Triple> & Product'};
my @errata;
my @messages;
my @queries;
my @seen;
my @toggles;
my $class_calls = 0;
sub getConfig { $config{$_[0]} }
sub readFile { open my $in, '<', $_[0] or die $!; return do { local $/; <$in> }; }
sub dwarn { }
sub getAddr { 'feedback@example.invalid' }
sub THEOREM { 3 }
sub CONJECTURE { 2 }
sub DEFINITION { 1 }
sub urlescape { URI::Escape::uri_escape_utf8($_[0]) }
sub classstring { $class_calls++; return 'pacs:01.30.Xx,pacs:42.25.Fx'; }
sub htmlescape { requestFormEscape($_[0]) }
sub humanReadableCmp { $_[0] cmp $_[1] }
sub hasPermissionTo {
    my ($table, $id, $user, $mode) = @_;
    return 1 if $mode eq 'read';
    return $user->{uid} == 5 || $user->{uid} == 6 if $mode eq 'write';
    return $user->{uid} == 6 if $mode eq 'acl';
    return 0;
}
sub dbSelect {
    my ($db, $query) = @_;
    push @queries, $query;
    my @rows = $query->{FROM} eq 'objects' || $query->{FROM} eq 'papers' ? ({%$record}) :
        $query->{WHAT} eq 'count(*) as cnt' ? ({cnt => scalar @errata}) :
        $query->{FROM} eq 'messages' ? @messages : @errata;
    return (1, bless {rows => \@rows}, 'EntryInteractionRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub _object_exists { 1 }
sub _userfields_by_id { {username => 'Message author'} }
sub nicifyTimestamp { $_[0] }
sub stdmsg { $_[0] }
sub getreplies { '' }
sub hasWatch { 0 }
sub hashToFormVars {
    my ($vars) = @_;
    return join '', map {'<input type="hidden" name="'.$_.'" value="'.requestFormEscape($vars->{$_}).'" />'} sort keys %$vars;
}
sub getPager { '<a href="/?op=getobj&amp;from=objects&amp;id=209&amp;offset=10">Next messages</a>' }
sub get_lastseen { 7 }
sub get_lastmsg { 10 }
sub update_lastseen { push @seen, [@_] }
sub toggleWatch { push @toggles, [@_] }
sub getWatchWidget { '<a href="/?op=getobj&amp;from=objects&amp;id=209&amp;watch=1">Watch entry</a>' }
sub lookupfield { 'Entry owner' }
sub nb { defined($_[0]) && length($_[0]) }
sub TeXtoUTF8 { $_[0] }
sub changeWatch { }
sub hitObject { }
sub renderEncyclopediaObj {
    return mathBox('<div class="pl-article-heading"><h1 class="pl-article-title">Vector triple product</h1><span class="pl-article-type">(Theorem)</span></div>',
        '<section id="original-article"><p>Original article and mathematical tables.</p></section>');
}
sub renderGeneric { '<p>Generic library item</p>' }
sub getGenericAdmin { '' }
sub errorMessage { $_[0] }
sub clearBox { '<table class="legacy-box"><tr><td>'.$_[0].'</td></tr><tr><td>'.$_[1].'</td></tr></table>' }
sub makeBox { clearBox(@_) }
sub adminBox { clearBox(@_) }
{
    package EntryInteractionRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[0] }
    sub finish { }
}
for my $spec (
    ['GetObj', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj getOwnerControls getAuthorControls getEncyclopediaInteract)],
    ['Admin', qw(getEncyclopediaAdminControls)],
    ['Messages', qw(getMessages printmessage printMsgHeaderLine printMsgExpanded getWatchBox getWatchString)],
    ['Corrections', qw(getPendingCorrections totalCorrections)],
    ['Util', qw(getSelectBox)],
    ['Layout', qw(mathBox)],
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
my $new = Template->can('new');
{
    no warnings qw(redefine once);
    *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$root/stemplates"}) };
}
sub user {
    my ($uid, $access) = @_;
    return {uid => $uid, ticket => 'a' x 64, data => {active => 1, access => $access || 0},
        prefs => {pagelength => 20, msgstyle => 'threaded', msgexpand => 1, msgorder => 'desc'}};
}
sub page {
    my ($user, $params) = @_;
    @queries = (); @seen = (); $class_calls = 0;
    return getObj({op => 'getobj', from => 'objects', id => 209, %{$params || {}}}, $user);
}
sub links {
    my ($html) = @_;
    my @links;
    HTML::Parser->new(start_h => [sub {
        my ($tag, $attrs) = @_;
        push @links, URI->new($attrs->{href}) if $tag eq 'a' && defined $attrs->{href};
    }, 'tagname, attr'])->parse($html);
    return @links;
}
sub query { return {$_[0]->query_form}; }
my $admin = page(user(1, 100), {method => 'make4ht'});
for my $title ('Admin Controls', 'Pending Errata and Addenda', 'Discussion', 'Interact') {
    like($admin, qr/<h2>\Q$title\E<\/h2>/, "$title has a compact semantic section heading");
}
like($admin, qr/class="pl-entry-section pl-entry-section-admin"/, 'admin section keeps a distinct red style');
like($admin, qr/None\..*No messages\./s, 'empty errata and discussion states remain');
like($admin, qr/id="original-article"/, 'article content is retained outside the interaction sections');
unlike($admin, qr/<center|class="legacy-box"/, 'article action boxes no longer use centered legacy tables');
is(scalar @queries, 5, 'object, message and correction lookups are not duplicated');
is($class_calls, 1, 'attachment classification is fetched only once');
is_deeply($seen[0], ['objects', 209, 1, 10], 'reading discussion still updates last-seen state');
my @links = links($admin);
for my $op (qw(rerender adminedit linkpolicy adminclassify delobj postmsg correct updatereq adden)) {
    ok((scalar grep { (query($_)->{op} || '') eq $op } @links), "existing $op action retained");
}
my ($rerender) = grep { query($_)->{op} eq 'rerender' } @links;
is_deeply({$rerender->query_form}, {op => 'rerender', from => 'objects', id => 209, method => 'make4ht'},
    'admin rerender retains the selected method');
my ($delete) = grep { query($_)->{op} eq 'delobj' } @links;
is(query($delete)->{ask}, 'yes', 'delete retains its confirmation step');
my ($request) = grep { query($_)->{op} eq 'updatereq' } @links;
is(query($request)->{identifier}, $record->{name}, 'special characters in article identifiers survive encoding');
for my $link (grep { query($_)->{op} eq 'adden' } @links) {
    my %params = $link->query_form;
    is($params{class}, 'pacs:01.30.Xx,pacs:42.25.Fx', 'attachment classifications are encoded once');
    is($params{parent}, $record->{name}, 'attachment parent is retained');
    like($params{title}, qr/\Q$record->{title}\E/, 'attachment title remains intact');
}
for my $uid (-1, 3, 5, 6) {
    my $html = page(user($uid));
    unlike($html, qr/<h2>Admin Controls/, "non-admin $uid has no admin controls");
    unlike($html, qr/op=adminedit|op=adminclassify/, "non-admin $uid receives no admin edit URLs");
    like($html, qr/<h2>Discussion.*<h2>Interact/s, 'ordinary visitors keep discussion and interaction');
    if ($uid == 5 || $uid == 6) {
        like($html, qr/<h2>Author Controls/, 'writers get author actions');
        my $acl = grep { query($_)->{op} eq 'acledit' } links($html);
        is($acl, $uid == 6 ? 1 : 0, 'ACL action respects its separate permission');
    } else {
        unlike($html, qr/<h2>Author Controls|<h2>Owner Controls/, 'reader has no ownership actions');
    }
}
my $owner = page(user(2));
like($owner, qr/<h2>Owner Controls/, 'owners get the matching modern controls');
like(page(user(2,100)), qr/<h2>Admin Controls.*<h2>Owner Controls/s,
    'an administrator who owns the article keeps both control sections');
unlike(page(user(1,99)), qr/<h2>Admin Controls/, 'administrator threshold is preserved');
for my $op (qw(edit rerender linkpolicy acledit creategroup transfer delobj abandon)) {
    ok((scalar grep { (query($_)->{op} || '') eq $op } links($owner)), "owner $op action retained");
}
{
    local $config{classification_supported} = 0;
    unlike(page(user(1,100)), qr/op=adminclassify/, 'classification toggle still controls admin link visibility');
}
for my $spec ([1, ['Derivation', 'Example']], [2, ['Proof', 'Result', 'Corollary', 'Example']], [3, ['Proof', 'Result', 'Corollary', 'Example']], [4, ['Example']]) {
    local $record->{type} = $spec->[0];
    my @types = map { query($_)->{type} || () } grep { query($_)->{op} eq 'adden' } links(page(user(3)));
    is_deeply(\@types, $spec->[1], "attachment actions match article type $spec->[0]");
}
@errata = ({uid => 90, userid => 7, title => 'Fix <script> & "formula"', username => '<Editor>', filed => '2026-10-03 12:00:00'});
@messages = ({uid => 10, userid => 7, threadid => 10, objectid => 209,
    tbl => 'objects', replyto => -1, created => '2026-10-03 12:00:00',
    subject => 'Discussion subject', body => '<p>Existing discussion message</p>'});
my $populated = page(user(2), {msgstyle => 'flat', msgexpand => 2, msgorder => 'asc'});
like($populated, qr/Fix &lt;script&gt; &amp; &quot;formula&quot;/, 'erratum titles are safely escaped');
like($populated, qr/&lt;Editor&gt;/, 'erratum author names are escaped');
like($populated, qr/op=getobj&amp;from=corrections&amp;id=90/, 'correction detail link preserved');
like($populated, qr/op=getcors&amp;id=209.*View all 1/s, 'all-corrections link and total preserved');
like($populated, qr/<label for="pl-entry-msgstyle">Style<\/label> <select name="msgstyle" id="pl-entry-msgstyle">.*value="flat" selected/s, 'discussion style control retains its selection and accessible label');
like($populated, qr/<label for="pl-entry-msgexpand">Expand<\/label> <select name="msgexpand" id="pl-entry-msgexpand">.*value="2" selected/s, 'expand selection retained');
like($populated, qr/<label for="pl-entry-msgorder">Order<\/label> <select name="msgorder" id="pl-entry-msgorder">.*value="asc" selected/s, 'order selection retained');
like($populated, qr/class="pl-entry-discussion-options" method="get" action="\/"/, 'display options remain a read-only GET form');
like($populated, qr/Existing discussion message.*Next messages/s, 'message body and pager retained');
like($populated, qr/<form method="post".*name="watch_10".*name="watch" value="toggle watches".*<\/form>/s, 'watch form preserves checkbox names and POST action');
my $decorated = requestFormDecorate($populated, user(2));
like($decorated, qr/name="_form_token"/, 'watch submission keeps response-time CSRF protection');
my ($form_depth, $nested_forms, $post_tokens) = (0, 0, 0);
HTML::Parser->new(
    start_h => [sub {
        my ($tag, $attrs) = @_;
        $nested_forms++ if $tag eq 'form' && $form_depth++;
        $post_tokens++ if $tag eq 'input' && ($attrs->{name} || '') eq '_form_token' && $form_depth;
    }, 'tagname, attr'],
    end_h => [sub { $form_depth-- if $_[0] eq 'form'; }, 'tagname'],
)->parse($decorated);
is($nested_forms, 0, 'forms do not nest inside discussion markup');
is($form_depth, 0, 'discussion forms have balanced closing tags');
is($post_tokens, 1, 'only the mutation form receives a CSRF token');
@toggles = ();
page(user(2), {watch => 'toggle watches', watch_10 => 1});
is_deeply(\@toggles, [['messages', 10, 2]], 'watch submission still toggles the selected thread for the reader');
my $collapsed = page(user(2), {msgexpand => 0});
like($collapsed, qr/Discussion subject/, 'collapsed discussion preserves its message links');
unlike($collapsed, qr/Existing discussion message/, 'collapsed discussion does not expand message bodies');
my $legacy = getEncyclopediaAdminControls(user(1,100), 'objects', 209, 'make4ht');
like($legacy, qr/class="legacy-box"/, 'legacy callers keep their original wrapper');
like(getPendingCorrections(209), qr/1\. <a/, 'legacy corrections list stays unchanged');
my $generic = page(user(3), {from => 'papers'});
unlike($generic, qr/pl-entry-section-header|pl-entry-discussion-options/, 'generic library pages are unaffected');

# Render representative full-page fixtures without a renderer or database for browser QA.
if (my $dir = $ENV{ENTRY_INTERACTIONS_TEST_DIR}) {
    my $tt = Template->new;
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>',
        features => $menu,
    }, \$sidebar) or die $tt->error;
    for my $case (['admin', $admin], ['owner', $owner], ['populated', $populated], ['reader', page(user(-1))]) {
        my $html = '';
        $tt->process('view.tt', {
            title => 'Entry interaction preview', site_name => 'Physics Library', sidebar => $sidebar,
            content => $case->[1],
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>',
        }, \$html) or die $tt->error;
        open my $out, '>', "$dir/$case->[0].html" or die $!;
        print {$out} $html;
        close $out;
    }
}

done_testing();
