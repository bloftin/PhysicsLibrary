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

my @probe_path_rules = $config =~ /RewriteRule\s+\^\/\?\(\?:root\|home\|srv\|storage\|vendor\|config\|wordpress\|wp-admin\|wp-content\|wp-includes\)\(\?:\/\|\$\)\s+-\s+\[F,L,NC\]/g;
is(scalar @probe_path_rules, 3, 'all HTTPS virtual hosts reject common probe-only path roots');

my @credential_rules = $config =~ /RewriteRule\s+\^\/\?\(\?:\.\*\?\/\)\?\\\.\(\?:env\(\?:\[\.~\]\.\*\)\?\|git\|aws\|ssh\|claude\|codex\|gemini\|config\|openclaw\|nerve\)\(\?:\/\|\$\)\s+-\s+\[F,L,NC\]/g;
is(scalar @credential_rules, 3, 'all HTTPS virtual hosts reject credential-directory probes');

done_testing();
