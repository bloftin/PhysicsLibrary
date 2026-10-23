#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Time::HiRes ();

my %sessions;
my @written_times;
my $user;
{
    package Noosphere;
    sub getConfig { return 'users' if $_[0] eq 'user_tbl'; }
    sub dbExecuteBound {
        my ($dbh, $sql, @bind) = @_;
        if ($sql =~ /\AINSERT INTO account_sessions /) {
            my ($key, $created, $expires, $seen, $stamp, $uid, $password_hash, $access) = @bind;
            return '0E0' unless $uid == $user->{uid} &&
                $password_hash eq $user->{password_hash} && $access == $user->{access};
            push @written_times, $created, $expires, $seen;
            # Model rounding on assignment to the production BIGINT columns.
            $sessions{$key} = {uid => $uid, credential_stamp => $stamp,
                created => int($created + .5), expires => int($expires + .5),
                last_seen => int($seen + .5)};
            return 1;
        }
        if ($sql =~ /\ADELETE FROM account_sessions WHERE token_hash = /) {
            return delete($sessions{$bind[0]}) ? 1 : '0E0';
        }
        if ($sql =~ /\AUPDATE account_sessions SET last_seen = /) {
            my ($now, $key, $before) = @bind;
            return '0E0' unless $sessions{$key} && $sessions{$key}{last_seen} < $before;
            push @written_times, $now;
            $sessions{$key}{last_seen} = int($now + .5);
            return 1;
        }
        die "Unexpected session test query\n";
    }
    sub dbSelectRowBound {
        my ($dbh, $sql, $key, $now, $idle_cutoff) = @_;
        my $row = $sessions{$key};
        return undef unless $row && $row->{expires} > $now && $row->{last_seen} > $idle_cutoff;
        return {%$row, password_hash => $user->{password_hash}, access => $user->{access}};
    }
}

subtest 'production search-before-session load order' => sub {
    # startup.pl loads Noosphere/NativeSearch before Login/Ticket. Force the
    # upper half of a second so an exported high-resolution time exposes the bug.
    no warnings 'redefine';
    local *Time::HiRes::time = sub { 2000000000.75 };
    require Noosphere::NativeSearch;
    ok(!defined(&Noosphere::time), 'search does not export a clock into the shared Noosphere package');
    require Noosphere::Ticket;
    my $before = CORE::time();
    my $now = Noosphere::sessionTime();
    my $after = CORE::time();
    is($now, int($now), 'session clock returns whole seconds despite search loading first');
    ok($now >= $before && $now <= $after, 'session clock uses core wall time, not the imported high-resolution timer');

    $user = {uid => 1, password_hash => Noosphere::hashAccountPassword('synthetic-clock-test'), access => 10};
    my $token = Noosphere::makeTicket(1, '', 1, 0, $user->{password_hash}, 10);
    ok(Noosphere::validSessionToken($token), 'session issuance succeeds');
    is(Noosphere::checkTicket($token), 1, 'immediate redirected request accepts a new session after BIGINT assignment');
    ok(!grep($_ != int($_), @written_times), 'all database timestamps are whole seconds before binding');
};

subtest 'whole-second clock remains isolated from future package imports' => sub {
    no warnings qw(redefine once);
    local *Noosphere::time = sub { 2000000000.99 };
    my $before = CORE::time();
    my $now = Noosphere::sessionTime();
    my $after = CORE::time();
    is($now, int($now), 'a different module cannot replace the session clock');
    ok($now >= $before && $now <= $after, 'explicit core clock wins over a shared-package override');
};

subtest 'actual future timestamps and changed credentials still invalidate' => sub {
    my $token = Noosphere::makeTicket(1, '', 1, 0, $user->{password_hash}, 10);
    require Digest::SHA;
    my $key = Digest::SHA::sha256_hex($token);
    $sessions{$key}{created} = CORE::time() + 60;
    is(Noosphere::checkTicket($token), -1, 'genuinely future-dated sessions remain rejected');
    ok(!exists($sessions{$key}), 'future-dated session is revoked');
    $token = Noosphere::makeTicket(1, '', 1, 0, $user->{password_hash}, 10);
    $key = Digest::SHA::sha256_hex($token);
    $user->{access}++;
    is(Noosphere::checkTicket($token), -1, 'privilege changes still invalidate sessions');
    ok(!exists($sessions{$key}), 'credential-bound session is revoked');
};

done_testing();
