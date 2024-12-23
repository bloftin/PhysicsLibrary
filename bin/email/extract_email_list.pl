#!/usr/bin/perl
#
# This file takes all the email addresses in database and puts it in a format to# be imported by email commander for the Noosphere Newsletter
# 
# author: Ben Loftin
#

use DBI;
use lib '/var/www/pp/noosphere/lib';
use Noosphere qw($dbh $DEBUG);
use Noosphere::DB;
use Noosphere::Config;

# Output file
my $output = 'email_list.csv';
open DATA, ">$output" or die "can't open $output ";

# define the tables
#
my $usertbl='users';

# Connect to database
#
$dbh=Noosphere::dbConnect;

my ($rv, $sth)=Noosphere::dbSelect($dbh,{WHAT=>'username, email',FROM=>$usertbl,WHERE=>''});

my @rows=Noosphere::dbGetRows($sth);

foreach my $row (@rows) {
  print DATA "$row->{username}, $row->{email}\n";
}

close (DATA);
