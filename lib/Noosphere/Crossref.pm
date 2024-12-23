package Noosphere;
use strict;

use Noosphere::Classification;
use Noosphere::Indexing;
use Noosphere::Cache;
use Noosphere::Config;
use Noosphere::Latex;
use Noosphere::Morphology;
use Noosphere::Collection;
use Noosphere::Linkpolicy;

# tags which allow linking to their contents
#
use vars qw{%LINKABLETAGS};
%LINKABLETAGS = (
	'PMlinkescapeword'=>1,
	'PMlinkescapephrase'=>1,
	'textit'=>1,
	'footnote'=>1,
	'emph'=>1,
	'proof'=>1,  # APM-Xi
	'defn'=>1,   # APM-Xi
	'text'=>1,
	'textsl'=>1, 
	'textsc'=>1, 
	'textmd'=>1, 
	'textbf'=>1, 
	'textit'=>1, 
	'tiny'=>1, 
	'scriptsize'=>1, 
	'footnotesize'=>1, 
	'small'=>1, 
	'normalsize'=>1, 
	'large'=>1, 
	'Large'=>1, 
	'LARGE'=>1, 
	'huge'=>1, 
	'HUGE'=>1
);

# crossReferenceLaTeX - main entry point for cross-referencing, you send it
# some LaTeX and it returns the same text, but with
# hyperlinks. Tres convenient, no?
#
sub crossReferenceLaTeX {
	my $newent = shift;		# new entry flag, 1 or 0
	my $latex = shift;
	my $title = shift;		# title of the object
	my $method = shift;
	my $syns = shift;		# synonyms, more things not to link to
	my $fromid = shift||-1;	# from id - if this is null or -1, we dont touch links tbl
	my $class = shift;		# classification string
	
	push @$syns,$title;

	dwarn "Cross-referencing $title";

	# delete old outgoing links
	#
	my $table = getConfig('en_tbl');	 # TODO: generalize this for any table
	xrefDeleteLinksFrom($fromid,$table);

	# fix l2h stuff
	#
	$latex = l2hhacks($latex) if ($method eq 'l2h');

	
	# separate math from linkable text, and do some massaging
	#
	my @user_escaped;
	my $escaped;
	my $linkids;

	($latex,@user_escaped) = getEscapedWords($latex);
	($latex,$escaped,$linkids) = splitPseudoLaTeX($latex, $method);
	
	$latex = preprocessLaTeX($latex);
	my ($nonmath,$math) = splitLaTeX($latex, $escaped);

	# handle manual linking metadata
	# 
	doManualLinks($linkids, $fromid);

	# do automatic linking
	#
	my ($terms,$concepts,$reverse,$nolink) = generateterms($fromid,$syns);
	my $matches = findmatches($nonmath,$terms);
	my ($linked,$links) = makelinks($nonmath,$math,$terms,$concepts,$matches,$class,$fromid,$nolink,\@user_escaped);
	
	my $recombined = recombine($linked, $math, $escaped);
	
	return (postprocessLaTeX($recombined),$links);
}

# preprocessing hacks to make l2h output look right
#
sub l2hhacks {
	my $latex = shift;

	# paragraphs
	#
	$latex =~ s/\r//gs;
	# 2003-05-29 : hack apparently no longer needed
	#$latex =~ s/(\n\n)/$1\\begin\{rawhtml\}<p>\\end\{rawhtml\}\n\n/sg;

	# xypic double-height fix
	#
	$latex =~ s/(\$\$)\s*(\\xymatrix\s*?\{.+?\})\s*?(\$\$)/$1\\begin{xy}\n*!C\\xybox\{\n$2 \}\\end\{xy\}$3/gs;
	# this next hack probably should be rethought.
	$latex =~ s/(\\begin\{center\})(\s*?)(\\xymatrix\s*?\{.+?\})\s*?(\\end\{center\})/\\begin\{rawhtml\}<div align="center">\\end\{rawhtml\}$2\\begin{xy}\n*!C\\xybox\{\n$3 \}\\end\{xy\}\n\\begin\{rawhtml\}<\/div>\\end\{rawhtml\}/gs;
	$latex =~ s/(\\\[)\s*(\\xymatrix\s*?\{.+?\})\s*?(\\\])/$1\\begin{xy}\n*!C\\xybox\{\n$2 \}\\end\{xy\}$3/gs;
	$latex =~ s/(\\begin\{displaymath\})\s*(\\xymatrix\s*?\{.+?\})\s*?(\\end\{displaymath\})/$1\\begin{xy}\n*!C\\xybox\{\n$2 \}\\end\{xy\}$3/gs;

	return $latex;
}

# handle figuring out the URLs for the \PMlinktofile pseudo-command
# \PMlinktofile directives get left after cross-referencing
#
sub dolinktofile {
	my $latex = shift;
	my $table = shift;	 
	my $id = shift;			# object id

	my $fileserver = getAddr('files');

	while ($latex =~ /\\PMlinktofile\{(.+?)\}\{(.+?)\}/s) {
		my $anchor = $1;
		my $filename = $2;
		my $url = protectURL("http://$fileserver/files/$table/$id/$filename");
		$latex =~ s/\\PMlinktofile\{.+?\}\{.+?\}/\\htmladdnormallink{$anchor}{$url}/s;
		#$latex=~s/\\PMlinktofile\{.+?\}\{.+?\}/$url/s;
	}

	return $latex;
}

# generate a list of terms 
#
# this list takes the form of a hash-of-hashes.	The hash is of the 
# form first_word_of_term => { hash containing all matching term => name's}
#
# this allows us a quick answer to the question "is word X a term, or the
# prefix of a term", in what is optimally O(1) time.	We can then find the 
# largest matching word at the current position in what should be O(1) on 
# average, depending on how many terms on average share their first word with
# another term.
#
sub generateterms {
	require Noosphere::Encyclopedia;
	
	my $thisid = shift; # id of this object
	my $extra = shift;	# array of hash of terms which are synonyms or defines
						# of the current entry.	These are handled specially to
						# suppress linking to them in this entry.
	
	my %terms;			# terms hash
	my %concepts;		# conceptid=>objectid hash
	my %reverse;		# reverse lookup on concept id (objectid=>conceptid)
	my %save;			# title=>conceptid hash for extras
	my @nolink;			# output array: list of concept ids not to link to
	my $maxid = 0;		# concept id counter

	my $index = getConfig('index_tbl');

	# we need to get master objects (type 1) first to generate concept ids
	#
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'title,cname as name,objectid,type',
		FROM=>$index,
		WHERE=>"tbl='".getConfig('en_tbl')."'",
		'ORDER BY'=>'type',ASC=>''});

	my @rows = dbGetRows($sth);

	# dummy values
	#
	$reverse{-1} = -1;
	$concepts{-1} = -1;

	# build firstword->{term->{name,type}, term->{name,type},...} hash
	#
	foreach my $row (@rows) {
		my $cid;

		my $term = $row->{'title'};
	
		# master object or defines; create new concept id
		#
		if ($row->{'type'} == 1 || $row->{'type'} == 3) {
			$concepts{$maxid} = $row->{'objectid'};
			#dwarn "*** generateterms: mapped objectid $row->{objectid} to conceptid $maxid";
			$reverse{$row->{'objectid'}} = $maxid;
			$cid = $maxid;
			$maxid++;
		} else {
			$cid = $reverse{$row->{'objectid'}};	 # look up concept id for syn
			#dwarn "*** generateterms: mapped concept id $cid to $row->{objectid}";
		}
		if (inset($term, @$extra)) {
			push @nolink,$cid;
			$save{$term} = $cid;
		}
		addterm(\%terms, $term, $cid);
		#dwarn "adding term to list: $row->{title} => $row->{name}";
	}

	# add the extra terms
	#
	if (defined $extra) {
		foreach my $title (@$extra) { 
		if (not exists $save{$title}) {
			push @nolink, -1;
				addterm(\%terms,$title,-1);
			}
		}
	}

	push @nolink, $reverse{$thisid};

	return ({%terms},{%concepts},{%reverse},[@nolink]);
}

# add to terms hash-of-hashes
#
sub addterm {
	my $terms = shift;
	my $title = shift;
	my $cid = shift;				# concept id
	my $encoding = shift || '';
	
	#dwarn "*** xref: original title is $title";
	$title = swaptitle($title);	# handle rearranging index forms

	# pull out first word of term 
	#
	$title =~ /^([^\s]+)/o;
	my $fwuc = $1;
	my $fw = lc($fwuc);
	
	# pull out last word
	#
	$title =~ /([^\s]+)$/o;
	my $lwuc = $1;
	my $lw = lc($lwuc);
	
	# do the actual adding
	#
	if (defined $terms->{$fw}) {
		push @{$terms->{$fw}->{$title}}, $cid;
		#dwarn "*** xref: adding term {$fw , $title}" if ($title=~/^li/);
	} else {
		my @array;					# create array
		push @array, $cid;
		$terms->{$fw}->{$title} = [@array];
		#dwarn "*** xref: adding term {$fw , $title}" if ($title=~/^li/);
	}
	
	# add extra nonmathy title for mathy titles (both levels of translation)
	#
	if (ismathy($title)) {
		addterm($terms,getnonmathy($title,1),$cid, $encoding);
	
		# APK - this is bad. we don't want $\zeta$ function linking to 
		# "function"
		#addterm($terms,getnonmathy($title,2),$cid);
	}

	# add extra nonpossessive entry for possessives, linking to same obj
	#
	addterm($terms,getnonpossessive($title),$cid, $encoding) if ispossessive($fwuc);

	# add extra nonplural entry for plurals, linking to same obj
	#
	addterm($terms,depluralize($title),$cid, $encoding) if isplural($lwuc);
	
	# handle aliases for internationalizations

	# figure out encoding (TeX or UTF8) and make aliases
	#
	if (!$encoding) {
		my $ascii = UTF8ToAscii($title);

		if ($ascii ne $title) { 
			addterm($terms, $ascii, $cid, 'utf8');
			my $tex = UTF8toTeX($title);
			addterm($terms, $tex, $cid, 'tex');
		}
		else { 
			my $utf8 = TeXtoUTF8($title);
			if ($utf8 ne $title) {
				addterm($terms, $utf8, $cid, 'tex');
				my $ascii = UTF8ToAscii($utf8);
				addterm($terms, $ascii, $cid, 'tex');
			}
		}
	} 
}

# disambiguate a link
#
sub disambiguate {
	my $concepts = shift;
	my $terms = shift;
	my $title = shift;
	my $class = normalizeclass(shift); 
	my $fromid = shift;

	dwarn "*** link disambiguation : find best match for '$title'", 2;
		
	# get array of ids of qualifying entries
	#
	$title =~ /^([^\s]+)(\s|$)/;
	my $fw = lc($1);
	my @ids = @{$terms->{$fw}->{$title}};	

	return $ids[0] if ($#ids == 0);	 # one entry early-out

	@ids = disambiguate_subcollection($fromid, $concepts, @ids);

	return $ids[0] if ($#ids == 0);	 # one entry early-out

	@ids = disambiguate_classification($class, $concepts, @ids);

	return $ids[0] if ($#ids == 0);	 # one entry early-out

	@ids = post_resolve_linkpolicy($fromid, $concepts, $title, @ids);

	if ($#ids > 0) {
		my $winner = disambiguate_graph($fromid, $concepts, @ids);
		return $winner if ($winner != -1);
	}

	return $ids[0];
}

sub disambiguate_graph {
	my $fromid = shift;
	my $concepts = shift;
	my @toplist = @_;
	
	my $table = getConfig('en_tbl');

	# if nothing above produced a single winner id, do the graph method
	#
	if ($#toplist > 0) {
		
		# do the BFS traversal
		my $winner = getBestByBFS($table, $fromid, [map { $concepts->{$_} } @toplist], 2);
		dwarn "*** link score: winner (for $fromid) by graph walking is $toplist[$winner]\n", 2;
		return $toplist[$winner];
	}

	return $toplist[0];
}

sub disambiguate_classification {
	my $class = shift;
	my $concepts = shift;
	my @ids = @_;

	my @classes = ();
	my @cstrings = ();

	my $topscore = -1;
	my @toplist = ();	# list of top scored entries
	my @topclass = ();	# their classifications

	my @cats = split(/\s*,\s*/,$class);

	my $table = getConfig('en_tbl');

	# if we have classification, we can compare it to the classifications of
	# the link choices
	#
	if ($#cats >= 0) {
		# get classifications
		#
		foreach my $id (@ids) {
			my ($str,$cf) = classinfo($table,$concepts->{$id});
			push @classes,$cf;
			push @cstrings,$str;
		}
	
		# loop through and score the classification for each id
		# against the current classification
		#
		my $i = -1;
		foreach my $id (@ids) {
			$i++;
			my @compare = split(/\s*,\s*/,$cstrings[$i]);
	
			next if ($#compare<0);	# no classification, skip

			# find score, update "winner"
			# this scoring scheme is a combination of scores considering full
			# category specification, and top-level specification, with 
			# preference going to full.
			#
			my $score1 = getscore(\@cats,\@compare);
			my $score2 = getscore(
				[map { catlevel($_, 2) } @cats],
				[map { catlevel($_, 2) } @compare]);
			my $score3 = getscore(
				[map { catlevel($_, 1) } @cats],
				[map { catlevel($_, 1) } @compare]);
				
			my $score = (100 * $score1) + (10 * $score2) + $score3;
			dwarn "*** link score: $id = $score , [$class] vs. [$cstrings[$i]]", 2; 
			if ($score > $topscore) {
				$topscore = $score;
				@toplist = ();		# reset the top list, we found a new winner
				push @toplist,$id;
				push @topclass,$classes[$i];
			} 

			# tied for top: add to toplist
			#
			elsif ($score == $topscore) {
				push @toplist, $id;	
				push @topclass, $classes[$i];
			}
		}

		if ($#toplist > 0) {
			dwarn "*** link score: tie", 2;
		}
	}

	return @toplist;
}

# filter a list of candidate concept IDs by subcollection
# 
sub disambiguate_subcollection {
	my $fromid = shift;
	my $concepts = shift;
	my @ids = @_;

	my $table = getConfig('en_tbl');

	# reduce the candidate pool using source collection commonality
	#
	if ($#ids >= 1) {

		my $thissource = getConfig('proj_nickname');
		if ($fromid != -1) {
			$thissource = getSourceCollection($table, $fromid);
		}

		# get a subset of IDs of items which match this entry's collection
		# 
		my @subset = ();
		foreach my $cid (@ids) {
			if ($thissource eq getSourceCollection($table, $concepts->{$cid})) {
				push @subset, $cid;
			}
		}

		# if the subset is not empty, use it instead of original set
		#
		if (scalar @subset) {
			@ids = @subset;
		}
	}
	
	return @ids;
}

# get a score: this ranks the current object against a potential match
# by comparing how much their classifications coincide (order counts).
# this is boiled down into a single number which serves as a metric.
#
sub getscore {
	my ($b_,$c_) = @_;

	my @base = @$b_;
	my @compare = @$c_;

	dwarn "*** getscore: base [@base], compare [@compare]", 3;

	return 0 if ($#compare<0);
	return 0 if ($#base<0);

	my %chash;

	# determine the match set 
	#
	my $cc = scalar @compare;
	my $i = $cc;
	foreach my $c (@compare) {
		# make the value for a match decrease based on position.  max is 
		# 1 = #cats/#cats, min is 1/#cats
		$chash{$c} = $i/$cc;	
		$i--;
	}

	# calculate match points
	#
	my $points = 0;
	foreach my $b (@base) {
		if (exists $chash{$b}) {
			$points += $chash{$b};
		}
	}
	
	# normalize matches by log # of cats. the goal of this is to favour 
	# matches to entries which are "more precisely" a match for the input 
	# set of categories
	#
	my $score = $points * 1/(1 + log($#base+1));

	return $score;
}

# pull an object unique name from our two-level terms hash, based on title
#
sub getnamebytitle {
	my $terms = shift;
	my $title = shift;

	# pull out first word of term
	#
	$title =~ /^([^\s]+)(\s|$)/;
	my $fw = lc($1);
	#dwarn "looking up name for title $title, prefix $fw";

	my $subhash = $terms->{$fw};
	return $subhash->{$title};
}

# make links in the LaTeX - combine matches info hash with the text
#
sub makelinks {
	my $text = shift;		# entry text
	my $math = shift;		# entry math.. so we can check for sentence ends
	my $names = shift;		# object names hash
	my $concepts = shift;	# conceptid=>objectid hash
	my $matches = shift;	# match structure
	my $class = shift;		# classification string
	my $fromid = shift;		# id of this object (or -1)
	my $cnolink = shift;	# concept ids not to link to
	my $escaped = shift;    # user escaped words/phrases
	
	my @linkarray;			# array of href's
	my %linked;				# linked titles
	my %clinked;			# linked concepts

	foreach my $nl (@$cnolink) {
		$clinked{$nl}=1;	# dont link to same concept as this entry
		#dwarn "*** xref: not linking concept $nl";
	}
	
	my $table = getConfig('en_tbl');

	my $stdurl = getConfig("main_url")."/encyclopedia/";
	my $listurl = getConfig("main_url")."/encyclopedia/";

	# set up no link word/phrase array
	#
	my @nolink = @$escaped;
	my $blacklist = getConfig('dontlink');	# global phrase blacklist
	foreach my $bl (@$blacklist) {
		push @nolink,$bl;
	}

	my @ltext = split(/\s+/,$text);

	# go through the matches forwards and remove duplicates and self links
	#
	foreach my $pos (sort {$a <=> $b} keys %$matches) {
		my $matchtitle = $matches->{$pos}->{'term'};

		next if ($linked{$matchtitle});

		my $anchor = getanchor($matches->{$pos});	
		next if (inset(lc($anchor),@nolink));	# skip blacklisted words

		my $cid = disambiguate($concepts,$names,$matchtitle,$class,$fromid);
		next if ($clinked{$cid});
	
		# save link info for match title and concept
		#
		$linked{$matchtitle} = $concepts->{$cid};		 # term linkage
		$clinked{$cid} = 1;

		$matches->{$pos}->{'active'}=1;			 # turn the link "on"
	}
	
	# we have to iterate backwards to do the replacements since we're 
	# potentially altering the indicies
	#
	foreach my $pos (sort {$b <=> $a} keys %$matches) {
		#dwarn "*** makelinks: looking at term ".$matches->{$pos}->{'term'};
		
		my $active = $matches->{$pos}->{'active'};
		next if (not $active);
	
		my $matchtitle = $matches->{$pos}->{'term'};
		my $length = $matches->{$pos}->{'length'};
		my $tags = $matches->{$pos}->{'tags'};
	
		my $id = $linked{$matchtitle};
		my $name = getnamebyid($id);
	
		my $anchor = getanchor($matches->{$pos});
		my $listanchor = $anchor;	# we are done preparing list anchor
	
		# force proper capitalization for replacement anchor
		#
		if ($anchor =~ /^([a-z]).+/) {
			my $newchar = uc($1);

			# normal text delimiter capitalizations
			#
			if ($pos == 0 || 
				$ltext[$pos - 1] eq '' || # because of prepended space to body
				$ltext[$pos - 1] =~ /\.$/ || 
				$ltext[$pos - 1] =~ /\?$/ || 
				$ltext[$pos - 1] =~ /\!$/ ||
				(skipword($ltext[$pos - 1]) && # double newline, par break
				 skipword($ltext[$pos - 2]))
				) {
				
				$anchor =~ s/^[a-z]/$newchar/;
			} 

			# maybe the previous chunk was math mode?
			#
			elsif ($ltext[$pos - 1] =~ /^##(\d+)##$/) {
			
				my $idx = $1;
				my $mcontent = $math->[$idx];
				
				# see if period ends the math mode
				#
				if ($mcontent =~ /\.\s*(\$\$|\$|\\\]|\\end)/) {
					
					$anchor =~ s/^[a-z]/$newchar/;
				}
			}
		}
	
		my ($left, $right) = outertags($tags);
		my $linktext = $left.'\htmladdnormallink{'.taganchor($tags,$anchor).'}{'.$stdurl.$name.'.html}'.$right;
	
		$ltext[$pos] = $linktext;
		splice @ltext,$pos+1,($length-1) if ($length > 1);
	
		# add to simple links list 
		#
		my $lnk = "<a href=\"$listurl$name.html\">$listanchor</a>";
		push @linkarray, mathTitle($lnk, 'highlight');
	
		# add to links table if we have a from id
		xrefAddLink($fromid,$table,$id,$table) if ($fromid);
	}
	
	my $finaltext = join(' ',@ltext);

	return ($finaltext, join(', ',@linkarray));
}

# remove things from the tags that should go "outside" the anchor.
#
sub outertags {
	my $tags = shift;

	my $first = "";
	my $last = "";

	my $l = scalar @$tags - 1;
	
	if ($tags->[0] =~ /^(["`\(\[]+)([^`\(\[].+)?$/) {
		$first = $1;
	$tags->[0] = $2;
	}

	if ($tags->[$l] =~ /^(.+[^\)"\]'.?!:])?([\)"\]'.?!:]+)$/) {
		$last = $2;
	$tags->[$l] = $1;
	}

	return ($first, $last);
}

# slap tags onto anchor words. input: tag arrayref, anchor string
#
sub taganchor {
	my $tags = shift;
	my $anchor = shift;

	my @tagged = ();	# array of tagged words

	my $i = 0;
	foreach my $word (split(/\s+/,$anchor)) {
		push @tagged, $tags->[2*$i].$word.$tags->[2*$i+1];
		$i++;
	}

	return join (' ',@tagged);
}

# get the anchor text for a link match term (pluralizes/possessivizes)
#
sub getanchor {
	my $match = shift;

	my $term = $match->{'term'};
	my $plural = $match->{'plural'};
	my $psv = $match->{'possessive'};
	
	my $anchor = $term;
	if ($psv == 1) {
		$anchor = getpossessive($term);
	} 
	if ($plural == 1) {
		$anchor = pluralize($term);
	}

	return $anchor;
}

# build a match description structure based on text and terms list
#
sub findmatches {
	my $text = shift;
	my $terms = shift;	# this should be a hash of title=>name

	#dwarn "*** xref: text is [$text]";
	($text,) = getEscapedWords($text);	# pull out \PMlinkescapeword/phrase
	my @tlist = split(/\s+/,$text);

	my %matches;	 # main matches hash (hash key is word position)

	# loop through words in the text. this is the O(m) main loop.
	my $tlen = $#tlist+1;
	for (my $i = 0; $i < $tlen; $i++) {

	my $stag = getstarttag($tlist[$i]);	# get tags around first word 
	my $etag = getendtag($tlist[$i]);			
		
	my $word = bareword($tlist[$i]);
	my $COND = 0;	 # debug
	
	# look for the first word, then try to match additional words
	#
	my $rv = 0;
	my $fail = 1;
	if (defined $terms->{$word}) {
		$fail = 0;
		dwarn "*** xref: found $word for $tlist[$i] in hash" if $COND;
		$rv = matchrest(\%matches,
					$word,$terms->{$word},
					\@tlist,$tlen,$i,
					[$stag,$etag]);
		$fail = !$rv;
		if (!$rv) {
			dwarn "*** xref: rejected initial match for $word" if $COND;
		}
	}
	if ($fail) {
		if (ispossessive($word)) {
			dwarn "*** xref: trying unpossesive for $word" if $COND;
			$word = getnonpossessive($word);
			$rv = matchrest(\%matches,
				$word,$terms->{$word},
				\@tlist,$tlen,$i,
				[$stag,$etag],1);
		} elsif (isplural($word)) {
			dwarn "*** xref: trying nonplural for $word" if $COND;
			my $np = depluralize($word);
			$rv = matchrest(\%matches,
				$word,$terms->{$np},
				\@tlist,$tlen,$i,
				[$stag,$etag],
				undef,1);
			} else {
					dwarn "*** xref: found no forms for $word" if $COND;
			}
		}
	}
	
	return {%matches};	
}

# return true if "word" shouldn't be considered in matching
#
sub skipword {
	my $word = shift;

	return 1 if ($word eq '__NL__');
	return 1 if ($word eq '__CR__');

	return 0;
}

# match the rest of a title after getting a first-word match.
#	
sub matchrest {
	my $matches = shift;	 # matches structs we keep updated (pointer to hash)
	my $word = shift;			# first word in matched sequence
	my $subhash = shift;	 # hash of matching terms to $word
	my $tlist = shift;		 # text words list (pointer to list)
	my $tlen = shift;			# text words count
	my $i = shift;				 # position in text words list we're at
	my $tags = shift;			# array of tags

	# optional parameters
	my $psv = shift || 0;		# append possessive flag
	my $plural = shift || 0; # gets set to 1 if ending word was plural
 
		
	# find longest matching term from subhash
	# since sorting in reverse order, we stop at first (longest) match.
	#
	my $matchterm = '';		# this gets set to non "" if we have a match
	my $matchlen = 0;			# length of match, the larger the better.
	my @mtags;						 # match tags
 
	foreach my $title (sort {lc($b) cmp lc($a)} keys %$subhash) {
		my $COND=0;	 # debug printing condition
		#my $COND=($word=~/^banach/i);		# debug printing condition
		dwarn " *** xref: comparing $word to $title" if $COND;

		@mtags = ();				 # reset match tags
		my @words = split(/\s+/,$title);	 # split into words

		my $midx = 0;	 # last matched index - we start at entry 0 matched
		my $widx = $#words;
		my $skip = 0;	# for index into text
		
		# see how many words we can match against this title
		#
		$skip++ if skipword($tlist->[$i+1]);
		dwarn "*** xref: skip starts out as $skip" if $COND;
		dwarn "*** xref: text word is $tlist->[$i+1]" if $COND;
		while (($i+$midx+$skip+1 < $tlen) && 
				 ($midx<$widx ) && 
			 (bareword($tlist->[$i+$midx+$skip+1]) eq lc($words[$midx+1]))) {

			dwarn " *** xref: matched word $tlist->[$i+$midx+$skip+1]" if $COND;

			push @mtags,getstarttag($tlist->[$i+$midx+$skip+1]); # keep tags
			push @mtags,getendtag($tlist->[$i+$midx+$skip+1]);
		
			$midx++;			# update indexes
			$skip++ if skipword($tlist->[$i+$midx+$skip+1]);
			dwarn "*** xref: skip is now $skip" if $COND;
		}

		dwarn " *** xref: skip is $skip" if $COND;

		# if we matched all words, store match info
		#
		if ($midx == $widx) {	 
			dwarn " *** xref: matched all words, $midx = $widx" if $COND;
			$matchterm = $title;
			$matchlen = $widx + $skip + 1;
			dwarn " *** xref: matchterm is [$matchterm]" if $COND;
			last;
		}

		# if we only need one more matching word...
		#
		if ($midx+1 == $widx) {	
			# ... check for plural last word ( and/or tag)
			#
			$skip++ if skipword($tlist->[$i+$midx+$skip+1]);
			my $nextword = $tlist->[$i+$midx+$skip+1];
			dwarn " *** xref: nextword is '$nextword'" if $COND;
			my $istagged = istagged($nextword);
			my $isplural = isplural(bareword($nextword));
			if ($isplural || $istagged) {
				my $clean = $nextword;
				$clean = bareword($nextword) if ($istagged);
				$clean = depluralize($clean) if ($isplural);
				if ($clean eq lc($words[$widx])) {
				dwarn " *** xref: we have a match" if $COND;
					
				$plural=$isplural;
				$matchterm=$title;
				$matchlen=$widx+$skip+1;
				dwarn " *** xref: match length is $matchlen" if $COND;

				push @mtags,getstarttag($nextword);	
				push @mtags,getendtag($nextword);

				last;
			}
		}
	}
	}

	# try to add match if we found one.
	#
	if ($matchterm ne "") {
		push @$tags,@mtags;		# save all the tags
		insertmatch($matches,$i,$matchterm,$matchlen,$plural,$psv,$tags);
	}
 
	return ($matchterm eq "")?0:1;		# return success or fail
}


# add to matches list - only if we found a better (larger) match for a position
#
sub insertmatch {
	my ($matches,$pos,$term,$length,$plural,$psv,$tags)=@_;
	
	# CHANGED : handling this at display time now to fix some behavior
	# check for term already being included, since we dont want repeats
	#return if (defined $mterms->{$term});
	
	# check for existing entry 
	#
	if (defined $matches->{$pos}) {
		if ($matches->{$pos}->{'length'} < $length) {
		#dwarn "replacing $term at $pos, length $length with $term, length $length\n";
		$matches->{$pos}->{'term'}=$term;
		$matches->{$pos}->{'length'}=$length;
		$matches->{$pos}->{'plural'}=$plural;
		$matches->{$pos}->{'possessive'}=$psv;
		$matches->{$pos}->{'tags'}=$tags;
		
		# remove matches at positions within the newly extended boundary
		#
		for (my $i=$pos;$i<($pos+$length);$i++) {
			if (defined $matches->{$i}) {
			#dwarn "removing $matches->{$i}->{term}, swallowed up by $term";
			$matches->{$i}=undef;
		}
		}
	} else {
		#dwarn "not adding $term at $pos, length $length\n";
	}
	} 
	
	# nonexistant - insert
	#
	else {
		my $ppos=undef;
		my $safe=1;
		foreach my $key (sort {$a <=> $b} keys %$matches) {
		last if ($key >= $pos);
		$ppos=$key;
	}
	if (defined $ppos) {
		$safe=0 if ($pos < ($ppos + $matches->{$ppos}->{'length'}));
	} 
		if ($safe) {
		#dwarn "*** xref: adding match $term at $pos, length $length\n";
			$matches->{$pos}={
		 'term'=>$term, 
		 'length'=>$length, 
		 'plural'=>$plural,
		 'possessive'=>$psv,
		 'tags'=>$tags};
		} else {
			#dwarn "match $term at $pos is inside range of previous term at $ppos, not adding\n";
	}
	}
}

# keep track of manual links
#
sub doManualLinks {
	my $list = shift;
	my $fromid = shift;

	return unless $fromid;

	my $table = getConfig('en_tbl');

	foreach my $id (@$list) {
		xrefAddLink($fromid,$table,$id,$table) if ($fromid);
	}
}

# split out, process pseudo-LaTeX linking commands
#
sub splitPseudoLaTeX {
	my $text = shift;
	my $method = shift; #BB: should we protect URLs?

	my @escaped = ();
	my @linkids = (); # list of ids to manually link
	my $eidx = 0;

	# crossreference escaping
	#
	# \PMlinkescapetext{four score and seven years} 
	while ($text =~ s/\\PMlinkescapetext\{(.+?)\}/\@\@$eidx\@\@/s) {
		push @escaped,$1;
		$eidx++;
	}
	# {\PMlinkescapetext four score adn seven years}
	while ($text =~ s/\{\\PMlinkescapetext\s(.+?)\}/\@\@$eidx\@\@/s) {
		push @escaped,$1;
		$eidx++;
	}

	# crossreference forcing 
	#
	while ($text =~ s/\\PMlinktofile\{(.+?)\}\{(.+?)\}/\@\@$eidx\@\@/s) {
		push @escaped,"\\PMlinktofile{$1}{$2}";	# preserve these commands
		$eidx++;
	}
	#BB: protect URL unless we are in l2h mode because l2h protects URLs
	while ($text =~ s/\\PMlinkexternal\{(.+?)\}\{(.+?)\}/\@\@$eidx\@\@/s) {
		push @escaped,"\\htmladdnormallink{".protectAnchor($1)."}{".(($method eq 'l2h')?$2:protectURL($2))."}";
		$eidx++;
	}
	while ($text =~ /\\PMlinkid\{(.+?)\}\{(.+?)\}/so) {
		my $anchor = $1;
		my $id = $2;
		if (objectExistsByUid($id)) {
			push @escaped,"\\htmladdnormallink{$anchor}{".protectURL(getConfig("main_url"))."/encyclopedia/$id.html}";
			$text =~ s/\\PMlinkid\{.+?\}\{.+?\}/\@\@$eidx\@\@/s;
			push @linkids, $id;
		} else {	# failed to resolve target
			push @escaped,$anchor;
			$text =~ s/\\PMlinkid\{.+?\}\{.+?\}/\@\@$eidx\@\@/s;
		}
		$eidx++;
	}
	while ($text =~ /\\PMlinkname\{(.+?)\}\{(.+?)\}/so) {
		my $anchor = $1;
		my $name = $2;
		my $id = objectExistsByName($name);
		if ($id) {
			push @escaped,"\\htmladdnormallink{$anchor}{".protectURL(getConfig("main_url"))."/encyclopedia/$name.html}";
			push @linkids, $id;
		} else {	# failed to resolve target
			push @escaped,$anchor;
		}
		$text =~ s/\\PMlinkname\{.+?\}\{.+?\}/\@\@$eidx\@\@/so;
		$eidx++;
	}

	return ($text, [@escaped], [@linkids]);
}

# split LaTeX into math and text, with ##N## anchors where the math used to be.
# now also removes escaped text portions
# 
sub splitLaTeX {
	my $text = shift;
	my $escaped = shift;

	my @math = ();

	# APK - these spaces will remove worries about some boundary conditions
	# so that the regexps in this sub work (as in when the entry starts or
	# ends with some math).
	#
	$text = " $text ";

	my $table = getConfig('en_tbl');
	
	if (not defined $escaped) {
		$escaped = [()];
	}

	my $midx = 0;
	my $eidx = scalar @$escaped;

	$text = fragmentpseudos($text);

	# rendered math escaping
	#
	# Moved Lalgorithm handling to top, as these environments tend to contain inlined math -LBH
	while ($text =~ s/(\\begin\{.+algorithm\}.+?\\end\{.+algorithm\})/##$midx##/s) {
		push @math,$1;
		$midx++;
	}
	while ($text =~ s/(\\\[.+?\\\])/##$midx##/s) {
		push @math,$1;
		$midx++;
	}
	# changed .+ to .* because the [^\\] is required to match	-LBH
	while ($text =~ s/([^\\])(\$\$.*?[^\\]\$\$)/$1##$midx##/s) {
		push @math,$2;
		$midx++;
	}
	# changed .+ to .* ...	-LBH
	while ($text =~ s/([^\\])(\$.*?[^\\]\$)/$1##$midx##/s) {
		push @math,$2;
		$midx++;
	}
	while ($text =~ s/(\\begin\{eqnarray[*]{0,1}\}.+?\\end\{eqnarray[*]{0,1}\})/##$midx##/s) {
		push @math,$1;
		$midx++;
	}
	while ($text =~ s/(\\begin\{displaymath\}.+?\\end\{displaymath\})/##$midx##/s) {
		push @math,$1;
		$midx++;
	}
	while ($text =~ s/(\\begin\{math\}.+?\\end\{math\})/##$midx##/s) {
		push @math,$1;
		$midx++;
	}
	while ($text =~ s/(\\begin\{equation[*]{0,1}\}.+?\\end\{equation[*]{0,1}\})/##$midx##/s) {
		push @math,$1;
		$midx++;
	}
	while ($text =~ s/(\\begin\{align[*]{0,1}\}.+?\\end\{align[*]{0,1}\})/##$midx##/s) {
		push @math,$1;
		$midx++;
	}

	# pull out bibliography section
	#
	if ($text =~ s/((\\begin\{\s*thebibliography\s*\}|\\(paragraph|section|textbf)\{\s*Reference.*?\}|\{\\bf\s+Reference.*?\}|\\(paragraph|section|textbf)\{\s*Further\s+Reading.*?\}|\{\\bf\s+Further\s+Reading.*?\}).+)$/\@\@$eidx\@\@/s) {
		#dwarn "link escaping biblio [$1]";
		push @$escaped,$1;
		$eidx++;
	}

	# escape quoted text
	#
	# APK - removed escaping of ".+?" ... this was bad... ended up escaping
	# consecutive instances of \" in words.
	while ($text =~ s/(``.+?'')/\@\@$eidx\@\@/s) {
		push @$escaped,"$1";
		$eidx++;
	}

	# escape everything not in the whitelist
	#
	while ($text =~ /(\\(\w+)[*]?(?:\[.+?\])?\{.+?\})/sgo) {
		my $cmd = $2;
		my $tag = $1;

		#dwarn "*** splitLaTeX : checking tag [$tag]";
	
		# if not in the whitelist, kill the whole command
		#
		if (not exists $LINKABLETAGS{$cmd}) {
			#dwarn "*** splitLaTeX : not in whitelist, escaping [$tag]";
			$text =~ s/\Q$tag\E/\@\@$eidx\@\@/s;
			push @$escaped, $tag; 
			$eidx++;
		}

		# just kill the tag
		# 
		else {
			$text =~ s/\\$cmd/\@\@$eidx\@\@/s;
			push @$escaped, "\\$cmd";
			$eidx++;
		}
	}
	
	return $text,[@math];
}

# preprocessing to do before xreffing
#
# all the spacing is done to make the "list of words" and chained-hash 
# concept index stuff work.
#
# we would be able to get rid of this if we had some "real" parsing; then 
# we could just walk a document tree later.
#
sub preprocessLaTeX {
	my $text = shift;

	# remove comments
	#
	$text =~ s/^\s*[%].*?$//gm;

	# tilde to special char
	#
	$text =~ s/([^\s])~([^\s])/$1 __TILDE__ $2/sg;

	# space punctuation out from the ends of words. that is, make them separate 
	# words.
	$text =~ s/([\w\}])([;.,):\?\!])/$1 __SPACER__ $2/sg;

	# space out punctuation from the beginning of words
	$text =~ s/([(])([\w\\])/$1 __SPACER__ $2/sg;

	# space out footnotes
	$text =~ s/(\w)(\\footnote)/$1 $2/sg;
	$text =~ s/(\\footnote\{)(\w)/$1 $2/sg;

	# space attribs and braces out
	#
	$text =~ s/(\\emph\{|\\textbf\{)(\w)/$1 __SPACER__ $2/sg;
	$text =~ s/(\\emph\{|\\textbf\{|\{\\it|\{\\bf|\{\\em)(.+?)(\})/$1$2 __SPACER__ $3/gs;
	
	# space out \\ linebreaks
	#
	$text =~ s/(\w)\\\\/$1 __SPACER__ \\\\/sg;

	# preserve newlines - this is important for LaTeX
	#
	$text =~ s/\n/ __NL__ /gs;
	$text =~ s/\r/ __CR__ /gs;

	return $text;
}

# post-xreffing processing
#
sub postprocessLaTeX {
	my $text = shift;

	# remove spaces added earlier
	$text =~ s/\s*__SPACER__\s*//gs;

#	$text =~ s/([\w\}]) ([;.,):\?\'\!])/$1$2/sg;
#	$text =~ s/([(\`]) ([\w\\])/$1$2/sg;
#	$text =~ s/(\w) (\})/$1$2/sg;
#	$text =~ s/(\w) (\\footnote)/$1$2/sg;

	# remove tilde thingie
	$text =~ s/\s*__TILDE__\s*/~/sg;

	# put back CR and NL
	$text =~ s/\s*__NL__\s*/\n/sg;
	$text =~ s/\s*__CR__\s*/\r/sg;

	return $text;
}
	

# get phrases/word to escape
#
sub getEscapedWords {
	my $text = shift;

	my @list = ();
	
	# \PMlinkescapeword{word or phrase}
	while ($text =~ /\\PMlinkescapeword\{(.+?)\}/) {
		my $phrase = $1;
		$text =~ s/\\PMlinkescapeword\{\Q$phrase\E\}//gs;
		push @list,$phrase;
	}
	
	# \PMlinkescapephrase{word or phrase}
	while ($text =~ /\\PMlinkescapephrase\{(.+?)\}/) {
		my $phrase = $1;
		$text =~ s/\\PMlinkescapephrase\{\Q$phrase\E\}//gs;
		push @list,$phrase;
	}

	return ($text,@list);
}

# fragment pseudo-latex Noosphere commands. basically this means we turn
# one command that contains some math environments, $-escaped, to multiple 
# commands with the math portions extracted and *between* the commands.
#
# for example, we convert things like:
#	 \PMlinkname{$\sigma$-derivation}{SigmaDerivation}
# to
#	 $\sigma$\PMlinkname{-derivation}{SigmaDerivation}
#
sub fragmentpseudos {
	my $text = shift;

	# better to read the description above and re-construct the code yourself
	# than to try to understand this... it could be a lot worse too.
	#
	while ($text =~ /\\PM\w+\{([^\}]*?)\$.+?\$([^\}]*?)\}\{.+?\}/s) {
		if ($1 && $2) {
			$text=~s/(\\PM\w+\{)([^\}]*?)(\$.+?\$)([^\}]*?\})(\{.+?\})/$1$2\}$5$3$1$4$5/s;
		} else {
			if ($2) {
				$text=~s/(\\PM\w+\{)([^\}]*?)(\$.+?\$)([^\}]*?\})(\{.+?\})/$3$1$4$5/s;
			}
			elsif ($1) {
				$text=~s/(\\PM\w+\{)([^\}]*?)(\$.+?\$)([^\}]*?\})(\{.+?\})/$1$2\}$5$3/s;
			}
			else {
				$text=~s/(\\PM\w+\{)([^\}]*?)(\$.+?\$)([^\}]*?\})(\{.+?\})/$3/s;
			}
		}
	}
	#dwarn "split text is [$text]";
	return $text;
}

# go through $text and escape all occurrences of a phrase (that is, put them
# in a list with stable order and replace them with an anchor in the text)
#
sub escapephrase {
	my $text = shift;
	my $phrase = shift;
	my $eidx = shift;
	my $list = shift;
	
	my $found = 0;
	do {
		$found = 0;
		if ($text =~ /\b(\Q$phrase\E)\b/) {
		$found = 1;
		push @$list,$1;
		$text =~ s/\b\Q$phrase\E\b/\@\@$eidx\@\@/s;
		$eidx++;
	}
	} while ($found == 1);

	return ($text,$eidx);
}

# recombine a math list and LaTeX with math anchors
#
sub recombine {
	my $text = shift;
	my $mathlist = shift;
	my $esclist = shift;
 
	# note that this HAS to be done in this order: escaped items
	# can contain math.
	#
	# APK - also, escaped items can be nested
	#
	while ($text=~s/\@\@([0-9]+)\@\@/$esclist->[$1]/s) { 1; };
	#foreach my $escitem (@$esclist) {
	#	$text=~s/\@\@$idx\@\@/$escitem/s;
	#	$idx++;
	#}
	while ($text=~s/##([0-9]+)##/$mathlist->[$1]/s) { 1; };
	#foreach my $mathitem (@$mathlist) {
	#	$text =~ s/##$idx##/$mathitem/s;
	#	$idx++;
	#}

	return $text;
}

###########################################################################
#	xref stuff
###########################################################################

# invalidate all objects that might need to be cross-referenced to 
# a new title.	this uses the word index, and the same processing on 
# the title string, as a heuristic to invalidate some _superset_ of
# the objects which have text that will be linked to the new title.
#
sub xrefTitleInvalidate {
	my $title = shift;
	my $table = shift;
	my $widx = getConfig('widx_tbl');

	my @words = getwordlist($title);
	return if ($#words < 0);	 # nothing to do if no "important" words

	my $wid = getwid($words[0]);
 
	#dwarn "*** xref: invalidating for new title $title" if ($DEBUG);
	#dwarn "*** xref: first word is $wid";
	
	return if (not $wid);

	# select objects that contain the first significant word
	#
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'distinct objectid',FROM=>$widx,WHERE=>"wid=$wid and tbl='$table'"});
	
	# go through and invalidate them all
	#
	while (my $row = $sth->fetchrow_hashref()) {
		# TODO: somehow we need to be able to kill a process which might 
		# be building this object (the build flag would be on but valid off)
		setbuildflag_off($table,$row->{objectid});
		setvalidflag_off($table,$row->{objectid});
	}
	$sth->finish();
}

# call this when a title changes
# 
sub xrefChange {
	my $id = shift;
	my $table = shift;

	# just delete all links to this object and invalidate cache
	xrefDeleteLinksTo($id,$table);
}

# add a link from->to (if its not already there)
#
sub xrefAddLink {
	my $fromid = shift;
	my $fromtbl= shift;
	my $toid = shift;
	my $totbl = shift;
	
	my $xtbl = getConfig('xref_tbl');

	if ($fromid<0 || $toid<0 || blank($fromtbl) || blank($totbl)) {
		#dwarn "we were passed a bad linking parameter: fromid=$fromid, toid=$toid, fromtbl=[$fromtbl], totbl=[$totbl]";
		return;
	}
	
	#dwarn "*** xref: adding link table entry for $fromid -> $toid" if ($DEBUG);
	if (!xrefLinkPresent($fromid,$fromtbl,$toid,$totbl)) {
		my ($rv,$sth)=dbInsert($dbh,{INTO=>$xtbl,VALUES=>"$fromid,'$fromtbl',$toid,'$totbl'"});
		$sth->finish();
	}
}

# see if a particular link is present in the db
# 
sub xrefLinkPresent {
	my $fromid = shift;
	my $fromtbl = shift;
	my $toid = shift;
	my $totbl = shift;
	
	my $xtbl = getConfig('xref_tbl');
	
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'fromid',FROM=>$xtbl,WHERE=>"fromid=$fromid and fromtbl='$fromtbl' and toid=$toid and totbl='$totbl'"});
	my $rc = $sth->rows();
	$sth->finish();

	return $rc?1:0;
}

# completely remove an item from the cross referencing links table
#
sub xrefUnlink {
	my $id = shift;
	my $table = shift;

	xrefDeleteLinksTo($id,$table);
	xrefDeleteLinksFrom($id,$table);
}

# delete from links table all objects point *to* given object
#	 also invalidate their cache records.
#
sub xrefDeleteLinksTo {
	my $id = shift;
	my $table = shift;

	my $xtbl = getConfig('xref_tbl');
	
	# find links
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'fromid,fromtbl',FROM=>$xtbl,WHERE=>"toid=$id and totbl='$table'"});

	my @rows = dbGetRows($sth);

	foreach my $row (@rows) {
		# invalidate source objects in cache
		# TODO: this should really be moved to a higher level... makes this 
		# function needlessly specific.
		#
		setvalidflag_off($row->{fromtbl},$row->{fromid});
		setbuildflag_off($row->{fromtbl},$row->{fromid});
	}
	 
	# now remove the links
	($rv,$sth) = dbDelete($dbh,{FROM=>$xtbl,WHERE=>"toid=$id and totbl='$table'"});
	$sth->finish();
}

# delete all links *from* given object+table
#
sub xrefDeleteLinksFrom {
	my $id = shift;
	my $table = shift;
	
	my $xtbl = getConfig('xref_tbl');

	return if ($id<0);	 # sanity

	# remove the links
	my ($rv,$sth) = dbDelete($dbh,{FROM=>$xtbl,WHERE=>"fromid=$id and fromtbl='$table'"});
	$sth->finish();
}

# get count of links /to/ a given object
# 
sub xrefGetLinksToCount {
	my $table = shift;
	my $id = shift;

	my $xtbl = getConfig('xref_tbl');
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'count(distinct fromid) as cnt',FROM=>$xtbl,WHERE=>"toid=$id and totbl='$table'"});
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	
	return $row->{'cnt'};
}

# get info for links to a given object: fromid, title, username, userid
#
sub xrefGetLinksTo {
	my $table = shift;
	my $id = shift;

	my $xtbl = getConfig('xref_tbl');

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>"distinct $xtbl.fromid,$table.title,users.username,$table.userid,$table.name",FROM=>"$xtbl,$table,users",WHERE=>"$xtbl.toid=$id and $xtbl.totbl='$table' and $table.uid=$xtbl.fromid and $table.userid=users.uid order by $table.title"});
	my @rows = dbGetRows($sth);
	
	return @rows;
}

# main entry point to graph categorization inference
#
sub getBestByBFS {
	my $table = shift;		# table the object is in
	my $rootid = shift;		# root id to enter the object graph
	my $homonyms = shift;	# list of homonym ids 
	my $depth = shift;		# how deep to go into the graph. we have to be careful
				# because entries have an average of 10 links, which 
				# means that by the second level we are analyzing 100
				# nodes!

	my $level = 1;		# initialize level
	my @queue = ();		# bfs queue
	my %seen;			# hash of ids we've seen (don't revisit nodes)

	# get classifications of the homonyms we are comparing against
	#
	my $hclass = [];
	foreach my $hid (@$homonyms) {
		push @$hclass, [getclass($table, $hid)];	
	}
	
	push @queue,$rootid;

	$seen{$rootid} = 1;
	my $ncount = expandBFSQueue($table,\@queue,\%seen);	# init list w/first level

	# each stage of this while loop represents a deeper "layer" of the graph
	my $w = -1;		# winner
	while ($w == -1 && $ncount > 0 && $level <= $depth) {
		#foreach my $node (@queue) {
		#	print "($level) $node\n";
		#}

		my @scores = scoreAgainstArray($table,$hclass,\@queue);
		#foreach my $i (0..$#scores) {
		#	print "$level) $homonyms->[$i] scores $scores[$i]\n";
		#}
	
		$w = winner(\@scores);
		my $ncount = expandBFSQueue($table,\@queue,\%seen);	 
		$level++;
	}

	return $w;	 # return winner index (or -1)	
}

# select the winning index out of an array of scores, -1 if indecisive
#
sub winner {
	my $scores = shift;

	my $top = -1;				
	my $topidx = -1;

	foreach my $i (0..scalar @{$scores}-1) {
		my $score = $scores->[$i];
		if ($score > $top) {
			$top = $score;
			$topidx = $i;
		} elsif ($score == $top) {
			return -1;			 # if we have a single tie, we fail
		}
	}

	return $topidx;
}

# returns an array which gives the score for each node in the input homonym
# list, which represents how much each homonym's classification coincides with
# the aggregate of the classifications on the input object list
#
sub scoreAgainstArray {
	my $table = shift;
	my $class = shift;
	my $array = shift;

	my @scores = ();
	my @carray = ();
	
	# get classification for the array items
	#
	foreach my $a (@$array) {
		#print "getting class for $a\n";
		my $fetchc = [getclass($table,$a)];
		push @carray,$fetchc if (@{$fetchc}[0]);
	}

	# loop through each input classification and score it
	#
	foreach my $ca (@$class) {
		my $total = 0;
		foreach my $cb (@carray) {
			#print "comparing a={$ca->[0]->{ns},$ca->[0]->{cat}, b={$cb->[0]->{ns},$cb->[0]->{cat}}\n";
			$total += classCompare($ca,$cb);
		}
		push @scores,$total;
	}

	return @scores;
}

# expand id queue by pushing all the nodes immediately connected onto it
#
sub expandBFSQueue {
	my $table = shift;
	my $queue = shift;
	my $seen = shift;
	
	my $count = scalar @{$queue};	 # we're going to remove current elements
#	print "count on queue $count\n";

	my @neighbors = xrefGetNeighborListByList($table,$queue,$seen);
	push @$queue,@neighbors;
	splice @$queue,0,$count;			# delete front elements

	return scalar @neighbors;			# return count of novel nodes
}

# pluralize the below, throwing out things in 'seen' list
#
sub xrefGetNeighborListByList {
	my $table = shift;
	my $sources = shift;
	my $seen = shift;
 
	my @outlist = ();	 # initialize output list
	
	foreach my $sid (@$sources) {
		my @list = xrefGetNeighborList($table,$sid);
		foreach my $nid (@list) {
			if (! defined $seen->{$nid}) {	# add only novel items
				push @outlist,$nid;
				$seen->{$nid} = 1;	 
			}
		}
	}

	return @outlist;
}

# get a list of "neighbors" in the crossreference graph, from a particular
# node (i.e. nodes the source node can "see" or has outgoing links to)
#
sub xrefGetNeighborList {
	my $table = shift;
	my $source = shift;
	
	my $xtbl = getConfig('xref_tbl');
 
	my @list = ();

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'toid',FROM=>$xtbl,WHERE=>"fromid=$source and fromtbl='$table' and totbl='$table'"});

	my @rows = dbGetRows($sth);

	foreach my $row (@rows) {
		push @list,$row->{toid};
	}

	return @list;
}

# compare and score two classifications against each other.	gives a count
# of the coinciding categories.
#
# TODO: perhaps make this smarter than just brute force O(nm) where n and m
# are the lengths of each classification
#
sub classCompare {
	my $classa = shift;
	my $classb = shift;

	my $total = 0;
	
	foreach my $cata (@$classa) {
		foreach my $catb (@$classb) {
			$total += catCompare($cata,$catb);
		}
	}

	return $total;
}

# an elementary operation... compare two classification hashes to determine if
# they are "equal" (in the same scheme, in the same section)
#
sub catCompare {
	my $a = shift;
	my $b = shift;

	# TODO: make this handle mappings between schemes
	#			 also, handlers for other schemes

	#print "comparing categories {$a->{ns},$a->{cat}}, {$b->{ns},$b->{cat}}\n";

	return 0 if ($a->{ns} ne $b->{ns});

	if ($a->{ns} eq 'msc') {
		$a->{cat} =~ /^([0-9]{2})/;
		my $aprefix = $1;
		$b->{cat} =~ /^([0-9]{2})/;
		my $bprefix = $1;

		return 1 if ($aprefix eq $bprefix);
	}

	# TODO: handlers for other schemes?

	return 0;
}


1;
