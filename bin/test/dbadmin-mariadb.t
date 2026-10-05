#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;

our $dbh;
my $root = "$FindBin::Bin/../..";
our %config = (dbms => 'MariaDB', access_admin => 100,
    main_url => 'https://physicslibrary.org', template_path => "$root/stemplates");
our (@queries, @executions, @finished);
our ($failure, $result_rows, $table_names) = ('',
    [{uid => 1, title => 'Vector <Triple> & "Product"', oid => 42, _key => 'visible private key'}],
    [qw(objects users cache), 'weird`table']);
sub getConfig { $config{$_[0]} }
sub noAccess { 'Insufficient access.' }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub urlescape { uri_escape_utf8($_[0]) }
sub urlunescape { uri_unescape($_[0]) }
sub source {
    open my $fh, '<', $_[0] or die $!;
    return do {local $/; <$fh>};
}
sub dbLowLevelSelect {
    my ($handle, $sql) = @_;
    push @queries, $sql;
    my $rows = $sql =~ /pg_attribute.attname as colname/ ?
        [{colname => 'uid', typename => 'int', notnull => 1, default => '[none]'}] : [];
    return (1, bless {sql => $sql, rows => $rows, NUM_OF_FIELDS => 4}, 'DBAdminTestStatement');
}
{
    package DBAdminTestDB;
    sub prepare {
        my ($self, $sql) = @_;
        push @queries, $sql;
        return if $failure eq 'prepare';
        my ($rows, $fields);
        if ($sql =~ /information_schema\.TABLES/) {
            $rows = [map {[$_]} @$table_names]; $fields = 1;
        } elsif ($sql =~ /information_schema\.COLUMNS/) {
            $rows = [{colname => 'uid', typename => 'int(11)', notnull => 1, default => undef},
                {colname => 'title', typename => 'varchar(255)', notnull => 0, default => "'<default>'"}];
            $fields = 4;
        } elsif ($sql =~ /information_schema\.STATISTICS/) {
            $rows = [{indname => 'PRIMARY', oncol => 'uid', primary => 1, unique => 1},
                {indname => 'composite', oncol => 'uid', primary => 0, unique => 1},
                {indname => 'composite', oncol => 'title', primary => 0, unique => 1}];
            $fields = 4;
        } elsif ($sql =~ /^select count\(\*\) as cnt/i) {
            $rows = [{cnt => 12}]; $fields = 1;
        } else {
            $fields = $sql =~ /^\s*(?:select|show|describe|with|\/\*)/i ? 4 : 0;
            $rows = $fields ? [map {{%$_}} @$result_rows] : [];
        }
        return bless {sql => $sql, rows => $rows, NUM_OF_FIELDS => $fields}, 'DBAdminTestStatement';
    }
    sub quote_identifier { my $name = $_[1]; $name =~ s/`/``/g; return '`'.$name.'`'; }
    sub errstr { 'Driver error <invalid> & "SQL"' }
    sub tables { return ('public.objects', 'public.users'); }
    package DBAdminTestStatement;
    sub execute {
        push @executions, [$_[0]->{sql}, @_[1..$#_]];
        return if $failure eq 'execute';
        return '0E0';
    }
    sub fetchrow_hashref { $_[0]->{rows}[$_[0]->{pos}++] }
    sub fetchall_arrayref { return if $failure eq 'fetch'; return $_[0]->{rows}; }
    sub err { $failure eq 'fetch' ? 1 : 0 }
    sub errstr { 'Fetch error <partial>' }
    sub finish { push @finished, $_[0]->{sql}; }
}
$dbh = bless {RaiseError => 1, PrintError => 1}, 'DBAdminTestDB';
for my $spec (['Admin', qw(dbAdmin printTabular printResultRows)], ['DB', qw(dbGetTables dbGetSchema dbGetRows)]) {
    my ($module, @names) = @$spec;
    my $source = source("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body; die $@ if $@;
    }
}
sub user { {uid => 1, ticket => 'a' x 64, data => {access => 100, active => 1}} }
sub reset_calls { @queries = (); @executions = (); @finished = (); }
for my $driver (qw(MariaDB mysql)) {
    local $config{dbms} = $driver;
    reset_calls();
    is_deeply([dbGetTables($dbh)], $table_names, "$driver returns raw table names, not quoted catalog-qualified names");
    like($queries[0], qr/TABLE_SCHEMA = DATABASE\(\)/, "$driver table list is scoped to current database");
    is(scalar @finished, 1, "$driver releases table-list statement");
    reset_calls();
    my ($cols, $indices) = dbGetSchema($dbh, 'weird`table');
    is_deeply([map {$_->{colname}} @$cols], [qw(uid title)], "$driver retains column ordering");
    is($cols->[0]{default}, '[none]', "$driver displays missing defaults");
    is($cols->[1]{default}, "'<default>'", "$driver retains literal defaults");
    is_deeply([map {$_->{oncol}} @$indices], [qw(uid uid title)], "$driver retains all composite-index columns");
    is_deeply([map {$_->[1]} @executions], ['weird`table', 'weird`table'], "$driver binds table name in both metadata lookups");
    like($queries[0], qr/ORDER BY ORDINAL_POSITION/, "$driver explicitly orders columns");
    like($queries[1], qr/ORDER BY INDEX_NAME, SEQ_IN_INDEX/, "$driver explicitly orders index columns");
    is(scalar @finished, 2, "$driver releases schema statements");
    for my $query (
        'select uid from users;',
        'SELECT COUNT(*) AS article_count FROM objects;',
        'SELECT CoUnT(*) FROM objects;',
        'SELECT method, COUNT(*) AS total FROM cache GROUP BY method;',
        'SELECT title FROM `objects` LIMIT 5;',
        "SELECT title\nFROM objects\nWHERE uid = 209;",
        'SELECT o.title FROM objects AS o JOIN users AS u ON o.userid=u.uid;',
        'WITH recent AS (SELECT uid FROM objects) SELECT uid FROM recent;',
        '/* inspect */ SELECT uid FROM objects;',
        'SHOW TABLES;', 'DESCRIBE objects;',
        'SELECT 1 AS healthy;', 'SELECT uid FROM objects UNION SELECT uid FROM users;'
    ) {
        reset_calls();
        my $html = dbAdmin({freeform => 1, query => $query}, user());
        is($queries[-1], $query, "$driver executes SQL unchanged: $query");
        like($html, qr/Results \(1\)/, "$driver recognizes rowsets by statement metadata");
        unlike($html, qr/name="(?:update|delete|oid|col_uid)"/, "$driver never offers legacy inline editing");
    }
    for my $action (qw(update delete)) {
        reset_calls();
        like(dbAdmin({$action => 1, table => 'objects', oid => 42, col_title => 'changed'}, user()),
            qr/Inline row editing is not available/, "$driver rejects forged legacy $action requests");
        ok(!grep(/^\s*(update|delete)/i, @queries), "$driver rejects $action before mutation");
    }
}
reset_calls();
my $html = dbAdmin({freeform => 1, query => 'SELECT * FROM objects LIMIT 1;'}, user());
like($html, qr/Vector &lt;Triple&gt; &amp; &quot;Product&quot;/, 'result values are escaped');
like($html, qr/visible private key/, 'underscore-prefixed result columns are not hidden by Template Toolkit');
like($html, qr/<th scope="col">oid<\/th>/, 'real OID-named data is displayed, not used as row identity');
unlike($html, qr/<script>/, 'results cannot inject markup');
my $decorated = requestFormDecorate($html, user());
is(scalar(() = $decorated =~ /name="_form_token"/g), 2, 'query and table-info forms retain CSRF tokens');
reset_calls();
$html = dbAdmin({schema => 1, table => 'weird`table'}, user());
like($html, qr/Schema for table.*varchar\(255\).*composite.*Rows in table.*12/s, 'MariaDB table information renders columns, indexes, and count');
is($queries[-1], 'select count(*) as cnt from `weird``table`', 'row count quotes table identifier');
like($html, qr/&#39;&lt;default&gt;&#39;/, 'metadata defaults are escaped');
reset_calls();
like(dbAdmin({schema => 1, table => 'objects; DELETE FROM users'}, user()), qr/Unknown table/, 'table-info endpoint rejects unknown names');
is(scalar @queries, 1, 'unknown table runs only metadata table listing');
reset_calls();
{
    local $result_rows = [];
    like(dbAdmin({freeform => 1, query => 'SELECT uid FROM users WHERE 1=0;'}, user()), qr/No matching rows\./, 'uppercase empty SELECT has explicit empty state');
}
reset_calls();
like(dbAdmin({freeform => 1, query => "UPDATE objects SET title='unchanged' WHERE 1=0;"}, user()),
    qr/Query successful \(0 rows affected\)/, 'zero-row command success is not treated as an error');
is($queries[-1], "UPDATE objects SET title='unchanged' WHERE 1=0;", 'explicit command runs unchanged');
for my $failure_kind (qw(prepare execute fetch)) {
    local $failure = $failure_kind;
    reset_calls();
    $html = dbAdmin({freeform => 1, query => 'SELECT uid FROM users;'}, user());
    like($html, qr/(?:Driver|Fetch) error &lt;/, "$failure_kind failure displays escaped error without crashing");
    unlike($html, qr/Results \(/, "$failure_kind failure does not display partial results");
    ok(@finished || $failure_kind eq 'prepare', "$failure_kind failure releases allocated statement");
    reset_calls();
    my ($cols, $indices) = dbGetSchema($dbh, 'objects');
    ok(!defined($cols) && !defined($indices), "$failure_kind metadata failure is returned safely");
    is_deeply([dbGetTables($dbh)], [], "$failure_kind table-list failure is returned safely");
}
is($dbh->{RaiseError}, 1, 'admin queries restore connection exception policy');
is($dbh->{PrintError}, 1, 'admin queries restore connection logging policy');
reset_calls();
like(dbAdmin({freeform => 1, query => 'DELETE FROM objects;'}, {data => {access => 0}}), qr/Insufficient access/, 'non-admin queries denied');
is(scalar @queries, 0, 'authorization precedes metadata and query execution');
{
    local $config{dbms} = 'pg';
    is_deeply([dbGetTables($dbh)], ['public.objects', 'public.users'], 'PostgreSQL table list behavior retained');
    reset_calls();
    my ($cols, $indices) = dbGetSchema($dbh, 'objects');
    is($cols->[0]{colname}, 'uid', 'PostgreSQL schema path retained');
    like($queries[0], qr/pg_attribute/, 'PostgreSQL uses its existing catalog lookup');
    reset_calls();
    dbAdmin({freeform => 1, query => 'SELECT COUNT(*) AS article_count FROM objects;'}, user());
    is($queries[-1], 'SELECT COUNT(*) AS article_count FROM objects;', 'uppercase PostgreSQL aggregate is not rewritten');
    reset_calls();
    dbAdmin({freeform => 1, query => 'select uid from users'}, user());
    is($queries[-1], 'select uid, users.oid from users', 'legacy PostgreSQL OID query behavior retained');
}
if (my $dir = $ENV{DBADMIN_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my $page = '';
    $tt->process('view.tt', {title => 'Database Admin test', content => $decorated,
        sidebar => '<div style="font-family:Arial;background:#003399;color:white;padding:.15rem .5rem">Demo admin</div>'}, \$page) or die $tt->error;
    open my $out, '>', "$dir/dbadmin-results.html" or die $!;
    print {$out} $page; close $out;
}
done_testing();
