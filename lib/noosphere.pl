#!/usr/bin/perl
use strict;

unless ($ENV{GATEWAY_INTERFACE}=~/^CGI-Perl/) {
 die "GATEWAY_INTERFACE not Perl!"; }

# Ben changed Apache to Apache2 for mod_perl 2
use Apache::FakeRequest ();
use CGI;

# call the startup script
# 
do "startup.pl";

# get CGI info
#
my $q = new CGI;

my $params = {$q->Vars};
my $cookies = {fetch CGI::Cookie};

# actually launch Noosphere at the entry point
#
Noosphere::cgi_handler($params, $cookies);
