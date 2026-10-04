#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use URI;
use HTML::Parser;
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;

our ($dbh, $reader);
our ($success, $missing, $allowed, $watched, $reply_failure) = (1, 0, 1, 0, 0);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    acl_tables => {objects => 1, collab => 1},
    message_maxcols => 80,
);
my %records = (
    395 => {uid => 395, threadid => 395, replyto => -1, tbl => 'forums', objectid => 0,
        userid => 1, subject => 'Physics <Library> & "tips"', created => '2025-03-04 05:31:13',
        body => "Original message.\n\\begin{figure}[h]\n<script>alert(1)</script>\nhttp://example.invalid/notes"},
    396 => {uid => 396, threadid => 395, replyto => 395, tbl => 'forums', objectid => 0,
        userid => 2, subject => 'Reply <One> & notes', created => '2025-03-04 06:31:13', body => 'First reply body'},
    397 => {uid => 397, threadid => 395, replyto => 395, tbl => 'forums', objectid => 0,
        userid => 3, subject => 'Reply two', created => '2025-03-04 07:31:13', body => 'Second reply body'},
    398 => {uid => 398, threadid => 395, replyto => 396, tbl => 'forums', objectid => 0,
        userid => 3, subject => 'Nested reply', created => '2025-03-04 06:45:13', body => 'Nested reply body'},
);
my (@queries, @authors, @permissions, @watch_changes, @watch_reads);
my $finished;
my (@spelling, @submissions, @visibility);
sub checkdoc { push @spelling, $_[0]; return '<a class="spell" href="/?op=checkword&amp;word=typo">typo</a>'; }
sub hasVisibleMessages { push @visibility, [@_]; return 0; }
sub submit_message { push @submissions, [@_]; return 'Posted by existing submission handler'; }
sub postError { $_[0] }
sub getConfig { $config{$_[0]} }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub htmlescape { requestFormEscape($_[0]) }
sub errorMessage { $_[0] }
sub nicifyTimestamp { $_[0] }
sub hasPermissionTo { push @permissions, [@_]; return $allowed; }
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    return (0, undef) unless $success;
    my @rows;
    if ($q->{WHERE} =~ /^uid = (\d+)$/) {
        @rows = ({%{$records{$1}}}) if !$missing && $records{$1};
    } elsif ($q->{WHERE} =~ /^replyto = (\d+)$/) {
        return (0, undef) if $reply_failure;
        my $parent = $1;
        @rows = map { {%$_} } sort { $a->{created} cmp $b->{created} }
            grep { $_->{replyto} == $parent } values %records;
    } else { die "Unexpected query $q->{WHERE}"; }
    return (1, bless {rows => \@rows, pos => 0}, 'MessageViewRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub _userfields_by_id { push @authors, [@_]; return {username => 'User <'.$_[0].'> & Editor'}; }
sub hasWatch { push @watch_reads, [@_]; return $watched; }
sub addWatch { push @watch_changes, ['add', @_]; $watched = 1; }
sub delWatchByInfo { push @watch_changes, ['remove', @_]; $watched = 0; }
sub hashToFormVars {
    my ($params, $exclude) = @_;
    my %exclude = map { $_ => 1 } @$exclude;
    return join '', map { '<input type="hidden" name="'.$_.'" value="'.requestFormEscape($params->{$_}).'" />' }
        grep { !$exclude{$_} } sort keys %$params;
}
{
    package MessageViewRows;
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub finish { $finished++; }
}
for my $spec (
    ['Messages', qw(getMessage getreplies _r_getmessages getWatchString printMsgHeaderLine getWatchBox postMessage getPostForm getquoted wordsplit)],
    ['Watches', qw(validWatchObjectArgs validWatchUserId changeWatch getWatchWidget)],
    ['Util', qw(stdmsg tohtmlascii)],
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
    return {uid => $_[0], ticket => 'a' x 64, data => {active => 1}};
}
sub page {
    my ($user, @params) = @_;
    @queries = (); @authors = (); @permissions = (); @watch_changes = (); @watch_reads = (); $finished = 0;
    return getMessage({op => 'getmsg', id => 395, @params}, $user);
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {
        my ($tag, $attr) = @_;
        push @links, [$attr->{href}, ''] if $tag eq 'a';
    }, 'tagname, attr'], text_h => [sub { $links[-1][1] .= $_[0] if @links; }, 'dtext'])->parse($_[0]);
    return map { URI->new($_->[0]) } @links;
}
sub query { return {$_[0]->query_form}; }
my $guest = page(user(-1));
like($guest, qr/<header class="pl-modern-box-header"><h1>Viewing Message<\/h1><\/header>/, 'message uses the compact shared blue header');
like($guest, qr/<h2 class="pl-message-subject">Physics &lt;Library&gt; &amp; &quot;tips&quot;<\/h2>/, 'subject remains visible and safely escaped');
like($guest, qr/User &lt;1&gt; &amp; Editor/, 'author name escaped');
like($guest, qr/2025-03-04 05:31:13/, 'original message date retained');
like($guest, qr/Original message\.<br \/>/, 'original message formatting retained');
like($guest, qr/\\begin\{figure\}\[h\]/, 'LaTeX source text retained');
like($guest, qr/&lt;script&gt;alert\(1\)&lt;\/script&gt;/, 'body still uses safe standard message rendering');
like($guest, qr/<a href="http:\/\/example.invalid\/notes">/, 'existing external-link formatting retained');
like($guest, qr/<h2>Replies<\/h2>/, 'reply list has a semantic heading');
like($guest, qr/Reply &lt;One&gt; &amp; notes/, 'reply subject escaped');
like($guest, qr/Nested reply.*Reply two/s, 'nested and sibling replies retain chronological traversal order');
unlike($guest, qr/First reply body|Second reply body|Nested reply body/, 'single-message view preserves collapsed reply previews');
unlike($guest, qr/<table|<center|name="watch_|pl-message-watch"/, 'guest view has no legacy tables, orphan watch checkboxes, or watch form');
is(scalar @queries, 5, 'message and recursive reply queries are not duplicated');
is($finished, 5, 'all fetched statement handles are finished');
is(scalar @authors, 4, 'each displayed message author is fetched once');
is(scalar @permissions, 0, 'public forum messages do not need ACL database lookups');
my @urls = links($guest);
my @reply = grep { (query($_)->{op} || '') eq 'postmsg' } @urls;
is(scalar @reply, 1, 'Reply action is no longer duplicated');
is_deeply(query($reply[0]), {op => 'postmsg', id => 0, replyto => 395}, 'Reply retains forum zero and original message target');
my @parent = grep { (query($_)->{op} || '') eq 'getobj' } @urls;
is(scalar @parent, 2, 'Parent object and Up navigation remain');
is_deeply(query($parent[0]), {op => 'getobj', from => 'forums', id => 0}, 'parent forum destination retained');
for my $id (396, 397, 398) {
    ok(scalar(grep { (query($_)->{op} || '') eq 'getmsg' && query($_)->{id} == $id } @urls), "reply $id remains navigable");
}
my ($list_depth, $unbalanced) = (0, 0);
HTML::Parser->new(start_h => [sub { $list_depth++ if $_[0] eq 'li'; }, 'tagname'],
    end_h => [sub { $unbalanced++ if $_[0] eq 'li' && --$list_depth < 0; }, 'tagname'])->parse($guest);
is($list_depth, 0, 'nested reply list items have closing tags');
is($unbalanced, 0, 'reply list has no stray closing items');
$reader = user(999);
my $member = page(user(2));
is($reader->{uid}, 999, 'message reader state is restored after the request');
like($member, qr/class="pl-message-watch"/, 'member retains root-thread watch control');
like($member, qr/name="op" value="getmsg"/, 'watch form returns to the message route');
like($member, qr/name="id" value="395"/, 'watch form keeps the thread id');
like($member, qr/name="watch" value="add"/, 'unwatched thread provides add action');
my $protected = requestFormDecorate($member, user(2));
like($protected, qr/<form[^>]*method="post"/, 'response decoration converts the legacy watch form to POST');
like($protected, qr/name="_form_token"/, 'watch form receives existing CSRF protection');
my ($form_depth, $nested_forms, $tokens) = (0, 0, 0);
HTML::Parser->new(start_h => [sub {
    my ($tag, $attrs) = @_;
    $nested_forms++ if $tag eq 'form' && $form_depth++;
    $tokens++ if $tag eq 'input' && ($attrs->{name} || '') eq '_form_token';
}, 'tagname, attr'], end_h => [sub { $form_depth-- if $_[0] eq 'form'; }, 'tagname'])->parse($protected);
is($nested_forms, 0, 'watch form is not nested');
is($form_depth, 0, 'watch form closes correctly');
is($tokens, 1, 'single mutation form receives one token');
my $watching = page(user(2), watch => 'add');
is_deeply(\@watch_changes, [['add', 'messages', 395, 2]], 'existing add-watch mutation is retained');
like($watching, qr/\(watching\)/, 'watching marker appears for the current reader');
like($watching, qr/name="watch" value="remove"/, 'watched thread provides remove action');
page(user(2), watch => 'remove');
is_deeply(\@watch_changes, [['remove', 'messages', 395, 2]], 'existing remove-watch mutation is retained');
my $child = page(user(2), id => 396);
like($child, qr/First reply body/, 'viewing a reply displays its own body');
unlike($child, qr/class="pl-message-watch"/, 'non-root messages do not duplicate thread watch forms');
my @child_urls = links($child);
my @navigation = grep { (query($_)->{op} || '') eq 'getmsg' && query($_)->{id} == 395 } @child_urls;
is(scalar @navigation, 2, 'reply retains both Up and Top navigation to the thread');
my $leaf = page(user(-1), id => 397);
unlike($leaf, qr/<section class="pl-message-reply-section"/, 'a message without replies does not show an empty reply section');
{
    local $records{395}{tbl} = 'collab';
    local $records{395}{objectid} = 7;
    local $allowed = 0;
    unlike(page(user(2), watch => 'add'), qr/Original message|Reply &lt;One&gt;/, 'private parent denies both message and reply content');
    is(scalar @authors, 0, 'private message authors are not fetched for denied readers');
    is(scalar @watch_changes, 0, 'denied reader cannot change the message watch');
    is_deeply($permissions[0], ['collab', 7, user(2), 'read'], 'private parent uses the existing read ACL');
    local $allowed = 1;
    like(page(user(2)), qr/Original message/, 'permitted reader can view private-parent messages');
}
for my $id (undef, '1 OR 1=1', -1, ['395'], "395\n") {
    is(page(user(2), id => $id), "Couldn't find that message!", 'invalid message id is handled without SQL or mutation');
    is(scalar @queries, 0, 'invalid id does not query the database');
    is(scalar @watch_changes, 0, 'invalid id does not change watches');
}
{
    local $missing = 1;
    is(page(user(2), watch => 'add'), "Couldn't find that message!", 'missing message returns existing error text');
    is(scalar @watch_changes, 0, 'missing message cannot trigger a watch mutation');
    is($finished, 1, 'missing message statement is finished');
}
{
    local $success = 0;
    is(page(user(2)), "Couldn't find that message!", 'database failure does not dereference a missing statement');
}
{
    local $reply_failure = 1;
    like(page(user(-1)), qr/Original message/, 'reply-query failure does not destroy the main message');
}
{
    local $reader = user(2);
    my $legacy = getreplies(user(2), 395, 0, 1, undef);
    like($legacy, qr/^<tr><td><ul>/, 'legacy discussion callers retain their original table wrapper');
    unlike($legacy, qr/pl-message-replies/, 'modern reply markup is opt-in');
}
sub compose {
    my ($member, @params) = @_;
    @queries = (); @authors = (); @permissions = (); @submissions = (); @spelling = (); @visibility = (); $finished = 0;
    return postMessage({op => 'postmsg', id => 0, replyto => 395, @params}, $member);
}
sub form_values {
    my %values;
    my $textarea;
    HTML::Parser->new(start_h => [sub {
        my ($tag, $attrs) = @_;
        $values{$attrs->{name}} = $attrs->{value} if $tag eq 'input' && $attrs->{name};
        if ($tag eq 'textarea') { $textarea = $attrs->{name}; $values{$textarea} = ''; }
    }, 'tagname, attr'], text_h => [sub { $values{$textarea} .= $_[0] if defined $textarea; }, 'dtext'],
        end_h => [sub { undef $textarea if $_[0] eq 'textarea'; }, 'tagname'])->parse($_[0]);
    return \%values;
}
my $composer = compose(user(2));
like($composer, qr/<h1>Replying to<\/h1>.*<h1>Compose Post<\/h1>/s, 'reply context and composer use compact blue headers');
like($composer, qr/Physics &lt;Library&gt; &amp; &quot;tips&quot;/, 'reply context subject safely escaped');
like($composer, qr/User &lt;1&gt; &amp; Editor.*2025-03-04 05:31:13/s, 'reply context author and date retained');
like($composer, qr/Original message\.<br \/>.*\\begin\{figure\}/s, 'reply context retains message formatting and source');
unlike($composer, qr/<table|<center|bgcolor=|width="600"/, 'reply form removes fixed-width and legacy grey boxes');
like($composer, qr/Note: Posts are in plain ASCII with whitespace preserved \(do not use HTML!\)\. URLs will be automatically hyperlinked when message is displayed\./, 'original posting note retained');
for my $control (qw(preview spell quote post)) {
    like($composer, qr/<button[^>]+type="submit"[^>]+name="$control"/, "$control control retained");
}
my $initial_values = form_values($composer);
is_deeply($initial_values, {subject => 'Re: Physics <Library> & "tips"', body => '',
    id => 0, replyto => 395, from => 'forums', op => 'postmsg'}, 'initial reply values include resolved forum zero and Re subject');
is(scalar @queries, 1, 'reply context and default subject share one query');
is($finished, 1, 'reply context statement finished');
my $draft = "A draft\n\\begin{figure}\n</textarea><script>alert(1)</script>&";
my $preview = compose(user(2), preview => 'preview', subject => 'Draft <subject> & "test"', body => $draft);
like($preview, qr/<h2>Preview:<\/h2>/, 'preview shown in its own section');
like($preview, qr/&lt;script&gt;alert\(1\)&lt;\/script&gt;/, 'preview still safely renders standard message text');
is(form_values($preview)->{body}, $draft, 'preview preserves exact draft including textarea closing text');
is(form_values($preview)->{subject}, 'Draft <subject> & "test"', 'preview preserves subject exactly');
is(scalar @submissions, 0, 'preview does not submit');
my $spelled = compose(user(2), spell => 'spellcheck', subject => 'Draft', body => "> quoted line\n  typo");
is_deeply(\@spelling, ['typo'], 'spellcheck omits quoted lines as before');
like($spelled, qr/Spell check \(broken words in red, clickable\):.*<a class="spell"/s, 'spellcheck label and clickable output retained');
is(form_values($spelled)->{body}, "> quoted line\n  typo", 'spellcheck does not replace draft');
is(scalar @submissions, 0, 'spellcheck does not submit');
my $quoted = compose(user(2), quote => 'quote', body => 'My reply');
is(form_values($quoted)->{body}, getquoted($records{395}{body})."\n\nMy reply", 'quote uses existing wrapping and prepends to draft');
is(scalar @queries, 1, 'quote reuses fetched parent body');
is(scalar @submissions, 0, 'quote does not submit');
is(form_values(compose(user(2), quote => 'quote'))->{body}, getquoted($records{395}{body}),
    'quote without a draft preserves the original quoted text exactly');
{
    local $records{395}{subject} = 'Re: Existing thread';
    is(form_values(compose(user(2)))->{subject}, 'Re: Existing thread', 'reply subject prefix is not duplicated');
}
my $missing_subject = compose(user(2), subject => '', body => $draft, post => 'post');
like($missing_subject, qr/role="alert">Need a subject\./, 'missing subject error stays with the compose form');
is(form_values($missing_subject)->{body}, $draft, 'missing subject keeps draft');
is(scalar @submissions, 0, 'missing subject cannot submit');
my $missing_body = compose(user(2), subject => 'Draft', body => '', post => 'post');
like($missing_body, qr/role="alert">Need a message body\./, 'missing body error stays with the compose form');
is(form_values($missing_body)->{subject}, 'Draft', 'missing body keeps subject');
is(scalar @submissions, 0, 'missing body cannot submit');
is(compose(user(2), subject => 'Draft', body => 'My reply', post => 'post', id => 99, from => 'objects'),
    'Posted by existing submission handler', 'post retains existing submission handler');
is_deeply(\@visibility, [['forums', 0]], 'reply visibility uses stored parent destination');
is_deeply($submissions[0], [{op => 'postmsg', id => 0, replyto => 395, from => 'forums',
    subject => 'Draft', body => 'My reply', post => 'post'}, user(2), 0], 'post preserves user and visibility with normalized reply destination');
my $new_post = compose(user(2), replyto => '', from => 'objects', id => 1359);
unlike($new_post, qr/<h1>Replying to<\/h1>|name="quote"/, 'new post has no reply context or quote action');
is(form_values($new_post)->{id}, 1359, 'new post keeps object destination');
is(scalar @queries, 0, 'new post does not query a nonexistent reply');
is(compose(user(2), replyto => undef, from => 'objects', id => 1359,
    subject => 'New discussion', body => 'A new post', post => 'post'),
    'Posted by existing submission handler', 'new discussion still submits through existing handler');
is_deeply(\@visibility, [['objects', 1359]], 'new discussion keeps supplied parent destination');
is(compose(user(-1)), "You can't post as anonymous.", 'anonymous posting remains blocked');
is(scalar @queries, 0, 'anonymous users do not fetch private reply context');
for my $id (['395'], '395 OR 1=1', -1, "395\n") {
    is(compose(user(2), replyto => $id), "Couldn't find that message!", 'invalid reply id rejected');
    is(scalar @queries, 0, 'invalid reply id cannot reach SQL');
}
{
    local $missing = 1;
    is(compose(user(2), quote => 'quote'), "Couldn't find that message!", 'missing reply handled without dereference');
    is($finished, 1, 'missing reply statement finished');
}
{
    local $success = 0;
    is(compose(user(2)), "Couldn't find that message!", 'reply database failure handled');
}
{
    local $records{395}{tbl} = 'collab';
    local $records{395}{objectid} = 7;
    local $allowed = 0;
    unlike(compose(user(2), body => 'My reply', subject => 'Draft'), qr/Original message/, 'private reply context hidden from denied reader');
    is(scalar @authors, 0, 'denied reply does not fetch author');
    is(scalar @submissions, 0, 'denied reply does not submit');
    is_deeply($permissions[0], ['collab', 7, user(2), 'read'], 'reply uses existing parent read ACL');
    local $allowed = 1;
    like(compose(user(2)), qr/Original message/, 'permitted reader gets private reply context');
}
my $protected_composer = requestFormDecorate($composer, user(2));
like($protected_composer, qr/<form[^>]*method="post"/, 'composer uses POST');
like($protected_composer, qr/name="_form_token"/, 'composer receives existing response-time CSRF token');
my $forms = () = $protected_composer =~ /<form\b/g;
my $compose_tokens = () = $protected_composer =~ /name="_form_token"/g;
is($forms, 1, 'reply context does not nest forms');
is($compose_tokens, 1, 'all compose actions share one CSRF token');
if (my $dir = $ENV{MESSAGE_VIEW_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($menu, $sidebar) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>',
    }, \$sidebar) or die $tt->error;
    my $long;
    {
        local $records{395}{subject} = 'A very long message subject about physics and figures ' x 4;
        local $records{395}{body} = 'Long source token: '.('x' x 200)."\nhttp://example.invalid/".('path' x 60);
        $long = page(user(-1));
    }
    for my $case (['guest', $guest], ['member', $protected], ['reply', $child], ['empty', $leaf], ['long', $long],
        ['compose', $protected_composer], ['preview', $preview], ['spell', $spelled], ['quote', $quoted],
        ['compose-error', $missing_subject], ['new-post', $new_post]) {
        my $html = '';
        $tt->process('view.tt', {title => 'Viewing Message', site_name => 'Physics Library',
            content => $case->[1], sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>',
        }, \$html) or die $tt->error;
        open my $out, '>', "$dir/$case->[0].html" or die $!;
        print {$out} $html; close $out;
    }
}
done_testing();
