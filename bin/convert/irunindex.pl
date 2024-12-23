#!/usr/bin/perl

# unindex arbitrary things.
# TODO: make on-line admin interface for this.
#

use DBI;
use lib '/var/www/noosphere/lib';
use Noosphere qw($dbh $DEBUG);
use Noosphere::IR;
use Noosphere::Config;
use Noosphere::DB;

my $todelete = [
	{id=>4385, tbl=>'users'},
#	{id=>752, tbl=>'users'}, 
#	{id=>753, tbl=>'users'}, 
];

$dbh = Noosphere::dbConnect;
my $table = Noosphere::getConfig('user_tbl');

foreach my $thing (@$todelete) {

  print "unindexing $thing->{tbl}:$thing->{id}\n";

  #my $tid = Noosphere::lookupfield('tdesc','uid',"tname='$thing->{tbl}'");
  Noosphere::irUnindex($thing->{'tbl'}, $thing->{'id'});
}

