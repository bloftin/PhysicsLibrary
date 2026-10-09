#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use XML::LibXML;
use URI::Escape qw(uri_escape_utf8);
use lib "$FindBin::Bin/../../lib";
use Noosphere::Sitemap;
use Noosphere::SecurityHeaders;

our ($request, $db, @queries, @bind, $failure, $connects);
our %config = (
    main_url => 'https://physicslibrary.org', en_tbl => 'objects',
    acl_tables => {objects => 1}, acl_tbl => 'acl',
    gmember_tbl => 'group_members', groups_tbl => 'groups',
    robotstxt => "User-agent: *\nDisallow: /cache/\nDisallow: /files/\n",
    bannedips => {}, screen_scrapers => [],
);
our @records = (
    {uid => 209, name => 'VectorTripleProduct', modified => '2026-01-02 03:04:05'},
    {uid => 1081, name => 'ScalarTripleProduct'},
);
{
    package Noosphere;
    use URI::Escape qw(uri_escape_utf8);
    our ($dbh, $DEBUG, $NoosphereTitle, $NoosphereCanonical, $AllowCache, $MAINTENANCE, $stats);
    our ($RequestFormUser, $RequestFormStatus, $RequestFormValidated);
    sub getConfig { return $main::config{$_[0]}; }
    sub dbConnect { $main::connects++; return $main::failure eq 'connect' ? undef : $main::db; }
    sub parseParams { return ($main::request->{params}, {}); }
    sub parseCookies { return (); }
    sub inMaintenance { return 0; }
    sub initStats { die 'Sitemap initialized statistics'; }
    sub handleLogin { die 'Sitemap handled an account'; }
    sub getObj { die 'Sitemap retrieved/rendered an article'; }
    sub getViewTemplateContent { die 'Sitemap rendered a page'; }
    sub requestAccountOriginError { die 'Sitemap entered account handling'; }
    sub dispatch { die 'Unexpected raw dispatch'; }
    sub dwarn { }
}
{
    package Apache2::RequestUtil;
    sub request { return $main::request; }
}
{
    package SitemapHeaders;
    sub set { $_[0]->{$_[1]} = $_[2]; }
}
{
    package SitemapRequest;
    sub uri { return $_[0]->{uri}; }
    sub method { return $_[0]->{method}; }
    sub headers_out { return $_[0]->{headers}; }
    sub status { $_[0]->{status} = $_[1]; }
    sub content_type { $_[0]->{type} = $_[1] if @_ > 1; return $_[0]->{type}; }
    sub print { $_[0]->{body} .= $_[1]; }
}
{
    package SitemapDB;
    sub prepare {
        push @main::queries, $_[1];
        return undef if $main::failure eq 'prepare';
        return bless {position => 0}, 'SitemapRows';
    }
}
{
    package SitemapRows;
    sub execute {
        @main::bind = @_[1 .. $#_];
        return undef if $main::failure eq 'execute';
        return '0E0';
    }
    sub fetchrow_hashref {
        die "Driver fetch detail\n" if $main::failure eq 'throw';
        return undef if $main::failure eq 'fetch';
        if ($main::failure eq 'overflow') {
            return undef if $_[0]->{position} >= 50001;
            my $id = ++$_[0]->{position};
            return {uid => $id, name => "Article$id"};
        }
        return $main::records[$_[0]->{position}++];
    }
    sub err { return $main::failure eq 'fetch' ? 1 : 0; }
    sub finish { return 1; }
}

# Run the real canonical helper, route, and raw robots path without Apache.
for my $spec (
    ['lib/Noosphere/GetObj.pm', 'getEncyclopediaCanonicalURL'],
    ['lib/Noosphere.pm', qw(handler getNoTemplateContent)],
) {
    my ($file, @names) = @$spec;
    open my $in, '<', "$FindBin::Bin/../../$file" or die $!;
    my $source = do { local $/; <$in> };
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless defined $sub;
        eval "package Noosphere; our (\$dbh, \$DEBUG, \$NoosphereTitle, \$NoosphereCanonical, \$AllowCache, \$MAINTENANCE, \$stats, \$RequestFormUser, \$RequestFormStatus, \$RequestFormValidated, %NONTEMPLATE); $sub";
        die $@ if $@;
    }
}

$db = bless {}, 'SitemapDB';
$failure = '';
$Noosphere::MAINTENANCE = 0;
sub fetch_sitemap {
    my ($method, $params) = @_;
    $request = bless {uri => '/sitemap.xml', method => $method || 'GET',
        params => $params || {}, body => '', headers => bless({}, 'SitemapHeaders')}, 'SitemapRequest';
    $connects = 0;
    @queries = ();
    @bind = ();
    local $ENV{REMOTE_ADDR} = '192.0.2.1';
    local $ENV{HTTP_USER_AGENT} = 'Sitemap test';
    Noosphere::handler();
    return $request;
}
sub locations {
    my ($xml) = @_;
    my $doc = XML::LibXML->load_xml(string => $xml);
    my $context = XML::LibXML::XPathContext->new($doc);
    $context->registerNs(s => 'http://www.sitemaps.org/schemas/sitemap/0.9');
    is($doc->documentElement->localname, 'urlset', 'response has a sitemap document root');
    return [map { $_->textContent } $context->findnodes('/s:urlset/s:url/s:loc')];
}

my $r = fetch_sitemap();
is($r->{status}, 200, 'GET sitemap succeeds');
is($r->{type}, 'application/xml;charset=UTF-8', 'XML response has the correct MIME type');
like($r->{body}, qr/\A<\?xml version="1.0" encoding="UTF-8"\?>/, 'XML declares UTF-8');
is_deeply(locations($r->{body}), [
    'https://physicslibrary.org/encyclopedia/VectorTripleProduct.html',
    'https://physicslibrary.org/encyclopedia/ScalarTripleProduct.html',
], 'both missing-from-Google examples use their article canonicals');
is($r->{headers}->{'Content-Length'}, length($r->{body}), 'length is measured in emitted bytes');
is($r->{headers}->{'X-Content-Type-Options'}, 'nosniff', 'standard security headers remain');
ok(!exists $r->{headers}->{'X-Robots-Tag'}, 'sitemap has no search-route noindex header');
ok(!exists $r->{headers}->{'Set-Cookie'}, 'sitemap does not create a session');
unlike($r->{body}, qr/<html|request_form|csrf|<priority>|<changefreq>/,
    'no HTML, account token, or invented crawler metadata');
like($r->{body}, qr{VectorTripleProduct\.html</loc>\s*<lastmod>2026-01-02</lastmod>},
    'actual article edit date is emitted without an invented timezone');
unlike($r->{body}, qr{ScalarTripleProduct\.html</loc>\s*<lastmod>}, 'unknown edit date is omitted');
like($queries[0], qr/SELECT DISTINCT o\.uid, o\.name, o\.modified FROM/, 'modification date uses the existing single metadata query');
is(scalar @queries, 1, 'one metadata query, not a query per article');
unlike($queries[0], qr/\bdata\b|\bpreamble\b|\bcache\b|\bobjindex\b/, 'no content, render cache, or synonym index scan');
is_deeply(\@bind, ['objects', 'objects'], 'ACL table values use bound parameters');
is($connects, 1, 'sitemap route connects only once');
my $normal_body = $r->{body};
$r = fetch_sitemap('HEAD');
is($r->{status}, 200, 'HEAD succeeds');
is($r->{body}, '', 'HEAD emits no body');
is($r->{headers}->{'Content-Length'}, length($normal_body), 'HEAD reports the GET body length');
$r = fetch_sitemap('GET', {op => 'listobj', from => 'collab', id => 9, method => 'make4ht',
    canonical_url => 'https://attacker.invalid', name => 'Private'});
is($r->{body}, $normal_body, 'query parameters cannot alter the sitemap or trigger another operation');
$r = fetch_sitemap('POST', {op => 'delete', id => 209});
is($r->{status}, 405, 'unsupported method is rejected without dispatch');
is($r->{headers}->{Allow}, 'GET, HEAD', 'supported methods are advertised');
is($connects, 0, 'unsupported method makes no database connection');

{
    local @records = (@records, $records[0], {uid => 5, name => ''}, {uid => 6, name => undef},
        {uid => 7, name => 'Caf'.chr(0xe9)}, {uid => 8, name => 'A/B?C#D&"<>'.$/});
    $r = fetch_sitemap();
    is_deeply(locations($r->{body}), [
        'https://physicslibrary.org/encyclopedia/VectorTripleProduct.html',
        'https://physicslibrary.org/encyclopedia/ScalarTripleProduct.html',
        'https://physicslibrary.org/encyclopedia/Caf%C3%A9.html',
        'https://physicslibrary.org/encyclopedia/A%2FB%3FC%23D%26%22%3C%3E%0A.html',
    ], 'duplicates and unnamed rows are omitted; Unicode/reserved characters are path encoded');
}
{
    local $config{main_url} = 'https://example.invalid/library&archive/';
    $r = fetch_sitemap();
    like($r->{body}, qr/library&amp;archive/, 'URL text is XML escaped');
    is(locations($r->{body})->[0], 'https://example.invalid/library&archive/encyclopedia/VectorTripleProduct.html',
        'XML parsing restores the configured canonical URL');
    like(Noosphere::getArticleRobotsText(), qr{Sitemap: https://example.invalid/library&archive/sitemap.xml\n\z},
        'robots uses the deployment origin and trims its trailing slash');
}
my $robots = Noosphere::getNoTemplateContent({op => 'robotstxt'}, {}, {});
like($robots, qr{Sitemap: https://physicslibrary.org/sitemap.xml\n\z}, 'robots handler advertises the sitemap');
like($robots, qr{Disallow: /cache/\nDisallow: /files/}, 'existing robots restrictions are retained');
{
    local @records = ();
    is_deeply(locations(fetch_sitemap()->{body}), [], 'empty encyclopedia still produces well-formed XML');
}
for my $bad_origin ('https://example.invalid/?x=1', 'https://example.invalid/#x',
    'https://user:pass@example.invalid', 'file:///tmp/test', "https://example.invalid/\n") {
    local $config{main_url} = $bad_origin;
    local $SIG{__WARN__} = sub {};
    is(fetch_sitemap()->{status}, 503, 'invalid configured origin fails closed');
}
{
    local $config{en_tbl} = 'objects;DROP TABLE objects';
    local $SIG{__WARN__} = sub {};
    is(fetch_sitemap()->{status}, 503, 'invalid configured SQL identifier fails closed');
    is(scalar @queries, 0, 'invalid identifiers never reach prepare');
}
{
    local @records = ({uid => 1, name => 'x' x 2048});
    local $SIG{__WARN__} = sub {};
    is(fetch_sitemap()->{status}, 503, 'overlong URL is not published as a valid sitemap');
}
for my $error (qw(connect prepare execute fetch throw overflow)) {
    local $failure = $error;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $r = fetch_sitemap();
    is($r->{status}, 503, "$error failure is not a partial 200 sitemap or homepage");
    is($r->{headers}->{'Retry-After'}, 300, 'crawler can retry later');
    is($r->{headers}->{'Cache-Control'}, 'no-store', 'failure is not cached');
    is($r->{body}, "Sitemap temporarily unavailable.\n", 'no driver details or partial article list leak');
    like(join('', @warnings), qr/Article sitemap generation failed/, 'failure is logged');
}

subtest 'public ACL filtering against a real isolated database' => sub {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'Optional SQL integration requires DBI and DBD::SQLite';
    local $db = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0, sqlite_unicode => 1});
    $db->do('CREATE TABLE objects (uid INTEGER, name TEXT, modified TEXT)');
    $db->do('CREATE TABLE acl (tbl TEXT, objectid INTEGER, default_or_normal TEXT, user_or_group TEXT, subjectid INTEGER, _read INTEGER)');
    $db->do('CREATE TABLE group_members (userid INTEGER, groupid INTEGER)');
    $db->do('CREATE TABLE groups (groupid INTEGER)');
    $db->do('INSERT INTO groups VALUES (4)');
    $db->do('INSERT INTO group_members VALUES (-1,4)');
    my @names = qw(Public Private NoACL AnonymousDenied OtherUserDenied GroupDenied OtherGroupDenied ConflictingDefaults NullRead PapersOnly EmptyName SentinelDenied Orphan);
    for my $i (0 .. $#names) {
        $db->do('INSERT INTO objects (uid,name) VALUES (?,?)', undef, $i + 1, $names[$i]);
    }
    $db->do('UPDATE objects SET name = ? WHERE uid = 11', undef, '');
    for my $row (
        ['objects',1,'d','u',0,1], ['objects',2,'d','u',0,0],
        ['objects',4,'d','u',0,1], ['objects',4,'n','u',-1,0],
        ['objects',5,'d','u',0,1], ['objects',5,'n','u',99,0],
        ['objects',6,'d','u',0,1], ['objects',6,'n','g',4,0],
        ['objects',7,'d','u',0,1], ['objects',7,'n','g',99,0],
        ['objects',8,'d','u',0,1], ['objects',8,'d','u',0,0],
        ['objects',9,'d','u',0,undef], ['papers',10,'d','u',0,1],
        ['objects',11,'d','u',0,1], ['objects',12,'d','u',0,1],
        ['objects',12,'n','g',-1,0], ['objects',13,'d','u',0,1],
    ) {
        $db->do('INSERT INTO acl VALUES (?,?,?,?,?,?)', undef, @$row);
    }
    $r = fetch_sitemap();
    is($r->{status}, 200, 'real SQL executes successfully');
    is_deeply(locations($r->{body}), [map { "https://physicslibrary.org/encyclopedia/$_.html" }
        qw(Public OtherUserDenied OtherGroupDenied Orphan)],
        'private/missing/conflicting/anonymous-denied ACLs are excluded; unrelated user/group denials and public orphans remain');
    $db->do('INSERT INTO objects (uid,name) VALUES (209,?)', undef, 'VectorTripleProduct');
    $db->do('INSERT INTO acl VALUES (?,?,?,?,?,?)', undef, 'objects',209,'d','u',0,1);
    like(fetch_sitemap()->{body}, qr/VectorTripleProduct\.html/, 'new public article appears without cron, rendering, or cache rebuild');
    $db->do('UPDATE objects SET modified = ? WHERE uid = 209', undef, '2026-02-03 04:05:06');
    like(fetch_sitemap()->{body}, qr{VectorTripleProduct\.html</loc>\s*<lastmod>2026-02-03</lastmod>},
        'real content edit appears in the next sitemap without a rebuild');
    $db->do('DELETE FROM objects WHERE uid = 209');
    unlike(fetch_sitemap()->{body}, qr/VectorTripleProduct/, 'deleted article disappears on the next fetch');
    $db->do('UPDATE acl SET _read = 0 WHERE tbl = ? AND objectid = 1', undef, 'objects');
    unlike(fetch_sitemap()->{body}, qr{/Public\.html}, 'newly private article disappears without a cached public response');
    {
        local $config{acl_tables} = {};
        is(scalar @{locations(fetch_sitemap()->{body})}, 12, 'deployments without article ACLs include all named articles');
    }
    $db->do('DROP TABLE acl');
    local $SIG{__WARN__} = sub {};
    is(fetch_sitemap()->{status}, 503, 'real SQL failure cannot disclose a partial sitemap');
};

subtest 'trustworthy calendar dates only' => sub {
    my $now = 1791507931; # 2026-10-09 UTC
    for my $value ('2026-10-03', '2026-10-03 12:34:56', '2026-10-03T12:34:56Z',
        '2026-10-03 12:34:56.123456+00') {
        is(Noosphere::getArticleLastmod($value, $now), '2026-10-03', 'stored date is retained, not generation time');
    }
    is(Noosphere::getArticleLastmod('2024-02-29 12:00:00', $now), '2024-02-29', 'leap day is valid');
    is(Noosphere::getArticleLastmod('2000-02-29', $now), '2000-02-29', '400-year leap day is valid');
    for my $bad (undef, '', '0000-00-00 00:00:00', '2026-02-29', '1900-02-29',
        '2026-04-31', '2026-00-10', '2026-13-10', '2026-01-00', '2026-01-02 24:00:00',
        '2026-01-02 12:60:00', '2026-01-02 12:00:60', '2026-01-02T12:00:00+99:99',
        '2026-01-02T12:00:00+14:01', '2099-01-01', '2026-10-10', '2026-01-02<script>', []) {
        is(Noosphere::getArticleLastmod($bad, $now), '', 'unknown, invalid or future timestamp is omitted');
    }
};

done_testing();
