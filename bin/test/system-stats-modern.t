#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);

my $root = "$FindBin::Bin/../..";
open my $in, '<', "$root/lib/Noosphere/Stats.pm" or die $!;
my $source = do { local $/; <$in> };
my ($handler) = $source =~ /(sub getSystemStats \{.*?^\})/ms;
my ($host_reader) = $source =~ /(sub getSystemStatsHost \{.*?^\})/ms;
my $real_tt = eval {
    require Template;
    require Template::Stash;
    Template->new({ INCLUDE_PATH => "$root/stemplates", STASH => Template::Stash->new() });
};

{
    package Noosphere;
    our $dbms = 'MariaDB';
    our @queries;
    our %counts = (objects => 1193, users => 585, corrections => 86, messages => 325, hits => 4216365);
    sub getConfig {
        return $dbms if $_[0] eq 'dbms';
        return 'Physics Library' if $_[0] eq 'projname';
        return 'stemplates';
    }
    sub dbRowCount {
        push @queries, [@_];
        return $counts{$_[0]};
    }
    sub paddingTable { return $_[0] }
    sub errorMessage { return $_[0] }
}
{
    package StatsTemplate;
    our $name;
    our $vars;
    sub process {
        my ($self, $name, $vars, $output) = @_;
        $StatsTemplate::name = $name;
        $StatsTemplate::vars = $vars;
        $$output = 'rendered stats';
        return 1;
    }
}

ok($handler && $host_reader, 'stats handler and host reader are available');
ok(eval("package Noosphere; $handler\n$host_reader\n1"), 'stats helpers compile') or diag($@);

my $render_vars;
{
    no warnings qw(redefine once);
    local *Template::new = sub { bless {}, 'StatsTemplate' };
    is(Noosphere::getSystemStats(), 'rendered stats', 'stats render through the dedicated template');
    is($StatsTemplate::name, 'systemstats.tt', 'dedicated template is selected');
    is(scalar @Noosphere::queries, 25, 'five metrics are counted for all five periods');
    is_deeply([map $_->[0], @Noosphere::queries[0..4]],
        [qw(objects users corrections messages hits)], 'columns have a stable order');
    is_deeply($StatsTemplate::vars->{rows}[0]{counts},
        ['1,193', '585', '86', '325', '4,216,365'], 'counts stay aligned and large values are formatted');
    is($StatsTemplate::vars->{rows}[0]{label}, 'All time', 'all-time row has a readable label');
    is($Noosphere::queries[5][1], 'created>now() - interval 1 DAY', 'MariaDB daily filter is preserved');
    is($Noosphere::queries[15][1], 'created>now() - interval 30 DAY', 'MariaDB monthly filter is preserved');
    is($Noosphere::queries[20][1], 'created>now() - interval 365 DAY', 'MariaDB yearly filter is preserved');
    $render_vars = $StatsTemplate::vars;

    @Noosphere::queries = ();
    $Noosphere::dbms = 'pg';
    Noosphere::getSystemStats();
    is($Noosphere::queries[5][1], "created>CURRENT_TIMESTAMP+'-1 day'", 'PostgreSQL daily filter is preserved');
    is($Noosphere::queries[15][1], "created>CURRENT_TIMESTAMP+'-1 month'", 'PostgreSQL calendar-month filter is preserved');

    $Noosphere::dbms = 'mysql';
    $Noosphere::counts{hits} = undef;
    Noosphere::getSystemStats();
    is($StatsTemplate::vars->{rows}[0]{counts}[4], 'Unavailable', 'missing counts do not appear as zero');
    $Noosphere::dbms = 'unsupported';
    is(Noosphere::getSystemStats(), 'System statistics are unavailable for this database.', 'unsupported database has a readable error');
}

my $proc = tempdir(CLEANUP => 1);
sub write_fixture {
    my ($name, $text) = @_;
    open my $fh, '>', "$proc/$name" or die $!;
    print {$fh} $text;
    close $fh;
}
write_fixture('uptime', "512100.50 800000.00\n");
write_fixture('loadavg', "0.09 0.04 0.01 1/234 1234\n");
my $host = Noosphere::getSystemStatsHost($proc);
is($host->{uptime}, '5 days 22 hours 15 minutes', 'uptime is formatted from the Linux counter');
is_deeply($host->{load}, ['0.09', '0.04', '0.01'], 'load average preserves all three windows');
write_fixture('uptime', "90060.00 100.00\n");
is(Noosphere::getSystemStatsHost($proc)->{uptime}, '1 day 1 hour 1 minute', 'singular units are formatted');
write_fixture('uptime', "25.00 10.00\n");
is(Noosphere::getSystemStatsHost($proc)->{uptime}, 'Less than a minute', 'recent boots have a readable uptime');
write_fixture('uptime', "<script>invalid</script>\n");
write_fixture('loadavg', "invalid\n");
is_deeply(Noosphere::getSystemStatsHost($proc), { uptime => 'Unavailable' }, 'malformed system data is ignored');
is_deeply(Noosphere::getSystemStatsHost("$proc/missing"), { uptime => 'Unavailable' }, 'missing system files do not break stats');
unlike($handler, qr/spawn_proc_prog|RequestUtil|read_data/, 'stats no longer require Apache subprocess handles');

SKIP: {
    skip 'Template Toolkit is not installed', 4 unless $real_tt;
    $render_vars->{host} = { uptime => '5 days 22 hours 15 minutes', load => ['0.09', '0.04', '0.01'] };
    my $html = '';
    ok($real_tt->process('systemstats.tt', $render_vars, \$html), 'stats template renders') or diag($real_tt->error);
    like($html, qr/4,216,365/, 'rendered table includes the large view count');
    like($html, qr/0\.09 \/ 0\.04 \/ 0\.01/, 'rendered host status includes load averages');
    like($html, qr/<th scope="row">All time<\/th>/, 'table exposes period row headings');
}

done_testing();
