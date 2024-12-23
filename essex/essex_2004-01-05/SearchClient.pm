# SearchClient.pm - module to interface with searchd server
#
# CHANGELOG:
#  2003-04-21 akrowne@vt.edu: added field weight support.  this is an optional
#    hash of {field=>weight} which can be passed to the search subroutines.
#    the hash will be appended to the query as field=weight strings.  these 
#    can also be inline in the query.
#  2003-04-07 akrowne@vt.edu: added support for limited searches.
#  2003-04-05 akrowne@vt.edu:
#    - added compaction (isn't really complete yet)
#    - changed indexing to put a newline between docid and tag name
#
#  2003-02-11 akrowne@vt.edu: adapted for OAI-VSearch
#  2002-08-07 kevin@nethernet.com: Started package.

package SearchClient;

use Carp;
use IO::Socket;

use strict;

use vars qw(%resp);

# response codes
#
%resp = (
	HELLO => 100,
	OK => 101,
	BYE => 102,

	NORESULT => 200,
	BEGINRESULT => 201,
	ENDRESULT => 202,
	NMATCHES => 203,

    NOSTRUCTURES => 400,
    BEGINQUERYRANK => 401,
    ENDQUERYRANK => 402,

	BADCMD => 300,
	DEADCONN => 301
);

# create an instance
#
sub new {
	my( $class, %args ) = @_;

	# defaults
	$args{Mode} ||= 'unix';
	$args{Host} ||= 'localhost';
	$args{Port} ||= 1723;
	$args{Sock} ||= 'searchd.sock';

	# sanity check
	die( "Mode must be 'unix' or 'inet'" ) unless( $args{Mode} eq 'unix' || $args{Mode} eq 'inet' );

	# create the socket
	if( $args{Mode} eq 'unix' ) {
		$args{sock} = new IO::Socket::UNIX (
			Type => SOCK_STREAM,
			Peer => $args{Sock} );
	} else {
		$args{sock} = new IO::Socket::INET (
			PeerAddr => $args{Host},
			PeerPort => $args{Port},
			Proto => 'tcp' );
	}

	return undef unless( $args{sock} );

	# check for HELLO
	my($code,$msg) = &getresp( $args{sock} );
	return undef unless( $code == $resp{HELLO} );

	bless \%args, $class;
}

# return an array of results.
# the keys in the hash are the names of the documents
# the data in the hash are lists of [code,weight] pairs
#
sub search {
	my $self = shift;
	my $query = shift;
	my $weights = shift;

	my @r;  # response array

	my $s = $self->{sock};
	die( "Nope, no socket" ) unless( $s );

	# if weights were given, add them into the query
	#
	if ($weights) {
		$query .= ' '.join(' ', (map "$_=$weights->{$_}", keys %$weights));
	}

	# clean newlines from query
	$query =~ s/\n//ogs;
	
	# send query across
	print $s "search\n$query\n";
	
	my( $code, $msg ) = &getresp( $s );

	if( $code == $resp{OK} ) {
		
		($code,$msg) = &getresp( $s );

		if ( $code == $resp{BEGINRESULT} ) {
			my $l = <$s>;
			while( $l !~ /^\d\d\d / ) {
				chomp $l;
				#print "Result: $l\n";
				my ($doc,$weight) = split( /\t/, $l ); 
				push @r, [$doc, $weight];
				$l = <$s>;  # read next result
			}
			chomp $l;
			($code,$msg) = ($1,$2) if( $l =~ /^(\d\d\d) (.*)$/ );
		} 
	}
	else {
		warn "SearchClient: search failed: expected OK after search command ($code=$msg)";
		return undef;
	}

	return [@r];
}

# version of the search with a limit of returned documents
#
sub limitsearch {
	my $self = shift;
	my $query = shift;
	my $limit = shift;
	my $weights = shift;

	my $nmatches = 0; # place to put actual number of matches

	my @r;  # response array

	my $s = $self->{sock};
	die( "Nope, no socket" ) unless( $s );

	# if weights were given, add them into the query
	#
	if ($weights) {
		$query .= ' '.join(' ', (map "$_=$weights->{$_}", keys %$weights));
	}

	# clean newlines from query
	$query =~ s/\n//ogs;
	
	# send query across
	print $s "limitsearch\n$query\n$limit\n";
	
	my( $code, $msg ) = &getresp( $s );

	if( $code == $resp{OK} ) {

		($code,$msg) = &getresp( $s );

		# get number of matches
		#
		if ($code == $resp{NMATCHES}) {
			chomp $msg;
			$nmatches = $msg;
			my $l = <$s>;  # eat a line
		}
		
		# get results
		#
		($code,$msg) = &getresp( $s );
		if ( $code == $resp{BEGINRESULT} ) {
			my $l = <$s>;
			while( $l !~ /^\d\d\d / ) {
				chomp $l;
				#print "Result: $l\n";
				my ($doc,$weight) = split( /\t/, $l ); 
				push @r, [$doc, $weight];
				$l = <$s>;  # read next result
			}
			chomp $l;
			($code,$msg) = ($1,$2) if( $l =~ /^(\d\d\d) (.*)$/ );
		} 
	}
	else {
		warn "SearchClient: search failed: expected OK after search command ($code=$msg)";
		return (undef,undef);
	}

	return ($nmatches, [@r]);
}

sub index {
	my $self = shift;
    my ($identifier, $tag, $wordlist) = @_;
	
	my $s = $self->{sock};
	die( "Nope, no socket" ) unless( $s );

	# silently fail if there are no actual alphabetical characters
	return 1 if ("@$wordlist" !~ /\w/);

	# send index message
	print $s "index\n";

	my( $code, $msg ) = &getresp( $s );
	if ($code != $resp{OK}) {
		warn "SearchClient: index failed: expected OK after sending index command ($code=$msg)";
		return 0;
	}

	print $s "$identifier\n$tag\n";

	( $code, $msg ) = &getresp( $s );
	if ($code != $resp{OK}) {
		warn "SearchClient: index failed: expected OK after sending IDs";
		return 0;
	}
	
	print $s "@$wordlist\n";
	print $s ".\n";

	return 1; # success
}

sub unindex {
	my $self = shift;
	my $identifier = shift;
	
	my $s = $self->{sock};

	die( "Nope, no socket" ) unless( $s );

	# send unindex message
	print $s "unindex\n";

	my( $code, $msg ) = &getresp( $s );
	if ($code != $resp{OK}) {
		warn "SearchClient: unindex failed: expected OK after sending unindex command";
		return 0;
	}

	print $s "$identifier\n";

	return 1;
}

sub printindex {
	my $self = shift;
	
	my $s = $self->{sock};

	die( "Nope, no socket" ) unless( $s );

	# send print inverted index message
	print $s "printindex\n";

	my( $code, $msg ) = &getresp( $s );
	if ($code != $resp{OK}) {
		warn "SearchClient: printindex failed to return OK!";
		return 0;
	}

	return 1;
}

sub stats {
	my $self = shift;
	
	my $s = $self->{sock};

	die( "Nope, no socket" ) unless( $s );

	# send print stats message
	print $s "stats\n";

	my( $code, $msg ) = &getresp( $s );
	if ($code != $resp{OK}) {
		warn "SearchClient: stats failed to return OK!";
		return 0;
	}

	return 1;
}

sub compactify {
	my $self = shift;
	
	my $s = $self->{sock};

	die( "Nope, no socket" ) unless( $s );

	# send print stats message
	print $s "compactify\n";

	my( $code, $msg ) = &getresp( $s );
	if ($code != $resp{OK}) {
		warn "SearchClient: compactify failed to return OK!";
		return 0;
	}

	return 1;
}

sub finish {
	my $self = shift;

	my $s = $self->{sock};

	print $s "quit\n";
	
	my( $code, $msg ) = &getresp( $s );
	if ($code != $resp{BYE}) {
		warn "SearchClient: finish failed to be graceful: expected BYE after sending quit command";
		return 0; 
	}
	
	close $s;

	return 1;
}

######

# get a response from the daemon, which is a message, errorcode pair.
# 
sub getresp {
	my $sock = shift;

	my( $code, $msg );

	my $stuff = <$sock>;
	($code,$msg) = ($1,$2) if( $stuff =~ /^(\d\d\d) (.*)$/ );
	chomp $msg;

	return ($code,$msg);
}

# return an hash of results (disguised as an array)
# the keys in the hash are the queries (strings of tag:term pairs)
# the data in the hash are the scores
#
sub structure {
	my $self = shift;
	my $query = shift;
	my $weights = shift;

    my $v;  # response value
	my @r;  # response array

	my $s = $self->{sock};
	die( "Nope, no socket" ) unless( $s );

	# if weights were given, add them into the query
	#
	if ($weights) {
		$query .= ' '.join(' ', (map "$_=$weights->{$_}", keys %$weights));
	}
	
	# send query across
	print $s "structurequery\n$query\n";
	
	my( $code, $msg ) = &getresp( $s );

	if( $code == $resp{OK} ) {
		
		($code,$msg) = &getresp( $s );

		if ( $code == $resp{BEGINQUERYRANK} ) {
			my $l = <$s>;
			while( $l !~ /^\d\d\d / ) {
                                # get the query
				chomp $l;
				push @r, $l;

                                #get the score
				$l = <$s>;
				chomp $l;
                                push @r, $l;

                                # read next result
				$l = <$s>;
			}
			chomp $l;
			($code,$msg) = ($1,$2) if( $l =~ /^(\d\d\d) (.*)$/ );
		}
	}

	return [@r];
}


1;
