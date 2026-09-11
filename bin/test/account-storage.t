#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::PasswordStorage;
use Encode qw(encode);

{
    package Noosphere;
    our $dbh;
    sub dbSelect { return (1, bless({}, 'StorageProfileStatement')); }
    package StorageProfileStatement;
    sub fetchrow_hashref { return {uid => 42, username => 'member', password => 'private', password_hash => 'private-hash'}; }
    sub finish { return 1; }
}
for my $file (['DB.pm', qw(dbSelectRowBound dbExecuteBound dbRunBound)],
              ['UserData.pm', qw(validUserId getUserData)]) {
    my ($path, @names) = @$file;
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/$path" or die $!;
    my $source = do { local $/; <$in> };
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name missing" unless $sub;
        eval "package Noosphere; our \$dbh; $sub";
        die $@ if $@;
    }
}

subtest 'hashing and exact verification' => sub {
    my $password = q{A long phrase with 'quotes' \ and spaces};
    my $a = Noosphere::hashAccountPassword($password);
    my $b = Noosphere::hashAccountPassword($password);
    ok(Noosphere::validPasswordHash($a), 'current Argon2id policy');
    isnt($a, $b, 'independent random salts');
    ok(length($a) < 255, 'fits hash column');
    unlike($a, qr/\Q$password\E/, 'not plaintext');
    ok(Noosphere::verifyAccountPassword($a, $password), 'correct password');
    ok(!Noosphere::verifyAccountPassword($a, lc($password)), 'case matters');
    ok(!Noosphere::verifyAccountPassword($a, "$password "), 'trailing space matters');
    ok(!Noosphere::verifyAccountPassword($a, 'wrong'), 'wrong password');
    for my $p ('0', ' ', "nul\0inside", 'x' x 4096, '$argon2id$looks-like-a-hash') {
        ok(Noosphere::verifyAccountPassword(Noosphere::hashAccountPassword($p), $p), 'literal password round trip');
    }
    my $unicode = "caf\x{e9}\x{1f680}";
    my $encoded = encode('UTF-8', $unicode);
    my $hash = Noosphere::hashAccountPassword($unicode);
    ok(Noosphere::verifyAccountPassword($hash, $encoded), 'UTF-8 octets and decoded characters agree');
    is($unicode, "caf\x{e9}\x{1f680}", 'hashing does not modify input');
    for my $bad (undef, '', [], 'x' x 4097) {
        eval { Noosphere::hashAccountPassword($bad) };
        is($@, "Could not prepare password.\n", 'invalid input has bounded generic error');
        ok(!Noosphere::verifyAccountPassword($a, $bad), 'invalid input cannot authenticate');
    }
    for my $bad (undef, '', [], $password, '$2b$unknown', $a."\n", $a =~ s/m=19456/m=999999999/r) {
        ok(!Noosphere::verifyAccountPassword($bad, $password), 'malformed or unknown format has no fallback');
    }
};

subtest 'failures and general user data' => sub {
    {
        no warnings 'redefine';
        local *Noosphere::passwordSalt = sub { die 'private random-source details'; };
        eval { Noosphere::hashAccountPassword('private-input') };
        is($@, "Could not prepare password.\n", 'random-source failure is closed and redacted');
    }
    {
        no warnings 'redefine';
        local *Noosphere::argon2id_pass = sub { return 'bad-output'; };
        eval { Noosphere::hashAccountPassword('private-input') };
        is($@, "Could not prepare password.\n", 'invalid library output cannot be stored');
    }
    my $data = Noosphere::getUserData(42);
    is($data->{username}, 'member', 'ordinary user data retained');
    ok(!exists($data->{password}) && !exists($data->{password_hash}), 'credential fields removed from general data');
};

subtest 'resumable isolated migration' => sub {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'Optional local integration requires DBI and DBD::SQLite';
    my $db = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1, PrintError => 0, sqlite_unicode => 1});
    $db->sqlite_create_function('OCTET_LENGTH', 1, sub { use bytes; return defined($_[0]) ? length($_[0]) : undef; });
    $db->do("CREATE TABLE users (uid INTEGER PRIMARY KEY, password TEXT NOT NULL DEFAULT '', password_hash TEXT, active INTEGER)");
    my %legacy = (-1 => 'system-value', 1 => q{quote'\literal}, 2 => 'inactive-password',
        3 => '   ', 4 => "caf\x{e9}\x{1f680}", 5 => "null\0inside", 6 => '$argon2id$literal');
    my $insert = $db->prepare('INSERT INTO users (uid, password, active) VALUES (?, ?, ?)');
    $insert->execute($_, $legacy{$_}, $_ == 2 ? 0 : 1) for sort {$a <=> $b} keys %legacy;
    $insert->execute(7, '', 1);
    is_deeply(Noosphere::accountStorageStatus($db), {legacy => 7, hashed => 0, empty => 1, mixed => 0, invalid => 0}, 'status counts all accounts including negative IDs and spaces');
    is(Noosphere::migrateAccountStorage($db, 2), 2, 'bounded first batch');
    my $first_hash = $db->selectrow_array('SELECT password_hash FROM users WHERE uid = -1');
    is(Noosphere::accountStorageStatus($db)->{legacy}, 5, 'remaining work counted');
    is(Noosphere::migrateAccountStorage($db, 100), 5, 'resume finishes all remaining accounts');
    is(Noosphere::migrateAccountStorage($db, 100), 0, 'repeat is a no-op');
    is($db->selectrow_array('SELECT password_hash FROM users WHERE uid = -1'), $first_hash, 'already converted hash not rehashed');
    is_deeply(Noosphere::accountStorageStatus($db), {legacy => 0, hashed => 7, empty => 1, mixed => 0, invalid => 0}, 'clean final status');
    for my $uid (sort {$a <=> $b} keys %legacy) {
        my $row = $db->selectrow_hashref('SELECT * FROM users WHERE uid = ?', undef, $uid);
        is($row->{password}, '', 'legacy value cleared');
        ok(Noosphere::verifyAccountPassword($row->{password_hash}, $legacy{$uid}), 'same password remains usable');
    }
    is($db->selectrow_array('SELECT active FROM users WHERE uid = 2'), 0, 'inactive account stays inactive');
    ok(!defined($db->selectrow_array('SELECT password_hash FROM users WHERE uid = 7')), 'empty account remains without a usable password');

    $insert->execute(8, 'not-cleared', 1);
    {
        no warnings 'redefine';
        local *Noosphere::passwordSalt = sub { die 'unavailable'; };
        eval { Noosphere::migrateAccountStorage($db, 100) };
        like($@, qr/Could not prepare password/, 'hashing error aborts batch');
    }
    is($db->selectrow_array('SELECT password FROM users WHERE uid = 8'), 'not-cleared', 'failed hash leaves original intact');
    my $replacement = Noosphere::hashAccountPassword('new-password');
    my $execute = \&Noosphere::dbExecuteBound;
    {
        no warnings 'redefine';
        local *Noosphere::dbExecuteBound = sub {
            $db->do("UPDATE users SET password = '', password_hash = ? WHERE uid = 8", undef, $replacement);
            return $execute->(@_);
        };
        eval { Noosphere::migrateAccountStorage($db, 100) };
        like($@, qr/Account changed during migration/, 'concurrent change detected');
    }
    is($db->selectrow_array('SELECT password_hash FROM users WHERE uid = 8'), $replacement, 'new password never overwritten');
    $db->do("UPDATE users SET password = 'leftover' WHERE uid = 8");
    eval { Noosphere::migrateAccountStorage($db, 100) };
    like($@, qr/Storage check failed/, 'mixed state refuses migration');
    is(Noosphere::accountStorageStatus($db)->{mixed}, 1, 'mixed state counted');
    $db->do("UPDATE users SET password = '', password_hash = 'broken' WHERE uid = 8");
    eval { Noosphere::migrateAccountStorage($db, 100) };
    like($@, qr/Storage check failed/, 'invalid hash refuses migration');
    is(Noosphere::accountStorageStatus($db)->{invalid}, 1, 'invalid state counted');
};

done_testing();
