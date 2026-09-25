package Noosphere;

use strict;
use Template;

# get a full msc comment for the given id and all categories above
#
sub getHierarchicalMscComment {
	my $id = shift;

	# leaf, but under a main -XX
	#
	if ($id =~ /([0-9]{2})-[0-9]{2}/) {
		return getShortMscCommentById("$1-XX").' :: '.
					 getShortMscCommentById($id);
	}

	# leaf under main/subcategory
	#
	if ($id =~ /([0-9]{2})([A-Z])[0-9]{2}/) {
		my $middle = getShortMscCommentById("$1$2xx");

		return getShortMscCommentById("$1-XX").' :: '.
					 (defined($middle)?$middle.' :: ':'').
					 getShortMscCommentById($id);
	}

	# others
	#
	return getShortMscCommentById($id);
}

# get math subject classification comment with no parens in it
#
sub getShortMscCommentById {
	my $comment = getMscCommentById(shift);

	return undef if (not defined $comment);

	$comment =~ s/\s*\(.*\)\s*/ /g;
	
	return $comment;
}

# get math subject classification comment by id
#
sub getMscCommentById {
	my $id = shift;

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'comment',
		FROM=>'msc',
		WHERE=>"id='$id'"});

	my $row = $sth->fetchrow_hashref();
	$sth->finish();

	return undef if (not defined $row);

	my $comment = $row->{'comment'};

	$comment =~ s/^\s*//;
	$comment =~ s/\s*$//;

	return $comment;
}

# Build a PACS term expression for an explicitly named MSC table alias.
#
sub pacsSearchCondition {
	my ($term, $alias) = @_;
	my @terms = grep { length } split(/\s+/, $term);

	return join(' and ', map {
		if (/^-(.+)$/) {
			"$alias.comment not like '%" . sq($1) . "%'";
		}
		else {
			my $safe_term = sq($_);
			"($alias.comment like '%$safe_term%' or $alias.id='$safe_term')";
		}
	} @terms);
}

# Search PACS labels and encyclopedia articles classified within matching topics.
#
sub pacsSearch {
	my $params = shift;

	my $term = $params->{pacsterm} || '';
	my $leaves = $params->{leaves} ? $params->{leaves} : ($term ? 'off' : 'on');
	my @results;
	my @article_results;
	my $article_results_limited = 0;

	if ($term) {
		my $searchterm = pacsSearchCondition($term, 'msc');
		my $leafq = $leaves eq 'on' ? "and not msc.id like '%X%'" : '';
		my ($rv,$sth) = dbSelect($dbh,{WHAT=>'id,comment, parent',FROM=>'msc',WHERE=>"$searchterm $leafq",'ORDER BY'=>'id',ASC=>''});
	
		while (my $row = $sth->fetchrow_hashref()) {
			my $linkto = (defined $row->{parent})?"id=$row->{parent}":'';
			push @results, {
				id => qhtmlescape($row->{id}),
				comment => qhtmlescape(latin1ToUTF8(htmlToLatin1($row->{comment}))),
				href => getConfig("main_url")."/?op=pacsbrowse&$linkto",
			};
		}
		$sth->finish();

		my $class = getConfig('class_tbl');
		my $clinks = getConfig('clinks_tbl');
		my $article_searchterm = pacsSearchCondition($term, 'matched_msc');
		my $article_leafq = $leaves eq 'on' ? "and not matched_msc.id like '%X%'" : '';
		my ($article_rv, $article_sth) = dbLowLevelSelect($dbh,
			"select distinct objects.uid, objects.title, assigned_msc.id as classification_id, assigned_msc.comment as classification_comment " .
			"from msc as matched_msc, $clinks, $class, objects, msc as assigned_msc " .
			"where $article_searchterm $article_leafq and " .
			"$clinks.a = matched_msc.uid and $class.catid = $clinks.b and " .
			"$class.nsid = $clinks.nsb and $class.tbl = 'objects' and " .
			"objects.uid = $class.objectid and assigned_msc.uid = $class.catid " .
			"order by lower(objects.title) limit 101");

		while (my $row = $article_sth->fetchrow_hashref()) {
			push @article_results, {
				id => $row->{uid},
				title => mathTitleXSL($row->{title}, 'highlight'),
				classification_id => qhtmlescape($row->{classification_id}),
				classification_comment => qhtmlescape(latin1ToUTF8(htmlToLatin1($row->{classification_comment}))),
				classification_href => getConfig('main_url')."/browse/objects/$row->{classification_id}/",
			};
		}
		$article_sth->finish();
		$article_results_limited = pop(@article_results) ? 1 : 0 if @article_results > 100;
	}

	my $html = '';
	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	$tt->process('pacssearch.tt', {
		term => qhtmlescape($term),
		leaves => $leaves eq 'on' ? 1 : 0,
		has_search => $term ne '' ? 1 : 0,
		results => \@results,
		article_results => \@article_results,
		article_results_limited => $article_results_limited,
	}, \$html) || die "Template process failed: ", $tt->error(), "\n";

	return paddingTable($html);
}

sub pacsBrowseLeaves {
	my ($scheme, $class, $domain, $id) = @_;

	return () unless ($domain eq 'objects' or $domain eq 'papers' or $domain eq 'lec' or $domain eq 'books');

	# PACS leaves can have a + symbol in their id, which Apache request handling converts to a space.
	$id =~ s/\s/+/g;
	my $safe_id = sq($id);

	my ($rv, $sth) = dbLowLevelSelect($dbh,
		"select $scheme.id, $scheme.comment, $domain.title, $domain.uid, users.username, users.uid as userid " .
		"from $scheme, $class, $domain, users where $scheme.id = '$safe_id' and " .
		"$class.tbl = '$domain' and $class.catid = $scheme.uid and " .
		"$domain.uid = $class.objectid and users.uid = $domain.userid order by lower($domain.title)");

	my @rows = dbGetRows($sth);
	my @leaves;
	foreach my $row (@rows) {
		push(@leaves,{
			domain 		=> $domain,
			uid		=> $row->{uid},
			userid		=> $row->{userid},
			username	=> $row->{username},
			title		=> mathTitleXSL($row->{'title'}, 'highlight'),
		});
	}

	return @leaves;
}

sub pacsBrowse {
	my $params = shift;
	#dwarn "pacsBrowse start";
	my $types = $params->{'types'};
	my $id = $params->{'id'};
	my $domain = $params->{'from'} || 'categories';
	my $tdesc = $domain ne 'categories' ? tabledesc($domain) : '';

	my $scheme = 'msc';
	my $class = getConfig('class_tbl');
	my $clinks = getConfig('clinks_tbl');
    my $file = 'pacsbrowse.tt';
	my $htmlout = "";
	my $domainSwitch = 0;
	my $idSwitch = 0;
	my $parent = '';
	my $desc = '';
	my $upstr = '';
	my $parent_url = '';
	my $parent_id = '';
	my $parent_desc = '';
	my $rv;
	my $sth;
	my @pacs_nodes = ();
	my @pacs_leaves = ();
	my @rows;

	# top level
	#
	# change -XX to .
	if(not(defined($id))) {
		#dwarn "not defined id";
		$idSwitch = 0;
		if ($domain ne 'categories') {
			#dwarn "$domain ne categories";
			$domainSwitch = 0;
			my $q = "select $scheme.id, $scheme.comment, count(distinct $class.objectid) as cnt " .
			"from $clinks, $class, $scheme ".
			"where ($scheme.id like '%-XX') and " .
			"$clinks.a = $scheme.uid and $class.catid = $clinks.b and " .
			"$class.nsid = $clinks.nsb and $class.tbl = '$domain' " .
			"group by $scheme.id, $scheme.comment order by $scheme.id";
			($rv, $sth) = dbLowLevelSelect($dbh, $q);
		}
		else
		{
			#dwarn "$domain equals categories";
			$domainSwitch = 1;
			($rv, $sth) = dbLowLevelSelect($dbh, "select $scheme.id, $scheme.comment from $scheme where ($scheme.id like '%-XX') order by $scheme.id");
		}

		@rows = dbGetRows($sth);

		foreach my $row (@rows) {
			
			
			my $child = lookupfield($scheme, 'id', "parent='$row->{id}'");
			#dwarn "row child:  $child";
			##$template->addText('<mscnode>');
		
			##$template->addText("<haschild />") if ($child);
			##$template->addText("<domain>$domain</domain>");
			##$template->addText("<id>$row->{id}</id>");
			##$template->addText("<count>$row->{cnt}</count>") if ($domain ne 'categories');
			my $comment = latin1ToUTF8(htmlToLatin1($row->{comment}));
			##$template->addText("<comment>$comment</comment>");
			##$template->addText('</mscnode>');
			my $count = 0;
			if ($domain ne 'categories') {
				$count = $row->{cnt};
				#dwarn "row count:  $count";
			}
			#dwarn "comment: $comment";
			push(@pacs_nodes,{ 
				child 			=> $child,
				domain 			=> $domain,
				id				=> $row->{id},
				count			=> $count,
				comment			=> $comment, 		 	
			});
		}

	}
	# ##-XX level / ##Cxx level
	# Ben changed XX to .
	elsif ($id =~ /XX$/io) {
		#dwarn "-XX level";
		#dwarn "domain: $domain ";
		if ($domain ne 'categories') {
			($rv, $sth) = dbLowLevelSelect($dbh, 
			
				"select $scheme.id, $scheme.comment, count(distinct $class.objectid) as cnt " .	
			"from $clinks, $class, $scheme where ($scheme.parent = '$id') and " .	
			"$clinks.a = $scheme.uid and $class.catid = $clinks.b and " .	
			"$class.nsid = $clinks.nsb and $class.tbl = '$domain' " . 
			"group by $scheme.id, $scheme.comment order by $scheme.id");
		} else {
			($rv, $sth) = dbLowLevelSelect($dbh, "select $scheme.id, $scheme.comment from $scheme where $scheme.parent = '$id' order by $scheme.id");
		}

		my @rows = dbGetRows($sth);
		$desc = getHierarchicalMscComment($params->{'id'});

		my $upid = lookupfield($scheme, 'parent', "id='$id'");
		$upstr = (defined $upid ? "$upid/" : '');
		$parent = 1;
		##$template->addText("<parent href=\"".getConfig("main_url")."/browse/$domain/$upstr\">");
		##$template->addText("<id>$params->{id}</id><desc>$desc</desc>");
		##$template->addText('</parent>');
	
		foreach my $row (@rows) {
			my $count = 0;
			$count = $row->{'cnt'} if ($domain ne 'categories');

			my $child = lookupfield($scheme, 'id', "parent='$row->{id}'");
			
			##$template->addText('<mscnode>');
			##$template->addText("<domain>$domain</domain>");
			##$template->addText("<haschild />") if ($child);
			##$template->addText("<id>$row->{id}</id>");
			##$template->addText("<count>$count</count>") if ($domain ne 'categories');
			my $comment = latin1ToUTF8(htmlToLatin1($row->{comment}));
			##$template->addText("<comment>$comment</comment>");
			##$template->addText('</mscnode>');
			#dwarn "child count: $count";
			#dwarn "domain: $domain";
			#dwarn "id: $id";
			push(@pacs_nodes,{ 
				child 			=> $child,
				domain 			=> $domain,
				id				=> $row->{id},
				count			=> $count,
				comment			=> $comment, 		 	
			});
		}
		push(@pacs_leaves, pacsBrowseLeaves($scheme, $class, $domain, $id));
	}
	
	# leaf level
	#
	else {
		#dwarn "leaf level";
		#dwarn "select:";
		#dwarn "domain: $domain";
		# need to make sure domain is valid else sql will crash things
		if( $domain eq 'objects' or $domain eq 'papers' or $domain eq 'lec' or $domain eq 'books' ) {
			$id =~ s/\s/+/g;
			$desc = getHierarchicalMscComment($params->{id});

			my $upid = lookupfield($scheme, 'parent', "id='$id'");
			$parent = 1;
			##$template->addText("<parent href=\"".getConfig("main_url")."/browse/$domain/$upid/\">");
			##$template->addText("<id>$params->{id}</id><desc>$desc</desc>");
			##$template->addText('</parent>');
			push(@pacs_leaves, pacsBrowseLeaves($scheme, $class, $domain, $id));
		}
	}

    my $vars = {
        category      => "PACS",
		idSwitch      => $idSwitch,
		domain		  => $domain,
		domainSwitch  => $domainSwitch,
		my_dbh_ref    => $dbh,
		tdesc		  => $tdesc, 
		parent		  => $parent,
		desc		  => $desc,
		upstr         => $upstr,
		id			  => $id,
		pacs_nodes	  => \@pacs_nodes,
		pacs_leaves   => \@pacs_leaves,	
    };

    my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
    my $ret = $tt->process($file, $vars, \$htmlout) || die "Template process failed: ", $tt->error(), "\n";
	#dwarn "templat html:\n$htmlout\nreturn value:\n$ret";
	#dwarn "pacsBrowse end";
    return $htmlout;
}

# the generic MSC browser; this can be used to either browse the MSC structure
#	itself, or the set of objects within MSC categories in a particular table.
#
sub mscBrowseOld {
	my $params = shift;

	#dwarn "mscBrowse start";
	my $types = $params->{'types'};
	my $id = $params->{'id'};
	my $domain = $params->{'from'} || 'categories';

	my $tdesc = $domain ne 'categories' ? tabledesc($domain) : '';
	my $scheme = 'msc';
	my $class = getConfig('class_tbl');
	my $clinks = getConfig('clinks_tbl');
	my $template = new XSLTemplate('mscbrowse.xsl');
	
	my $rv;
	my $sth;

	$template->addText('<mscset>');
	$template->addText("<tdesc>$tdesc</tdesc>") if ($tdesc);

	# top level
	#
	# change -XX to .
	if(not(defined($id))) {
		if ($domain ne 'categories') {
			my $q = "select $scheme.id, $scheme.comment, count(distinct $class.objectid) as cnt " .
			"from $clinks, $class, $scheme ".
			"where ($scheme.id like '%-XX') and " .
			"$clinks.a = $scheme.uid and $class.catid = $clinks.b and " .
			"$class.nsid = $clinks.nsb and $class.tbl = '$domain' " .
			"group by $scheme.id, $scheme.comment order by $scheme.id";
			($rv, $sth) = dbLowLevelSelect($dbh, $q);
		} else {
			($rv, $sth) = dbLowLevelSelect($dbh, "select $scheme.id, $scheme.comment from $scheme where ($scheme.id like '%-XX') order by $scheme.id");
		}

		my @rows = dbGetRows($sth);

		foreach my $row (@rows) {
			my $child = lookupfield($scheme, 'id', "parent='$row->{id}'");
			$template->addText('<mscnode>');
		
			$template->addText("<haschild />") if ($child);
			$template->addText("<domain>$domain</domain>");
			$template->addText("<id>$row->{id}</id>");
			$template->addText("<count>$row->{cnt}</count>") if ($domain ne 'categories');
			my $comment = latin1ToUTF8(htmlToLatin1($row->{comment}));
			$template->addText("<comment>$comment</comment>");
			$template->addText('</mscnode>');
		}
	}

	# ##-XX level / ##Cxx level
	# Ben changed XX to .
	elsif ($id =~ /XX$/io) {
		if ($domain ne 'categories') {
			($rv, $sth) = dbLowLevelSelect($dbh, 
			
				"select $scheme.id, $scheme.comment, count(distinct $class.objectid) as cnt " .	
			"from $clinks, $class, $scheme where ($scheme.parent = '$id') and " .	
			"$clinks.a = $scheme.uid and $class.catid = $clinks.b and " .	
			"$class.nsid = $clinks.nsb and $class.tbl = '$domain' " . 
			"group by $scheme.id, $scheme.comment order by $scheme.id");
		} else {
			($rv, $sth) = dbLowLevelSelect($dbh, "select $scheme.id, $scheme.comment from $scheme where $scheme.parent = '$id' order by $scheme.id");
		}

		my @rows = dbGetRows($sth);
		my $desc = getHierarchicalMscComment($params->{'id'});

		my $upid = lookupfield($scheme, 'parent', "id='$id'");
		my $upstr = (defined $upid ? "$upid/" : '');

		$template->addText("<parent href=\"".getConfig("main_url")."/browse/$domain/$upstr\">");
		$template->addText("<id>$params->{id}</id><desc>$desc</desc>");
		$template->addText('</parent>');
	
		foreach my $row (@rows) {
			my $count = 0;
			$count = $row->{'cnt'} if ($domain ne 'categories');

			my $child = lookupfield($scheme, 'id', "parent='$row->{id}'");
			
			$template->addText('<mscnode>');
			$template->addText("<domain>$domain</domain>");
			$template->addText("<haschild />") if ($child);
			$template->addText("<id>$row->{id}</id>");
			$template->addText("<count>$count</count>") if ($domain ne 'categories');
			my $comment = latin1ToUTF8(htmlToLatin1($row->{comment}));
			$template->addText("<comment>$comment</comment>");
			$template->addText('</mscnode>');
		}
	}
	
	# leaf level
	#
	else {
		($rv, $sth) = dbLowLevelSelect($dbh, 
		"select $scheme.id, $scheme.comment, $domain.title, $domain.uid, users.username, users.uid as userid " .
		"from $scheme, $class, $domain, users where $scheme.id = '$id' and " .	"$class.tbl = '$domain' and $class.catid = $scheme.uid and " .
		"$domain.uid = $class.objectid and users.uid = $domain.userid order by lower($domain.title)");
		my @rows = dbGetRows($sth);
		my $desc = getHierarchicalMscComment($params->{id});

		my $upid = lookupfield($scheme, 'parent', "id='$id'");

		$template->addText("<parent href=\"".getConfig("main_url")."/browse/$domain/$upid/\">");
		$template->addText("<id>$params->{id}</id><desc>$desc</desc>");
		$template->addText('</parent>');
		foreach my $row (@rows) {
			$template->addText('<mscleaf>');
			$template->addText("<domain>$domain</domain>");
			$template->addText("<id>$row->{uid}</id>");
			
			my $title = mathTitleXSL($row->{'title'}, 'highlight');
			$template->addText("<title>$title</title>");
			
			$template->addText("<owner href=\"".getConfig("main_url")."/?op=getuser;id=$row->{userid}\">$row->{username}</owner>");
			$template->addText('</mscleaf>');
		}
	}

	$template->addText('</mscset>');
	#dwarn "mscBrowse end";
	return paddingTable($template->expand());
}

1;
