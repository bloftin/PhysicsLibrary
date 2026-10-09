use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use Cwd qw(abs_path);

my $script = abs_path("$FindBin::Bin/../backup-db");
plan skip_all => 'Linux command-line backup test' unless $^O eq 'linux';
for my $tool (qw(bash gzip sha256sum flock timeout realpath)) {
    system('sh', '-c', "command -v $tool >/dev/null") == 0 or plan skip_all => "Missing $tool";
}
my $root = tempdir(CLEANUP => 1);
my $mockbin = "$root/bin";
make_path($mockbin);
my $real_gzip = qx{sh -c 'command -v gzip'};
chomp $real_gzip;

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
}
write_file("$mockbin/mariadb-dump", <<'MOCK');
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_ARGS"
case "${MOCK_MODE:-success}" in
  crashed)
    printf '%s\n' 'CREATE TABLE books (uid INT);'
    printf '%s\n' 'Table books_uid_seq is marked as crashed (145)' >&2
    exit 2 ;;
  hang) sleep 5 ;;
  nofooter) printf '%s\n' 'CREATE TABLE books (uid INT);'; exit 0 ;;
esac
printf '%s\n' '-- MariaDB dump' 'CREATE TABLE books (uid INT);' \
  'INSERT INTO books VALUES (406);' '-- Dump completed on 2026-10-09 12:00:00'
MOCK
write_file("$mockbin/gzip", <<'MOCK');
#!/usr/bin/env bash
if [[ "$1" == -1 ]]; then
  case "${MOCK_GZIP:-success}" in
    failed) cat >/dev/null; exit 3 ;;
    corrupt) cat >/dev/null; printf 'not gzip'; exit 0 ;;
  esac
fi
exec "$REAL_GZIP" "$@"
MOCK
write_file("$mockbin/sha256sum", <<'MOCK');
#!/usr/bin/env bash
if [[ "${MOCK_CHECKSUM:-success}" == failed ]]; then exit 4; fi
exec /usr/bin/sha256sum "$@"
MOCK
chmod 0700, "$mockbin/mariadb-dump", "$mockbin/gzip", "$mockbin/sha256sum";

sub run_backup {
    my ($name, $mode, $gzip_mode, @options) = @_;
    my $out = "$root/$name";
    local $ENV{PATH} = "$mockbin:$ENV{PATH}";
    local $ENV{MOCK_ARGS} = "$root/$name.args";
    local $ENV{MOCK_MODE} = $mode;
    local $ENV{MOCK_GZIP} = $gzip_mode;
    local $ENV{REAL_GZIP} = $real_gzip;
    my $pid = fork();
    die 'fork' unless defined $pid;
    if (!$pid) {
        open STDOUT, '>', "$root/$name.stdout" or die $!;
        open STDERR, '>', "$root/$name.stderr" or die $!;
        exec 'bash', $script, '--output-dir', $out, @options;
        die 'exec';
    }
    waitpid($pid, 0);
    my $status = $? >> 8;
    return ($status, $out);
}
sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    return do { local $/; <$fh> };
}
sub private_mode {
    return (stat($_[0]))[2] & 0777;
}

my ($status, $out) = run_backup('help', 'success', 'success', '--help');
is($status, 0, 'help succeeds');
ok(!-e $out, 'help does not create directory');
ok(!-e "$root/help.args", 'help does not connect');
($status, $out) = run_backup('noack', 'success', 'success');
isnt($status, 0, 'write lock requires acknowledgement');
ok(!-e $out, 'missing acknowledgement creates no files');

($status, $out) = run_backup('success', 'success', 'success', '--allow-write-lock', '--socket', '/tmp/test.sock');
is($status, 0, 'complete backup succeeds');
my @backups = glob("$out/*/dump.sql.gz");
is(scalar @backups, 1, 'exactly one completed dump');
my $backup = $backups[0];
is(private_mode($out), 0700, 'private output directory');
is(private_mode($backup), 0600, 'private dump');
is(private_mode("$backup.sha256"), 0600, 'private checksum');
ok(!-e "$backup.partial", 'partial renamed only on success');
is(system($real_gzip, '-t', $backup), 0, 'actual gzip verifies');
my $sum = read_file("$backup.sha256");
like($sum, qr/\A[a-f0-9]{64}  dump\.sql\.gz\n\z/, 'portable relative checksum filename');
my $digest = `sha256sum '$backup'`;
is(substr($sum, 0, 64), substr($digest, 0, 64), 'checksum matches actual dump');
my @args = split /\n/, read_file("$root/success.args");
is($args[0], '--no-defaults', 'ignores inherited dump exclusions/force');
for my $arg (qw(--protocol=socket --socket=/tmp/test.sock --lock-all-tables --quick --routines --events --triggers --hex-blob --dump-date pp)) {
    ok(scalar(grep { $_ eq $arg } @args), "dump option $arg");
}
unlike(join(' ', @args), qr/--force|--ignore-table|--single-transaction|--password/, 'no skipping, transactional-only backup, or inline credentials');

for my $case (['crashed', 'crashed', 'success'], ['compression', 'success', 'failed'],
              ['integrity', 'success', 'corrupt'], ['footer', 'nofooter', 'success']) {
    my ($name, $mode, $gzip_mode) = @$case;
    ($status, $out) = run_backup($name, $mode, $gzip_mode, '--allow-write-lock');
    isnt($status, 0, "$name failure exits nonzero");
    is(scalar(glob("$out/*/dump.sql.gz")), undef, "$name failure publishes no completed dump");
    my @partials = glob("$out/*/dump.sql.gz.partial");
    is(scalar @partials, 1, "$name failure retains partial privately");
    is(private_mode($partials[0]), 0600, "$name partial private");
    like(read_file("$root/$name.stderr"), qr/Backup FAILED/, "$name reports failure");
    unlike(read_file("$root/$name.stdout"), qr/Backup completed/, "$name never claims success");
}
my @logs = glob("$root/crashed/*/dump.stderr");
like(read_file($logs[0]), qr/crashed \(145\)/, 'original crash diagnostic retained');

{
    local $ENV{MOCK_CHECKSUM} = 'failed';
    ($status, $out) = run_backup('checksum', 'success', 'success', '--allow-write-lock');
    isnt($status, 0, 'checksum failure exits nonzero');
    is(scalar(glob("$out/*/dump.sql.gz")), undef, 'checksum failure publishes no dump');
}
($status, $out) = run_backup('timeout', 'hang', 'success', '--allow-write-lock', '--timeout', '1');
isnt($status, 0, 'hung dump times out');
is(scalar(glob("$out/*/dump.sql.gz")), undef, 'timeout publishes no completed dump');

for my $case (['dbname', '--database', '-bad'], ['timeoutzero', '--timeout', '0'],
              ['timeoutlarge', '--timeout', '99999'], ['unknown', '--force'],
              ['missingvalue', '--database'],
              ['relative', '--output-dir', 'relative'], ['webroot', '--output-dir', '/var/www/pp/backups'],
              ['project', '--output-dir', "$FindBin::Bin/../../tmp/private-backups"],
              ['socket', '--socket', 'relative.sock']) {
    my ($name, @opts) = @$case;
    ($status, $out) = run_backup($name, 'success', 'success', '--allow-write-lock', @opts);
    isnt($status, 0, "rejects $name");
    ok(!-e "$root/$name.args", "$name rejected before dump");
}
make_path("$root/public", {mode => 0755});
($status, $out) = run_backup('public', 'success', 'success', '--allow-write-lock');
isnt($status, 0, 'refuses nonprivate existing directory');
is(private_mode($out), 0755, 'does not change existing directory permissions');
make_path("$root/locked", {mode => 0700});
open my $lock, '>', "$root/locked/.backup-db.lock" or die $!;
use Fcntl qw(LOCK_EX LOCK_NB);
flock($lock, LOCK_EX | LOCK_NB) or die $!;
($status, $out) = run_backup('locked', 'success', 'success', '--allow-write-lock');
isnt($status, 0, 'overlap rejected');
ok(!-e "$root/locked.args", 'overlap rejected before connecting');
close $lock;

symlink('/var/www/pp', "$root/web-alias") or die $!;
($status, $out) = run_backup('alias', 'success', 'success', '--allow-write-lock', '--output-dir', "$root/web-alias/backups");
isnt($status, 0, 'resolved webroot symlink rejected');
ok(!-e "$root/alias.args", 'symlink rejected before dump');
($status, $out) = run_backup('success', 'success', 'success', '--allow-write-lock');
is($status, 0, 'second backup succeeds');
@backups = glob("$out/*/dump.sql.gz");
is(scalar @backups, 2, 'repeat run does not overwrite or prune previous backup');
is(read_file("$backup.sha256"), $sum, 'previous backup checksum unchanged');

done_testing();
