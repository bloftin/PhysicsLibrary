package Noosphere;

use strict;
use Noosphere::XML;
use XML::DOM;
use Cwd qw(chdir);
use File::Path qw(make_path); 
use Text::Diff;
use File::Remove 'remove';

sub _supportedVersionTable {
	my $table = shift;

	return 1 if (defined $table && $table eq getConfig('en_tbl'));
	return 1 if (defined $table && $table eq getConfig('collab_tbl'));

	return 0;
}

sub _validVersionRequest {
	my $params = shift;

	return 'Unsupported version history type.' if (!_supportedVersionTable($params->{'from'}));
	return 'Invalid object id.' if (!defined $params->{'id'} || $params->{'id'} !~ /^\d+$/);

	return '';
}

sub _validVersionNumber {
	my $version = shift;

	return (defined $version && $version =~ /^\d+$/);
}

sub _validVersionSelector {
	my $version = shift;

	return (defined $version && ($version eq 'current' || $version =~ /^\d+$/));
}

# roll back an object to a particular version.  must be owner!
#
sub rollBack {
	my $params = shift;
	my $userinf = shift;

	my $error = _validVersionRequest($params);
	return errorMessage($error) if ($error);
	return errorMessage('Invalid version.') if (!_validVersionNumber($params->{'ver'}));

	my ($ownerid, $title) = lookupfields($params->{'from'}, 'userid, title', "uid=$params->{id}");

	return errorMessage("Must be object owner to do that!") if ($userinf->{'uid'} != $ownerid);

	my $version = $params->{'ver'};

	if ($params->{'confirm'}) {

		# go to the dir, delete all snapshots that are more recent than the 
		# target version
		#
		my $dir = getConfig('version_root').'/'."$params->{from}/$params->{id}";
	
		if (-e $dir) {

			##chdir "$dir";
			chdir("$dir");# or dwarn "ERROR chdir: cannot change: $!\n";
	
			my @files = <*>;

			foreach my $file (@files) {

				my $dom = getFileDOM($file);			

				my $ver = domGetVersion($dom, 'version');
			
				if ($ver > $version) {
					#warn "*** rollBack : i'd normally unlink $file";
					unlink $file;
				}

				if ($ver == $version) {

					#warn "*** rollBack : i'd normally apply snapshot in $file to database";

					my $dom = getFileDOM($file);

					applyEncyclopediaSnapshot($dom) if getConfig('en_tbl') eq $params->{'from'};
					applyCollabSnapshot($dom) if getConfig('collab_tbl') eq $params->{'from'};

					# send out notice that the object was modified
					updateEventWatches($params->{'id'}, 
						$params->{'from'}, 
						$userinf->{'uid'}, 
						$params->{'comment'}, 
						"object rolled back to version $version");

					unlink $file;
				}
			}

			# return a message informing of completion
			#
			my $template = new XSLTemplate('rollback_done.xsl');
			$template->addText('<rollback_done>');
			$template->setKey('title', $title);
			$template->setKeys(%$params);
			$template->addText('</rollback_done>');
			return $template->expand();

		} else {
			dwarn "*** rollBack : dir $dir does not exist";
		}
	}

	# get confirmation and revision comment
	#
	else {
		my $template = new XSLTemplate("rollback_confirm.xsl");

		$template->addText('<rollback_confirm>');
		$template->setKeys(%$params);
		$template->setKey('title', $title);
		$template->addText('</rollback_confirm>');

		return $template->expand();
	}
}

# load up an encyclopedia entry from XML 
#
sub applyEncyclopediaSnapshot {
	my $dom = shift;

	my $doc = $dom->getDocumentElement;

	# build metadata hash from snapshot data

	my $en = getConfig('en_tbl');
	my $md = {from => $en};

	# get basic, "flat" metadata
	#
	$md->{'title'} = domGetVal($dom, 'title');
	$md->{'name'} = domGetVal($dom, 'name');
	$md->{'created'} = domGetVal($dom, 'created');
	$md->{'modified'} = domGetVal($dom, 'modified');
	$md->{'type'} = domGetVal($dom, 'type');
	$md->{'selfproof'} = domGetVal($dom, 'selfproof');
	$md->{'preamble'} = domGetVal($dom, 'preamble');
	$md->{'data'} = domGetVal($dom, 'content');

	my @pnodes = $doc->getElementsByTagName('parent');
	if (@pnodes) {
		my $hash = domAttrHash($pnodes[0]);
		$md->{'parentid'} = $hash->{'id'};
	}

	my $rechash = domAttrHash($doc);
	$md->{'version'} = $rechash->{'version'};
	$md->{'id'} = $rechash->{'id'};
	$md->{'uid'} = $rechash->{'id'};

	# get pronunciation metadata
	#
	my @pronouncelist;
	foreach my $spec (domGetChildren($dom, 'pronunciation')) {

		my $hash = domAttrHash($spec);
		$hash->{'definition'} = domTextValue($spec);

		push @pronouncelist, "$hash->{term}=$hash->{system}:/$hash->{definition}/";
	}
	$md->{'pronounce'} = join(', ', @pronouncelist);

	# this will allow us to set the list of authors to a state consistent
	# with the edits at the time of this revision
	#
	my @authors;
	foreach my $author ($doc->getElementsByTagName('author')) {
		my $hash = domAttrHash($author);

		push @authors, $hash->{'id'};	
	}

	# get classification metadata
	#
	my @catlist;
	foreach my $category (domGetChildren($dom, 'classification')) {

		my $hash = domAttrHash($category);

		push @catlist, "$hash->{scheme}:$hash->{code}";
	}
	$md->{'class'} = join(', ', @catlist);

	# get concept metadata
	#
	my @defineslist;
	foreach my $concept (domGetChildren($dom, 'defines')) {
		push @defineslist, domTextValue($concept);
	}
	$md->{'defines'} = join(', ', @defineslist);
	
	# TODO: this needs to be generalized, right now we lose LHS handle 
	# information and just assume title synonym
	my @synonymslist;
	foreach my $syn (domGetChildren($dom, 'synonyms')) {
		my $hash = domAttrHash($syn);
		# assume only aliases of title, for now.
		push @synonymslist, $hash->{'alias'};
	}
	$md->{'synonyms'} = join (', ', @synonymslist);
	
	my @relatedlist;
	foreach my $rel (domGetChildren($dom, 'related')) {
		my $hash = domAttrHash($rel);
		push @relatedlist, $hash->{'name'};
	}
	$md->{'related'} = join (', ', @relatedlist);
	
	my @keywordslist;
	foreach my $keyword (domGetChildren($dom, 'keywords')) {
		push @keywordslist, domTextValue($keyword);
	}
	$md->{'keywords'} = join(', ', @keywordslist);
	
	# apply author list changes
	setAuthorList($en, $md->{'uid'}, \@authors);

	# grab current record before we replace it
	my $sth = $dbh->prepare("select * from $en where uid=$md->{uid}");
	$sth->execute();
	my $rec = $sth->fetchrow_hashref();
	$sth->finish();

	# revert metadata
	insertEncyclopediaSnapshot($md);
	
	# do updates elsewhere in the system for consistency
	handleEncyclopediaChange($md, $rec);
}

# load up an collaboration entry from XML 
#
sub applyCollabSnapshot {
	my $dom = shift;

	my $doc = $dom->getDocumentElement;

	# build metadata hash from snapshot data

	my $table = getConfig('collab_tbl');
	my $md = {from => $table};

	# get basic, "flat" metadata
	#
	$md->{'title'} = domGetVal($dom, 'title');
	$md->{'created'} = domGetVal($dom, 'created');
	$md->{'modified'} = domGetVal($dom, 'modified');
	$md->{'data'} = domGetVal($dom, 'content');

	my $rechash = domAttrHash($doc);
	$md->{'version'} = $rechash->{'version'};
	$md->{'id'} = $rechash->{'id'};
	$md->{'uid'} = $rechash->{'id'};

	# this will allow us to set the list of authors to a state consistent
	# with the edits at the time of this revision
	#
	my @authors;
	foreach my $author ($doc->getElementsByTagName('author')) {
		my $hash = domAttrHash($author);

		push @authors, $hash->{'id'};	
	}

	# apply author list changes
	setAuthorList($table, $md->{'uid'}, \@authors);

	# revert metadata
	insertCollabSnapshot($md);
}

# extract a top-level value from a DOM
#
sub domGetVal {
	my $dom = shift;
	my $name = shift;
 
	my $record = $dom->getDocumentElement;

	my $item = $record->getElementsByTagName($name)->item(0);

	my $val;
	if ($item && $item->getFirstChild) {
		$val = $item->getFirstChild->getNodeValue;
	}

	return $val;
}

# get the text value of a node
#
sub domTextValue {
	my $node = shift;
	
	my $val;
	if ($node && $node->getFirstChild) {
		$val = $node->getFirstChild->getNodeValue;
	}

	return $val;
}

# extract the contents of an element node from a DOM. returns a list.
# (only returns element children)
#
sub domGetChildren {
	my $dom = shift;
	my $name = shift;

	my @list;

	my $doc = $dom->getDocumentElement;

	my $node = $doc->getElementsByTagName($name)->item(0);
	
	if ($node) {
		foreach my $elem ($node->getChildNodes) {

			if ($elem->getNodeType == ELEMENT_NODE) {
				push @list, $elem;
			}
		}
	}

	return @list;
}

# get the special version attribute which is on the document element
#
sub domGetVersion {
	my $dom = shift;
 
	my $attrs = domAttrHash($dom->getDocumentElement);

	return $attrs->{version};
}

# get an attribute hash from a DOM
#
sub domGetAttrs {
	my $dom = shift;
	my $name = shift;
	
	my $record = $dom->getDocumentElement;

	my $node = $record->getElementsByTagName($name)->item(0);

	return domAttrHash($node);
}

# save a snapshot of an object
#
sub snapshot {
	my $table = shift;
	my $id = shift;
	my $filename = shift;	# file name to use
	my $modifier = shift;	# who's generating the snapshot?
	my $comment = shift;	 # revision comment

	my $xml = getObjectXML($table, $id, $modifier, $comment);

	my $dir = getConfig('version_root').'/'."$table/$id";

	make_path("$dir", {verbose => 1, mode => 0771}) if (not -e "$dir");

	open OUTFILE, ">$dir/$filename.xml";	
	print OUTFILE $xml;
	close OUTFILE;
}

# get a list of versions and revision times
#
sub getVersionList {
	my $table = shift;
	my $id = shift;

	my %versions;
	
	my $dir = getConfig('version_root').'/'."$table/$id";

	my ($fmodified, $fversion) = lookupfields($table, 'modified,version', "uid = $id");

	my %mlist = ($fversion => $fmodified);
	
	if (-e $dir) {

		##chdir "$dir";
		chdir("$dir");# or dwarn "ERROR chdir: cannot change: $!\n";
	
		my @files = <*>;

		foreach my $file (@files) {
			warn "*** vlist : processing file $file";
			#dwarn "getFileDOM before";
			my $dom = getFileDOM($file);			
			#dwarn "domGetVersion before";
			my $version = domGetVersion($dom, 'version');
			#dwarn "version: $version";
			my $modifier = domGetAttrs($dom, 'modifier');
			#dwarn "modifier: $modifier";
			my $modified = domGetVal($dom, 'modified');
			#dwarn "modified: $modified";
			my $comment = domGetVal($dom, 'comment');
			#dwarn "comment: $comment";
			$versions{$version} = {version=>$version, 
				 modifier=>$modifier->{'id'},
				 comment=>$comment}; 

			$mlist{$version} = $modified;  # grab modified date
		}

		# set staggered modified dates.  really we have to do this because
		# we are storing modified dates shifted back by one.  this should be 
		# remedied sometime (TODO)
		#
		foreach my $version (keys %mlist) {
			if (exists $versions{$version}) {
				#dwarn "mlist version";
				$versions{$version}->{'modified'} = $mlist{$version + 1};
			} 
		}
	} else {
		dwarn "*** vlist : dir $dir does not exist";
	}
	
	return {%versions};
}

# return the version browser
#
sub getVersionBrowser {
	my $params = shift;
	my $userinf = shift;

	my $error = _validVersionRequest($params);
	return errorMessage($error) if ($error);

	my $file = 'versionbrowser.tt';
	my $html = '';
	my $html_pager = '';
	my $scale = 1;
	my @item_array = ();

	return errorMessage("You don't have permissions to do that.") if (!hasPermissionTo($params->{from}, $params->{id}, $userinf, 'read') &&
	($userinf->{data}->{access}<getConfig('access_admin')));	

	# set owner flag
	my $owner = 0;
	$owner = 1 if (lookupfield($params->{'from'},'userid', "uid=$params->{id}") == $userinf->{'uid'});

	#dwarn "Owner: $owner";

	my $versions = getVersionList($params->{from}, $params->{id});
	
	my $template = new XSLTemplate('versionbrowser.xsl');
	my $total = scalar keys %$versions;
	my $offset = $params->{offset} || 0;
	my $limit = $userinf->{prefs}->{pagelength};
	
	# create the XML
	#
	my @keyset = sort {$b <=> $a} keys %$versions;
	my $left = $#keyset - $offset + 1;
	my $count = ($left>$limit) ? $limit : $left;

	my $title = qhtmlescape(lookupfield($params->{from},'title',"uid=$params->{id}"));

	$template->addText("<versionbrowser title=\"$title\" href=\"".getConfig("main_url")."/?op=getobj&amp;from=$params->{from}&amp;id=$params->{id}\" owner=\"$owner\">\n");
	my $title_link = getConfig("main_url")."/?op=getobj&amp;from=$params->{from}&amp;id=$params->{id} owner=$owner";
	my $ord = 0;
	foreach my $key (@keyset[$offset..$count-1]) {
		my $nextkey = $key + 1;
		$nextkey = 'current' if ($nextkey > $keyset[0]);
		$nextkey = 'missing' if (not exists $keyset[$nextkey]);
		my $version = $versions->{$key};
		my $modid = $version->{'modifier'};
		my $comment = htmlescape($version->{'comment'});
		my $modname = qhtmlescape(lookupfield(getConfig('user_tbl'),'username',"uid=$modid"));
		my $timestamp = $version->{'modified'};
		$timestamp =~ s/\..*$//go;
	
		$template->addText(" <item>\n");
		$template->addText("	<series ord=\"$ord\"/>\n");
		$template->addText("	<version name=\"$key\" href=\"".getConfig("main_url")."/?op=viewver&amp;from=$params->{from}&amp;id=$params->{id}&amp;ver=$key\"/>\n");
		$template->addText("	<rollback href=\"".getConfig("main_url")."/?op=rollback&amp;from=$params->{from}&amp;id=$params->{id}&amp;ver=$key\"/>\n");
		#BB: added difference viewer
		$template->addText("    <viewdiff href=\"".getConfig("main_url")."/?op=viewdiff&amp;from=$params->{from}&amp;old=$key&amp;new=$nextkey&amp;id=$params->{id}\"/>\n");
		$template->addText("	<modifier name=\"$modname\" href=\"".getConfig("main_url")."/?op=getuser&amp;id=$modid\"/>\n");
		$template->addText("	<timestamp>$timestamp</timestamp>\n");
		$template->addText("	<comment>".htmlescape($comment)."</comment>\n");
		$template->addText(" </item>\n");

		my $version_name = $key;
		my $version_link = getConfig("main_url")."/?op=viewver&amp;from=$params->{from}&amp;id=$params->{id}&amp;ver=$key";
		my $viewdiff = getConfig("main_url")."/?op=viewdiff&amp;from=$params->{from}&amp;old=$key&amp;new=$nextkey&amp;id=$params->{id}";
		my $rollback = getConfig("main_url")."/?op=rollback&amp;from=$params->{from}&amp;id=$params->{id}&amp;ver=$key";
		my $modifier_name = $modname;
		my $modifier_link = getConfig("main_url")."/?op=getuser&amp;id=$modid";

		push(@item_array,{ 
				modname 		=> $modname, 
				comment 		=> $comment, 
				version_name	=> $version_name,
				version_link	=> $version_link, 
				ord 			=> $ord, 
				viewdiff 		=> $viewdiff, 
				rollback 		=> $rollback,
				modifier_name 	=> $modifier_name,
				modifier_link 	=> $modifier_link,
				timestamp  		=> $timestamp,
				modid    		=> $modid,
				version			=> $version,	
		});

		$ord++;
	}
	$template->addText("</versionbrowser>\n");
	
	$params->{offset} = $offset;
	$params->{total} = $total;
	
	#getPageWidgetXSLT($template, $params, $userinf);
	$html_pager = getPager($params, $userinf, $scale);

	#dwarn "items: ",scalar @item_array,"\n";

	my $vars = {
        title        	=> $title,
		title_link      => $title_link,
		items			=> \@item_array,
		pager			=> $html_pager,
		owner			=> $owner,
    };

    my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
    my $ret = $tt->process($file, $vars, \$html) || die "Template process failed: ", $tt->error(), "\n";

	return $html; #$template->expand();
}

# display metadata for a version snapshot of an object
#
sub getVersion {
	my $params = shift;
	my $userinf = shift;

	my $error = _validVersionRequest($params);
	return errorMessage($error) if ($error);
	return errorMessage('Invalid version.') if (!_validVersionNumber($params->{'ver'}));

	my $template;

	$template = new XSLTemplate("en_version.xsl") if $params->{'from'} eq getConfig('en_tbl');
	$template = new XSLTemplate("collab_version.xsl") if $params->{'from'} eq getConfig('collab_tbl');
	
	# read in the XML for this version
	#
	my $name = "";
	$name = lookupfield($params->{'from'},'name',"uid=$params->{id}") if $params->{'from'} eq getConfig('en_tbl');
	$name = "Collab$params->{id}" if $params->{'from'} eq getConfig('collab_tbl');

	my $file = getConfig('version_root').'/'."$params->{from}/$params->{id}/$name"."_$params->{ver}.xml";

	return errorMessage('Version not found.') if (! -e $file);

	return $template->expandFile($file);
}

# BB: read several version; each is specified by either version number or word ``current'' 
sub readVersions {
	my $params = shift;
	my @vers = ();
	
	# go to the dir, read each version until the desired versions are found 

	my $dir = getConfig('version_root').'/'."$params->{from}/$params->{id}";

	for (my $i = 0; $i < @_; $i++) {
		if ($_[$i] eq 'current') {
			# query up the object
			#
			(my $rv, my $sth) = dbSelect($dbh,{WHAT =>'*', 
							   FROM => $params->{from},
							   WHERE => "uid=$params->{id}"});
			if (! $rv || $sth->rows()<1) {
				#dwarn "**** readVersions : object `$params->{id}' not found!";
				$vers[$i] = 'Object not found.';
			} else {
				my $rec = $sth->fetchrow_hashref();
				$vers[$i] = $rec->{'data'};
			}
		}
	}
		


	if (-e $dir) {

		##chdir "$dir";
		chdir("$dir");# or dwarn "ERROR chdir: cannot change: $!\n";
	
		my @files = <*>;

		foreach my $file (@files) {

			my $dom = getFileDOM($file);

			my $ver = domGetVersion($dom, 'version');

			for (my $i = 0; $i < @_; $i++) {
				if ($ver eq $_[$i]) {
					my $doc = $dom->getDocumentElement;
					$vers[$i] = domGetVal($dom, 'content');
				}
			}
		}
	} else {
		dwarn "*** readVersions : dir $dir does not exist ***";
	}
	
	return @vers;
}

# BB: show difference between versions
sub getVersionDiff {
	my $params = shift;
	my $userinf = shift;

	my $error = _validVersionRequest($params);
	return errorMessage($error) if ($error);
	return errorMessage('Invalid old version.') if (!_validVersionSelector($params->{'old'}));
	return errorMessage('Invalid new version.') if (!_validVersionSelector($params->{'new'}));

	my $file = 'ver_diff.tt';
	my $html = '';
	my @line_array = ();
	my $newtext = '';
	my $oldtext = '';
	my $template = new XSLTemplate("ver_diff.xsl");

	my @vers=readVersions($params,$params->{old},$params->{new});

	return errorMessage('Version not found.') if (!defined $vers[0] || !defined $vers[1]);

	my $oldfile = getTempFileName();
	my $newfile = getTempFileName();
	# Parsing is easier when files differ, so add `x' to the old and `y' to the new
	# We also do not want to bother with messages ``no newline at end of file''
	# because these are not very usefull, and they make counting lines more difficult
	# so we add \n at the end if there is none
	unless (substr($vers[0],-1) eq "\n") {$vers[0].="\n"}
	unless (substr($vers[1],-1) eq "\n") {$vers[1].="\n"}
	writeFile($oldfile,"xxxxxxxx\nzzzzzzzzzzzzzz\n".$vers[0]);
	writeFile($newfile,"yyyyyyyy\nzzzzzzzzzzzzzz\n".$vers[1]);
	#my $ftext = readFile(getConfig('diffcmd')." -b -c -C2000 $newfile $oldfile 2>/dev/null |");
	#my $ftext =  diff("xxxxxxxx\nzzzzzzzzzzzzzz\n".$vers[0], "yyyyyyyy\nzzzzzzzzzzzzzz\n".$vers[1]);
	my $ftext =  diff($oldfile, $newfile,  { STYLE => "OldStyle" } );
	#dwarn("Before getVersionDif unlink");
	#system("unlink $oldfile, $newfile");
	#dwarn("After getVersionDif unlink");
	remove($oldfile);
	remove($newfile);
	#dwarn "diff:\n $ftext";
	my @diff = split(/\n/,$ftext);
	##dwarn "after split";
	my $difflen = (scalar @diff)-5; # number of lines in diff except `x' and `y' 
	#dwarn "after difflen: $difflen";
	my $title = qhtmlescape(lookupfield($params->{from},'title',"uid=$params->{id}"));
	#dwarn "after title";
	##$template->addText("<ver_diff title=\"$title\" changed=\"$difflen\" oldvernum=\"$params->{old}\" newvernum=\"$params->{new}\"> href=\"".getConfig("main_url")."/?op=viewdiff&amp;old=$params->{old};new=$params->{new}\"");
	#dwarn "after template";
	my $newvernum = $params->{new};
	my $oldvernum = $params->{old};
	my $diff_link = getConfig("main_url")."/?op=viewdiff&amp;old=$params->{old};new=$params->{new}";

	# if ($difflen) {
	# 	dwarn "difflen true";
	# 	$diff[1] =~ /^\*+\s1,(\d+)/;
	# 	my $newend = 1+$1;
	# 	my $temp_diff = $diff[1];
	# 	dwarn "diff[3]: $temp_diff ";
		
	# 	dwarn "newend: $newend";
	# 	$diff[$newend] =~ /^-+\s1,(\d+)/;
		
	# 	my $oldend = $newend+1+$1;
	# 	$temp_diff = $diff[$newend];
	# 	dwarn "diff[newend]: $temp_diff ";
	# 	my $newpos = 2;
	# 	my $oldpos = $newend + 1;
	# 	$newpos+=2;$oldpos+=2; # skip xxxx's and yyyy's
	# 	dwarn "skip xxxx's and yyyy's";
	# 	dwarn "newpos: $newpos";
	# 	dwarn "newend: $newend";
	# 	dwarn "oldpos: $oldpos";
	# 	dwarn "oldend: $oldend";
	# 	while ($newpos<$newend) {
	# 		my $newstr = $diff[$newpos];
	# 		dwarn "newstring:\n $newstr";
	# 		my $oldstr = $diff[$oldpos];
			
	# 		dwarn "oldstring:\n $oldstr";
	# 		# indicator characters
	# 		my $nchar = substr($newstr,0,1);
	# 		my $ochar = substr($oldstr,0,1);
	# 		# strings without indicator characters
	# 		my $pnewstr = substr($newstr,2);
	# 		my $poldstr = substr($oldstr,2);
	# 		if ($newstr eq $oldstr) {
	# 			dwarn "newstr eq oldstr";
	# 			$template->addText(" <line>"); #newtext=\"$newstr\" oldtext=\"$newstr\">\n");
	# 			$template->addText("    <newtext><span class=\"nodiff\">".htmlescape($pnewstr)."</span></newtext>\n");
	# 			$template->addText("    <oldtext><span class=\"nodiff\">".htmlescape($pnewstr)."</span></oldtext>\n");
	# 			$template->addText(" </line>\n");
	# 			$newtext = "<span class=\"nodiff\">".htmlescape($pnewstr)."</span>";
	# 			$oldtext = "<span class=\"nodiff\">".htmlescape($pnewstr)."</span>";
	# 			push(@line_array,{ 
	# 				newtext 		=> $newtext, 
	# 				oldtext 		=> $oldtext, 	
	# 			});

	# 			$oldpos++; $newpos++;
	# 		} elsif ($nchar eq '-') {
	# 			dwarn "nchar eq -";
	# 			$template->addText(" <line>\n");
	# 			$template->addText("    <newtext><ins class=\"diffadd\">".htmlescape($pnewstr)."</ins></newtext>\n");
	# 			$template->addText(" </line>\n");
	# 			$newtext = "<ins class=\"diffadd\">".htmlescape($pnewstr)."</ins>";
	# 			$oldtext = '';
	# 			push(@line_array,{ 
	# 				newtext 		=> $newtext, 
	# 				oldtext 		=> $oldtext, 	
	# 			});
	# 			$newpos++;
	# 		} elsif ($ochar eq '+') {
	# 			dwarn "ochar eq +";
	# 			$template->addText(" <line>\n");
	# 			$template->addText("    <oldtext><del class=\"diffdel\">".htmlescape($poldstr)."</del></oldtext>\n");
	# 			$template->addText(" </line>\n");

	# 			$newtext = '';
	# 			$oldtext = "<del class=\"diffdel\">".htmlescape($poldstr)."</del>";
	# 			push(@line_array,{ 
	# 				newtext 		=> $newtext, 
	# 				oldtext 		=> $oldtext, 	
	# 			});

	# 			$oldpos++;
	# 		} elsif ($ochar eq '!') {
	# 			dwarn "ochar eq !";
	# 			my $nend=$newpos;
	# 			my $oend=$oldpos;
	# 			while (substr($diff[$nend++],0,1) eq '!') {}
	# 			while (substr($diff[$oend++],0,1) eq '!') {}
	# 			# if number of lines in two chunks differ, output them as is
	# 			# otherwise, try to detect differences
	# 			unless (($oend-$oldpos)==($nend-$newpos)) {
	# 				dwarn "number of lines in two chunks differ,";
	# 				while ((substr($diff[$oldpos],0,1) eq '!') && (substr($diff[$newpos],0,1) eq '!')) {

	# 					$newtext = "<ins class=\"diffadd\">".htmlescape(substr($diff[$newpos],2))."</ins>";
	# 					$oldtext = "<del class=\"diffdel\">".htmlescape(substr($diff[$oldpos],2))."</del>";

	# 					$template->addText(" <line>\n");
	# 					$template->addText("    <oldtext><del class=\"diffdel\">".htmlescape(substr($diff[$oldpos++],2))."</del></oldtext>\n");
	# 					$template->addText("    <newtext><ins class=\"diffadd\">".htmlescape(substr($diff[$newpos++],2))."</ins></newtext>\n");
	# 					$template->addText(" </line>\n");

						
						
	# 					push(@line_array,{ 
	# 						newtext 		=> $newtext, 
	# 						oldtext 		=> $oldtext, 	
	# 					});

	# 				}
	# 				while (substr($diff[$oldpos],0,1) eq '!') {

	# 					$newtext = '';
	# 					$oldtext = "<del class=\"diffdel\">".htmlescape(substr($diff[$oldpos],2))."</del>";

	# 					$template->addText(" <line>\n");
	# 					$template->addText("    <oldtext><del class=\"diffdel\">".htmlescape(substr($diff[$oldpos++],2))."</del></oldtext>\n");
	# 					$template->addText(" </line>\n");

						
	# 					push(@line_array,{ 
	# 						newtext 		=> $newtext, 
	# 						oldtext 		=> $oldtext, 	
	# 					});

	# 				}
	# 				while (substr($diff[$newpos],0,1) eq '!') {

	# 					$newtext = "<ins class=\"diffadd\">".htmlescape(substr($diff[$newpos],2))."</ins>";
	# 					$oldtext = '';

	# 					$template->addText(" <line>\n");
	# 					$template->addText("    <newtext><ins class=\"diffadd\">".htmlescape(substr($diff[$newpos++],2))."</ins></newtext>\n");
	# 					$template->addText(" </line>\n");

						
	# 					push(@line_array,{ 
	# 						newtext 		=> $newtext, 
	# 						oldtext 		=> $oldtext, 	
	# 					});

	# 				}
	# 			} else {
	# 				dwarn "we can process just one line because the cycle condition is maintained";
	# 				# we can process just one line because the cycle condition is maintained
	# 				$oldpos++; $newpos++;
	# 				# find the position where old and new start/end differing with each other 
	# 				my $spos = 0;
	# 				my $epos = -1;
	# 				# To simplify the border cases
	# 				$pnewstr .= 'Z';
	# 				$poldstr .= 'Z';
	# 				while (substr($pnewstr,$spos,1) eq substr($poldstr,$spos,1)) {$spos++;}
	# 				while (substr($pnewstr,$epos,1) eq substr($poldstr,$epos,1)) {$epos--;}
	# 				$template->addText(" <line>\n");
	# 				$template->addText("    <oldtext>".produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($poldstr,0,$spos))).produceHtmlParam("<del class=\"diffdel\">",htmlescape(substr($poldstr,$spos,$epos+1))).produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($poldstr,$epos+1,-1)))."</oldtext>\n");
	# 				$template->addText("    <newtext>".produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($pnewstr,0,$spos))).produceHtmlParam("<ins class=\"diffadd\">",htmlescape(substr($pnewstr,$spos,$epos+1))).produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($pnewstr,$epos+1,-1)))."</newtext>\n");
	# 				$template->addText(" </line>\n");

	# 				$newtext = produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($pnewstr,0,$spos))).produceHtmlParam("<ins class=\"diffadd\">",htmlescape(substr($pnewstr,$spos,$epos+1))).produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($pnewstr,$epos+1,-1)));
	# 				$oldtext = produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($poldstr,0,$spos))).produceHtmlParam("<del class=\"diffdel\">",htmlescape(substr($poldstr,$spos,$epos+1))).produceHtmlParam("<span class=\"nodiff\">",htmlescape(substr($poldstr,$epos+1,-1)));

	# 				push(@line_array,{ 
	# 						newtext 		=> $newtext, 
	# 						oldtext 		=> $oldtext, 	
	# 				});

	# 			}
	# 		} else {
	# 			dwarn "****** showVersionDiff : unknown diff command";
	# 			$newpos++; $oldpos++;
	# 		}
	# 	}
	# 	while ($oldpos<$oldend) {
	# 		dwarn "oldpos < oldend";
	# 		my $oldstr = $diff[$oldpos];
	# 		my $ochar = substr($oldstr,0,1);
	# 		my $poldstr = substr($oldstr,2);
	# 		if ($ochar eq '+') {
	# 			dwarn "ochar eq +";
	# 			$template->addText(" <line>\n");
	# 			$template->addText("    <oldtext><del class=\"diffdel\">".htmlescape($poldstr)."</del></oldtext>\n");
	# 			$template->addText(" </line>\n");

	# 			$newtext = '';
	# 			$oldtext = "<del class=\"diffdel\">".htmlescape($poldstr)."</del>";


	# 			push(@line_array,{ 
	# 						newtext 		=> $newtext, 
	# 						oldtext 		=> $oldtext, 	
	# 			});

	# 			$oldpos++;
	# 		} else {
	# 			dwarn "****** showVersionDiff : unknown diff command";
	# 			$oldpos++;
	# 		}
	# 	}
	# } 

##$template->addText("</ver_diff>");

	my $vars = {
        title        	=> $title,
		difflen			=> $difflen,
		newvernum		=> $newvernum,
		oldvernum		=> $oldvernum,
		lines			=> \@line_array,
		diff_text       => $ftext,

    };

    my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
    my $ret = $tt->process($file, $vars, \$html) || die "Template process failed: ", $tt->error(), "\n";

	#return $template->expand();
	return $html;
}


1;

