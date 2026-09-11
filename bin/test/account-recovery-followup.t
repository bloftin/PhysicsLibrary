#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Digest::SHA qw(sha256_hex);

eval { require DBI; require DBD::SQLite; 1 }
    or plan skip_all => 'Requires DBI and DBD::SQLite for isolated database tests';

{
    package Noosphere;
    sub getConfig { return $_[0] eq 'user_tbl' ? 'users' : undef; }
    sub errorMessage { return $_[0]; }
    sub paddingTable { return $_[0]; }
    sub makeBox { return join ' ', @_; }
    sub htmlescape { return $_[0]; }
}
require Noosphere::Password;

open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/DB.pm" or die $!;
my $source = do { local $/; <$in> };
close $in;
for my $name (qw(dbSelectRowBound dbExecuteBound dbRunBound)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name missing" unless defined $sub;
    eval "package Noosphere; $sub";
    die $@ if $@;
}

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/accounts.db";
my $db = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
my $other_db = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
$Noosphere::dbh = $db;
$db->do("CREATE TABLE users (uid INTEGER PRIMARY KEY, username TEXT, password TEXT DEFAULT '', password_hash TEXT, active INTEGER DEFAULT 1)");
$db->do('CREATE TABLE password_reset_tokens (uid INTEGER, token_hash TEXT PRIMARY KEY, created TEXT, expires TEXT, used_at TEXT)');
open my $migration_in, '<', "$FindBin::Bin/../../db/migrations/account-recovery-followup.sql" or die $!;
my $migration = do { local $/; <$migration_in> };
close $migration_in;
# Existing links deliberately receive no credential stamp during migration.
my $legacy_token = 'a' x 64;
$db->do('INSERT INTO password_reset_tokens (uid, token_hash, created, expires) VALUES (1, ?, ?, ?)',
    undef, sha256_hex($legacy_token), Noosphere::passwordResetTime(), Noosphere::passwordResetTime(7200));
$db->do($migration);
my $initial_hash = Noosphere::hashAccountPassword('initial-password');
$db->do('INSERT INTO users (uid, username, password_hash) VALUES (1, ?, ?)', undef, 'member', $initial_hash);
$db->do('INSERT INTO users (uid, username, password_hash) VALUES (2, ?, ?)', undef, 'other', $initial_hash);

sub current_hash {
    return $db->selectrow_array('SELECT password_hash FROM users WHERE uid = 1');
}

subtest 'migration and sibling invalidation' => sub {
    ok(!defined(Noosphere::passwordResetTicket($legacy_token)), 'pre-migration link is rejected');
    like(Noosphere::changePassword($legacy_token, 'not-written'), qr/Invalid password change URL/, 'old link cannot update password');
    is(current_hash(), $initial_hash, 'migration leaves account password unchanged');
    my $first = Noosphere::createPasswordResetTicket('member');
    my $second = Noosphere::createPasswordResetTicket('member');
    my $other = Noosphere::createPasswordResetTicket('other');
    ok(Noosphere::passwordResetTicket($first), 'first link works before reset');
    ok(Noosphere::passwordResetTicket($second), 'second link works before reset');
    my ($stamp) = $db->selectrow_array('SELECT credential_stamp FROM password_reset_tokens WHERE token_hash = ?', undef, sha256_hex($first));
    is($stamp, Noosphere::passwordResetCredentialStamp($initial_hash), 'link bound to credential state');
    isnt($stamp, $initial_hash, 'reset table does not duplicate password hash');
    like(Noosphere::changePassword($first, 'new-password'), qr/Password Changed/, 'first reset succeeds');
    ok(!defined(Noosphere::passwordResetTicket($second)), 'unused sibling rejected after reset');
    like(Noosphere::changePassword($second, 'not-written'), qr/Invalid password change URL/, 'unused sibling cannot replace password');
    like(Noosphere::changePassword($first, 'not-written'), qr/Invalid password change URL/, 'used link still rejects replay');
    ok(Noosphere::verifyAccountPassword(current_hash(), 'new-password'), 'winning password is intact');
    ok(Noosphere::passwordResetTicket($other), 'other account link is unaffected');
    my $fresh = Noosphere::createPasswordResetTicket('member');
    ok(Noosphere::passwordResetTicket($fresh), 'new request after reset is valid');
};

subtest 'two already-validated submissions cannot both succeed' => sub {
    my $first = Noosphere::createPasswordResetTicket('member');
    my $second = Noosphere::createPasswordResetTicket('member');
    my $ticket_a = Noosphere::passwordResetTicket($first);
    my $ticket_b;
    {
        local $Noosphere::dbh = $other_db;
        $ticket_b = Noosphere::passwordResetTicket($second);
    }
    ok($ticket_a && $ticket_b, 'both connections validate before either writes');
    my $winner = Noosphere::hashAccountPassword('winner');
    my $loser = Noosphere::hashAccountPassword('loser');
    is(Noosphere::consumePasswordResetTicket($ticket_a, $winner), 1, 'first conditional update succeeds');
    {
        local $Noosphere::dbh = $other_db;
        my $rv = Noosphere::consumePasswordResetTicket($ticket_b, $loser);
        ok(defined($rv) && $rv == 0, 'stale submission changes no account row');
    }
    is(current_hash(), $winner, 'losing submission cannot overwrite winner');
};

subtest 'same password text still invalidates older links' => sub {
    my $first = Noosphere::createPasswordResetTicket('member');
    my $second = Noosphere::createPasswordResetTicket('member');
    my $before = current_hash();
    like(Noosphere::changePassword($first, 'winner'), qr/Password Changed/, 'reset may keep the same password text');
    isnt(current_hash(), $before, 'new salt changes credential state');
    ok(!defined(Noosphere::passwordResetTicket($second)), 'same-password reset invalidates sibling');
};

subtest 'request racing with a completed reset remains invalid' => sub {
    my $winning_link = Noosphere::createPasswordResetTicket('member');
    my $select = \&Noosphere::dbSelectRowBound;
    my $interleave = 1;
    my $racing_link;
    {
        no warnings 'redefine';
        local *Noosphere::dbSelectRowBound = sub {
            my $row = $select->(@_);
            if ($interleave && $_[1] =~ /^SELECT uid, password_hash FROM users/) {
                $interleave = 0;
                like(Noosphere::changePassword($winning_link, 'race-winner'), qr/Password Changed/, 'reset finishes after issuance reads old credentials');
            }
            return $row;
        };
        $racing_link = Noosphere::createPasswordResetTicket('member');
    }
    ok(defined($racing_link), 'racing request stores its original snapshot');
    ok(!defined(Noosphere::passwordResetTicket($racing_link)), 'racing link cannot bypass completed reset');
    ok(Noosphere::passwordResetTicket(Noosphere::createPasswordResetTicket('member')), 'subsequent fresh request works');
};

subtest 'missing stamp and password changes outside recovery' => sub {
    my $link = Noosphere::createPasswordResetTicket('member');
    my $stamp = $db->selectrow_array('SELECT credential_stamp FROM password_reset_tokens WHERE token_hash = ?', undef, sha256_hex($link));
    for my $invalid (undef, '', 'broken') {
        $db->do('UPDATE password_reset_tokens SET credential_stamp = ? WHERE token_hash = ?', undef, $invalid, sha256_hex($link));
        ok(!defined(Noosphere::passwordResetTicket($link)), 'invalid credential binding fails closed');
    }
    $db->do('UPDATE password_reset_tokens SET credential_stamp = ? WHERE token_hash = ?', undef, $stamp, sha256_hex($link));
    $db->do('UPDATE users SET password_hash = ? WHERE uid = 1', undef, Noosphere::hashAccountPassword('outside-change'));
    ok(!defined(Noosphere::passwordResetTicket($link)), 'another password-change route also invalidates links');
};

subtest 'failed account update does not report success' => sub {
    my $link = Noosphere::createPasswordResetTicket('member');
    my $sibling = Noosphere::createPasswordResetTicket('member');
    my $before = current_hash();
    $db->do("CREATE TRIGGER fail_password_update BEFORE UPDATE ON users BEGIN SELECT RAISE(ABORT, 'private database detail'); END");
    my $message = Noosphere::changePassword($link, 'not-written');
    like($message, qr/Could not change/, 'write error reported generically');
    unlike($message, qr/private database detail/, 'driver detail not exposed');
    is(current_hash(), $before, 'failed update leaves account intact');
    ok(!defined(Noosphere::passwordResetTicket($link)), 'claimed link stays consumed on write failure');
    ok(Noosphere::passwordResetTicket($sibling), 'without a successful password change sibling still works');
    $db->do('DROP TRIGGER fail_password_update');
};

$other_db->disconnect();
$db->disconnect();
done_testing();
