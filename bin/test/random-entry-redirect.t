#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use URI::Escape qw(uri_escape_utf8);
use Encode ();

our ($dbh, $DEBUG, $NoosphereTitle, $AllowCache, $MAINTENANCE, $stats);
my $dbms = 'MariaDB';
my $main_url = 'https://physicslibrary.org';
my @rows;
my @queries;
my $params;
my $request;
my $logins;
sub getConfig {
    return {en_tbl => 'objects', dbms => $dbms, main_url => $main_url,
        bannedips => {}, screen_scrapers => []}->{$_[0]};
}
sub getMethods { return qw(make4ht pdf png src l2h); }
sub dbEval { push @queries, $_[0]; return shift @rows; }
sub errorMessage { return $_[0]; }
sub dwarn { }
sub writeFile { }
sub parseParams { return ($params, {}); }
sub parseCookies { return (); }
sub inMaintenance { return 0; }
sub dbConnect { return 'test database'; }
sub initStats { $stats = 1; }
sub handleLogin { $logins++; return (uid => -1); }
sub getNoTemplateContent { die 'Random request reached template processing'; }
sub getObj { die 'Random request rendered an article before redirecting'; }

{ package Apache2::RequestUtil;
  sub request { return $request; }
}
{ package RandomHeaders;
  sub set { $_[0]->{$_[1]} = $_[2]; }
  sub add { $_[0]->{$_[1]} = $_[2]; }
}
{ package RandomRequest;
  sub new { bless {headers => bless({}, 'RandomHeaders'), body => ''}, shift; }
  sub headers_out { $_[0]->{headers}; }
  sub uri { return '/'; }
  sub status { $_[0]->{status} = $_[1]; }
  sub content_type { $_[0]->{type} = $_[1] if @_ > 1; return $_[0]->{type}; }
  sub print { $_[0]->{body} .= $_[1]; }
  sub rflush { }
}

# Exercise the actual request routing and response writer without Apache or a DB.
for my $spec (
    ['lib/Noosphere.pm', qw(handler sendOutput)],
    ['lib/Noosphere/Encyclopedia.pm', qw(serveRandomEntry)],
) {
    my ($file, @subs) = @$spec;
    open my $in, '<', "$FindBin::Bin/../../$file" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    for my $name (@subs) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name not found" unless defined $sub;
        eval $sub;
        die $@ if $@;
    }
}

sub random_request {
    my ($name, $extra, $count) = @_;
    @rows = (defined($count) ? $count : 1, $name);
    @queries = ();
    $params = {op => 'randomentry', %{$extra || {}}};
    $request = RandomRequest->new;
    $logins = 0;
    local $ENV{REMOTE_ADDR} = '192.0.2.1';
    handler();
    return $request;
}

for my $backend (qw(MariaDB mysql pg)) {
    $dbms = $backend;
    subtest "$dbms canonical redirect" => sub {
        my $r = random_request('InvertibleMatrix');
        is($r->{status}, 302, 'temporary redirect');
        is($r->{headers}->{Location}, "$main_url/encyclopedia/InvertibleMatrix.html",
            'address bar receives the canonical article URL');
        is($r->{headers}->{'Cache-Control'}, 'no-store', 'selection cannot be cached');
        is($r->{body}, '', 'no article or page shell in redirect response');
        is($r->{headers}->{'content-length'}, 0, 'empty response length');
        is($logins, 1, 'normal login and cookie handling still runs');
        is_deeply($params, {op => 'randomentry'}, 'request parameters are not rewritten');
        is($queries[0], 'count(*) from objects', 'counts encyclopedia entries');
        is($queries[1], $dbms eq 'pg' ? 'name from objects limit 1 offset 0'
            : 'name from objects limit 0,1', 'selects name with the correct DB syntax');
    };
}

for my $method (getMethods()) {
    my $r = random_request('InvertibleMatrix', {method => $method, id => 9,
        name => 'Unrelated', from => 'collab'});
    is($r->{headers}->{Location}, "$main_url/encyclopedia/InvertibleMatrix.html?method=$method",
        "$method preserved without unrelated parameters");
}
my $r = random_request('InvertibleMatrix', {method => "pdf\r\nX-Test: yes"});
is($r->{headers}->{Location}, "$main_url/encyclopedia/InvertibleMatrix.html",
    'invalid renderer is omitted');

$main_url .= '/';
$r = random_request("A/B?C#D\r\n");
is($r->{headers}->{Location},
    'https://physicslibrary.org/encyclopedia/A%2FB%3FC%23D%0D%0A.html',
    'canonical name is encoded as a path segment and base slash normalized');

$r = random_request('InvertibleMatrix', {}, 10);
like($queries[1], qr/offset [0-9]$/, 'random index remains within entry count');

$r = random_request(undef, {}, 0);
is($r->{status}, 404, 'empty encyclopedia returns a clear failure');
is(scalar(@queries), 1, 'empty encyclopedia does not query a random offset');
ok(!exists $r->{headers}->{Location}, 'empty encyclopedia has no redirect');
like($r->{body}, qr/No encyclopedia entries/, 'empty encyclopedia explanation');

for my $name (undef, '') {
    $r = random_request($name);
    is($r->{status}, 404, 'missing selection returns a clear failure');
    ok(!exists $r->{headers}->{Location}, 'missing selection has no broken redirect');
}

done_testing();
