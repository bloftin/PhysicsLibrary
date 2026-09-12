#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use Digest::SHA qw(sha256_hex);
use lib "$FindBin::Bin/../../lib";

our ($method, $mail_failure, $blocked, $clock, $uid);
our (%headers, @mail, @setup);
{
    package Noosphere;
    our $dbh;
    sub getConfig {
        return {user_tbl => 'users', groups_tbl => 'groups', default_preamble => 'test-preamble',
            siteaddrs => {main => 'example.invalid'}}->{$_[0]};
    }
    sub errorMessage { return $_[0]; }
    sub paddingTable { return $_[0]; }
    sub clearBox { return join ' ', @_; }
    sub makeBox { return join ' ', @_; }
    sub sendMail {
        die 'private mail error' if $main::mail_failure;
        push @main::mail, [@_];
    }
    sub nextval { return ++$main::uid; }
    sub lookupfield { return 5; }
    sub makeDefaultGroup { push @main::setup, 'group'; }
    sub addUserToGroup { push @main::setup, 'membership'; }
    sub addDefaultUserACL { push @main::setup, 'acl'; }
    sub indexTitle { push @main::setup, 'title'; }
    sub irIndex { push @main::setup, 'index'; }
    package Apache2::RequestUtil;
    sub request { return bless {}, 'RegistrationRequest'; }
    package RegistrationRequest;
    sub method { return $main::method; }
    sub headers_out { return $_[0]; }
    sub set { $main::headers{$_[1]} = $_[2]; }
    package TemplateNS;
    sub new { return bless {file => $_[1]}, $_[0]; }
    sub setKey { $_[0]->{$_[1]} = $_[2]; }
    sub setKeys { my $self = shift; my %keys = @_; @{$self}{keys %keys} = values %keys; }
    sub expand {
        my $self = shift;
        return q{\newcommand{\name}{O'Neil}} if $self->{file} eq 'test-preamble';
        return "https://$self->{hostname}/?op=activate&hash=$self->{hash}" if $self->{file} eq 'newuseremail';
        return join ' ', map { defined($_) ? $_ : '' } @{$self}{qw(file error hash)};
    }
}
require Noosphere::NewUser;
require Noosphere::Password;
{
    no warnings 'redefine';
    *Noosphere::email_blacklisted = sub { return $blocked; };
    *Noosphere::registrationTime = sub { return $clock; };
}
for my $file (['DB.pm', qw(dbSelectRowBound dbExecuteBound dbRunBound)],
              ['Util.pm', qw(user_registered)]) {
    my ($path, @names) = @$file;
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/$path" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name missing" unless defined $sub;
        eval 'package Noosphere; our $dbh; ' . $sub;
        die $@ if $@;
    }
}

subtest 'lock drivers and failure handling' => sub {
    no warnings 'redefine';
    for my $driver (qw(mysql MariaDB Pg)) {
        for my $mode (qw(success busy callback release)) {
            my (@queries, $called, $disconnected);
            my $fake = bless {Driver => {Name => $driver}}, 'RegistrationDatabase';
            local *RegistrationDatabase::disconnect = sub { $disconnected++; };
            local *Noosphere::dbSelectRowBound = sub {
                my ($db, $sql, @bind) = @_;
                push @queries, [$sql, @bind];
                return {acquired => $mode eq 'busy' ? 0 : 1} if @queries == 1;
                return {released => $mode eq 'release' ? 0 : 1};
            };
            my $result = eval { Noosphere::withRegistrationLock($fake, sub {
                $called++;
                die 'private callback details' if $mode eq 'callback';
                return 'result';
            }) };
            if ($mode eq 'success') {
                is($result, 'result', "$driver returns result");
                is($@, '', 'no exception');
            } else {
                is($@, "Registration unavailable.\n", "$driver $mode fails generically");
            }
            is($called || 0, $mode eq 'busy' ? 0 : 1, 'only lock holder enters callback');
            is(scalar @queries, $mode eq 'busy' ? 1 : 2, 'held lock released even after callback failure');
            is($disconnected || 0, $mode eq 'release' ? 1 : 0, 'failed unlock closes connection');
            like($queries[0]->[0], $driver eq 'Pg' ? qr/pg_try_advisory_lock/ : qr/GET_LOCK\(\?, 5\)/, 'expected acquisition');
            if (@queries == 2) {
                is_deeply([@{$queries[0]}[1..$#{$queries[0]}]],
                    [@{$queries[1]}[1..$#{$queries[1]}]], 'release uses same lock identity');
            }
        }
    }
    eval { Noosphere::withRegistrationLock({Driver => {Name => 'unknown'}}, sub { die 'should not run' }) };
    is($@, "Registration unavailable.\n", 'unknown driver fails closed');
};

subtest 'isolated registration workflow' => sub {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'Requires DBI and DBD::SQLite for isolated database tests';
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/registration.db";
    my $db = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
    my $other_db = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
    $other_db->sqlite_busy_timeout(10);
    local $Noosphere::dbh = $db;
    ($method, $mail_failure, $blocked, $clock, $uid) = ('GET', 0, 0, 1800000000, 100);
    $db->do("CREATE TABLE users (uid INTEGER PRIMARY KEY, joined TEXT, username TEXT, email TEXT, password TEXT DEFAULT '', password_hash TEXT, preamble TEXT, active INTEGER DEFAULT 1)");
    $db->do('CREATE TABLE password_reset_tokens (uid INTEGER, token_hash TEXT PRIMARY KEY, created TEXT, expires TEXT, used_at TEXT, credential_stamp TEXT)');
    open my $in, '<', "$FindBin::Bin/../../db/schema.pg.sql" or die $!;
    my $schema = do { local $/; <$in> };
    close $in;
    my ($create) = $schema =~ /(CREATE TABLE account_registration_tokens \(.*?\);)/s;
    ok($create, 'registration table present in schema');
    $db->do($create);
    my $params = {verify => 1, license => 'on', user => 'Test Member', email => 'member@example.invalid'};
    my $anonymous = {uid => 0};
    my $password = q{Long 'quoted' password \ for testing};
    my $activate = sub { return Noosphere::activateAccount($db, $_[0], $password, $password); };
    my $used = sub { return $db->selectrow_array('SELECT used_at FROM account_registration_tokens WHERE token_hash = ?',
        undef, sha256_hex('activation-v1:' . $_[0])); };

    subtest 'request and read-only link opening' => sub {
        @mail = ();
        like(Noosphere::getNewUser($params, $anonymous), qr/Use the registration form/, 'GET cannot send mail');
        is(scalar @mail, 0, 'no mail side effect');
        local $method = 'POST';
        like(Noosphere::getNewUser($params, $anonymous), qr/Mail Sent/, 'POST sends mail');
        is($mail[0]->[0], $params->{email}, 'mail recipient is validated');
        my ($token) = $mail[0]->[1] =~ /hash=([0-9a-f]{64})/;
        ok($token, 'opaque token in mail');
        unlike($mail[0]->[1], qr/Test Member|member\@/, 'link contains no identity');
        my $row = $db->selectrow_hashref('SELECT * FROM account_registration_tokens');
        is($row->{token_hash}, sha256_hex('activation-v1:' . $token), 'stored digest only');
        isnt($row->{token_hash}, $token, 'database does not contain bearer token');
        is($row->{expires} - $row->{created}, 86400, '24-hour expiry');
        for (1..2) {
            local $method = 'GET';
            like(Noosphere::getActivate({hash => $token}), qr/activate.html/, 'opening link displays form');
            ok(!defined($used->($token)), 'opening link does not consume token');
        }
        is($headers{'Cache-Control'}, 'no-store', 'activation form not cached');
        is($headers{'Referrer-Policy'}, 'no-referrer', 'activation URL not sent as referrer');
        for my $verb (qw(GET HEAD PUT)) {
            local $method = $verb;
            like(Noosphere::getActivate({hash => $token, setpass => 1, p1 => $password, p2 => $password}),
                qr/Use the activation form/, "$verb cannot activate");
            ok(!defined($used->($token)), 'method rejection does not consume token');
        }
        like(Noosphere::getActivate({hash => $token, setpass => 1, p1 => 'one', p2 => 'two'}),
            qr/passwords are different/, 'password mismatch displayed in form');
        ok(!defined($used->($token)), 'mismatch allows retry');
        for my $bad (undef, '', [], 'x' x 4097) {
            isnt(Noosphere::activateAccount($db, $token, $bad, $bad), '', 'invalid password cannot create account');
            ok(!defined($used->($token)), 'invalid password does not consume token');
        }
        @setup = ();
        like(Noosphere::getActivate({hash => $token, setpass => 1, p1 => $password, p2 => $password,
            user => 'Injected', email => 'other@example.invalid'}), qr/Success/, 'valid submission succeeds');
        is_deeply(\@setup, [qw(group membership acl acl title index)], 'account setup retained');
        my $user = $db->selectrow_hashref('SELECT * FROM users');
        is($user->{username}, 'Test Member', 'stored username used');
        is($user->{email}, 'member@example.invalid', 'stored email used');
        is($user->{password}, '', 'legacy password field empty');
        ok(Noosphere::verifyAccountPassword($user->{password_hash}, $password), 'Argon2id password works');
        ok(defined($used->($token)), 'successful submission consumes token');
        like($activate->($token), qr/invalid, expired, or already used/, 'replay rejected');
        is($db->selectrow_array('SELECT COUNT(*) FROM users'), 1, 'replay creates no duplicate');
    };

    subtest 'expiry, malformed and purpose-specific links' => sub {
        my $token = Noosphere::createRegistrationTicket('Expiry', 'expiry@example.invalid');
        {
            local $clock = $clock + 86400;
            ok(!Noosphere::registrationTicket($db, $token), 'expired at exact expiry boundary');
            like($activate->($token), qr/invalid, expired, or already used/, 'expired link cannot create account');
            my $fresh = Noosphere::createRegistrationTicket('Expiry', 'expiry@example.invalid');
            isnt($fresh, $token, 'new request creates independent token');
            is($activate->($fresh), '', 'fresh request works');
        }
        for my $bad (undef, '', [], {}, 'f' x 64, 'a' x 63, 'a' x 65, ('a' x 64)."\n",
            'Test:member@example.invalid:'.('a' x 40), q{' OR 1=1 --}) {
            ok(!Noosphere::registrationTicket($db, $bad), 'bad or old link is rejected');
            like($activate->($bad), qr/invalid, expired, or already used/, 'bad link cannot activate');
        }
        my $reset = Noosphere::createPasswordResetTicket('Test Member');
        ok($reset, 'separate reset token created');
        like($activate->($reset), qr/invalid, expired, or already used/, 'recovery token cannot activate');
        my $registration = Noosphere::createRegistrationTicket('Purpose', 'purpose@example.invalid');
        ok(!Noosphere::passwordResetTicket($registration), 'registration token cannot reset a password');
    };

    subtest 'sibling and competing identities' => sub {
        my $first = Noosphere::createRegistrationTicket('Siblings', 'siblings@example.invalid');
        my $second = Noosphere::createRegistrationTicket('Siblings', 'siblings@example.invalid');
        my $case = Noosphere::createRegistrationTicket('SIBLINGS', 'elsewhere@example.invalid');
        my $email = Noosphere::createRegistrationTicket('Other Name', 'SIBLINGS@example.invalid');
        is($activate->($first), '', 'first identity activates');
        for my $token ($second, $case, $email) {
            like($activate->($token), qr/invalid, expired, or already used/, 'conflicting identity is not activated');
        }
        is($db->selectrow_array("SELECT COUNT(*) FROM users WHERE lower(username) = 'siblings'"), 1, 'no duplicate username');
        is($db->selectrow_array(q{SELECT COUNT(*) FROM users WHERE lower(email) = 'siblings@example.invalid'}), 1, 'no duplicate email');
        $db->do("UPDATE users SET active=0 WHERE username='Siblings'");
        like($activate->($second), qr/invalid, expired, or already used/, 'old link cannot reactivate account');
        is($db->selectrow_array("SELECT active FROM users WHERE username='Siblings'"), 0, 'inactive account stays inactive');
    };

    subtest 'request validation and service failures' => sub {
        local $method = 'POST';
        my $token = Noosphere::createRegistrationTicket('Failure', 'failure@example.invalid');
        for my $pair (['Bad  Name', 'ok@example.invalid'], ['x' x 33, 'ok@example.invalid'],
            ['Okay', 'x' x 129], ['Okay', "ok\@example.invalid\n"], [[], 'ok@example.invalid'],
            ['Okay', {}], [q{' OR 1=1 --}, 'ok@example.invalid']) {
            @mail = ();
            unlike(Noosphere::getNewUser({%$params, user => $pair->[0], email => $pair->[1]}, $anonymous),
                qr/Mail Sent/, 'invalid identity rejected');
            is(scalar @mail, 0, 'invalid identity sends no mail');
        }
        {
            local $blocked = 1;
            ok(!Noosphere::createRegistrationTicket('Blocked', 'blocked@example.invalid'), 'blocked address rejected');
        }
        $db->do("CREATE TRIGGER fail_insert BEFORE INSERT ON users BEGIN SELECT RAISE(ABORT, 'private db detail'); END");
        @setup = ();
        like($activate->($token), qr/Could not activate/, 'insert failure is generic');
        is(scalar @setup, 0, 'no setup on failed insert');
        $db->do('DROP TRIGGER fail_insert');
        my $fresh = Noosphere::createRegistrationTicket('Failure', 'failure@example.invalid');
        is($activate->($fresh), '', 'lock released after error');
        {
            no warnings 'redefine';
            local *Noosphere::passwordSalt = sub { die 'private rng detail'; };
            @mail = ();
            like(Noosphere::getNewUser({%$params, user => 'Random', email => 'random@example.invalid'}, $anonymous),
                qr/Could not process registration/, 'random-source error is generic');
            is(scalar @mail, 0, 'random-source failure sends no mail');
        }
        {
            local $mail_failure = 1;
            like(Noosphere::getNewUser({%$params, user => 'Mail Error', email => 'mailerror@example.invalid'}, $anonymous),
                qr/Could not send registration email/, 'mail exception is generic');
        }
        $db->do('DROP TABLE account_registration_tokens');
        like(Noosphere::getNewUser({%$params, user => 'Missing', email => 'missing@example.invalid'}, $anonymous),
            qr/Could not process registration/, 'missing migration fails closed');
        like(Noosphere::getActivate({hash => 'a' x 64}), qr/Could not process activation/, 'database read error is generic');
    };
};

done_testing();
