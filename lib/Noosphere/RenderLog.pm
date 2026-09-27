package Noosphere::RenderLog;

use strict;
use warnings;
use Time::HiRes qw(time clock_gettime CLOCK_MONOTONIC);

our $CURRENT;
my $serial = 0;

sub context {
    my ($enabled, $table, $object, $method) = @_;
    return $CURRENT if $CURRENT;
    return undef unless $enabled;
    return {
        trace => join('-', $$, int(time * 1000000), ++$serial),
        table => $table, object => $object, method => $method,
        started => clock_gettime(CLOCK_MONOTONIC), span => 0,
    };
}

sub memory {
    local $/ = "\n";
    my %values = (rss_kb => 'NA', peak_rss_kb => 'NA', vm_kb => 'NA');
    if (open my $status, '<', '/proc/self/status') {
        my %names = (VmRSS => 'rss_kb', VmHWM => 'peak_rss_kb', VmSize => 'vm_kb');
        while (my $line = <$status>) {
            if ($line =~ /^(VmRSS|VmHWM|VmSize):\s+(\d+)\s+kB/) {
                $values{$names{$1}} = $2;
            }
        }
        close $status;
    }
    return %values;
}

sub token {
    my $value = defined($_[0]) ? substr($_[0], 0, 100) : 'NA';
    $value =~ s/[^A-Za-z0-9_.:-]/_/g;
    return length($value) ? $value : 'NA';
}

sub emit {
    return unless $CURRENT;
    my ($stage, $event, $span, $started) = @_;
    # Diagnostics must not replace an exception or the converter's exit status.
    local ($@, $!, $?);
    eval {
        my $now = clock_gettime(CLOCK_MONOTONIC);
        my %fields = (
            trace => $CURRENT->{trace}, pid => $$,
            table => $CURRENT->{table}, object => $CURRENT->{object},
            method => $CURRENT->{method}, stage => $stage, event => $event,
            span => $span,
            elapsed_ms => int(1000 * ($now - $CURRENT->{started})),
            stage_ms => int(1000 * ($now - $started)),
            memory(),
        );
        my @order = qw(trace pid table object method stage event span elapsed_ms stage_ms rss_kb peak_rss_kb vm_kb);
        my $line = 'PL_RENDER ' . join(' ', map { "$_=" . token($fields{$_}) } @order);
        warn "$line\n";
        1;
    };
}

sub run {
    my ($stage, $code) = @_;
    return $code->() unless $CURRENT;
    my $want = wantarray;
    my $span = ++$CURRENT->{span};
    my $started = clock_gettime(CLOCK_MONOTONIC);
    emit($stage, 'begin', $span, $started);
    my (@result, $result, $error, $ok);
    {
        local $@;
        $ok = eval {
            if (!defined $want) { $code->(); }
            elsif ($want) { @result = $code->(); }
            else { $result = $code->(); }
            1;
        };
        $error = $@ unless $ok;
    }
    emit($stage, $ok ? 'end' : 'error', $span, $started);
    die $error unless $ok;
    return $want ? @result : $result;
}

1;
