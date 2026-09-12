package Noosphere;
use strict;

sub setStandardSecurityHeaders {
    my ($req) = @_;

    my $headers = $req->headers_out;
    $headers->set('X-Content-Type-Options' => 'nosniff');
    $headers->set('X-Frame-Options' => 'SAMEORIGIN');
    $headers->set('Referrer-Policy' => 'same-origin');
}

1;
