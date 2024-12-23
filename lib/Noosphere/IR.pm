package Noosphere;
use strict;

use lib '/var/www/pp/noosphere/essex/essex_2004-01-05';
use SearchClient;

use Noosphere::Config;
use Noosphere::DB;
use Noosphere::Util;
use Noosphere::Indexing;
use Noosphere::Latex;

sub irSearch {
	my $query = shift;
	my $mode = shift;   # if this is "searchrelated", allow one extra result.

	# some preprocessing
	#
	$query =~ s/(\w)-(\w)/$1 $2/g;  # ignore hyphenations
	$query = TeXtoUTF8($query);

	# get default field weights
	#
	my $fieldweights = getConfig('indexweights');

	# have the search engine do the dirty (searching) work
	#
	my $se = SearchClient->new(Sock => getConfig('searchd_sock'));
	if (not defined $se) {
	    warn "Could not contact search daemon!!!!";
	    return (undef, undef);
	}

	my ($nmatches, $results) = $se->limitsearch($query, getConfig('search_limit'), $fieldweights);
	$se->finish();

#	warn "search engine: got nmatches = $nmatches";

	# insert the results as a results set in search results table
	#
	my $results_table = getConfig('results_tbl');
	my $token = irGetToken();
	
	foreach my $result (@$results) {
	    my $id = $result->[0];
	    my $rank = $result->[1];

		next if ($rank == 0);

		# unpack identifier
		my ($tname,$objectid) = split(/\./,$id);
		#my $table = tablename($tid);

		#warn "storing result $tname:$objectid = $rank";

		# store results
		if (defined $results_table && defined $objectid && $rank >= 0 && defined $token) {
			my ($rv,$sth) = dbInsert($dbh,{INTO=>$results_table,COLS=>'tbl,objectid,rank,token',VALUES=>"'$tname',$objectid,$rank,$token"});
			$sth->finish() if $sth;
		}
	}

	return ($token, $nmatches);
}

# get an unused search results table token
#
sub irGetToken {

	my $token = int(rand 65536);
	while (irTokenUsed($token)) {
		$token = int(rand 65536);
	}

	return $token;
}

# return true if a token is in use
# 
sub irTokenUsed {
	my $token = shift;

	my $table = getConfig('results_tbl');
	
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>"token",FROM=>$table,WHERE=>"token=$token",LIMIT=>1});
	my $count = $sth->rows();
	
	$sth->finish();

	return $count;
}

# main procedure to index some fields under an identifier
#
sub irIndex {
	my $table = shift;
	my $row = shift;
	my $mode = shift || 'normal';	# can be 'test'
	
	my $objectid = $row->{'uid'} || $row->{'id'};

	return if (not defined $objectid);

	my $indexablefields = getConfig('indexablefields');
	my $fields = $indexablefields->{$table};

	my $indexid = "$table.$objectid";

	# start searchclient connection
	#
	my $se;
	$se = SearchClient->new(Sock => getConfig('searchd_sock'))
		if $mode eq 'normal';
	$se = SearchClient->new(Sock => getConfig('searchd_test_sock'))
		if $mode eq 'test';

	if (not defined $se) {
		warn "couldn't start search client";
		return;
	}

	# delete any existing indexed chunks for this record
	#
	$se->unindex($indexid);

	# loop through each field, indexing them under this identifier
	#
	foreach my $field (keys %$fields) {
		my $indexfield = $fields->{$field};

		my $text = $row->{$field};

		# hack to look up what we really want for "related" 
		# (the titles of the entries we're referring to)
		#
		if ($table eq getConfig('en_tbl') && $field eq 'related') {
			$text = getTitleStrings($row->{$field});
		}
	
		# get a cleaned and translated wordlist
		#
		my @wordlist = irWordList($text);

		next if ($#wordlist < 0);

		# do the indexing
		#
		#warn "indexing words for $indexid, $indexfield";
		$se->index($indexid, $indexfield, [@wordlist]) 
            or return 0; # failure
	}

	# close search engine connection
	#
	$se->finish();

    return 1; # success
}

# unindex an object
#
sub irUnindex {
	my $table = shift;
	my $objectid = shift;
	
	# start searchclient connection
	#
	my $se = SearchClient->new(Sock => getConfig('searchd_sock'));

	if (not defined $se) {
		warn "couldn't start search client";
		return;
	}

	# make search-engine namespace identifier
	#
	my $indexid = "$table.$objectid";

	# send unindexing directive
	#
	$se->unindex($indexid);

	# close search engine connection
	#
	$se->finish();
}

# get a list of titles from a list of canonical names
#
sub getTitleStrings {
	my $cnames = shift;

	my @list = ();
	  
	foreach my $name (split(/\s*,\s*/,$cnames)) {
		my $title = lookupfield(getConfig('en_tbl'),'title',"name='$name'");
		push @list,$title if (nb($title));
	}

	return join(',',@list);
} 

# get a clean word list from some text
#
sub irWordList {
	my $text = shift;

	$text = TeXtoUTF8(getPlainText($text));

	# kill almost everything but word characters
	#
	$text =~ s/[\:\=\?\.\|,_\{\}\-\[\]";\(\)\*`\&\^\%\$\#\@\!~]/ /gs;
	$text =~ s/''/ /gs;  # kill closing TeX quotes

	# split into list
	#
	my @list = split(/\s+/,lc($text));

	# add un-internationalized aliases to the word list.
	# 
	@list = unI18nAlias(@list);

	return @list;
}


1;

