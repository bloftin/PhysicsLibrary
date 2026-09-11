package Noosphere;

use strict;
use Digest::SHA qw(sha256_hex);
use Noosphere::PasswordStorage;

our $dbh;

sub sessionTime { return time; }

sub sessionLifetime {
    my $minutes = getConfig('cookie_timeout');
    return 14 * 24 * 60 * 60 unless defined($minutes) && !ref($minutes) &&
        $minutes =~ /\A[1-9][0-9]*\z/ && $minutes <= 14 * 24 * 60;
    return 60 * $minutes;
}

sub sessionIdleTimeout {
    my $seconds = getConfig('session_idle_timeout');
    return 2 * 60 * 60 unless defined($seconds) && !ref($seconds) &&
        $seconds =~ /\A[1-9][0-9]*\z/ && $seconds <= sessionLifetime();
    return $seconds;
}

sub validSessionToken {
    my ($token) = @_;
    return defined($token) && !ref($token) && $token =~ /\A[0-9a-f]{64}\z/;
}

sub sessionCredentialStamp {
    my ($hash, $access) = @_;
    return undef unless validPasswordHash($hash) && defined($access) && !ref($access) &&
        $access =~ /\A-?[0-9]+\z/;
    return sha256_hex(join(':', 'session-v1', $hash, $access));
}

# Bind issuance to the credentials that were actually verified at login.
sub makeTicket {
    my ($uid, $ip, $minutes, $login_time, $password_hash, $access) = @_;
    return undef unless defined($uid) && !ref($uid) && $uid =~ /\A[1-9][0-9]*\z/;
    my $stamp = sessionCredentialStamp($password_hash, $access);
    return undef unless defined $stamp;
    my $token = unpack('H*', passwordSalt() . passwordSalt());
    my $now = sessionTime();
    my $rv = dbExecuteBound($dbh,
        'INSERT INTO account_sessions (token_hash, uid, created, expires, last_seen, credential_stamp) '.
        'SELECT ?, uid, ?, ?, ?, ? FROM '.getConfig('user_tbl').
        ' WHERE uid = ? AND active = 1 AND password_hash = ? AND access = ?',
        sha256_hex($token), $now, $now + sessionLifetime(), $now, $stamp,
        $uid, $password_hash, $access);
    return defined($rv) && $rv == 1 ? $token : undef;
}

sub checkTicket {
    my ($token) = @_;
    return -1 unless validSessionToken($token);
    my $uid = eval {
        my $now = sessionTime();
        my $hash = sha256_hex($token);
        my $row = dbSelectRowBound($dbh,
            'SELECT s.uid, s.created, s.credential_stamp, u.password_hash, u.access '.
            'FROM account_sessions s JOIN '.getConfig('user_tbl').' u ON u.uid = s.uid '.
            'WHERE s.token_hash = ? AND s.expires > ? AND s.last_seen > ? AND u.active = 1',
            $hash, $now, $now - sessionIdleTimeout());
        if (!$row) {
            -1;
        } else {
            my $stamp = sessionCredentialStamp($row->{password_hash}, $row->{access});
            if (!defined($stamp) || $stamp ne $row->{credential_stamp} ||
                $row->{created} > $now || $now - $row->{created} >= sessionLifetime()) {
                dbExecuteBound($dbh, 'DELETE FROM account_sessions WHERE token_hash = ?', $hash);
                -1;
            } else {
                dbExecuteBound($dbh,
                    'UPDATE account_sessions SET last_seen = ? WHERE token_hash = ? AND last_seen < ?',
                    $now, $hash, $now);
                $row->{uid};
            }
        }
    };
    return defined($uid) && $uid > 0 ? $uid : -1;
}

sub revokeTicket {
    my ($token) = @_;
    return 1 unless validSessionToken($token);
    dbExecuteBound($dbh, 'DELETE FROM account_sessions WHERE token_hash = ?', sha256_hex($token));
    return 1;
}

sub revokeUserSessions {
    my ($uid) = @_;
    die "Invalid account.\n" unless defined($uid) && !ref($uid) && $uid =~ /\A[1-9][0-9]*\z/;
    dbExecuteBound($dbh, 'DELETE FROM account_sessions WHERE uid = ?', $uid);
    return 1;
}

sub logoutFormToken {
    my ($token) = @_;
    return validSessionToken($token) ? sha256_hex('logout-v1:' . $token) : '';
}

sub setAccountActive {
    my ($uid, $active) = @_;
    die "Invalid account.\n" unless defined($uid) && !ref($uid) && $uid =~ /\A[1-9][0-9]*\z/;
    die "Invalid account state.\n" unless defined($active) && !ref($active) && $active =~ /\A[01]\z/;
    revokeUserSessions($uid) if $active;
    dbExecuteBound($dbh, 'UPDATE '.getConfig('user_tbl').' SET active = ? WHERE uid = ?', $active, $uid);
    revokeUserSessions($uid) unless $active;
    return 1;
}

1;
