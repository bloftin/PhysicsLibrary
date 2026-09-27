#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RenderLog;
use IO::Select;
use IPC::Open3;
use Symbol qw(gensym);

my @lines;
local $SIG{__WARN__} = sub { push @lines, $_[0] };
ok(!Noosphere::RenderLog::context(0, 'objects', 376, 'make4ht'), 'logging can be disabled');
is(Noosphere::RenderLog::run('off', sub { 7 }), 7, 'disabled callback runs');
is(scalar @lines, 0, 'disabled logging emits nothing');

{
    local $Noosphere::RenderLog::CURRENT = Noosphere::RenderLog::context(1, 'objects', 376, 'make4ht');
    my $trace = $Noosphere::RenderLog::CURRENT->{trace};
    is(Noosphere::RenderLog::context(1, 'objects', 376, 'make4ht')->{trace}, $trace,
        'nested stages share the render correlation ID');
    my @result = Noosphere::RenderLog::run('outer', sub {
        Noosphere::RenderLog::run('inner', sub { return ('document', 'links') });
    });
    is_deeply(\@result, ['document', 'links'], 'list results survive nested tracing');
    is_deeply([map { /stage=(\S+) event=(\S+)/; "$1:$2" } @lines],
        [qw(outer:begin inner:begin inner:end outer:end)], 'nested stage ordering is preserved');
    like($lines[0], qr/trace=\Q$trace\E pid=$$ table=objects object=376 method=make4ht/,
        'line identifies the process, object, method, and render');
    like($lines[0], qr/elapsed_ms=\d+ stage_ms=\d+ rss_kb=(?:\d+|NA) peak_rss_kb=(?:\d+|NA) vm_kb=(?:\d+|NA)/,
        'timing and memory fields are always present');
    my @contexts;
    Noosphere::RenderLog::run('void', sub { push @contexts, defined(wantarray) ? 'wrong' : 'void' });
    my $scalar = Noosphere::RenderLog::run('scalar', sub { push @contexts, wantarray ? 'wrong' : 'scalar'; 0 });
    is_deeply(\@contexts, [qw(void scalar)], 'void and scalar calling contexts are preserved');
    is($scalar, 0, 'false return value is preserved');

    my $exception = bless {}, 'RenderFailure';
    eval { Noosphere::RenderLog::run('failure', sub { die $exception }) };
    is($@, $exception, 'original exception object is rethrown');
    like($lines[-1], qr/stage=failure event=error/, 'exception emits an error breadcrumb');

    local $@ = 'prior error';
    local $? = 1792;
    local $! = 2;
    Noosphere::RenderLog::emit('status', 'end', 99, $Noosphere::RenderLog::CURRENT->{started});
    is($@, 'prior error', 'logger preserves eval error');
    is($?, 1792, 'logger preserves child status');
    is(0 + $!, 2, 'logger preserves errno');
    {
        local $SIG{__WARN__} = sub { die 'logger failed' };
        is(Noosphere::RenderLog::run('logging_failure', sub { 42 }), 42,
            'logging failure does not break the render');
    }
    is(Noosphere::RenderLog::token("objects\ninjected=yes"), 'objects_injected_yes',
        'metadata cannot inject extra lines or fields');
    is(length(Noosphere::RenderLog::token('x' x 2000)), 100, 'metadata is bounded');

    # Exercise the real command wrapper without loading Apache/DB dependencies.
    open my $fh, '<', "$FindBin::Bin/../../lib/Noosphere/Latex.pm" or die $!;
    my $source = do { local $/; <$fh> };
    close $fh;
    for my $name (qw(runExternalCommand read_command_pipes)) {
        my ($body) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        eval $body;
        die $@ if $@;
    }
    my ($status, $out, $err) = runExternalCommand($^X,
        ['-e', 'print "stdout"; print STDERR "stderr"; exit 7'], 5);
    is($status >> 8, 7, 'real child exit status is unchanged by tracing');
    is($out, 'stdout', 'converter stdout is unchanged');
    is($err, 'stderr', 'converter stderr is unchanged');
    like(join('', @lines), qr/stage=external.capture event=begin/, 'pipe capture has its own breadcrumb');
    unlike(join('', @lines), qr/print STDERR|document|prior error|logger failed/,
        'logs do not include command arguments, callback results, or exception messages');
    my ($exit_status, $exit_out, $exit_err) = runExternalCommand($^X,
        ["-I$FindBin::Bin/../../lib", '-MNoosphere::RenderLog', '-MPOSIX', '-e',
        'local $Noosphere::RenderLog::CURRENT = Noosphere::RenderLog::context(1,"objects",376,"make4ht"); Noosphere::RenderLog::run("abrupt_exit", sub { POSIX::_exit(9) });'], 5);
    is($exit_status >> 8, 9, 'abrupt child exits with expected status');
    like($exit_err, qr/stage=abrupt_exit event=begin/, 'begin record survives exit without Perl cleanup');
    unlike($exit_err, qr/event=end/, 'abrupt exit does not produce a misleading end record');
    is($exit_out, '', 'diagnostics never go into rendered stdout');
}
ok(!defined $Noosphere::RenderLog::CURRENT, 'context does not leak into the next request');
done_testing();
