#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Digest::SHA qw(sha256_hex);

our %config = (user_tbl => 'users', cookie_timeout => 14 * 24 * 60,
    access_admin => 50, main_url => 'https://example.invalid');
{
    package Noosphere;
    sub getConfig { return $main::config{$_[0]}; }
    sub getUserData { return {prefs => ''}; }
    sub parsePrefs { return {neverlogout => 'on'}; }
    sub markUserAccess { return; }
    sub errorMessage { return $_[0]; }
    sub paddingTable { return $_[0]; }
    sub makeBox { return join ' ', @_; }
    sub htmlescape { return $_[0]; }
}
require Noosphere::Login;
require Noosphere::Cookies;
require Noosphere::Password;

{
    package SessionHeaders;
    sub new { return bless {cookies => [], fields => {}}, $_[0]; }
    sub add { push @{$_[0]->{cookies}}, $_[2]; }
    sub set { $_[0]->{fields}->{$_[1]} = $_[2]; }
    package SessionRequest;
    sub new { return bless {method => $_[1] || 'GET', cookie => $_[2] || '', headers => SessionHeaders->new()}, $_[0]; }
    sub method { return $_[0]->{method}; }
    sub headers_out { return $_[0]->{headers}; }
    sub header_in { return $_[1] eq 'Cookie' ? $_[0]->{cookie} : ''; }
}

sub request {
    my ($method, $params, $token) = @_;
    my $req = SessionRequest->new($method, defined($token) ? "__Host-pl_session=$token" : '');
    my %cookies = Noosphere::parseCookies($req);
    my %user = Noosphere::handleLogin($req, $params, \%cookies);
    return (\%user, $req);
}

subtest 'cookie scope and removal' => sub {
    my $req = SessionRequest->new();
    Noosphere::setCookie($req, 'ticket', 'a' x 64, 7200);
    my $cookie = $req->{headers}->{cookies}->[0];
    like($cookie, qr/^__Host-pl_session=/, 'host-prefixed session cookie');
    for my $flag ('Path=/', 'Secure', 'HttpOnly', 'SameSite=Lax', 'Max-Age=7200') {
        like($cookie, qr/(?:^|; )\Q$flag\E(?:;|$)/, $flag);
    }
    unlike($cookie, qr/Domain=/i, 'cookie cannot be shared across subdomains');
    Noosphere::clearCookie($req, 'ticket');
    like($req->{headers}->{cookies}->[1], qr/^__Host-pl_session=;.*Max-Age=0; Expires=Thu, 01 Jan 1970/, 'session cookie explicitly expired');
    like($req->{headers}->{cookies}->[2], qr/^ticket=;.*Max-Age=0/, 'legacy cookie also removed');
    for my $value ("x\r\nInjected: yes", 'x; Secure', []) {
        eval { Noosphere::setCookie($req, 'ticket', $value, 7200); };
        like($@, qr/Invalid cookie/, 'invalid cookie value rejected');
    }
    eval { Noosphere::setCookie($req, 'ticket', 'x', "0; Domain=example.invalid"); };
    like($@, qr/Invalid cookie expiry/, 'expiry cannot inject attributes');
};

subtest 'cookie parsing and old sessions' => sub {
    my $token = 'b' x 64;
    my %cookies = Noosphere::parseCookies(SessionRequest->new('GET', "ticket=legacy; __Host-pl_session=$token; other=a=b"));
    is($cookies{ticket}, $token, 'only new cookie supplies login ticket');
    is($cookies{other}, 'a=b', 'ordinary cookie values preserved');
    for my $raw ('ticket=legacy', "__Host-pl_session=$token; __Host-pl_session=$token",
        '__Host-pl_session=' . ('c' x 65), '') {
        my %parsed = Noosphere::parseCookies(SessionRequest->new('GET', $raw));
        ok(!defined($parsed{ticket}), 'legacy, duplicate, oversized or absent session ignored');
    }
    for my $invalid (undef, [], '', '1:20160:1000:old-signature', "' OR 1=1 --", 'a' x 63) {
        is(Noosphere::checkTicket($invalid), -1, 'invalid session never accesses a database');
    }
    isnt(Noosphere::logoutFormToken($token), $token, 'logout form does not expose session token');
    isnt(Noosphere::logoutFormToken($token), Noosphere::logoutFormToken('c' x 64), 'logout token bound to session');
};

subtest 'bounded lifetime defaults' => sub {
    is(Noosphere::sessionLifetime(), 1209600, 'default maximum is fourteen days');
    is(Noosphere::sessionIdleTimeout(), 7200, 'default idle timeout is two hours');
    local $config{cookie_timeout} = 30;
    is(Noosphere::sessionLifetime(), 1800, 'shorter existing maximum respected');
    local $config{session_idle_timeout} = 600;
    is(Noosphere::sessionIdleTimeout(), 600, 'explicit idle timeout respected');
    for my $value (undef, [], 0, -1, 'bad', 999999999) {
        local $config{cookie_timeout} = $value;
        is(Noosphere::sessionLifetime(), 1209600, 'invalid or unbounded maximum falls back');
    }
};

subtest 'preferences omit obsolete unlimited session option' => sub {
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/UserData.pm" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    my ($sub) = $source =~ /^(sub editUserPrefs \{.*?)(?=^sub |\z)/ms;
    eval "package Noosphere; $sub";
    die $@ if $@;
    {
        package TemplateNS;
        sub new { return bless {}, $_[0]; }
        sub setKeys { return; }
        sub setKey { $_[0]->{$_[1]} = $_[2]; }
        sub expand { return $_[0]->{inputs}; }
    }
    no warnings qw(redefine once);
    local *Noosphere::changePrefs = sub { return ''; };
    local *Noosphere::getUserPrefs = sub { return {}; };
    local *Noosphere::getPrefsWidget = sub { return ('widget', $_[1]); };
    local $config{prefs_groupings} = [['General', ['pagesize']], ['Security', ['neverlogout']]];
    my $html = Noosphere::editUserPrefs({}, {uid => 1, data => {username => 'member'}, prefs => {}});
    like($html, qr/pagesize/, 'ordinary preference remains');
    unlike($html, qr/neverlogout|Security/, 'obsolete option and empty group omitted');
};

subtest 'session database and routes' => sub {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'Integration requires DBI and DBD::SQLite';
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/DB.pm" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    for my $name (qw(dbSelectRowBound dbExecuteBound dbRunBound)) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name missing" unless defined $sub;
        eval "package Noosphere; $sub";
        die $@ if $@;
    }
    local $Noosphere::dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1, PrintError => 0});
    my $db = $Noosphere::dbh;
    $db->do("CREATE TABLE users (uid INTEGER PRIMARY KEY, username TEXT, password TEXT DEFAULT '', password_hash TEXT, access INTEGER DEFAULT 10, active INTEGER DEFAULT 1)");
    $db->do('CREATE TABLE account_sessions (token_hash TEXT PRIMARY KEY, uid INTEGER NOT NULL, created BIGINT NOT NULL, expires BIGINT NOT NULL, last_seen BIGINT NOT NULL, credential_stamp TEXT NOT NULL)');
    $db->do('CREATE TABLE password_reset_tokens (uid INTEGER, token_hash TEXT PRIMARY KEY, created TEXT, expires TEXT, used_at TEXT)');
    my $hash = Noosphere::hashAccountPassword('first-password');
    $db->do('INSERT INTO users (uid, username, password_hash) VALUES (1, ?, ?)', undef, 'member', $hash);
    $db->do('INSERT INTO users (uid, username, password_hash) VALUES (2, ?, ?)', undef, 'other', $hash);
    my $now = 2000000000;
    no warnings qw(redefine once);
    local *Noosphere::sessionTime = sub { return $now; };

    my ($user, $req) = request('POST', {op => 'login', user => 'member', passwd => 'first-password'});
    is($user->{uid}, 1, 'POST login authenticates');
    my $first = $user->{ticket};
    like($first, qr/\A[0-9a-f]{64}\z/, 'new session is random opaque token');
    is($db->selectrow_array('SELECT COUNT(*) FROM account_sessions WHERE token_hash = ?', undef, $first), 0, 'raw token is not stored');
    is($db->selectrow_array('SELECT token_hash FROM account_sessions'), sha256_hex($first), 'stored token digest');
    is(scalar @{$req->{headers}->{cookies}}, 1, 'neverlogout does not extend cookie');
    is($req->{headers}->{fields}->{'Cache-Control'}, 'no-store', 'login response cannot be cached');
    is($req->{headers}->{fields}->{'Referrer-Policy'}, 'same-origin', 'account URL not leaked cross-origin');
    ($user) = request('GET', {op => 'login', user => 'member', passwd => 'first-password'});
    is($user->{uid}, 0, 'GET cannot submit credentials');
    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'first-password'});
    my $second = $user->{ticket};
    isnt($second, $first, 'same-second logins have distinct sessions');
    my $other = Noosphere::makeTicket(2, '', 1, 0, $hash, 10);

    ($user, $req) = request('GET', {op => 'logout'}, $first);
    is($user->{uid}, 1, 'GET logout requires confirmation');
    my $form = Noosphere::logoutPage({op => 'logout'}, $user);
    like($form, qr/form method="post"/, 'logout confirmation uses POST');
    like($form, qr/name="logout_token"/, 'logout confirmation contains form token');
    unlike($form, qr/\Q$first\E/, 'session secret is not in form');
    ($user) = request('POST', {op => 'logout', logout_token => Noosphere::logoutFormToken($second)}, $first);
    is($user->{uid}, 1, 'token from another session cannot sign this one out');
    ($user) = request('POST', {op => 'logout'}, $first);
    is($user->{uid}, 1, 'missing logout token does not revoke');
    ($user, $req) = request('POST', {op => 'logout', logout_token => Noosphere::logoutFormToken($first)}, $first);
    is($user->{uid}, 0, 'confirmed logout succeeds');
    is(Noosphere::checkTicket($first), -1, 'copied cookie rejected after logout');
    is(Noosphere::checkTicket($second), 1, 'other browser stays signed in');
    like($req->{headers}->{cookies}->[0], qr/Max-Age=0/, 'logout expires cookie');

    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'first-password'}, $second);
    my $rotated = $user->{ticket};
    isnt($rotated, $second, 'login rotates current browser session');
    is(Noosphere::checkTicket($second), -1, 'replaced session cannot be reused');

    my $another_browser = Noosphere::makeTicket(1, '', 1, 0, $hash, 10);
    my $reset = Noosphere::createPasswordResetTicket('member');
    like(Noosphere::changePassword($reset, 'second-password'), qr/Password Changed/, 'real recovery changes password');
    is(Noosphere::checkTicket($rotated), -1, 'password recovery invalidates existing session');
    is(Noosphere::checkTicket($another_browser), -1, 'password recovery invalidates all browsers');
    is(Noosphere::checkTicket($other), 2, 'other account stays signed in');
    ok(!defined(Noosphere::makeTicket(1, '', 1, 0, $hash, 10)), 'stale verified credentials cannot mint a session');
    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $third = $user->{ticket};
    is($user->{uid}, 1, 'new password creates session normally');
    open my $admin_in, '<', "$FindBin::Bin/../../lib/Noosphere/Admin.pm" or die $!;
    my $admin_source = do { local $/; <$admin_in> };
    close $admin_in;
    for my $name (qw(deactivate reactivate)) {
        my ($handler) = $admin_source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        eval "package Noosphere; our \$dbh; $handler";
        die $@ if $@;
    }
    local *Noosphere::objectExistsByUid = sub { return 1; };
    local *Noosphere::loginExpired = sub { return 'Sign in'; };
    my $admin = {uid => 2, data => {access => 100}};
    like(Noosphere::deactivate({id => 1, ask => 'no'}, {uid => 1, data => {access => 10}}), qr/Only admins/, 'ordinary user cannot deactivate accounts');
    is(Noosphere::checkTicket($third), 1, 'denied admin action leaves session valid');
    like(Noosphere::deactivate({id => 1, ask => 'no'}, $admin), qr/User deactivated/, 'admin deactivation handler succeeds');
    is(Noosphere::checkTicket($third), -1, 'deactivation revokes session');
    like(Noosphere::reactivate({id => 1, ask => 'no'}, $admin), qr/User reactivated/, 'admin reactivation handler succeeds');
    is(Noosphere::checkTicket($third), -1, 'reactivation does not revive old session');

    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $access_token = $user->{ticket};
    $db->do('UPDATE users SET access = 100 WHERE uid = 1');
    is(Noosphere::checkTicket($access_token), -1, 'privilege change requires new login');
    $db->do('UPDATE users SET access = 10 WHERE uid = 1');
    is(Noosphere::checkTicket($access_token), -1, 'rejected session remains revoked');
    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $idle_token = $user->{ticket};
    $now += 7199;
    is(Noosphere::checkTicket($idle_token), 1, 'activity before idle deadline accepted');
    is($db->selectrow_array('SELECT last_seen FROM account_sessions WHERE token_hash = ?', undef, sha256_hex($idle_token)), $now, 'activity advances idle timer');
    $now += 7200;
    is(Noosphere::checkTicket($idle_token), -1, 'idle deadline enforced at boundary');
    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $absolute = $user->{ticket};
    $now += Noosphere::sessionLifetime();
    $db->do('UPDATE account_sessions SET last_seen = ? WHERE token_hash = ?', undef, $now, sha256_hex($absolute));
    is(Noosphere::checkTicket($absolute), -1, 'activity cannot extend absolute deadline');

    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $update_failure = $user->{ticket};
    $db->do("CREATE TRIGGER fail_session_update BEFORE UPDATE ON account_sessions BEGIN SELECT RAISE(ABORT, 'synthetic private detail'); END");
    $now++;
    is(Noosphere::checkTicket($update_failure), -1, 'database update failure also fails closed');
    $db->do('DROP TRIGGER fail_session_update');

    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $disabled = $user->{ticket};
    $db->do('UPDATE users SET active = 0 WHERE uid = 1');
    is(Noosphere::checkTicket($disabled), -1, 'direct deactivation checked on every request');
    Noosphere::setAccountActive(1, 1);
    is(Noosphere::checkTicket($disabled), -1, 'reactivation purges even directly disabled account sessions');
    $db->do('DELETE FROM users WHERE uid = 2');
    is(Noosphere::checkTicket($other), -1, 'deleted user cannot authenticate');

    ($user) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    my $outage_token = $user->{ticket};
    $db->do('DROP TABLE account_sessions');
    is(Noosphere::checkTicket($outage_token), -1, 'database failure cannot authenticate');
    ($user, $req) = request('POST', {op => 'login', user => 'member', passwd => 'second-password'});
    is($user->{uid}, 0, 'session insert failure cannot authenticate');
    ok(!defined($user->{ticket}), 'failed insert supplies no ticket');
    unlike(join('', @{$req->{headers}->{cookies}}), qr/__Host-pl_session=[0-9a-f]{64}/, 'failed login emits no live cookie');
    eval { request('POST', {op => 'logout', logout_token => Noosphere::logoutFormToken($outage_token)}, $outage_token); };
    is($@, "Account database operation failed.\n", 'failed revocation is not reported as successful logout');
};

done_testing();
