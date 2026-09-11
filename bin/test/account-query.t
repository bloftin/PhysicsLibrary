#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use FindBin;
use lib "$FindBin::Bin/../../lib";

our (@queries, @results, @cookies, @mail, @setup, @policies);
our ($failure, $finished);
my $payload = q{' OR 1=1 --};
my $quoted_password = q{a'\b; active=0 --};

{
    package Noosphere;
    use Digest::SHA qw(sha1_hex sha256_hex);
    use POSIX qw(strftime);
    use Noosphere::PasswordStorage;
    our $dbh;
    sub SECRET () { 'synthetic-test-key' }
    sub PASSWORD_RESET_TOKEN_BYTES () { 32 }
    sub DEFAULT_PASSWORD_RESET_TOKEN_LIFETIME () { 7200 }
    sub getConfig {
        return {user_tbl => 'users', cookie_timeout => 60,
            password_reset_token_lifetime => 7200,
            default_preamble => 'test-preamble', groups_tbl => 'groups'}->{$_[0]};
    }
    sub getUserData { return {uid => $_[0], prefs => ''}; }
    sub parsePrefs { return {neverlogout => 'off'}; }
    sub makeTicket { return 'synthetic-session-'.$_[0]; }
    sub checkTicket { return -1; }
    sub revokeTicket { return 1; }
    sub sessionLifetime { return 3600; }
    sub setCookie { push @main::cookies, [@_]; }
    sub clearCookie { return; }
    sub markUserAccess { return; }
    sub errorMessage { return $_[0]; }
    sub paddingTable { return $_[0]; }
    sub makeBox { return join ' ', @_; }
    sub urlunescape { return $_[0]; }
    sub htmlescape {
        my $s = $_[0]; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g;
        return $s;
    }
    sub sendPwChangeMail { push @main::mail, [@_]; return 'Mail Sent'; }
    sub nextval { return 99; }
    sub lookupfield { return 5; }
    sub addUserToGroup { push @main::setup, 'membership'; }
    sub addDefaultUserACL { push @main::setup, 'acl'; }
    sub indexTitle { push @main::setup, 'title'; }
    sub irIndex { push @main::setup, 'index'; }
    sub dwarn { return; }
}
{
    package TemplateNS;
    sub new { return bless {file => $_[1]}, $_[0]; }
    sub setKey { $_[0]->{$_[1]} = $_[2]; }
    sub expand {
        return q{\newcommand{\name}{O'Neil}} if $_[0]->{file} eq 'test-preamble';
        return $_[0]->{error} || 'Form';
    }
    package QueryRequest;
    sub header_in { return ''; }
    sub method { return 'POST'; }
    sub headers_out { return bless {}, 'QueryHeaders'; }
    package QueryHeaders;
    sub set { return; }
    package QueryDatabase;
    sub prepare {
        my ($self, $sql) = @_;
        push @main::policies, [@{$self}{qw(PrintError RaiseError ShowErrorStatement)}];
        die 'private prepare detail' if $main::failure eq 'prepare';
        return undef if $main::failure eq 'prepare-undef';
        return bless {sql => $sql}, 'QueryStatement';
    }
    package QueryStatement;
    sub execute {
        my ($self, @bind) = @_;
        push @main::queries, {sql => $self->{sql}, bind => \@bind};
        die 'private execute detail with password' if $main::failure eq 'execute';
        return undef if $main::failure eq 'execute-undef';
        $self->{result} = shift @main::results;
        return $self->{sql} =~ /^SELECT/ ? '0E0' : $self->{result};
    }
    sub fetchrow_hashref {
        die 'private fetch detail' if $main::failure eq 'fetch';
        return $_[0]->{result};
    }
    sub err { return $main::failure eq 'fetch-err' ? 1 : undef; }
    sub finish { $main::finished++; return 1; }
}

for my $file (
    ['DB.pm', qw(dbSelectRowBound dbExecuteBound dbRunBound)],
    ['Login.pm', qw(findLoginUser handleLogin)],
    ['Password.pm', qw(pwChange changePassword pwChangeRequest passwordResetTokenLifetime
        passwordResetTime newPasswordResetToken validPasswordResetToken createPasswordResetTicket
        passwordResetCredentialStamp passwordResetTicket consumePasswordResetTicket)],
    ['NewUser.pm', qw(checkHash makeHash activateAccount)],
    ['Util.pm', qw(user_registered getuidbyusername)],
    ['UserData.pm', qw(isUserActive)],
    ['Groups.pm', qw(makeDefaultGroup)],
) {
    my ($path, @names) = @$file;
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/$path" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name missing" unless defined $sub;
        eval "package Noosphere; our \$dbh; $sub";
        die $@ if $@;
    }
}

sub fixture {
    @queries = @results = @cookies = @mail = @setup = @policies = ();
    ($failure, $finished) = ('', 0);
    $Noosphere::dbh = bless {PrintError => 1, RaiseError => 0, ShowErrorStatement => 1}, 'QueryDatabase';
}
sub login {
    my ($user, $password) = @_;
    local $ENV{REMOTE_ADDR} = '192.0.2.1';
    return {Noosphere::handleLogin(bless({}, 'QueryRequest'),
        {op => 'login', user => $user, passwd => $password}, {})};
}

subtest 'login parameters and failure behavior' => sub {
    fixture();
    @results = ({uid => 42, password_hash => Noosphere::hashAccountPassword($quoted_password)});
    is(login('  Test   Member  ', $quoted_password)->{uid}, 42, 'successful login');
    is($queries[0]->{sql}, 'SELECT uid, password_hash, access FROM users WHERE lower(username) = lower(?) AND active = 1 LIMIT 1', 'fixed login SQL');
    is_deeply($queries[0]->{bind}, ['Test Member'], 'only username is sent to the login query');
    is(scalar @cookies, 1, 'session minted after match');
    is($finished, 1, 'statement finished');
    for my $pair ([$payload, 'wrong'], ['member', $payload], [undef, 'pw'], ['member', undef],
        [[], 'pw'], ['member', {}], ['', 'pw'], ['member', '']) {
        fixture();
        my $user = login(@$pair);
        is($user->{uid}, 0, 'unmatched or malformed login fails');
        ok(!defined $user->{ticket}, 'no ticket');
        is(scalar @cookies, 0, 'no login cookie');
        if (@queries) {
            unlike($queries[0]->{sql}, qr/\Q$payload\E/, 'input not embedded in query');
            is_deeply($queries[0]->{bind}, [$pair->[0]], 'username remains literal bound data');
        }
    }
    fixture(); @results = ({uid => 42, password_hash => Noosphere::hashAccountPassword('0')});
    is(login('member', '0')->{uid}, 42, 'nonempty zero password handled as data');
    fixture(); @results = ({uid => 42, password => 'old-password', password_hash => undef});
    is(login('member', 'old-password')->{uid}, 0, 'unmigrated account has no plaintext fallback');
    fixture(); @results = ({uid => 42, password_hash => Noosphere::hashAccountPassword('Case Sensitive')});
    is(login('member', 'case sensitive')->{uid}, 0, 'login verifies password with exact case');
};

subtest 'shared account lookups' => sub {
    for my $field (qw(username email)) {
        fixture(); @results = ({uid => 42});
        is(Noosphere::user_registered($payload, $field), 1, 'registered lookup uses fetched row');
        is($queries[0]->{sql}, "SELECT uid FROM users WHERE lower($field) = lower(?) LIMIT 1", 'allowlisted column');
        is_deeply($queries[0]->{bind}, [$payload], 'lookup value bound');
    }
    fixture();
    eval { Noosphere::user_registered('member', "username) OR 1=1 --") };
    like($@, qr/Invalid account lookup field/, 'column cannot be supplied as SQL');
    is(scalar @queries, 0, 'bad column never queried');
    fixture(); @results = ({active => 0}, {uid => 42});
    is(Noosphere::isUserActive($payload), 0, 'inactive state preserved');
    is(Noosphere::getuidbyusername($payload), 42, 'UID lookup');
    is_deeply([map { $_->{bind} } @queries], [[$payload], [$payload]], 'both use bound values');
};

subtest 'recovery lookup and change' => sub {
    my $old_hash = Noosphere::hashAccountPassword('old-password');
    fixture(); @results = ({username => "O'Neil", email => 'member@example.invalid'}, {uid => 42, password_hash => $old_hash}, 1, 1);
    is(Noosphere::pwChangeRequest({submit => 1, username => "o'neil"}), 'Mail Sent', 'recovery request');
    is($queries[0]->{sql}, 'SELECT username, email FROM users WHERE username = ? AND active = 1 LIMIT 1', 'fixed lookup SQL');
    is_deeply($queries[0]->{bind}, ["o'neil"], 'lookup bound');
    is_deeply([@{$mail[0]}[0,1]], ["O'Neil", 'member@example.invalid'], 'mail uses stored identity and address');
    like($mail[0]->[2], qr/\A[0-9a-f]{64}\z/, 'recovery mail uses opaque token');
    is($queries[1]->{sql}, 'SELECT uid, password_hash FROM users WHERE username = ? AND active = 1 LIMIT 1', 'token creation finds active account');
    is($queries[3]->{sql}, 'INSERT INTO password_reset_tokens (uid, token_hash, created, expires, used_at, credential_stamp) VALUES (?, ?, ?, ?, NULL, ?)', 'reset row stored');
    is($queries[3]->{bind}->[0], 42, 'reset row belongs to user');
    like($queries[3]->{bind}->[1], qr/\A[0-9a-f]{64}\z/, 'only token hash is stored');
    isnt($queries[3]->{bind}->[1], $mail[0]->[2], 'stored value is not the link token');
    fixture();
    like(Noosphere::pwChangeRequest({submit => 1, username => $payload}), qr/Cannot find/, 'missing user');
    is(scalar @mail, 0, 'no mail on missing match');
    is_deeply($queries[0]->{bind}, [$payload], 'SQL-like username is just a value');
    my $token = 'a' x 64;
    my $token_hash = sha256_hex($token);
    my $ticket = {uid => 42, token_hash => $token_hash, username => "O'Neil",
        password_hash => $old_hash, credential_stamp => Noosphere::passwordResetCredentialStamp($old_hash)};
    fixture(); @results = ($ticket, $ticket, 1, 1);
    like(Noosphere::pwChange({hash => $token, submit => 1, pw1 => $quoted_password, pw2 => $quoted_password}),
        qr/Password Changed/, 'password change route succeeds');
    is($queries[0]->{sql}, 'SELECT pr.uid, pr.token_hash, pr.credential_stamp, u.username, u.password_hash FROM password_reset_tokens pr JOIN users u ON u.uid = pr.uid WHERE pr.token_hash = ? AND pr.used_at IS NULL AND pr.expires >= ? AND u.active = 1 LIMIT 1', 'reset token lookup');
    is($queries[0]->{bind}->[0], $token_hash, 'lookup hashes token');
    is($queries[2]->{sql}, 'UPDATE password_reset_tokens SET used_at = ? WHERE token_hash = ? AND used_at IS NULL AND expires >= ?', 'token consumed first');
    is($queries[2]->{bind}->[1], $token_hash, 'consumption uses token hash');
    is($queries[3]->{sql}, "UPDATE users SET password_hash = ?, password = '' WHERE uid = ? AND active = 1 AND password_hash = ?", 'fixed conditional change SQL');
    is($queries[3]->{bind}->[2], $old_hash, 'password update requires the validated credential state');
    ok(Noosphere::verifyAccountPassword($queries[3]->{bind}->[0], $quoted_password), 'only hash is stored');
    is($queries[3]->{bind}->[1], 42, 'password change targets the token user');
    for my $bad (undef, [], '', 'invalid') {
        fixture();
        like(Noosphere::changePassword($bad, 'pw'), qr/Invalid password change URL/, 'helper requires valid link');
        is(scalar @queries, 0, 'invalid link cannot write');
    }
    for my $password (undef, [], '') {
        fixture();
        @results = ($ticket);
        like(Noosphere::changePassword($token, $password), qr/enter a password/, 'invalid password rejected');
        is(scalar @queries, 1, 'invalid password cannot write');
    }
    fixture(); @results = ($ticket, '0E0');
    like(Noosphere::changePassword($token, 'new'), qr/Could not change/, 'already used token not reported as success');
    is(scalar @queries, 2, 'user password not updated after failed consumption');
    fixture();
    @results = ($ticket);
    like(Noosphere::pwChange({hash => $token, submit => 1, pw1 => 'one', pw2 => 'two'}),
        qr/passwords don't match/, 'confirmation mismatch does not save');
    is(scalar @queries, 1, 'mismatch never updates database');
    for my $driver (qw(mysql MariaDB)) {
        fixture();
        $Noosphere::dbh->{Driver} = {Name => $driver};
        @results = ($ticket, 1, '0E0');
        like(Noosphere::changePassword($token, 'new'), qr/Could not change/, "$driver stale state is not reported as success");
        like($queries[2]->{sql}, qr/AND BINARY password_hash = BINARY \?\z/, "$driver compares exact credential bytes");
        is($queries[2]->{bind}->[2], $old_hash, 'expected credential hash is bound');
    }
};

subtest 'recovery lifetime without a configuration edit' => sub {
    no warnings qw(redefine once);
    for my $value (undef, '', 0, -1, 'invalid', []) {
        local *Noosphere::getConfig = sub { return $value; };
        is(Noosphere::passwordResetTokenLifetime(), 7200, 'missing or invalid setting defaults to two hours');
    }
    {
        local *Noosphere::getConfig = sub { die 'unknown configuration key'; };
        is(Noosphere::passwordResetTokenLifetime(), 7200, 'unavailable setting defaults to two hours');
    }
    {
        local *Noosphere::getConfig = sub { return 1800; };
        is(Noosphere::passwordResetTokenLifetime(), 1800, 'explicit lifetime is respected');
    }
    {
        local *Noosphere::getConfig = sub { return $_[0] eq 'user_tbl' ? 'users' : undef; };
        local *Noosphere::passwordResetTime = sub { return $_[0] || 0; };
        fixture();
        @results = ({uid => 42, password_hash => Noosphere::hashAccountPassword('old-password')}, 1, 1);
        ok(Noosphere::createPasswordResetTicket('member'), 'ticket created without a lifetime setting');
        is($queries[2]->{bind}->[3] - $queries[2]->{bind}->[2], 7200,
            'stored expiry is two hours after creation');
    }
};

subtest 'activation binds all record values' => sub {
    fixture(); @results = (undef, 1, {username => "O'Neil"}, 1, {groupid => 99});
    my $hash = Noosphere::makeHash("O'Neil", 'member@example.invalid');
    is(Noosphere::activateAccount($Noosphere::dbh, $hash, $quoted_password, $quoted_password), '', 'activation succeeds');
    is($queries[1]->{sql}, "INSERT INTO users (uid, joined, username, password, password_hash, email, preamble) VALUES (?, CURRENT_TIMESTAMP, ?, '', ?, ?, ?)", 'fixed insert SQL');
    ok(Noosphere::verifyAccountPassword($queries[1]->{bind}->[2], $quoted_password), 'activation stores a hash');
    is_deeply([@{$queries[1]->{bind}}[0,1,3,4]], [99, "O'Neil", 'member@example.invalid', q{\newcommand{\name}{O'Neil}}], 'other values literal including preamble');
    is_deeply($queries[3]->{bind}, [99, 99, "O'Neil", "This is the default group for user O'Neil."], 'default group also binds stored username');
    is_deeply(\@setup, [qw(membership acl acl title index)], 'post-creation setup retained');
    fixture(); @results = (undef, '0E0');
    like(Noosphere::activateAccount($Noosphere::dbh, $hash, 'pw', 'pw'), qr/failed to add user/, 'insert failure reported');
    is(scalar @setup, 0, 'no post-creation setup on failed insert');
};

subtest 'database errors are closed and redacted' => sub {
    for my $mode (qw(prepare prepare-undef execute execute-undef fetch fetch-err)) {
        fixture(); $failure = $mode;
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $user = login('member', $quoted_password);
        is($user->{uid}, 0, "$mode cannot authenticate");
        is(scalar @cookies, 0, 'no session on failure');
        my $html = Noosphere::pwChangeRequest({submit => 1, username => 'member'});
        like($html, qr/Could not process/, 'recovery reports failure');
        is(scalar @mail, 0, 'no mail on query error');
        unlike(join('', @warnings, $html), qr/private|\Q$quoted_password\E/, 'no driver detail or password exposed');
        is_deeply($policies[0], [0,1,0], 'query error policy suppresses value disclosure');
        is_deeply([@{$Noosphere::dbh}{qw(PrintError RaiseError ShowErrorStatement)}], [1,0,1], 'connection policy restored');
        eval { Noosphere::user_registered('member', 'username') };
        is($@, "Account database operation failed.\n", 'existence lookup does not fail open');
    }
    for my $mode (qw(prepare prepare-undef execute execute-undef)) {
        fixture(); $failure = $mode;
        my $token = 'c' x 64;
        my $html = Noosphere::changePassword($token, $quoted_password);
        like($html, qr/Could not change/, "$mode password write reports failure");
        unlike($html, qr/private|\Q$quoted_password\E/, 'write error contains no driver detail');
    }
};

subtest 'isolated database integration' => sub {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'Optional local integration requires DBI and DBD::SQLite';
    fixture();
    local $Noosphere::dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0, sqlite_unicode => 1});
    my $db = $Noosphere::dbh;
    $db->do("CREATE TABLE users (uid INTEGER PRIMARY KEY, joined TEXT, username TEXT, password TEXT DEFAULT '', password_hash TEXT, email TEXT, preamble TEXT, active INTEGER DEFAULT 1, access INTEGER DEFAULT 10)");
    $db->do("CREATE TABLE password_reset_tokens (uid INTEGER, token_hash TEXT PRIMARY KEY, created TEXT, expires TEXT, used_at TEXT, credential_stamp TEXT)");
    $db->do('CREATE TABLE groups (groupid INTEGER PRIMARY KEY, userid INTEGER, groupname TEXT, description TEXT)');
    my $insert = $db->prepare('INSERT INTO users (uid, username, password_hash, email, active) VALUES (?, ?, ?, ?, ?)');
    $insert->execute(1, 'member', Noosphere::hashAccountPassword('old-password'), 'member@example.invalid', 1);
    $insert->execute(2, 'other', Noosphere::hashAccountPassword('untouched'), 'other@example.invalid', 1);
    $insert->execute(3, 'inactive', Noosphere::hashAccountPassword('password'), 'inactive@example.invalid', 0);
    is(login('MEMBER', 'old-password')->{uid}, 1, 'real login preserves case-insensitive name');
    is(login($payload, 'wrong')->{uid}, 0, 'username payload cannot authenticate');
    is(login('member', $payload)->{uid}, 0, 'password payload cannot authenticate');
    is(login('inactive', 'password')->{uid}, 0, 'inactive account cannot authenticate');
    like(Noosphere::pwChangeRequest({submit => 1, username => $payload}), qr/Cannot find/, 'recovery payload matches no account');
    is(scalar @mail, 0, 'no recovery mail for payload');
    like(Noosphere::pwChangeRequest({submit => 1, username => 'member'}), qr/Mail Sent/, 'real recovery request');
    my $token = $mail[0]->[2];
    like($token, qr/\A[0-9a-f]{64}\z/, 'real recovery token');
    is($db->selectrow_array('SELECT COUNT(*) FROM password_reset_tokens WHERE token_hash = ?', undef, $token), 0,
        'real token is not stored directly');
    like(Noosphere::changePassword($token, $quoted_password), qr/Password Changed/, 'quoted password saved');
    is($db->selectrow_array('SELECT password FROM users WHERE uid = 1'), '', 'legacy field remains empty');
    is($db->selectrow_array('SELECT COUNT(*) FROM password_reset_tokens WHERE used_at IS NOT NULL'), 1, 'reset token consumed');
    like(Noosphere::changePassword($token, 'replay'), qr/Invalid password change URL/, 'consumed reset token cannot be reused');
    ok(Noosphere::verifyAccountPassword($db->selectrow_array('SELECT password_hash FROM users WHERE uid = 1'), $quoted_password), 'hash round trip');
    ok(Noosphere::verifyAccountPassword($db->selectrow_array('SELECT password_hash FROM users WHERE uid = 2'), 'untouched'), 'other account unchanged');
    is(login('member', $quoted_password)->{uid}, 1, 'quoted password authenticates normally');
    my $expired = 'b' x 64;
    $db->do("INSERT INTO password_reset_tokens (uid, token_hash, created, expires, used_at) VALUES (1, ?, '2000-01-01 00:00:00', '2000-01-01 01:00:00', NULL)",
        undef, sha256_hex($expired));
    like(Noosphere::changePassword($expired, 'not-written'), qr/Invalid password change URL/, 'expired reset token cannot update');
    my $literal = $payload . ('a' x 64);
    like(Noosphere::changePassword($literal, 'not-written'), qr/Invalid password change URL/, 'SQL-like token is only data');
    ok(Noosphere::verifyAccountPassword($db->selectrow_array('SELECT password_hash FROM users WHERE uid = 1'), $quoted_password), 'failed identity match leaves hash intact');
    my $new = Noosphere::makeHash("O'Neil", 'new@example.invalid');
    is(Noosphere::activateAccount($db, $new, $quoted_password, $quoted_password), '', 'real activation insert');
    is(login("O'Neil", $quoted_password)->{uid}, 99, 'new account login');
    is($db->selectrow_array('SELECT groupname FROM groups WHERE userid = 99'), "O'Neil", 'default group keeps literal name');
    is(Noosphere::user_registered("O'Neil", 'username'), 1, 'real existence lookup');
    is(Noosphere::isUserActive("O'Neil"), 1, 'real active lookup');
    is(Noosphere::getuidbyusername("O'Neil"), 99, 'real UID lookup');
    $db->do('DROP TABLE users');
    is(login('member', $quoted_password)->{uid}, 0, 'real driver error cannot authenticate');
};

done_testing();
