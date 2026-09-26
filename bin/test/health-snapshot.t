use strict;
use warnings;
use Test::More;
use FindBin;

my $script = "$FindBin::Bin/../../etc/monitoring/physicslibrary-health-snapshot";

open my $fh, '<', $script or die "Cannot read $script: $!";
my $source = do { local $/; <$fh> };
close $fh;

like($source, qr/pressure_threshold_kb=.*262144/, 'monitor defaults memory-pressure snapshots to 256 MiB');
like($source, qr/memory-pressure\.log/, 'monitor records pressure snapshots separately from health rows');
like($source, qr/mem_available_kb < pressure_threshold_kb/, 'monitor only captures processes below the memory threshold');
like($source, qr/ps -eo pid,ppid,user,rss,pcpu,pmem,etime,comm,args --sort=-rss/, 'pressure snapshots include largest resident processes');
like($source, qr/PHYSICSLIBRARY_MEMORY_SNAPSHOT_THRESHOLD_KB/, 'memory threshold can be adjusted by deployment configuration');

done_testing();
