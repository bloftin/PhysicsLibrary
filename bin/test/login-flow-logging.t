#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::Login;
use Noosphere::Cookies;
use Encode ();
use bytes ();

{
    package Noosphere;
    sub getConfig { return 'users' if $_[0] eq 'user_tbl'; }
}

{
    package LoginLogRequest;
    sub method { $_[0]->{method} || 'GET' }
    sub unparsed_uri { $_[0]->{uri} || '/' }
    sub header_in { $_[0]->{headers}{$_[1]} }
    sub headers_out { $_[0]->{out} ||= bless {}, 'LoginLogHeaders' }
    sub status { $_[0]->{status} = $_[1] }
    sub content_type { $_[0]->{content_type} = $_[1] if @_ > 1; $_[0]->{content_type} }
    sub print { $_[0]->{body} = $_[1] }
    sub rflush { 1 }
    package LoginLogHeaders;
    sub set { $_[0]->{$_[1]} = $_[2] }
    sub add { $_[0]->{$_[1]} = $_[2] }
}

sub fixture {
    my (%args) = @_;
    return bless {headers => {}, %args}, 'LoginLogRequest';
}

sub capture {
    my ($code) = @_;
    my @lines;
    local $SIG{__WARN__} = sub { push @lines, @_ };
    $code->();
    return join('', @lines);
}

subtest 'opt-in, scoped request metadata only' => sub {
    is(Noosphere::LoginLog::context(0, undef, undef, undef), undef, 'disabled logging does not inspect the request');
    my $req = fixture(method => 'POST', uri => '/?private=do-not-log', headers => {
        Cookie => '__Host-pl_session=' . ('a' x 64),
        'Content-Length' => '123',
        'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
    });
    my $params = {op => 'login', user => "private-user\nInjected", passwd => 'private-password',
        url => '/?secret=private-return', private => 'private-form'};
    local $Noosphere::LoginLog::CURRENT = Noosphere::LoginLog::context(1, $req, $params, {ticket => 'a' x 64});
    my $text = capture(sub {
        Noosphere::LoginLog::emit('request', 'begin');
        Noosphere::LoginLog::emit('response', 303);
        Noosphere::LoginLog::emit('private-stage', 'private-event');
        Noosphere::LoginLog::emit('credentials', "error\nInjected");
    });
    is(scalar(() = $text =~ /^PL_LOGIN /mg), 2, 'only permitted stage and outcome pairs logged');
    like($text, qr/method=POST route=page op=login cookie=present encoding=urlencoded body=1 user_field=1 passwd_field=1 /,
        'only fixed categories and field presence recorded');
    like($text, qr/stage=response event=303 elapsed_ms=\d+\n/, 'response status and timing recorded');
    unlike($text, qr/private|Injected|a{64}|Cookie:|SELECT|__Host/i, 'credentials, cookie values, URLs and unknown supplied data absent');
    my @traces = $text =~ /trace=(\S+)/g;
    is($traces[0], $traces[1], 'stages in one request share a trace');
    my $another = Noosphere::LoginLog::context(1, $req, $params, {});
    isnt($another->{trace}, $traces[0], 'next request receives a distinct trace');
    is($another->{cookie}, 'unusable', 'cookie name received but rejected by parser is distinguishable');
    is(Noosphere::LoginLog::context(1, fixture(uri => '/encyclopedia/Example.html'), {}, {}), undef,
        'anonymous article requests are not traced');
    is(Noosphere::LoginLog::context(1, fixture(uri => '/?op=about'), {op => 'about'}, {}), undef,
        'anonymous non-homepage GET is not traced');
    my $lost = Noosphere::LoginLog::context(1, fixture(method => 'POST', headers => {'Content-Length' => 80}), {}, {});
    is($lost->{route}, 'home', 'homepage POST with missing parsed operation is included');
    is($lost->{op}, 'none', 'missing operation distinguished from login');
    is($lost->{body}, 1, 'body advertised but not logged');
    is($lost->{user_field}, 0, 'missing parsed credential fields visible');
    my $logout = Noosphere::LoginLog::context(1, fixture(method => 'POST'), {op => 'logout'}, {});
    is($logout->{op}, 'logout', 'logout POSTs cannot be confused with login POSTs');
    my $other = Noosphere::LoginLog::context(1, fixture(method => 'POST'), {op => 'private-operation'}, {});
    is($other->{op}, 'other', 'unrecognized operation value not retained');
    my $injected = Noosphere::LoginLog::context(1, fixture(method => "POST\nInjected", headers => {
        'Content-Type' => "private-content-type\nInjected", 'Content-Length' => "5\nInjected"}), {}, {});
    is($injected->{method}, 'other', 'method cannot inject log content');
    is($injected->{encoding}, 'other', 'content type cannot inject log content');
    is($injected->{body}, 0, 'malformed length cannot inject log content');
};

subtest 'logging cannot change exception state or authentication outcomes' => sub {
    local $Noosphere::LoginLog::CURRENT = Noosphere::LoginLog::context(1, fixture(), {}, {});
    $@ = 'existing exception';
    $! = 2;
    $? = 7;
    my $errno = 0 + $!;
    my $text = capture(sub { Noosphere::LoginLog::emit('request', 'begin') });
    is($@, 'existing exception', 'exception state preserved');
    is(0 + $!, $errno, 'errno preserved');
    is($?, 7, 'child status preserved');
    like($text, qr/PL_LOGIN /, 'record was produced');
    {
        local $SIG{__WARN__} = sub { die "logging unavailable\n" };
        eval { Noosphere::LoginLog::emit('request', 'begin'); 1 };
        is($@, '', 'logging sink failure cannot interrupt a request');
    }
    no warnings qw(redefine once);
    local *Noosphere::dbSelectRowBound = sub { die "private SQL error private-password\n" };
    $text = capture(sub {
        ok(!defined(Noosphere::findLoginUser('private-user', 'private-password')), 'database failure still rejects credentials');
        is(Noosphere::checkTicket('b' x 64), -1, 'session database failure still fails closed');
    });
    like($text, qr/stage=credentials event=error/, 'credential lookup failure is distinguishable from rejection');
    like($text, qr/stage=session_lookup event=error/, 'previously silent session lookup failure logged');
    unlike($text, qr/private|SQL|b{64}/, 'caught exception and credential values not logged');
    local $Noosphere::LoginLog::CURRENT;
    is(capture(sub { Noosphere::checkTicket('b' x 64) }), '', 'disabled diagnostics remain silent even on a database failure');
};

subtest 'login, cookie issuance, and session-check outcomes' => sub {
    my $req = fixture(method => 'POST');
    my $params = {op => 'login', user => 'private-user', passwd => 'private-password'};
    local $Noosphere::LoginLog::CURRENT = Noosphere::LoginLog::context(1, $req, $params, {});
    no warnings qw(redefine once);
    local *Noosphere::sessionTime = sub { 2000000000 };
    local *Noosphere::getUserData = sub { return {} };
    local *Noosphere::parsePrefs = sub { return {} };
    local *Noosphere::markUserAccess = sub {};
    local *Noosphere::dbSelectRowBound = sub { return {uid => 1, password_hash => 'private-hash', access => 10} };
    local *Noosphere::verifyAccountPassword = sub { return 1 };
    local *Noosphere::makeTicket = sub { return 'c' x 64 };
    my $text = capture(sub {
        my %user = Noosphere::handleLogin($req, $params, {});
        is($user{uid}, 1, 'successful login remains authenticated');
    });
    like($text, qr/stage=credentials event=accepted.*stage=session_issue event=accepted.*stage=session_cookie event=set/s,
        'verified credentials, session creation and cookie response have distinct stages');
    {
        local *Noosphere::makeTicket = sub { die "private-database-failure\n" };
        $text = capture(sub {
            my %user = Noosphere::handleLogin($req, $params, {});
            ok($user{login_unavailable}, 'issuance failure still reports unavailable sign-in');
            is($user{uid}, 0, 'issuance failure still rejects authentication');
        });
        like($text, qr/stage=session_issue event=error/, 'session issuance exception diagnosed');
        unlike($text, qr/stage=session_cookie|private/, 'no successful cookie stage or raw exception on issuance failure');
    }
    {
        local *Noosphere::makeTicket = sub { return undef };
        $text = capture(sub { Noosphere::handleLogin($req, $params, {}) });
        like($text, qr/stage=session_issue event=rejected/, 'stale-credential issuance rejection differs from exception');
    }
    {
        local *Noosphere::dbSelectRowBound = sub { return undef };
        $text = capture(sub { is(Noosphere::checkTicket('c' x 64), -1, 'unknown session is rejected') });
        like($text, qr/stage=session_check event=unmatched/, 'missing, expired or inactive sessions have a non-error outcome');
    }
    local *Noosphere::sessionCredentialStamp = sub { return 'private-stamp' };
    local *Noosphere::dbSelectRowBound = sub { return {uid => 1, created => Noosphere::sessionTime(), credential_stamp => 'private-stamp'} };
    {
        local *Noosphere::dbExecuteBound = sub { die "private-touch-error\n" };
        $text = capture(sub { is(Noosphere::checkTicket('c' x 64), -1, 'activity update failure remains fail-closed') });
        like($text, qr/stage=session_touch event=error/, 'activity update error distinguished from lookup error');
        unlike($text, qr/private|c{64}/, 'session digest, token and error text absent');
    }
    {
        local *Noosphere::dbExecuteBound = sub { return 1 };
        $text = capture(sub { is(Noosphere::checkTicket('c' x 64), 1, 'valid session still accepted') });
        like($text, qr/stage=session_check event=accepted/, 'accepted cookie-backed session visible');
    }
    {
        local *Noosphere::sessionCredentialStamp = sub { return 'changed-stamp' };
        local *Noosphere::dbExecuteBound = sub { return 1 };
        $text = capture(sub { is(Noosphere::checkTicket('c' x 64), -1, 'credential binding rejection unchanged') });
        like($text, qr/stage=session_check event=invalidated/, 'credential invalidation distinguished from database failure');
        local *Noosphere::dbExecuteBound = sub { die "private-delete-error\n" };
        $text = capture(sub { is(Noosphere::checkTicket('c' x 64), -1, 'revocation cleanup failure remains fail-closed') });
        like($text, qr/stage=session_revoke event=error/, 'invalidation cleanup exception distinguished');
        unlike($text, qr/private|c{64}/, 'cleanup exceptions are not dumped');
    }
};

subtest 'production hooks stay request-scoped and include final response' => sub {
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere.pm" or die $!;
    my $source = do { local $/; <$in> };
    like($source, qr/sub handler \{\s*local \$Noosphere::LoginLog::CURRENT;/,
        'mod_perl cannot leak a trace into another request');
    my ($output) = $source =~ /(sub sendOutput \{.*?^\})/ms;
    like($output, qr/Noosphere::LoginLog::emit\('response', \$status\)/, 'actual response status recorded by shared output path');
    like($source, qr/if \(length \$account_error\) \{\s*Noosphere::LoginLog::emit\('origin', 'rejected'\)/,
        'origin rejection distinguished from a login or session failure');
    {
        no warnings qw(redefine once);
        local *Noosphere::requestFormDecorate = sub { $_[0] };
        local *Noosphere::setStandardSecurityHeaders = sub {};
        local *Noosphere::requestFormToken = sub { undef };
        ok(eval("package Noosphere; our (\$RequestFormStatus, \$RequestFormUser); $output; 1"),
            'real response function compiles') or diag($@);
        for my $status (200, 303, 403) {
            my $req = fixture();
            local $Noosphere::LoginLog::CURRENT = Noosphere::LoginLog::context(1, $req, {}, {});
            my $text = capture(sub { Noosphere::sendOutput($req, 'unchanged body', $status) });
            is($req->{status}, $status, 'HTTP status unchanged');
            is($req->{body}, 'unchanged body', 'HTTP body unchanged');
            like($text, qr/stage=response event=$status /, 'real response produces corresponding diagnostic');
        }
    }
};

done_testing();
