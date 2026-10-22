package Noosphere::LoginLog;

use strict;
use warnings;
use Time::HiRes qw(time clock_gettime CLOCK_MONOTONIC);

our $CURRENT;
my $serial = 0;
my %events = (
    request => {begin => 1},
    origin => {rejected => 1},
    credentials => {missing => 1, accepted => 1, rejected => 1, error => 1},
    session_issue => {accepted => 1, rejected => 1, error => 1},
    session_cookie => {set => 1},
    session_check => {absent => 1, malformed => 1, unmatched => 1, invalidated => 1, accepted => 1},
    session_lookup => {error => 1},
    session_touch => {error => 1},
    session_revoke => {error => 1},
    logout => {confirmed => 1},
);

sub context {
    my ($enabled, $req, $params, $cookies) = @_;
    return undef unless $enabled;
    local ($@, $!, $?);
    return eval {
        my $method = $req->method;
        $method = 'other' unless $method =~ /\A(?:GET|HEAD|POST)\z/;
        my $op = $params->{op};
        $op = !defined($op) || (!ref($op) && $op eq '') ? 'none' :
            !ref($op) && $op =~ /\A(?:login|logout)\z/ ? $op : 'other';
        my $raw_cookie = $req->header_in('Cookie') || '';
        my $cookie = defined($cookies->{ticket}) ? 'present' :
            $raw_cookie =~ /(?:\A|;)\s*__Host-pl_session=/ ? 'unusable' : 'absent';
        my $uri = $req->unparsed_uri || '';
        my $home = $uri =~ m{\A/\??\z};
        return undef unless $op eq 'login' || $op eq 'logout' || $cookie ne 'absent' ||
            $home || ($method eq 'POST' && $uri =~ m{\A/\?});
        my $length = $req->header_in('Content-Length') || '';
        my $content_type = $req->header_in('Content-Type') || '';
        my $encoding = $content_type =~ m{\Aapplication/x-www-form-urlencoded(?:\s*;|\s*\z)}i ? 'urlencoded' :
            $content_type =~ m{\Amultipart/form-data(?:\s*;|\s*\z)}i ? 'multipart' :
            length($content_type) ? 'other' : 'absent';
        return {
            trace => join('-', $$, int(time * 1000000), ++$serial),
            started => clock_gettime(CLOCK_MONOTONIC),
            pid => $$, method => $method, route => $home ? 'home' : 'page',
            op => $op, cookie => $cookie, encoding => $encoding,
            body => $length =~ /\A[0-9]+\z/ && $length =~ /[1-9]/ ? 1 : 0,
            user_field => exists($params->{user}) ? 1 : 0,
            passwd_field => exists($params->{passwd}) ? 1 : 0,
        };
    };
}

sub emit {
    my ($stage, $event) = @_;
    return unless $CURRENT;
    # Only fixed enums and generated metadata reach the log, never supplied values.
    return if !defined($stage) || ref($stage) || !defined($event) || ref($event);
    return unless ($stage eq 'response' && $event =~ /\A[1-5][0-9]{2}\z/) ||
        (exists($events{$stage}) && exists($events{$stage}{$event}));
    local ($@, $!, $?);
    eval {
        my @fields = map { "$_=$CURRENT->{$_}" }
            qw(trace pid method route op cookie encoding body user_field passwd_field);
        my $elapsed = int(1000 * (clock_gettime(CLOCK_MONOTONIC) - $CURRENT->{started}));
        warn 'PL_LOGIN '.join(' ', @fields, "stage=$stage", "event=$event", "elapsed_ms=$elapsed")."\n";
        1;
    };
}

1;
