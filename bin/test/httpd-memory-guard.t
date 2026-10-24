#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

open my $in, '<', "$FindBin::Bin/../../etc/httpd-physicslibrary.conf" or die $!;
my $base_config = do { local $/; <$in> };
close $in;

open $in, '<', "$FindBin::Bin/../../etc/httpd-physicslibrary-le-ssl.conf" or die $!;
my $config = do { local $/; <$in> };
close $in;

like(
    $base_config,
    qr{MaxRequestWorkers\s+8},
    'prefork worker concurrency leaves memory for the host and rendering',
);
like(
    $base_config,
    qr{MaxConnectionsPerChild\s+10},
    'base prefork workers have a short connection lifetime',
);
like(
    $config,
    qr{<IfModule\s+mpm_prefork_module>\s*#.*?\s*MaxConnectionsPerChild\s+10\s*</IfModule>}s,
    'HTTPS configuration keeps the effective prefork lifetime short',
);

my ($primary_vhost) = $config =~ m{
    <VirtualHost\s+\*:443>\s*
    ServerName\s+physicslibrary\.org\b
    (.*?)
    </VirtualHost>
}sx;
ok(defined $primary_vhost, 'primary HTTPS virtual host is present');
like(
    $primary_vhost,
    qr{RewriteRule\s+\^/\?versions\(\?:/\|\$\)\s+-\s+\[F,L\]},
    'primary HTTPS virtual host rejects direct version archive requests',
);

my @crawler_rules = $config =~ /RewriteCond\s+%\{HTTP_USER_AGENT\}\s+\([^\n]*\bSogou\b[^\n]*\bBytespider\b[^\n]*\bdwnupd\b[^\n]*\)\s+\[NC\]/g;
is(scalar @crawler_rules, 3, 'all HTTPS virtual hosts reject the observed abusive crawlers');

my @scanner_includes = $config =~ /^\s*Include \/var\/www\/pp\/etc\/httpd-scanner-404\.conf\s*$/mg;
is(scalar @scanner_includes, 3, 'all HTTPS virtual hosts use the shared early scanner guard');

open $in, '<', "$FindBin::Bin/../../etc/httpd-scanner-404.conf" or die $!;
my $scanner = do { local $/; <$in> };
close $in;
like($scanner, qr/RewriteCond\s+%\{QUERY_STRING\}\s+\(\^\|&\)p=php.*?RewriteRule\s+\^\s+-\s+\[R=404,L\]/s,
    'observed PHP traversal-query probes still stop before application handling');
like($scanner, qr/^RewriteRule .*root\|home\|srv\|storage\|vendor\|config\|wordpress.*\[R=404,L,NC\]$/m,
    'common scanner-only path roots retain early rejection');
like($scanner, qr/^RewriteRule .*\|git\|aws\|ssh\|claude\|codex\|gemini\|config\|openclaw\|nerve.*\[R=404,L,NC\]$/m,
    'credential-directory probes retain early rejection');

done_testing();
