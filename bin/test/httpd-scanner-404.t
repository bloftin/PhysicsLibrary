#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use IO::Socket::INET;
use HTTP::Tiny;
use POSIX qw(setsid);
use Time::HiRes qw(sleep);

{
    package ApacheScannerTestServer;
    sub stop {
        my $pid = delete $_[0]{pid} or return;
        kill 'TERM', $pid;
        waitpid($pid, 0);
    }
    sub DESTROY { $_[0]->stop }
}

my $root = abs_path("$FindBin::Bin/../..");
my $snippet = "$root/etc/httpd-scanner-404.conf";
sub read_file {
    open my $in, '<', $_[0] or die "$! ($_[0])";
    return do { local $/; <$in> };
}
my $rules = read_file($snippet);
like($rules, qr/^ErrorDocument 404 "Not found\."$/m, 'inline error body cannot invoke an application error page');
unlike($rules, qr/^\s*(?:Perl\w+|SetHandler|ErrorDocument\s+404\s+\/)/m, 'guard has no application handler or error redirect');

for my $spec (['httpd-physicslibrary.conf',2], ['httpd-physicslibrary-le-ssl.conf',3]) {
    my @vhosts = read_file("$root/etc/$spec->[0]") =~ /(^<VirtualHost\b.*?^<\/VirtualHost>)/msg;
    is(scalar @vhosts, $spec->[1], "$spec->[0] live virtual host count");
    for my $vhost (@vhosts) {
        my ($host) = $vhost =~ /ServerName\s+(\S+)/;
        my @includes = $vhost =~ /^\s*Include \/var\/www\/pp\/etc\/httpd-scanner-404\.conf\s*$/mg;
        is(scalar @includes, 1, "$host has one mandatory shared guard");
        my $before = (split /Include \/var\/www\/pp\/etc\/httpd-scanner-404\.conf/, $vhost)[0];
        unlike($before, qr/^\s*(?:RewriteRule|Redirect|PerlRequire|<Location)\b/m,
            "$host guard precedes routing, redirects, and application setup");
    }
}

# Check path boundaries even on developer machines without Apache installed.
my @patterns = map { qr/$_/i } $rules =~ /^RewriteRule (\S+) - \[R=404,L,NC\]$/mg;
is(scalar @patterns, 4, 'four path-only scanner rules');
my @blocked = qw(
    /index.php /wp-login.php /xmlrpc.php /login.PHP5 /random/a.phtml
    /shell.phar /index.php/shell /index.php.bak /a.php~ /a.php;test
    /wp-admin/ /wp-content/plugins/ /wordpress/ /phpMyAdmin/ /pma/
    /.env /.env.local /nested/.env /nested/.git/config /composer.json /dump.sql
    /root/.ssh/id_rsa /vendor/autoload /config/settings /id_rsa.pub
);
my @allowed = (
    '/', '/?op=login', '/?op=search&q=php', '/?q=example.php',
    '/?op=getobj&from=books&id=7', '/?op=downloadfile&path=files/books/7/example.php',
    '/encyclopedia/Oscillation.html', '/encyclopedia/PHP.html', '/encyclopedia',
    '/browse/pacs/42/', '/files/books/7/lecture.pdf', '/snapshots/example.tar.gz',
    '/examples/one-point-oscillation/index.html', '/examples/gradient-lab/app.js',
    '/data/images/logo.png', '/awstatsicons/other/php.png', '/sitemap.xml', '/robots.txt',
    '/.well-known/acme-challenge/disposable-token', '/configuration.html', '/vendor-notes.html',
);
for my $url (@blocked, @allowed) {
    my ($path) = split /\?/, $url, 2;
    my $matched = grep {$path =~ $_} @patterns;
    my $expected = grep {$_ eq $url} @blocked;
    is(!!$matched, !!$expected, "path rules: $url");
}

my $httpd = $ENV{SCANNER_TEST_HTTPD};
my $modules = $ENV{SCANNER_TEST_MODULES} || '/usr/lib/apache2/modules';
if (!$httpd) {
    ($httpd) = grep {-x $_} qw(/usr/sbin/apache2 /usr/sbin/httpd);
}
SKIP: {
    skip 'Run unprivileged with Apache/mod_perl (or set SCANNER_TEST_HTTPD and SCANNER_TEST_MODULES) for integration', 1
        unless $> != 0 && $httpd && -x $httpd && -f "$modules/mod_perl.so";
    subtest 'real Apache returns small 404s without invoking Perl' => sub {
        my $dir = tempdir('pl-scanner-404-XXXXXX', TMPDIR=>1, CLEANUP=>1);
        my $socket = IO::Socket::INET->new(LocalAddr=>'127.0.0.1', LocalPort=>0, Listen=>1) or die $!;
        my $port = $socket->sockport;
        close $socket;
        my $marker = "$dir/perl-handler.log";
        my $fixture = <<'PERL';
package Scanner404Probe;
use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
sub handler {
    my $r = shift;
    open my $out, '>>', '__MARKER__' or die $!;
    print {$out} "Perl handler invoked\n";
    close $out;
    $r->content_type('text/plain');
    $r->print('APP_HANDLER');
    return 0;
}
1;
PERL
        $fixture =~ s/__MARKER__/$marker/;
        open my $out, '>', "$dir/Scanner404Probe.pm" or die $!;
        print {$out} $fixture; close $out;
        my %addresses = ('app.test'=>'127.0.0.1', 'assets.test'=>'127.0.0.2', 'redirect.test'=>'127.0.0.3');
        my $config = "ServerRoot \"$dir\"\nDefaultRuntimeDir \"$dir\"\nPidFile \"$dir/httpd.pid\"\n".
            "ServerName localhost\nErrorLog \"$dir/error.log\"\nLogLevel warn\n";
        $config .= "Listen $_:$port\n" for sort values %addresses;
        for my $module (qw(mpm_prefork authz_core alias rewrite perl)) {
            $config .= "LoadModule ${module}_module \"$modules/mod_$module.so\"\n";
        }
        $config .= "PerlRequire \"$dir/Scanner404Probe.pm\"\n".
            "ServerLimit 1\nStartServers 1\nMinSpareServers 1\nMaxSpareServers 1\nMaxRequestWorkers 1\n";
        # Simulate the main handler, asset vhost, and HTTP-to-HTTPS redirect.
        # A preexisting dynamic ErrorDocument must not pull scanners into Perl.
        for my $host (qw(app.test assets.test redirect.test)) {
            $config .= "<VirtualHost $addresses{$host}:$port>\nServerName $host\nDocumentRoot \"$dir\"\n".
                "ErrorDocument 404 /dynamic-error\nInclude \"$snippet\"\n";
            $config .= "<If \"%{REQUEST_URI} !~ m#/\\.well-known/acme-challenge/#\">\n".
                "Redirect permanent / https://example.invalid/\n</If>\n" if $host eq 'redirect.test';
            $config .= "<Location />\nSetHandler modperl\nPerlResponseHandler Scanner404Probe\n".
                "Require all granted\n</Location>\n</VirtualHost>\n";
        }
        open $out, '>', "$dir/httpd.conf" or die $!;
        print {$out} $config; close $out;
        my $config_status = system($httpd, '-t', '-f', "$dir/httpd.conf");
        is($config_status, 0, 'Apache validates the real shared rules');
        BAIL_OUT('Invalid disposable Apache configuration') if $config_status;
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            setsid() >= 0 or die "setsid: $!";
            open STDERR, '>>', "$dir/startup.log" or die $!;
            exec $httpd, '-f', "$dir/httpd.conf", '-DFOREGROUND';
            die "exec: $!";
        }
        my $server = bless {pid=>$pid}, 'ApacheScannerTestServer';
        my $ready;
        for (1..100) {
            my $probe = IO::Socket::INET->new(PeerAddr=>'127.0.0.1', PeerPort=>$port, Timeout=>0.1);
            if ($probe) {close $probe; $ready=1; last}
            sleep 0.05;
        }
        if (!$ready) {
            $server->stop;
            BAIL_OUT('Apache did not start: '.(-f "$dir/error.log" ? read_file("$dir/error.log") : read_file("$dir/startup.log")));
        }
        local @ENV{qw(http_proxy HTTP_PROXY https_proxy HTTPS_PROXY all_proxy ALL_PROXY)};
        my $client = HTTP::Tiny->new(timeout=>5, max_redirect=>0);
        my $smoke = $client->get("http://127.0.0.1:$port/");
        if ($smoke->{status} != 200 || $smoke->{content} ne 'APP_HANDLER') {
            $server->stop;
            BAIL_OUT('Perl positive control failed: '.$smoke->{content}.read_file("$dir/error.log"));
        }
        for my $host (qw(app.test assets.test redirect.test)) {
            for my $method (qw(GET HEAD POST)) {
                for my $url (@blocked, '/index.%70hp', '/index%2ephp', '/?p=php%2fetc/passwd') {
                    my $before = -e $marker ? -s $marker : 0;
                    my $response = $client->request($method, "http://$addresses{$host}:$port$url");
                    is($response->{status}, 404, "$host $method $url is 404");
                    is($response->{content} // '', $method eq 'HEAD' ? '' : 'Not found.', 'tiny fixed body (no body for HEAD)');
                    ok(!exists $response->{headers}{location}, 'no redirect');
                    is(-e $marker ? -s $marker : 0, $before, 'Perl handler was never invoked');
                }
            }
            for my $url (@allowed) {
                my $response = $client->get("http://$addresses{$host}:$port$url");
                my $redirect = $host eq 'redirect.test' && $url !~ m{^/\.well-known/acme-challenge/};
                is($response->{status}, $redirect ? 301 : 200, "$host legitimate route preserved: $url");
                is($response->{content}, 'APP_HANDLER', 'allowed request reaches the handler') unless $redirect;
            }
        }
        $server->stop;
        ok(-s $marker, 'positive control proves the Perl handler actually ran for allowed paths');
    };
}
done_testing();
