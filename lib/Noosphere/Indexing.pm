package Noosphere;
use strict;

use Noosphere::Latex;
use Noosphere::Morphology;

# get the first alphanum character of a title
#
sub getIndexChar {
	my $title = shift;

	# remove math font stuff
	$title =~ s/\\(mathbb|mathrm|mathbf|mathcal|mathfrak)\{//g;

	# grab first wordical character
	$title =~ /^\W*(\w)/;
	my $ichar = $1;

#	dwarn "title $title ichar $ichar";
	
	return uc($ichar);
}

# add a title to the main index
#
sub indexTitle {
	my $table = shift;
	my $objectid = shift;
	my $ownerid = shift;
	my $title = shift;
	my $cname = shift;
	my $source = shift || getConfig('proj_nickname'); # source collection

	my $index = getConfig('index_tbl');

	deleteTitle($table,$objectid);	 # precautionary delete

	my $ichar = getIndexChar(mangleTitle($title));

	my ($rv,$sth) = dbInsert($dbh,{INTO=>$index,COLS=>'objectid,tbl,userid,title,cname,source,ichar',VALUES=>"$objectid,'$table',$ownerid,'".sq($title)."','$cname', '$source', '$ichar'"});
	$sth->finish();
}

# delete a title from the main index.
#
sub deleteTitle {
	my $table = shift;
	my $objectid = shift;

	my $index = getConfig('index_tbl');

	my ($rv,$sth) = dbDelete($dbh,{FROM=>$index,WHERE=>"tbl='$table' and objectid=$objectid"});
	$sth->finish();
}

# index one encyclopedia object
#
sub wordIndexEntry { 
	my $table = shift;
	my $row = shift;
	
	my $uid = $row->{uid}||$row->{id};

	my $code = $row->{data};
	my $text = getPlainText($code);
	my @list = getwordlist($text);
	my $OLDDEBUG = $DEBUG;

 # dwarn "*** idx: indexing $row->{title}" if ($DEBUG);

	$DEBUG = 0;
	
	# delete all entries with this objectid+table - we will redo
	dropFromWordIndex($uid,$table);

	# insert an entry for each word into dictionary and word list
	foreach my $word (@list) {
	
		# insert into word list (will not do anything if word is there)
		#
		$dbh->{PrintError} = 0;	# no, we dont need to see uniqueness errors.
		my ($rv,$sth) = dbInsert($dbh,{INTO=>'words',COLS=>'word',VALUES=>"'$word'"});
		$sth->finish();
		$dbh->{PrintError} = 1;
	
		# look up word's wid
		#
		my $wid = getwid($word);

		# insert into word index
		#
		($rv,$sth) = dbInsert($dbh,{INTO=>'wordidx',VALUES=>"$wid,$uid,'$table'"});
	$sth->finish();
	}

	$DEBUG = $OLDDEBUG;
}

# drop object from word index table
#
sub dropFromWordIndex {
	my $id = shift;
	my $table = shift;

	my ($rv,$sth) = dbDelete($dbh,{FROM=>'wordidx',WHERE=>"objectid=$id and tbl='$table'"});
	$sth->finish();
}

# get word unique ID from words table
#
sub getwid {
	my $word = shift;

	my $sth = $dbh->prepare("select uid from words where word=?");
	my $rv = $sth->execute($word);
	my $row = $sth->fetchrow_hashref();
	$sth->finish();

	return $row->{'uid'};
}
		
# strip out any latex and junk from text
#
sub getPlainText {
	my $text = shift;
	
	# remove math tags
	#
	$text =~ s/\\\[.+?\\\]//sg;
	$text =~ s/\$\$.+?\$\$//gs;
	$text =~ s/\$.+?\$//gs;
	$text =~ s/\\begin\{eqnarray[*]{0,1}\}.+?\\end\{eqnarray[*]{0,1}\}//gs;
	$text =~ s/\\begin\{displaymath\}.+?\\end\{displaymath\}//gs;

	# remove emph, underline, leaving whats in the tags
	# 
	$text =~ s/\\underline\{(.+?)\}/$1/gs;
	$text =~ s/\\emph\{(.+?)\}/$1/gs;

	# remove all other non-environment tags
	#
	$text =~ s/\\\w+\{.+?\}\[.+?\]//gs;
	$text =~ s/\\\w+(\{.+?\})+//gs;

	# remove environment tags (leaving whats in the environment)
	#
	$text =~ s/\{\\\w+\s(.+?)\}/$1/gs;

	# kill non-brace-parameter tags like \item or \item[]
	#
	$text =~ s/\\\w+\[.+?\]//gs;
	$text =~ s/\\\w+//gs;
	
	# kill all backslashes 
	#
	# APK - we want to be able to process trigraphs
#	$text =~ s/\\//gs;

	return $text;
}

# turn text into a word list
# 
sub getwordlist {
	my $text = shift;
	
	# kill almost everything but word characters
	#
	$text =~ s/[\:\=\?\.\|,_\{\}\-\[\]";\(\)\*`\&\^\%\$\#\@\!~]/ /gs;

	# split into list
	#
	my @list = split('\s+',lc($text));

	# remove certain entries from the list
	#
	my $i = 0;
	while ($i <= $#list) {
		my $remove = 0;
	
		# do elementary stemming of word
		#
		$list[$i] = bogostem($list[$i]);

		# so-called "stopwords"
		#
		$remove = 1 if (isstopword($list[$i]));
	
		# numerical-starting entries 
		#
		$remove = 1 if ($list[$i]=~/^[0-9]/);

		# one letter entries 
		#
		$remove = 1 if (length($list[$i])<2);
	
		# do the removal
		#
		if ($remove == 1){
			splice @list,$i,1;
		} else {
			$i++;	# and go to next item.
		}
	}

	return @list;
}

# check to see if a word is a stopword
#
sub isstopword {
	my $word = shift;
	my $stops = getConfig('stopwords');

	foreach my $sw (@$stops) {
		return 1 if (lc($word) eq lc($sw));		
	}

	return 0;
}

# split a list of titles that can possibly be in "index" format. The list is
# comma separated, so ,, indicates a comma that is part of a title.
#
sub splitindexterms {
	my $terms = shift;

	($terms,my $math) = escapeMathSimple($terms);

	$terms =~ s/,,/;/g;	# we cheat by changing ,, to ; before splitting
	my @list = split(/\s*,\s*/,$terms);
	for my $i (0..$#list) {	# then replacing ; with , afterwards
		$list[$i] =~ s/;/,/;
		$list[$i] = unescapeMathSimple($list[$i], $math);
	}
	return @list;
}

# take a title in "index" form (Euler, Leonhard) and swap it to "inline" form
# (Leonhard Euler)
#
sub swaptitle {
	my $title = shift;

	$title =~ s/,,/;/g;	# "escape" double commas 

	# escape math portions
	#
	($title, my $math) = escapeMathSimple($title);

	# do swapping
	#
	if ($title =~ /,/) {
		my @array = split(/\s*,\s*/,$title);
		$title = $array[1].' '.$array[0];
	}

	$title =~ s/;/,/g;	# unescape commas

	# unescape math portions
	#
	$title = unescapeMathSimple($title, $math);

	return $title;
}

1;
