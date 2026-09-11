package Noosphere;
use strict;

sub setCookie {
    my ($req, $key, $val, $exp) = @_;
    die "Invalid cookie.\n" unless defined($key) && !ref($key) && $key =~ /\A[A-Za-z0-9_-]+\z/ &&
        defined($val) && !ref($val) && $val =~ /\A[\x21\x23-\x2b\x2d-\x3a\x3c-\x5b\x5d-\x7e]*\z/;
    die "Invalid cookie expiry.\n" if defined($exp) && (ref($exp) || $exp !~ /\A[0-9]+\z/);
    $key = '__Host-pl_session' if $key eq 'ticket';
    my @parts = ("$key=$val", 'Path=/', 'Secure', 'HttpOnly', 'SameSite=Lax');
    push @parts, "Max-Age=$exp" if defined $exp;
    push @parts, 'Expires=Thu, 01 Jan 1970 00:00:00 GMT' if defined($exp) && $exp == 0;
    $req->headers_out->add('Set-Cookie' => join('; ', @parts));
}

sub clearCookie {
    my ($req, $key) = @_;
    setCookie($req, $key, '', 0);
    if ($key eq 'ticket') {
        $req->headers_out->add('Set-Cookie' =>
            'ticket=; Path=/; Secure; HttpOnly; SameSite=Lax; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT');
    }
}

sub parseCookies {
    my ($req) = @_;
    my $buf = $req->header_in('Cookie') || '';
    my (%cookies, %seen);
    foreach my $cookie (split(/;\s*/, $buf)) {
        my ($key, $val) = split(/=/, $cookie, 2);
        next unless defined($key) && defined($val);
        next if $key eq 'ticket';
        if ($key eq '__Host-pl_session') {
            $seen{$key}++;
            $cookies{ticket} = $val if length($val) <= 64;
        } else {
            $cookies{$key} = $val;
        }
    }
    delete $cookies{ticket} if ($seen{'__Host-pl_session'} || 0) > 1;
    return %cookies;
}

1;
