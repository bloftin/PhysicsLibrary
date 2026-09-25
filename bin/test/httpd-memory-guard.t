#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

open my $in, '<', "$FindBin::Bin/../../etc/httpd-physicslibrary-le-ssl.conf" or die $!;
my $config = do { local $/; <$in> };
close $in;

like(
    $config,
    qr{<IfModule\s+mpm_prefork_module>\s*MaxConnectionsPerChild\s+1000\s*</IfModule>}s,
    'prefork workers have a finite connection lifetime',
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

done_testing();
