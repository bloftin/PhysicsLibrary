package Noosphere;

###############################################################################
#
# Collection.pm
#
# Routines for handling Noosphere subcollections.
#
###############################################################################

use strict;

# get a printable provenance URL for a source collection nickname
# 
sub getProvenanceURL {
	my $source = shift;

	my $sth = $dbh->prepare("select name, url from source where nickname=?");
	$sth->execute($source);
	if ($sth->rows()) {

		my $row = $sth->fetchrow_hashref();
		$sth->finish();

		return "<a href=\"$row->{url}\">$row->{name}</a>";

	} else {
		$sth->finish();
		return undef;
	}
}

# get the source collection identifier based on a record identifier
#
sub getSourceCollection {
	my $table = shift;
	my $objectid = shift;

	my $idx = getConfig('index_tbl');
	return undef unless defined $idx && $idx =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
	return undef unless defined $table && $table =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
	return undef unless defined $objectid && $objectid =~ /\A\d+\z/;

	my $sth = $dbh->prepare("select source from $idx where tbl=? and objectid=?");
	$sth->execute($table, $objectid);

	my $count = $sth->rows();

	if (!$count) {
		$sth->finish();
		return undef;
	}

	my $row = $sth->fetchrow_arrayref();
	$sth->finish();

	return defined $row ? $row->[0] : undef;
}

1;
