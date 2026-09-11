package Noosphere;

use strict;
use warnings;
use Crypt::Argon2 0.032 qw(argon2id_pass argon2id_verify);
use Encode qw(encode FB_CROAK LEAVE_SRC);

sub passwordOctets {
    my ($password) = @_;
    return undef unless defined($password) && !ref($password) && length($password);
    my $bytes = utf8::is_utf8($password)
        ? encode('UTF-8', $password, FB_CROAK | LEAVE_SRC) : $password;
    return length($bytes) <= 4096 ? $bytes : undef;
}

sub validPasswordHash {
    my ($hash) = @_;
    return defined($hash) && !ref($hash) &&
        $hash =~ /\A\$argon2id\$v=19\$m=19456,t=2,p=1\$[A-Za-z0-9+\/]{22}\$[A-Za-z0-9+\/]{43}\z/;
}

sub passwordSalt {
    open my $rng, '<:raw', '/dev/urandom' or die "Password service unavailable.\n";
    my $salt = '';
    while (length($salt) < 16) {
        my $count = sysread($rng, my $chunk, 16 - length($salt));
        die "Password service unavailable.\n" unless defined($count) && $count > 0;
        $salt .= $chunk;
    }
    close $rng;
    return $salt;
}

sub hashAccountPassword {
    my ($password) = @_;
    my $hash;
    my $ok = eval {
        my $bytes = passwordOctets($password);
        die 'invalid password' unless defined $bytes;
        $hash = argon2id_pass($bytes, passwordSalt(), 2, '19M', 1, 32);
        die 'invalid output' unless validPasswordHash($hash);
        1;
    };
    die "Could not prepare password.\n" unless $ok;
    return $hash;
}

sub verifyAccountPassword {
    my ($hash, $password) = @_;
    return 0 unless validPasswordHash($hash);
    return eval {
        my $bytes = passwordOctets($password);
        defined($bytes) && argon2id_verify($hash, $bytes) ? 1 : 0;
    } || 0;
}

sub accountStorageStatus {
    my ($dbh) = @_;
    my %status = (legacy => 0, hashed => 0, empty => 0, mixed => 0, invalid => 0);
    my $last;
    while (my $row = dbSelectRowBound($dbh,
        'SELECT uid, password_hash, CASE WHEN OCTET_LENGTH(password) > 0 THEN 1 ELSE 0 END AS has_legacy FROM users'.
        (defined($last) ? ' WHERE uid > ?' : '').' ORDER BY uid LIMIT 1', defined($last) ? ($last) : ())) {
        $last = $row->{uid};
        if (defined($row->{password_hash})) {
            $status{hashed}++;
            $status{invalid}++ unless validPasswordHash($row->{password_hash});
            $status{mixed}++ if $row->{has_legacy};
        } elsif (!$row->{has_legacy}) {
            $status{empty}++;
        }
        $status{legacy}++ if $row->{has_legacy};
    }
    return \%status;
}

sub migrateAccountStorage {
    my ($dbh, $limit) = @_;
    die "Invalid batch size.\n" unless defined($limit) && !ref($limit) &&
        $limit =~ /\A[1-9][0-9]*\z/ && $limit <= 10000;
    my $status = accountStorageStatus($dbh);
    die "Storage check failed; no migration performed.\n" if $status->{mixed} || $status->{invalid};
    my $migrated = 0;
    my $last;
    while ($migrated < $limit) {
        my $row = dbSelectRowBound($dbh,
            'SELECT uid, password FROM users WHERE password_hash IS NULL AND OCTET_LENGTH(password) > 0'.
            (defined($last) ? ' AND uid > ?' : '').' ORDER BY uid LIMIT 1', defined($last) ? ($last) : ());
        last unless $row;
        $last = $row->{uid};
        my $hash = hashAccountPassword($row->{password});
        die "Storage check failed.\n" unless verifyAccountPassword($hash, $row->{password});
        # Compare bytes, not the account column's case-insensitive collation.
        my $match = $dbh->{Driver}->{Name} =~ /\A(?:mysql|MariaDB)\z/
            ? 'BINARY password = BINARY ?' : 'password = ?';
        my $rv = dbExecuteBound($dbh,
            "UPDATE users SET password_hash = ?, password = '' WHERE uid = ? AND password_hash IS NULL AND $match",
            $hash, $row->{uid}, $row->{password});
        die "Account changed during migration; stop other account writers and retry.\n"
            unless defined($rv) && $rv == 1;
        $migrated++;
    }
    return $migrated;
}

1;
