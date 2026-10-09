#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Template;
use URI::Escape qw(uri_escape_utf8);

our ($dbh, $DEBUG, $NoosphereTitle, $NoosphereCanonical, $AllowCache, $MAINTENANCE, $stats);
our ($RequestFormUser, $RequestFormStatus, $RequestFormValidated);
my $main_url = 'https://physicslibrary.org';
my $permitted = 1;
my $request;
my @queries;
my %records = (
    209 => {uid => 209, name => 'VectorTripleProduct', title => 'Vector Triple Product', userid => -1},
    1081 => {uid => 1081, name => 'ScalarTripleProduct', title => 'scalar triple product', userid => -1},
);
sub getConfig {
    return {main_url => $main_url, en_tbl => 'objects', projname => 'Physics Library',
        papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec', news_tbl => 'news',
        collab_tbl => 'collab', forum_tbl => 'forums', polls_tbl => 'polls', req_tbl => 'requests',
        user_tbl => 'users', cor_tbl => 'corrections', bug_url => '/bugs',
        bannedips => {}, screen_scrapers => []}->{$_[0]};
}
sub getidbyname {
    return {VectorTripleProduct => 209, OldVectorTitle => 209, ScalarTripleProduct => 1081}->{$_[0]} // -1;
}
sub dbSelect {
    my ($db, $query) = @_;
    push @queries, $query;
    my ($id) = $query->{WHERE} =~ /^uid=(\d+)$/;
    return (1, bless({rec => $records{$id}}, 'CanonicalRows'));
}
sub hasPermissionTo { return $permitted; }
sub errorMessage { return '<p>Error: '.$_[0].'</p>'; }
sub getAddr { return 'feedback@example.invalid'; }
sub nb { return defined($_[0]) && $_[0] ne ''; }
sub TeXtoUTF8 { return $_[0]; }
sub changeWatch { }
sub hitObject { }
sub get_lastseen { return 0; }
sub get_lastmsg { return 0; }
sub update_lastseen { }
sub getMessages { return ''; }
sub clearBox { return $_[1]; }
sub makeBox { return $_[1]; }
sub entryInteractionSection { return $_[1]; }
sub getEncyclopediaAdminControls { return ''; }
sub getEncyclopediaInteract { return ''; }
sub getPendingCorrections { return ''; }
sub getGenericAdmin { return ''; }
sub getOwnerControls { return ''; }
sub getWatchWidget { return ''; }
sub renderEncyclopediaObj { return bless {}, 'CanonicalContent'; }
sub renderGeneric { return bless {}, 'CanonicalContent'; }
sub parseParams { return ({%{$_[0]->{params}}}, {}); }
sub parseCookies { return (); }
sub inMaintenance { return 0; }
sub dbConnect { return 'test database'; }
sub initStats { $stats = 1; }
sub requestAccountOriginError { return ''; }
sub handleLogin { return (uid => -1); }
sub getNoTemplateContent { return ''; }
sub getViewTemplateContent {
    return $_[0]->{op} eq 'getobj' ? getObj(@_) : '<p>Other page</p>';
}
sub fillInLeftBar { return ''; }
sub sendOutput { $_[0]->{body} = $_[1]; }
sub dwarn { }
{
    package CanonicalRows;
    sub rows { return $_[0]->{rec} ? 1 : 0; }
    sub fetchrow_hashref { return {%{$_[0]->{rec}}}; }
}
{
    package CanonicalContent;
    sub setKey { }
    sub expand { return '<p>Article content</p>'; }
}
{
    package TemplateNS;
    sub new { return bless {}, shift; }
    sub setKey { }
    sub expand { return ''; }
}
{
    package Apache2::RequestUtil;
    sub request { return $request; }
}
{
    package CanonicalHeaders;
    sub set { $_[0]->{$_[1]} = $_[2]; }
}
{
    package CanonicalRequest;
    sub uri { return $_[0]->{uri}; }
    sub content_type { return 'text/html'; }
    sub headers_out { return $_[0]->{headers}; }
}

# Execute the real object retrieval, routing, and shared template with synthetic services.
for my $spec (
    ['lib/Noosphere/GetObj.pm', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj)],
    ['lib/Noosphere.pm', qw(handler applyIndexingPolicy)],
) {
    my ($file, @names) = @$spec;
    open my $in, '<', "$FindBin::Bin/../../$file" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless defined $sub;
        eval $sub;
        die $@ if $@;
    }
}

my $new = Template->can('new');
{
    no warnings qw(redefine once);
    *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$FindBin::Bin/../../stemplates"}) };
}
sub page {
    my ($uri, $params) = @_;
    $request = bless {uri => $uri, params => $params,
        headers => bless({}, 'CanonicalHeaders')}, 'CanonicalRequest';
    local $ENV{REMOTE_ADDR} = '192.0.2.1';
    local $ENV{HTTP_USER_AGENT} = 'Canonical test';
    @queries = ();
    handler();
    return $request->{body};
}
sub canonical_is {
    my ($html, $url, $label) = @_;
    my @links = $html =~ /<link rel="canonical" href="([^"]+)"\s*\/>/g;
    is_deeply(\@links, [$url], "$label has exactly one canonical");
    like($html, qr{<head>.*<link rel="canonical".*</head>}s, 'canonical is in the document head');
    unlike($html, qr/name="robots" content="noindex/, 'article remains indexable');
    ok(!exists $request->{headers}->{'X-Robots-Tag'}, 'article has no noindex header');
    is(scalar @queries, 1, 'canonical uses the existing object lookup without another query');
}

my $vector = "$main_url/encyclopedia/VectorTripleProduct.html";
my $scalar = "$main_url/encyclopedia/ScalarTripleProduct.html";
$NoosphereCanonical = 'outer metadata';
for my $case (
    ['/encyclopedia/VectorTripleProduct.html', {}],
    ['/Encyclopedia/VectorTripleProduct.htm', {}],
    ['/VectorTripleProduct.html', {}],
    ['/encyclopedia/209.html', {}],
    ['/', {op => 'getobj', from => 'objects', id => 209}],
    ['/', {op => 'getobj', from => 'objects', name => 'VectorTripleProduct'}],
    ['/', {op => 'getobj', from => 'objects', name => 'OldVectorTitle'}],
) {
    canonical_is(page(@$case), $vector, $case->[0]);
    is($NoosphereCanonical, 'outer metadata', 'handler restores metadata on return');
}
for my $method (qw(make4ht l2h png pdf src)) {
    canonical_is(page('/', {op => 'getobj', from => 'objects', id => 209,
        method => $method, offset => 50, total => 100, sort => 'created_desc',
        canonical_url => 'https://attacker.invalid/', name_unused => 'Unrelated'}),
        $vector, "$method and unrelated parameters");
}
canonical_is(page('/encyclopedia/ScalarTripleProduct.html', {}), $scalar, 'next article');

for my $case (
    ['/', {op => 'getobj', from => 'unknown', id => 209}],
    ['/', {op => 'getobj', from => 'objects', id => -2}],
    ['/', {op => 'getobj', from => 'objects', id => 99999}],
    ['/', {op => 'getobj', from => 'objects', name => 'Missing'}],
    ['/', {op => 'getobj', from => 'books', id => 209}],
    ['/', {op => 'getobj', from => 'papers', id => 209}],
    ['/', {op => 'getobj', from => 'lec', id => 209}],
    ['/', {op => 'listobj', from => 'objects', canonical_url => $vector}],
    ['/', {op => 'getrefs', from => 'objects', id => 209}],
) {
    unlike(page(@$case), qr/rel="canonical"/, 'non-article or failed lookup has no article canonical');
}
is($request->{headers}->{'X-Robots-Tag'}, undef, 'ordinary helper policy is unchanged');
page('/', {op => 'listobj', from => 'objects'});
is($request->{headers}->{'X-Robots-Tag'}, 'noindex, follow', 'listing noindex policy remains intact');
$permitted = 0;
unlike(page('/encyclopedia/VectorTripleProduct.html', {}), qr/rel="canonical"/,
    'permission failure has no article canonical');
$permitted = 1;

is(getEncyclopediaCanonicalURL('objects', {name => undef}), '', 'unnamed article has no broken canonical');
is(getEncyclopediaCanonicalURL('objects', {name => ''}), '', 'empty name has no broken canonical');
$main_url .= '/';
is(getEncyclopediaCanonicalURL('objects', $records{209}), $vector, 'trailing base slash is normalized');
is(getEncyclopediaCanonicalURL('objects', {name => 'A/B?C#D&"'}),
    'https://physicslibrary.org/encyclopedia/A%2FB%3FC%23D%26%22.html', 'name is encoded as one path segment');
is(getEncyclopediaCanonicalURL('objects', {name => 'Caf'.chr(0xe9)}),
    'https://physicslibrary.org/encyclopedia/Caf%C3%A9.html', 'Unicode name is UTF-8 encoded');

my $html = '';
Template->new->process('view.tt', {canonical_url => 'https://example.invalid/?a=1&b="x"'}, \$html)
    or die Template->new->error;
like($html, qr{href="https://example\.invalid/\?a=1&amp;b=&quot;x&quot;"}, 'canonical attribute is HTML escaped');

done_testing();
