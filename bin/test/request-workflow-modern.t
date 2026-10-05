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

our $dbh;
my $root = "$FindBin::Bin/../..";
my %config = (template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    req_tbl => 'requests', en_tbl => 'objects', olinks_tbl => 'objectlinks', page_widget_width => 5);
our @completed = (
    {uid => 41, title => 'position <vector> & "direction"', created => '2009-04-14 08:00:00',
        creatorid => 441, fulfillerid => 21, username => 'Requester <One>', username2 => 'Filler & Editor'},
    {uid => 40, title => 'integral equation', created => '2009-04-13 08:00:00',
        creatorid => 441, fulfillerid => 21, username => 'bci1', username2 => 'pahio'},
    {uid => 39, title => 'inflexion point', created => '2009-04-12 08:00:00',
        creatorid => 441, fulfillerid => 21, username => 'bci1', username2 => 'pahio'},
);
our @pending = ({uid => 90, title => 'Vector <Triple> & Product'}, {uid => 12, title => 'Alpha request'});
our ($failure, $already_filled) = ('', 0);
my (@queries, @finished, @updates, @inserts, @watches, @notices, @identifiers);
sub getConfig { $config{$_[0]} }
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub errorMessage { $_[0] }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub urlescape { uri_escape_utf8($_[0]) }
sub htmlescape { requestFormEscape($_[0]) }
sub sq { my $s = $_[0]; $s =~ s/'/''/g; $s }
sub objectExistsByAny { push @identifiers, $_[0]; $_[0] eq '209' || $_[0] eq 'VectorTripleProduct' }
sub getidbyname { $_[0] eq 'VectorTripleProduct' ? 209 : -1 }
sub lookupfield { $_[0] eq 'requests' ? $already_filled : 21 }
sub userInfoById { (uid => $_[0]) }
sub addWatchIfAllowed { push @watches, [@_] }
sub updateWatches { push @notices, [@_] }
sub reqList { 'Existing requests landing page' }
sub dbUpdate { push @updates, $_[1]; return (1, bless {rows => [], kind => 'update'}, 'RequestWorkflowRows'); }
sub dbInsert { push @inserts, $_[1]; return (1, bless {rows => [], kind => 'insert'}, 'RequestWorkflowRows'); }
sub dbSelect {
    my ($db, $q) = @_;
    push @queries, $q;
    my (@rows, $kind);
    if ($q->{WHERE} eq 'fulfilled is null') { @rows = @pending; $kind = 'options'; }
    elsif ($q->{WHAT} eq 'uid') { @rows = map {{uid => $_->{uid}}} @completed; $kind = 'count'; }
    else {
        @rows = sort {$b->{created} cmp $a->{created}} @completed;
        splice @rows, 0, $q->{OFFSET} if $q->{OFFSET};
        splice @rows, $q->{LIMIT} if @rows > $q->{LIMIT};
        $kind = 'list';
    }
    return (0, undef) if $failure eq $kind;
    return (1, bless {rows => [map {{%$_}} @rows], pos => 0, kind => $kind}, 'RequestWorkflowRows');
}
{
    package RequestWorkflowRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub finish { push @finished, $_[0]->{kind} }
}
for my $spec (
    ['Requests', qw(oldReqs updateReq updateRequest getUnfilledReqs getRequestUpdater)],
    ['Util', qw(ymd humanReadableCmp getSelectBoxSortByValue)],
    ['Layout', qw(getPager)], ['DB', qw(dbGetRows)],
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
sub user { {uid => $_[0], ticket => 'a' x 64, data => {active => 1}, prefs => {pagelength => $_[1] || 2}} }
sub reset_calls { @queries = (); @finished = (); @updates = (); @inserts = (); @watches = (); @notices = (); @identifiers = (); }
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {push @links, URI->new($_[1]{href}) if $_[0] eq 'a'}, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub query { return {$_[0]->query_form}; }
sub elements {
    my @elements;
    HTML::Parser->new(start_h => [sub {push @elements, {tag => $_[0], %{$_[1]}}}, 'tagname, attr'])->parse($_[0]);
    return @elements;
}
my %fixtures;
my $params = {op => 'oldreqs'};
my $html = oldReqs($params, user(-1));
$fixtures{completed} = $html;
like($html, qr/<h1>Old Requests<\/h1>/, 'completed requests uses shared header and existing title');
like($html, qr/1-2 of 3/, 'page range preserved');
like($html, qr/position &lt;vector&gt; &amp; &quot;direction&quot;/, 'completed title escaped');
like($html, qr/Requester &lt;One&gt;.*Filler &amp; Editor/s, 'both contributor names escaped');
like($html, qr/2009-04-14.*requested by.*filled.*by/s, 'date and attribution wording retained');
like($html, qr/position &lt;vector&gt;.*integral equation/s, 'newest-first order retained');
unlike($html, qr/inflexion point/, 'listing respects page length');
is(scalar @queries, 2, 'initial page retains count and list queries');
is($queries[1]{OFFSET}, 0, 'default offset retained');
is($queries[1]{LIMIT}, 2, 'user page-length preference retained');
like($queries[1]{WHERE}, qr/closed is not null and u1.uid=requests.creatorid and u2.uid=requests.fulfillerid/,
    'completed-only filter and existing contributor joins retained');
is_deeply(\@finished, ['count', 'list'], 'statement handles released');
is_deeply($params, {op => 'oldreqs', total => 3, offset => 0}, 'pager state returned to caller');
my @links = links($html);
ok(grep((query($_)->{op} || '') eq 'reqlist', @links), 'back-to-requests navigation present');
ok(grep((query($_)->{op} || '') eq 'updatereq', @links), 'update form navigation present');
my ($request) = grep {(query($_)->{op} || '') eq 'getobj'} @links;
is_deeply(query($request), {op => 'getobj', from => 'requests', id => 41}, 'request object link preserved');
my @profiles = grep {(query($_)->{op} || '') eq 'getuser'} @links;
is_deeply([map {query($_)->{id}} @profiles], [441, 21, 441, 21], 'requester and filler profile links retained');
my ($next) = grep {(query($_)->{offset} || '') eq '2'} @links;
is_deeply(query($next), {op => 'oldreqs', offset => 2, total => 3}, 'pager targets same completed-request route');
reset_calls();
my $last = oldReqs({op => 'oldreqs', offset => 2, total => 3}, user(-1));
$fixtures{last} = $last;
like($last, qr/3-3 of 3.*inflexion point/s, 'last page range and remaining row correct');
like($last, qr/start="3"/, 'numbering continues across pages');
is(scalar @queries, 1, 'supplied total retains existing one-query paging behavior');
{
    local @completed;
    my $empty = oldReqs({}, user(-1));
    $fixtures{empty} = $empty;
    like($empty, qr/No old requests/, 'original empty-state wording retained');
    unlike($empty, qr/1-0|class="pl-completed-request"/, 'empty list has no misleading range or rows');
}
like(oldReqs({offset => 99, total => 3}, user(-1)), qr/No old requests on this page/, 'out-of-range page has readable state');
for my $fail ('count', 'list') {
    local $failure = $fail;
    is(oldReqs({}, user(-1)), 'Request query failed!', "$fail failure handled safely");
}
reset_calls();
oldReqs({offset => '0; DROP TABLE requests', total => 'broken'}, user(-1));
is($queries[1]{OFFSET}, 0, 'malformed offset cannot enter SQL');
{
    my $u = user(-1); $u->{prefs}{pagelength} = 0;
    reset_calls(); oldReqs({}, $u);
    is($queries[1]{LIMIT}, 20, 'invalid page length has safe default');
}
{
    local $completed[0]{title} = 'VeryLongUnbrokenRequestTitle' x 15;
    local $completed[0]{username} = 'VeryLongUnbrokenUsername' x 15;
    $fixtures{'long-completed'} = oldReqs({}, user(-1));
}

reset_calls();
is(updateReq({}, user(-1)), 'You have to be logged in for this!', 'guest cannot load update form');
is(updateReq({}, user(0)), 'You have to be logged in for this!', 'anonymous user zero cannot load update form');
is(scalar @queries, 0, 'denied form does not query request catalog');
$html = updateReq({}, user(1));
$fixtures{update} = $html;
like($html, qr/<h1>Update a request<\/h1>/, 'update form uses shared compact header');
like($html, qr/Update filled status for:.*Object which fills this request:.*\(id or canonical name\)/s,
    'all original field labels and helper text retained');
like($html, qr/Vector &lt;Triple&gt; &amp; Product/, 'request choices escaped');
my @elements = elements($html);
my ($form) = grep {$_->{tag} eq 'form'} @elements;
is($form->{method}, 'post', 'update remains a POST');
is($form->{action}, '/', 'existing submission target retained');
my @options = grep {$_->{tag} eq 'option'} @elements;
is_deeply([map {$_->{value}} @options], ['-1', '12', '90'], 'all choices retain natural ordering and none sentinel');
is($options[0]{selected}, 'selected', 'none selected initially');
my ($identifier) = grep {($_->{name} || '') eq 'identifier'} @elements;
is($identifier->{value}, '', 'identifier initially empty');
ok(grep(($_->{name} || '') eq 'op' && $_->{value} eq 'updatereq', @elements), 'operation field retained');
ok(grep(($_->{name} || '') eq 'submit' && $_->{value} eq 'update', @elements), 'update submit flag retained');
for my $control ('request', 'identifier') {
    my ($field) = grep {($_->{name} || '') eq $control} @elements;
    ok(grep($_->{tag} eq 'label' && $_->{for} eq $field->{id}, @elements), "$control has an associated label");
}
$html = updateReq({request => 90, identifier => 'VectorTripleProduct'}, user(1));
$fixtures{prefilled} = $html;
like($html, qr/value="90" selected="selected"/, 'request preselection preserved');
like($html, qr/name="identifier"[^>]*value="VectorTripleProduct"/, 'article-name prefill preserved');
my $bad_identifier = '"><script>alert(1)</script>';
$html = updateReq({submit => 'update', request => 90, identifier => $bad_identifier}, user(1));
$fixtures{error} = $html;
like($html, qr/role="alert".*No object found for identifier\./s, 'existing validation message visible in alert');
like($html, qr/value="90" selected="selected"/, 'validation retains selected request');
unlike($html, qr/<script>/, 'identifier cannot inject markup');
my ($retained) = grep {($_->{name} || '') eq 'identifier'} elements($html);
is($retained->{value}, $bad_identifier, 'invalid identifier retained as safe attribute text');
for my $selection (undef, '', '-1', '[none]', '90 OR 1=1') {
    reset_calls();
    like(updateReq({submit => 'update', request => $selection, identifier => '209'}, user(1)),
        qr/You must select a request\./, 'missing/sentinel/invalid selection rejected');
    is(scalar @updates + scalar @inserts, 0, 'invalid selection never mutates database');
}
like(updateReq({submit => 'update', request => 90, identifier => ''}, user(1)),
    qr/No object found for identifier\./, 'blank object identifier rejected');
{
    local @pending;
    like(updateReq({}, user(1)), qr/>\[none\]<\/option>/, 'empty catalog retains none choice');
}
{
    local $failure = 'options';
    is(updateReq({}, user(1)), 'Request query failed!', 'failed catalog query handled');
}
for my $article ('209', 'VectorTripleProduct') {
    reset_calls();
    is(updateReq({submit => 'update', request => 90, identifier => $article}, user(1)),
        'Existing requests landing page', 'numeric/canonical article update returns to existing landing page');
    is(scalar @updates, 1, 'request fulfillment written once');
    is_deeply($updates[0], {WHAT => 'requests', SET => 'fulfilled=CURRENT_TIMESTAMP,fulfillerid=21', WHERE => 'uid=90'},
        'existing fulfillment timestamp and author attribution preserved');
    is($inserts[0]{VALUES}, "'requests',90,'objects',209,'request fill'", 'original context link preserved');
    is_deeply($notices[0], [90, 'requests', 209, 'objects', 1, 'request reported as fulfilled'], 'watch notifications preserved');
    is(scalar @watches, 2, 'reporter and article-author watches preserved');
}
{
    local $already_filled = 1;
    reset_calls(); updateReq({submit => 'update', request => 90, identifier => '209'}, user(1));
    is(scalar @updates + scalar @inserts, 0, 'already-filled request keeps existing no-op behavior');
}
like(getRequestUpdater({request => 90}), qr/^Update filled status for: <select name="request">/,
    'legacy self-contained updater helper remains compatible');
my $decorated = requestFormDecorate($fixtures{prefilled}, user(1));
my ($token) = grep {($_->{name} || '') eq '_form_token'} elements($decorated);
ok($token && length($token->{value}) == 64, 'update form retains response-time CSRF protection');
unlike($decorated, qr/(?:href|action)="[^"]*_form_token/, 'token never placed in URL');
my $dispatch = readFile("$root/lib/Noosphere/Dispatch.pm");
like($dispatch, qr/'oldreqs'\s*=>\s*\\&oldReqs/, 'completed-list route unchanged');
like($dispatch, qr/'updatereq'\s*=>\s*\\&updateReq/, 'update route unchanged');
ok(grep($_ eq 'oldreqs', requestFormReadRoutes()), 'completed listing remains read-only');
ok(!requestFormNeedsProtection({op => 'updatereq'}, 'GET'), 'initial update navigation stays read-only');
ok(requestFormNeedsProtection({op => 'updatereq', submit => 'update'}, 'POST'), 'update submission remains protected');

if (my $dir = $ENV{REQUEST_WORKFLOW_TEST_DIR}) {
    local $pending[0]{title} = 'VeryLongUnbrokenRequestTitle' x 20;
    $fixtures{'long-update'} = updateReq({request => 90, identifier => 'VeryLongCanonicalName' x 20}, user(1));
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    for my $name (sort keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Request preview', site_name => 'Physics Library', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page; close $out;
    }
}
done_testing();
