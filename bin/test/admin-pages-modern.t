#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use URI;
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use HTML::Parser;
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;

our ($dbh, $stats);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    access_admin => 100, access_editobj => 100, access_postnews => 200, dbms => 'MariaDB',
    blist_tbl => 'blacklist', storage_tbl => 'storage', cache_tbl => 'cache', en_tbl => 'objects',
    news_tbl => 'news', polls_tbl => 'polls', xref_tbl => 'xref', page_widget_width => 5,
    typechars => {1 => 'D', 2 => 'T'}, typestrings => {1 => 'Definition', 2 => 'Theorem'},
    prefs_schema => {method => ['Rendering style', 'select', 'make4ht', {make4ht => 'HTML', pdf => 'PDF', src => 'Source'}]},
);
our @blacklist = ({uid => 7, mask => '^user[0-9]+@example\.invalid$'}, {uid => 8, mask => '"><script>alert(1)</script>'});
our @storage = ({_key => 'top_news', valid => 1, lastupdate => '2026-10-05 10:00:00'}, {_key => 'key <with> "quotes"', valid => 0, lastupdate => '2026-10-04 10:00:00'});
our @cache = ({objectid => 40, tbl => 'objects', title => 'Vector <Triple> & "Product"', valid => 1, build => 0, touched => '2026-10-05 10:00:00'});
our @results = ({oid => 15, uid => 40, title => 'Vector <Triple> & "Product"', data => '"><script>not HTML</script>'});
our ($failure, $object_count) = ('', 10);
my (@queries, @sql, @executes, @inserts, @deletes, @invalidations, @flags, @finished, @spell_calls, @counts);
sub getConfig { $config{$_[0]} }
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub noAccess { 'Insufficient access.' }
sub loginExpired { 'Sign in required.' }
sub errorMessage { $_[0] }
sub dwarn { }
sub urlescape { uri_escape_utf8($_[0]) }
sub urlunescape { uri_unescape($_[0]) }
sub sq { my $s = $_[0]; $s =~ s/'/''/g; $s }
sub nextval { 99 }
sub normalize { $_[0] }
sub lookupfield { $_[1] eq 'mask' ? $blacklist[0]{mask} : $cache[0]{title} }
sub getDefaultRenderMethod { 'make4ht' }
sub getMethods { qw(make4ht pdf src) }
sub makeDate { $_[0] }
sub mdhm { $_[0] }
sub getrowcount { 80 }
sub getUnprovenTheorems { {40 => 'First theorem', 41 => 'Second theorem'} }
sub setbuildflag_off { push @flags, ['build', @_] }
sub setvalidflag_off { push @flags, ['valid', @_] }
sub checkdoc { push @spell_calls, $_[0]; '<p>Spell report: '.requestFormEscape($_[0]).'</p>' }
sub dbGetTables { qw(users objects storage) }
sub dbGetSchema { ([{colname => 'title', typename => 'text', notnull => 0, default => '<none>'}], [{indname => 'title_idx', oncol => 'title', primary => 0, unique => 0}]) }
sub dbRowCountWithWhat {
    push @counts, [@_];
    return 0 if $object_count == 0;
    return 50 if $_[1] eq 'xref';
    return 3 if $_[2] =~ /valid = 0/;
    return 1 if $_[2] =~ /build/;
    return $object_count;
}
sub rows { bless {rows => $_[0], pos => 0, kind => $_[1]}, 'AdminPageRows' }
sub dbSelect {
    push @queries, $_[1];
    my $table = $_[1]{FROM};
    return (0, undef) if $failure eq $table;
    return (1, rows([map {{%$_}} $table eq 'blacklist' ? @blacklist : @storage], $table));
}
sub dbLowLevelSelect {
    push @sql, $_[1];
    return (0, undef) if $failure eq 'cache';
    return (1, rows([map {{%$_}} @cache], 'cache'));
}
sub dbInsert { push @inserts, $_[1]; return ($failure eq 'insert' ? 0 : 1, rows([], 'insert')); }
sub dbDelete { push @deletes, $_[1]; return (1, rows([], 'delete')); }
{
    package AdminPageRows;
    sub rows { scalar @{$_[0]->{rows}} }
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub finish { push @finished, $_[0]->{kind} }
    sub execute { push @executes, [$_[0]->{sql}, @_ > 1 ? @_[1..$#_] : ()]; return $failure eq 'query' ? 0 : 1; }
    package AdminPageDB;
    sub prepare {
        push @sql, $_[1];
        my $data = $_[1] =~ /^select count/ ? [{cnt => 12}] : $_[1] =~ /^select/ ? [map {{%$_}} @results] : [];
        my $sth = Noosphere::rows($data, 'sql'); $sth->{sql} = $_[1]; return $sth;
    }
    sub errstr { 'SQL error <unexpected> & "token"' }
    package AdminPageStats;
    sub invalidate { push @invalidations, $_[1] }
}
$dbh = bless {}, 'AdminPageDB';
$stats = bless {}, 'AdminPageStats';
for my $spec (
    ['Admin', qw(dbAdmin printTabular printResultRows cacheControl blacklistEditor adminStats adminDBStats)],
    ['News', qw(postNews checkPostNews insertNewsItem)],
    ['Polls', qw(addPoll checkNewPoll insertNewPoll)],
    ['Layout', qw(getPager)], ['Util', qw(inset)], ['DB', qw(dbGetRows)],
) {
    my ($module, @names) = @$spec;
    my $source = readFile("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body; die $@ if $@;
    }
}
sub user { {uid => $_[0] || 1, ticket => 'a' x 64, data => {active => 1, access => defined($_[1]) ? $_[1] : 200}, prefs => {pagelength => 20}} }
sub reset_calls { @queries = (); @sql = (); @executes = (); @inserts = (); @deletes = (); @invalidations = (); @flags = (); @finished = (); @spell_calls = (); @counts = (); }
sub elements {
    my @tags;
    HTML::Parser->new(start_h => [sub {push @tags, {tag => $_[0], %{$_[1]}}}, 'tagname, attr'])->parse($_[0]);
    return @tags;
}
sub form_fields { return {map {$_->{name} => $_->{value}} grep {$_->{tag} eq 'input' && defined($_->{name})} elements($_[0])}; }
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {push @links, {URI->new($_[1]{href})->query_form} if $_[0] eq 'a'}, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub safe_forms {
    my ($html, $name) = @_;
    my ($depth, $nested, $tokens, $forms) = (0, 0, 0, 0);
    HTML::Parser->new(start_h => [sub {
        if ($_[0] eq 'form') { $nested++ if $depth++; $forms++ if lc($_[1]{method} || 'get') eq 'post'; }
        $tokens++ if $_[0] eq 'input' && ($_[1]{name} || '') eq '_form_token';
    }, 'tagname, attr'], end_h => [sub {$depth-- if $_[0] eq 'form'}, 'tagname'])->parse(requestFormDecorate($html, user(1)));
    is($nested, 0, "$name has no nested forms");
    is($depth, 0, "$name closes its forms");
    is($tokens, $forms, "$name retains per-POST-form CSRF tokens") if $forms;
}
my %fixtures;
my @routes = ([dbadmin => \&dbAdmin, 'Database Admin'], [cachecont => \&cacheControl, 'Cache Control'],
    [blacklist => \&blacklistEditor, 'Blacklist Editor'], [postnews => \&postNews, 'Post News Item'],
    [newpoll => \&addPoll, 'Create Poll'], [adminstats => \&adminStats, 'Administrative Statistics']);
for my $route (@routes) {
    my ($op, $handler, $title) = @$route;
    my $html = $handler->({op => $op}, user(1));
    $fixtures{$op} = $html;
    like($html, qr/<header class="pl-modern-box-header"><h1>\Q$title\E<\/h1>/, "$op uses shared compact blue header");
    unlike($html, qr/<NS:template|###NSTAG###|<center|bgcolor=/, "$op has no legacy layout wrappers");
    reset_calls();
    like($handler->({op => $op, submit => 'create', add => 1, new_mask => 'blocked', freeform => 1, query => 'delete from objects', invalidate => 1, group => 'stats'}, user(-1, 0)),
        qr/Insufficient access|Sign in required/, "$op denies unauthorized submissions");
    is(scalar @queries + scalar @sql + scalar @inserts + scalar @deletes + scalar @invalidations + scalar @counts, 0, "$op denies access before any DB/cache work");
}
is(postNews({}, user(1, 199)), 'Insufficient access.', 'news keeps its higher posting threshold');
is(addPoll({}, user(1, 99)), 'Insufficient access.', 'non-admin cannot create polls');
is(blacklistEditor({}, user(1, 99)), 'Insufficient access.', 'non-admin cannot edit blacklist');
for my $op (qw(dbadmin cachecont blacklist postnews newpoll)) {
    ok(!requestFormNeedsProtection({op => $op}, 'GET'), "$op initial navigation stays read-only");
    ok(requestFormNeedsProtection({op => $op, submit => 1}, 'POST'), "$op submissions stay protected");
}
ok(!requestFormNeedsProtection({op => 'adminstats'}, 'GET'), 'admin statistics remains read-only');

my $html = $fixtures{dbadmin};
like($html, qr/Get table information.*Select a table:.*Freeform query.*History:/s, 'database tools and wording retained');
my @table_options = grep {$_->{tag} eq 'option'} elements($html);
is_deeply([map {$_->{value}} @table_options], [qw(objects storage users)], 'all database table options retained in stable order');
my $q = 'select title from objects where title=\'<script>\'';
my $history = join ';', map {urlescape("select $_ from objects")} 1..20;
$html = dbAdmin({query => $q, qhist => $history}, user(1));
unlike($html, qr/<script>/, 'query text and history cannot inject HTML');
like($html, qr/name="query".*?&lt;script&gt;/s, 'query content retained safely');
my @history_options = grep {$_->{tag} eq 'option' && $_->{value} =~ /select/} elements($html);
is(scalar @history_options, 15, 'query history remains capped at fifteen');
is(urlunescape($history_options[0]{value}), $q, 'latest query stays first in history');
like($html, qr/onchange="this.form.elements.query.value=unescape\(this.value\)"/, 'history selection still fills query editor');
reset_calls();
$html = dbAdmin({schema => 1, table => 'objects'}, user(1));
$fixtures{schema} = $html;
like($html, qr/Schema for table.*title.*Indices on table.*title_idx.*Rows in table.*12/s, 'schema columns, indices and count retained');
like($html, qr/&lt;none&gt;/, 'schema values escaped');
ok(grep($_ eq 'sql', @finished), 'row-count statement released');
reset_calls();
$html = dbAdmin({freeform => 'submit', query => 'select title from objects'}, user(1));
$fixtures{results} = $html;
is($sql[0], 'select title, objects.oid from objects', 'original nonaggregate query OID behavior preserved');
my $fields = form_fields($html);
is($fields->{oid}, 15, 'hidden row OID retained');
is($fields->{table}, 'objects', 'result update/delete table retained');
is($fields->{col_title}, $results[0]{title}, 'row title remains editable without double escaping');
is($fields->{col_data}, $results[0]{data}, 'row data remains editable without markup injection');
ok(!exists($fields->{col_oid}), 'implicit OID stays hidden');
unlike($html, qr/<script>/, 'result text cannot inject markup');
safe_forms($html, 'database results');
reset_calls();
dbAdmin({freeform => 1, query => 'select count(*) from objects'}, user(1));
is($sql[0], 'select count(*) from objects', 'aggregate query not rewritten');
reset_calls();
dbAdmin({update => 'update', table => 'objects', oid => 15, col_title => 'New title'}, user(1));
is_deeply($executes[0], ['update objects set title=? where oid=15', 'New title'], 'result updates keep bound values and original row target');
reset_calls();
like(dbAdmin({delete => 'delete', table => 'objects', oid => 15}, user(1)), qr/Delete successful\./, 'original delete feedback retained');
is($sql[0], 'delete from objects where oid=15', 'original result delete query retained');
{
    local $failure = 'query';
    like(dbAdmin({freeform => 1, query => 'select * from objects'}, user(1)), qr/SQL error &lt;unexpected&gt; &amp; &quot;token&quot;/, 'SQL errors safely displayed');
}
{
    local @results;
    like(dbAdmin({freeform => 1, query => 'select * from objects'}, user(1)), qr/No matching rows\./, 'empty query result retained');
}

$html = $fixtures{blacklist};
like($html, qr/Current Blacklist:.*Add Blacklist Mask:.*perl regular expression masks/s, 'blacklist sections and full explanation retained');
is(form_fields($html)->{mask_8}, $blacklist[1]{mask}, 'quoted blacklist mask retained safely');
unlike($html, qr/<script>/, 'blacklist mask cannot inject HTML');
safe_forms($html, 'blacklist');
reset_calls();
$html = blacklistEditor({op => 'blacklist', add => 'add mask', new_mask => '<new mask>'}, user(1));
is_deeply($executes[0], ['insert into blacklist (uid, mask) values (?, ?)', 99, '<new mask>'], 'blacklist addition uses original bound parameters');
like($html, qr/Mask &#39;&lt;new mask&gt;&#39; added\./, 'blacklist addition feedback escaped once');
reset_calls();
blacklistEditor({op => 'blacklist', update_7 => 'update', mask_7 => '^changed$'}, user(1));
is_deeply($executes[0], ['update blacklist set mask=? where uid=7', '^changed$'], 'mask update keeps original field name and bound value');
reset_calls();
blacklistEditor({op => 'blacklist', delete_7 => 'delete'}, user(1));
is_deeply($deletes[0], {FROM => 'blacklist', WHERE => 'uid=7'}, 'mask deletion targets original row');
{
    local @blacklist;
    like(blacklistEditor({}, user(1)), qr/No entries in the blacklist currently\./, 'empty blacklist state retained');
}

my @groups = map {$_->{group}} links($fixtures{cachecont});
is_deeply(\@groups, [qw(stats en files)], 'all original cache groups retained');
like(cacheControl({group => 'files'}, user(1)), qr/not yet implemented/, 'files group remains explicitly unsupported');
$html = cacheControl({group => 'stats'}, user(1));
$fixtures{'cache-stats'} = $html;
like($html, qr/top_news/, 'underscore-backed cache key displayed correctly');
like($html, qr/key &lt;with&gt; &quot;quotes&quot;/, 'invalid cache key escaped');
like($html, qr/\(invalid\)/, 'invalid statistic retains disabled-state text');
is(form_fields($html)->{key}, 'top_news', 'stats invalidation retains exact cache key');
safe_forms($html, 'statistics cache');
reset_calls();
cacheControl({group => 'stats', invalidate => 1, key => 'top_news'}, user(1));
is_deeply(\@invalidations, ['top_news'], 'stats invalidation callback unchanged');
reset_calls();
$html = cacheControl({op => 'cachecont', group => 'en', method => 'pdf', offset => 40}, user(1));
$fixtures{'cache-en'} = $html;
like($sql[0], qr/c\.method='pdf'.*limit 40, 40$/, 'cache renderer filter and scaled page size preserved');
like($html, qr/title.*last update.*valid.*build.*control/s, 'all encyclopedia cache columns retained');
$fields = form_fields($html);
is_deeply({map {$_ => $fields->{$_}} qw(id from group method offset)}, {id => 40, from => 'objects', group => 'en', method => 'pdf', offset => 40}, 'invalidation form retains selected method and page');
safe_forms($html, 'encyclopedia cache');
my ($next) = grep {($_->{offset} || 0) == 80} links($html);
my ($previous) = grep {($_->{offset} || 0) == 0 && ($_->{op} || '') eq 'cachecont' && ($_->{method} || '') eq 'pdf'} links($html);
ok($previous && $previous->{group} eq 'en', 'cache pager preserves selected method and group');
reset_calls();
cacheControl({group => 'en', method => 'pdf', from => 'objects', id => 40, invalidate => 1}, user(1));
is_deeply(\@flags, [['build', 'objects', 40, 'pdf'], ['valid', 'objects', 40, 'pdf']], 'cache invalidation clears the selected renderer flags');
reset_calls();
cacheControl({group => 'en', method => "pdf'; drop table cache", offset => 'bad'}, user(1));
like($sql[0], qr/method='make4ht'.*limit 0, 40$/, 'unknown renderer and malformed offset safely default');
{
    local $config{dbms} = 'pg';
    reset_calls(); cacheControl({group => 'en', offset => 40}, user(1));
    like($sql[0], qr/offset 40 limit 40$/, 'PostgreSQL cache pagination preserved');
}
for my $fail (qw(blacklist storage cache)) {
    local $failure = $fail;
    my $error = $fail eq 'blacklist' ? blacklistEditor({}, user(1)) : cacheControl({group => $fail eq 'storage' ? 'stats' : 'en'}, user(1));
    like($error, qr/query failed\./, "$fail query failure handled safely");
}

safe_forms($fixtures{postnews}, 'post news');
safe_forms($fixtures{newpoll}, 'new poll');
like($fixtures{postnews}, qr/Intro copy \(teaser, shows up on main page\):.*Full copy \(rest of article, do not repeat any of the above\):/s, 'all news field wording retained');
reset_calls();
$html = postNews({submit => 'spell', headline => '"><title>', intro => '<intro>', body => '</textarea><script>body</script>'}, user(1));
$fixtures{'news-spell'} = $html;
is($spell_calls[0], '<intro></textarea><script>body</script>', 'spellcheck receives original intro and body');
unlike($html, qr/<script>|<title>/, 'news form and spellcheck safely retain text');
is(scalar @inserts, 0, 'spellcheck does not publish');
reset_calls();
$html = postNews({submit => 'post', headline => 'Saved headline'}, user(1));
like($html, qr/Need an intro copy\./, 'news validation wording retained');
like($html, qr/value="Saved headline"/, 'news validation retains entered values');
is(scalar @inserts, 0, 'invalid news never inserted');
reset_calls();
$html = postNews({submit => 'post', headline => 'News headline', intro => 'Intro copy', body => ''}, user(1));
$fixtures{'news-added'} = $html;
is($inserts[0]{COLS}, 'uid,created,modified,title,userid,intro,body', 'news insert fields unchanged');
like($inserts[0]{VALUES}, qr/99, now\(\), now\(\), 'News headline',1, 'Intro copy', ''/, 'news briefs still allow empty body');
is_deeply(\@invalidations, ['top_news'], 'news publication refreshes top-news cache');
like($html, qr/News Item Added.*Your post made it\./s, 'news completion page modernized with original wording');
is(form_fields($fixtures{newpoll})->{ttl}, '7', 'poll defaults to seven days');
reset_calls();
$html = addPoll({submit => 'create', question => '<question>', response => 'One,Two', ttl => 'wrong'}, user(1));
$fixtures{'poll-error'} = $html;
like($html, qr/time-to-live is of the wrong format/, 'poll validation wording retained');
is(form_fields($html)->{question}, '<question>', 'poll question retained safely on error');
is(form_fields($html)->{ttl}, 'wrong', 'invalid poll TTL retained');
is(scalar @inserts, 0, 'invalid poll not inserted');
reset_calls();
$html = addPoll({submit => 'create', question => 'Question', response => 'One,Two', ttl => ' 14 '}, user(1));
$fixtures{'poll-created'} = $html;
is($inserts[0]{COLS}, 'uid,userid,start,finish,options,title', 'poll insert fields unchanged');
like($inserts[0]{VALUES}, qr/interval 14  DAY,'One,Two','Question'$/, 'poll responses and duration retain original SQL behavior');
like($html, qr/Poll created.*successfully created/s, 'poll completion page modernized');

reset_calls();
$html = adminStats({}, user(1));
like($html, qr/Cross-references\/Object.*5\.00/s, 'cross-reference ratio preserved');
like($html, qr/Unproven Theorems.*2/s, 'unproven count preserved');
ok(grep($_->[0] eq 'distinct objectid' && $_->[2] eq "valid = 0 and method='make4ht'", @counts), 'invalid-object count remains scoped to make4ht');
ok(grep($_->[0] eq 'distinct objectid' && $_->[2] eq "not build = 0 and method='make4ht'", @counts), 'in-build count remains scoped to make4ht');
like($html, qr/Definition.*Theorem/s, 'all configured object-type statistics retained');
{
    local $object_count = 0;
    like(adminStats({}, user(1)), qr/Undefined/, 'empty database avoids divide-by-zero');
}
my $menu = entryInteractionTemplate('adminmenu.tt', {main_url => 'https://physicslibrary.org'});
for my $op (qw(postnews newpoll adminstats dbadmin cachecont blacklist webstats)) {
    ok(grep(($_->{op} || '') eq $op, links($menu)), "admin menu retains $op link");
}

if (my $dir = $ENV{ADMIN_PAGES_TEST_DIR}) {
    local $blacklist[0]{mask} = 'VeryLongUnbrokenBlacklistMask' x 20;
    $fixtures{'blacklist-long'} = blacklistEditor({}, user(1));
    local $results[0]{title} = 'VeryLongUnbrokenDatabaseValue' x 20;
    $fixtures{'results-long'} = dbAdmin({freeform => 1, query => 'select title from objects'}, user(1));
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    my $adminmenu = entryInteractionTemplate('adminmenu.tt', {main_url => 'https://physicslibrary.org'});
    $tt->process('sidebar.tt', {features => $menu, admin => $adminmenu,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo admin</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    for my $name (sort keys %fixtures) {
        my $page = '';
        $tt->process('view.tt', {title => 'Admin preview', site_name => 'Physics Library', content => $fixtures{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page; close $out;
    }
}
done_testing();
