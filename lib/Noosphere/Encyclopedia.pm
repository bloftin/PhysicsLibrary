package Noosphere;
use strict;

use Noosphere::Util;
use Noosphere::UserData;
use Noosphere::Indexing;
use Noosphere::Pronounce;
use Noosphere::Watches;
use Noosphere::Classification;
use Noosphere::ACL;
use Noosphere::IR;
use Noosphere::Crossref;
use Noosphere::Authors;

# display an encyclopedia object
# 
sub renderEncyclopediaObj {
	my $rec = shift;
	my $params = shift;
	my $userinf = shift;
 
	my $method = $params->{'method'} || $userinf->{'prefs'}->{'method'};
	my $html = new Template('encyclopediaobject.html');
	my $en = getConfig('en_tbl');
	my $content = getRenderedContentHtml($en,$rec,$method);
	my $contentbox = '';
	my $title = $rec->{'title'};
	
	if ( nb($content) ) {

		# draw world-writeable comment
		#
		if (isWorldWriteable($en, $rec->{'uid'})) {
			
			$content .= "<br /><i>Anyone <a href=\"".getConfig("main_url")."/?op=newuser\">with an account</a> can edit this entry.  Please help improve it!</i><br />";
		}

		# draw owner comment. handles no owner.
		#
		if ($rec->{'userid'} > 0) {
			$content .= "<br /><font size=\"-1\">\"".mathTitle($title)."\" is owned by <a href=\"".getConfig("main_url")."/?op=getuser&amp;id=".$rec->{'userid'}."\">".$rec->{'username'}."</a>.</font>";
		} else {
			my ($lastid, $lastname) = getLastData($en, $rec->{'uid'});
			
			$content .= "<br /><font size=\"-1\">\"".mathTitle($title)."\" has no owner. (Was owned by <a href=\"".getConfig("main_url")."/?op=getuser&amp;id=$lastid\">$lastname</a>.  <a href=\"".getConfig("main_url")."/?op=adopt&amp;from=$params->{from}&amp;id=$rec->{uid}&amp;ask=yes\">Adopt</a>)</font>";
		}
	
		# draw author/owner list links
		#
		my $acount = getAuthorCount($en, $rec->{'uid'});
		my $ocount = getPastOwnerCount($en, $rec->{'uid'});
		if ($acount > 1 || $ocount > 0) {
			$content .= " <font size=\"-1\">[ ";

			my @links;
			push @links, "<a href=\"".getConfig("main_url")."/?op=authorlist&amp;from=$en&amp;id=$rec->{uid}\">full author list</a> ($acount)" if $acount > 1;
			push @links, "<a href=\"".getConfig("main_url")."/?op=ownerhistory&amp;from=$en&amp;id=$rec->{uid}\">owner history</a> ($ocount)" if $ocount > 0; 

			$content .= join(' | ', @links);

			$content .= " ]</font>";
		}

		# draw title bar, with "up" arrow for attachments, and type string.
		#
		my $up = '';
		if (defined $rec->{'parentid'} && $rec->{'parentid'} >= 0) {
			$up = getUpArrow("".getConfig("main_url")."/?op=getobj&amp;from=$en&amp;id=$rec->{parentid}",'parent');
		}

		my $btitle = "
			<table width=\"100%\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">
				<tr>
					<td align=\"left\">$up 
						<font color=\"#ffffff\">".mathTitle($title, 'title')."</font>
					</td>
				
					<td align=\"right\"> 
						<font color=\"#ffffff\" size=\"-2\">(".getTypeString($rec->{type}).")
						</font>
					</td>
				</tr>
			</table>";

		# ugly hack to handle failed rendering, since we don't really return
		# an error code from rendering, just an error log.
		#
		my $failed = ($content =~ /rendering\s+failed/i);
		my $isowner = ($userinf->{'uid'} == $rec->{'userid'});
		if ($failed && !$isowner) {
			my $ftemplate = new XSLTemplate('render_fail.xsl');	
			$ftemplate->addText('<render_fail>');
			$ftemplate->setKey('id',$rec->{'uid'});
			$ftemplate->addText('</render_fail>');
			$content = $ftemplate->expand();
		}

		$contentbox = mathBox($btitle, $content);

	} else	{
		my $contact = getAddr('feedback');
		$contentbox = errorMessage("Missing cached output! Please <a href=\"mailto:$contact\">contact</a> an admin."); 
		dwarn "getRenderContentHtml Failed!!!!"
	}
	my $metadata = getEncyclopediaMetadata($rec,$method);

	# get method select box
	#
	my $viewstyle = getViewStyleWidget($params,$method);
	$html->setKey('viewstyle', $viewstyle);
	
	my $interact = makeBox('Interact',getEncyclopediaInteract($rec));
	
	$html->setKey('id',$rec->{'uid'});
	$html->setKeys('mathobj' => $contentbox, 'metadata' => $metadata, 'interact' => $interact);
	
	return $html;
}

# get a random entry
#
sub getRandomEntry {
	my $params = shift;
	my $userinf = shift;
	
	my $tbl = getConfig('en_tbl');

	# select a random in-bounds index
	#
	my $index;
	#$index = dbEval("round(random()*(select count(*) from $tbl))")
	#	if getConfig('dbms') eq 'pg';
	#$index = dbEval("round(rand()*count(*)) from $tbl")
	#	if getConfig('dbms') eq 'mysql';
        my $count;
	$count = dbEval("count(*) from $tbl")
		if getConfig('dbms') eq 'pg';
	$count = dbEval("count(*) from $tbl")
		if getConfig('dbms') eq 'mysql';
	$count = dbEval("count(*) from $tbl")
        if getConfig('dbms') eq 'MariaDB';

        $index = int(rand($count));
       
	# get a uid randomly from the database
	#
	my $uid;
	$uid = dbEval("uid from $tbl limit 1 offset $index")
		if getConfig('dbms') eq 'pg';
	$uid = dbEval("uid from $tbl limit $index,1")
		if getConfig('dbms') eq 'mysql';
	$uid = dbEval("uid from $tbl limit $index,1")
        if getConfig('dbms') eq 'MariaDB';

	# "stuff" the proper getobj params
	#
	$params->{'op'} = 'getobj';
	$params->{'from'} = $tbl;
	$params->{'id'} = $uid;

	return getObj($params, $userinf);
}

# show the "rest" of the encyclopedia metadata (below the main rendered 
# content)
#
sub getEncyclopediaMetadata {
	my $rec = shift;
	my $method = shift;

	my $name = $rec->{'name'};
	my $html = '';
	my $table = getConfig('en_tbl');
	
	# related
	#
	if (nb($rec->{'related'})) {
		my @rels = ();
		foreach my $related (split(/\s*,\s*/,$rec->{'related'})) {
		next if (blank($related));
		my $title = objectTitleByName($related);
		if (blank($title)) {
			dwarn "*** encyclopedia metadata: couldn't resolve title for $related";
			next;
		}
		push @rels,"<a href=\"".getConfig("main_url")."/?op=getobj&amp;from=$table&amp;name=$related\">".mathTitle($title, 'highlight')."</a>";
		}
		if (scalar @rels) {
			$html .= "See Also: ";
			$html .= join(', ',@rels)."<br /><br />\n";
		}
	}

	# synonyms
	#
	if (nb($rec->{'synonyms'})) { 
		$html.="<table cellpadding=\"0\" cellspacing=\"0\">
					<tr>
						<td valign=\"top\">Other&nbsp;names:&nbsp;</td>
						<td>".displayTitleList($rec->{'synonyms'})."</td>
					</tr>
			</table>";
	}
	# defines
	#
	if (nb($rec->{'defines'})) { 
		$html.="<table cellpadding=\"0\" cellspacing=\"0\">
					<tr>
						<td valign=\"top\">Also&nbsp;defines:&nbsp;</td>
						<td>".displayTitleList($rec->{'defines'})."</td>
					</tr>
			</table>\n";
	}

	# keywords
	#
	if (nb($rec->{'keywords'})) { 
		$html.="<table cellpadding=\"0\" cellspacing=\"0\">
					<tr>
						<td valign=\"top\">Keywords:&nbsp;</td>
						<td>".displayTitleList($rec->{'keywords'})."</td>
					</tr>
			</table>\n";
	}
	
	# pronunciation
	#
	if (nb($rec->{'pronounce'})) {
		my $text = generatePronunciations($rec->{'title'}, $rec->{'pronounce'});
		my $staticsite = getConfig('siteaddrs')->{'static'};

		$html .= "<br />Pronunciation <font size=\"-1\">(<a href=\"http://$staticsite/doc/jargon.html\">guide</a>)</font>: $text";
	}

	my ($rv,$sth);

	# handle parent (this object is /attached/)
	#
	if (defined $rec->{'parentid'} && $rec->{'parentid'} != -1) {
		$html .= "<br />";
		$html .= "This object's <a href=\"".getConfig("main_url")."/?op=getobj&amp;from=$table&amp;id=$rec->{parentid}\">parent</a>.<br />";
	} 
	
	# handle attachments 
	#
	($rv,$sth) = dbSelect($dbh,{WHAT=>"$table.uid,$table.type,$table.name,$table.title,users.username",
		FROM=>"$table, users",
		WHERE=>"$table.userid=users.uid and parentid=$rec->{uid}",
		'ORDER BY'=>"created"});
	my @rows = dbGetRows($sth);
	if ($#rows >= 0) {
		$html.="<br />";
		$html .= "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">
					<tr>
					<td><dl><dt>Attachments:</dt>\n";
		$html .= "<dd>\n";
		foreach my $row (@rows) {
			$html .= getBullet()." ";
			my $tstring = getTypeString($row->{type});
			$html .= "<a href=\"".getConfig("main_url")."/?op=getobj&amp;from=$table&amp;id=$row->{uid}\">".mathTitle($row->{'title'},'highlight')."</a> <font size=\"-1\">($tstring)</font> by $row->{username}<br />\n";
		}
		$html .= "</dd></dl></td></tr></table>\n";
	}

	$html .= "<font size=\"-1\"><br />\n";

	# reference links
	#
	my $links = getRenderedObjectLinks($table,$rec->{'uid'},$method);
	$links =~ s/&amp,/&amp;/g;	# bugfix
	if (nb($links)) {
		$html.="Cross-references: $links<br />\n";
	}
	my $linksto = xrefGetLinksToCount($table,$rec->{'uid'});
	if ($linksto > 0) {
		$html .= "There ".( ('is','are')[$linksto<=>1] )." <a href=\"".getConfig("main_url")."/?op=getrefs&amp;from=$table&amp;name=$rec->{name}\">$linksto reference".( ('','s')[$linksto<=>1] )."</a> to this object.<br />\n";
	}
	if (nb($links) || $linksto > 0) { $html .= "<br />\n" }
	
	# print provenance if object has foreign origin
	#
	my $prov = getSourceCollection($table, $rec->{'uid'});	
	if ($prov ne getConfig('proj_nickname')) {
		my $provURL = getProvenanceURL($prov);
		$html .= "Provenance: $provURL.<br />";
	}
	
	# versions
	#
	my $mod = ymd($rec->{modified});
	my $cre = ymd($rec->{created});
	my $modprn = ($rec->{modified} eq $rec->{created}) ? '' : ", modified $mod";
	
	my $main = getConfig('main_url');

	$html .= "This is <a href=\"$main/?op=vbrowser&amp;from=$table&amp;id=$rec->{uid}\">version $rec->{version}</a> of ";
	
	$html .= "<a href=\"$main/encyclopedia/$rec->{name}.html\">".mathTitle($rec->{'title'}, 'highlight')."</a>";
	
	$html .=", born on $cre$modprn.<br />\n";

	$html .= "Object id is $rec->{uid}, canonical name is $rec->{name}.<br />\n";
	
	$html .= "Accessed $rec->{hits} times total.<br />\n";
 
	$html .= "</font>";

	# classification
	#
	my $class = printclass($table,$rec->{uid},'-1');
	if (nb($class)) {
		$html .= "<br />Classification:<br />\n";
		$html .= "$class";
	}

	return $html;
}


# get a list of latest encyclopedia revisions or additions ordered by date
#
sub encyclopediaChrono {
	my $params = shift;
	my $userinf = shift;

	my $otbl = getConfig('en_tbl');
	my $utbl = getConfig('user_tbl');

	my $xml = '';
	my $template = new XSLTemplate('encyclopediachrono.xsl');
	$params->{'offset'} = $params->{'offset'} || 0;
	my $limit = $userinf->{'prefs'}->{'pagelength'};
	my $mode = $params->{'mode'}; # created or modified
	
	# get total if needed
	#
	if (not defined $params->{'total'}) {
		$params->{'total'} = dbRowCount($otbl);
	}

	# query up the objects in order
	#
	my ($rv, $sth) = dbSelect($dbh, {
		WHAT => "$otbl.*, username", 
		FROM => "$otbl, $utbl", 
		WHERE => "$otbl.userid=$utbl.uid", 
		'ORDER BY' => "$otbl.$mode", 
		DESC => 1,
		LIMIT => $limit,
		OFFSET => $params->{'offset'}
	});

	$template->addText("<entries mode=\"$mode\">");

	while (my $row = $sth->fetchrow_hashref()) {

		my $cdate = mdhm($row->{'created'});
		my $mdate = mdhm($row->{'modified'});
		my $title = mathTitleXSL($row->{'title'}, 'highlight');
		my $username = htmlescape($row->{'username'});
		my $href = getConfig('main_url')."/?op=getobj&amp;from=objects&amp;id=$row->{uid}";
		my $uhref = getConfig('main_url')."/?op=getuser&amp;id=$row->{userid}";

		$xml .= "		<entry>";
		$xml .= "			<mdate>$mdate</mdate>";
		$xml .= "			<cdate>$cdate</cdate>";
		$xml .= "			<title>$title</title>";
		$xml .= "			<username>$username</username>";
		$xml .= "			<href>$href</href>";
		$xml .= "			<uhref>$uhref</uhref>";
		$xml .= "		</entry>";
	}
	
	$template->addText($xml);
	$template->addText('</entries>');

	getPageWidgetXSLT($template, $params, $userinf);

	return $template->expand();
}

# format a raw list of titles (synonyms, defines) in string form, suitable for
# display
#
sub displayTitleList {
	my $list = shift;	# comma-separated list

	my ($text, $math) = escapeMathSimple($list);

	return join(', ',(map { mathTitle(unescapeMathSimple($_, $math)) } split(/\s*,\s*/, $text)));
}

# display the preamble of an entry
#
sub getPreamble {
	my $params = shift;

	my $template = new XSLTemplate('preamble.xsl');
 
	my $preamble = htmlescape(lookupfield(getConfig('en_tbl'),'preamble',"uid=$params->{id}"));
	my $title = htmlescape(lookupfield(getConfig('en_tbl'),'title',"uid=$params->{id}"));

	$template->addText("<preamble>\n");
	$template->addText("	<objectid>$params->{id}</objectid>\n");
	$template->addText("	<table>".getConfig('en_tbl')."</table>\n");
	$template->addText("	<title>$title</title>\n");
	$template->addText("	<text>$preamble</text>\n");
	$template->addText("</preamble>\n");

	return $template->expand();
}

# show screen with references to an object
#
sub getEnRefsTo {
	my $params = shift;
	
	my $html = '';
	
	my $id = ($params->{'name'} ? getidbyname($params->{'name'}):$params->{'id'});
	my $table = $params->{'from'};
	
	my @refs = xrefGetLinksTo($table,$id);

	my $idx = 1;
	foreach my $ref (@refs) {
		$html .= "$idx. <a href=\"".getConfig("main_url")."/?op=getobj&from=$table&name=$ref->{name}\">$ref->{title}</a> by <a href=\"".getConfig("main_url")."/?op=getuser&id=$ref->{userid}\">$ref->{username}</a><br />";
		$idx++;
	}
 
	my $title = lookupfield($table,'title',"uid=$id");

	return paddingTable(clearBox("References to '$title'",$html));
}

# get a character for a type
#
sub getTypeChar {
	my $type = shift;
	
	my $typechars = getConfig('typechars');

	return $typechars->{$type} if (defined $typechars->{$type});

	return '?';
}

# get a string for a type
#
sub getTypeString {
	my $type = shift;

	my $typestrings = getConfig('typestrings');

	return $typestrings->{$type} if (defined $typestrings->{$type});

	return '?';
}
# getEncyclopedia - interface to Encyclopedia browsing, alphabetical
#
sub getEncyclopedia {
	my $params = shift;

	dwarn "getEncyclopedia start";	
	my $idx = $params->{idx};
	my $content = '';
	my $letter = '';
	
	my $table = getConfig('en_tbl');
	my $index = getConfig('index_tbl');

	if (defined($idx)) {
		$letter = pack('C',$idx);
	}
	
	# link to the msc browser for encylcopedia
	#
	$content .= "<center><a href=\"".getConfig("main_url")."/browse/objects/\">(browse by subject)</a></center>";
	
	# build the index selector with an initial query.
	#
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'ichar as idx, count(objectid) as cnt',
								FROM=>$index,
								 WHERE=>"tbl='$table'",
								 'GROUP BY'=>'idx'});

	my @rows = dbGetRows($sth);
	$content .= "<table width=\"90%\" align=\"right\"><td><dl>";
	foreach my $row (@rows) {
		my $num = ord($row->{idx});
		$content .= "<dt>";
		$content .= "<font class=\"indexfont\" size=\"+1\"><a href=\"/encyclopedia/$row->{idx}/\">$row->{idx}</a></font> - $row->{cnt} ";
		$content .= ($row->{'cnt'}>1) ? 'entries' : 'entry';
		$content .= "</dt>";
		if ($letter eq $row->{'idx'}) {
			$content .= "<dd>";
			($rv,$sth) = dbSelect($dbh,{WHAT=>"$index.objectid,$index.type,$index.cname as name,$index.title,users.username,$index.userid",
													FROM=>"$index,users",
																WHERE=>"ichar = '$letter' AND users.uid=$index.userid AND tbl='".getConfig('en_tbl')."'"});
		
			my @objects = dbGetRows($sth);
			$content .= "<table>";
			foreach my $object (sort {cleanCmp(mangleTitle($a->{title}),mangleTitle($b->{title}))} @objects) {
				$content .= "<tr><td>";

				my $mtitle = mangleTitle($object->{title});
				$content .= "<a href=\"/encyclopedia/$object->{name}.html\">".mathTitle($mtitle, 'highlight')."</a>";

				# take account of synonyms 
				#
				if ($object->{'type'} == 2) {
					my $parenttitle = lookupfield($index,'title',"objectid=$object->{objectid} and type=1 and tbl='$table'");

					$content .= " (=<i>".mathTitle($parenttitle)."</i>)";
				}	

				# take account of defines
				#
				elsif ($object->{'type'} == 3) {
					my $parenttitle = lookupfield($index,'title',"objectid=$object->{objectid} and type=1 and tbl='$table'");

					$content .= " (in <i>".mathTitle($parenttitle)."</i>)";
				}
				$content .= ' owned by ';
				$content .= $object->{'username'};
				$content .= "</td></tr>";
			}
			$content .= "</table>";
			$content .= "</dd>";
		}
	}
	$content .= "</dl>";
	$content .= "</td></table>";

	# count distinct entries
	#
	($rv,$sth) = dbSelect($dbh,{WHAT=>'count(uid) as cnt',FROM=>$table,WHERE=>'1'});
	my $row = $sth->fetchrow_hashref();
	my $count = $row->{'cnt'};
	$sth->finish();

	# count titles and defines entries; these are individual "concepts"
	#
	($rv,$sth) = dbSelect($dbh,{WHAT=>'count(*) as cnt',FROM=>$index,WHERE=>"tbl = '$table' and (type = 1 or type = 3)"});
	$row = $sth->fetchrow_hashref();
	my $concepts = $row->{'cnt'};
	$sth->finish();

	# build output
	#
	$content = clearBox(getConfig('projname').' Encyclopedia',$content);
	my $interact .= makeBox("Interact","<center><a href=\"".getConfig("main_url")."/?op=adden\">add</center>");
	my $html = "<table width=\"100%\" cellpadding=\"2\" cellspacing=\"0\">
		<tr>
		<td>$content</td>
	</tr>
	<tr>
		<td><center>
		 $count entries total.  <br />
		 $concepts concepts total.
		 </center>
		</td>
	</tr>
	<tr>
		<td>$interact</td>
	</tr></table>";
	dwarn "getEncyclopedia end";
	return $html;
}

# addEncyclopedia - main interface to adding something to the Encyclopedia
#
sub addEncyclopedia {
	my ($params,$user_info,$upload) = @_;
 
	my $template = new XSLTemplate('addencyclopedia.xsl');
	my $table = getConfig('en_tbl');

	$template->addText('<entry>');
 
	return errorMessage('You can\'t post anonymously.') if ($user_info->{uid} <= 0);
 
	# handle post - done editing
	#
	if (defined $params->{'post'}) {
		return insertEncyclopedia($params, $user_info);
	}
 
	# handle preview 
	#
	elsif (defined $params->{'preview'}) {
		$AllowCache = 0;	# kill caching

		previewEncyclopedia($template,$params,$user_info);
		handleFileManager($template,$params,$upload);
	} 

	elsif (defined($params->{filebox})) {
		handleFileManager($template, $params, $upload);
	}
 
	# initial request, return blank form
	#
	else {
		# initialize parent data
		#
		if ($params->{parent}) {
			$template->setKeys(
				'parent' => $params->{parent},
				'title' => $params->{title},
				'class' => classstring($table, getidbyname($params->{parent}))
			);
		}
		# initialize request data
		#
		if ($params->{request}) {
			$template->setKey('title', $params->{title});
		}
		$template->setKey('preamble', $user_info->{data}->{preamble});

		handleFileManager($template, $params);
	}
 
	refreshAddEncyclopedia($template, $params);

	$template->addText('</entry>');
	
	return paddingTable(clearBox('Add to the Encyclopedia',$template->expand()));
}

# delete synonyms for an object
#
sub deleteSynonyms { 
	my $table = shift;
	my $uid = shift;	

	my $index = getConfig('index_tbl');

	# delete existing synonyms if existing record
	#
	if (defined $uid) {
	my ($rv,$sth) = dbDelete($dbh,{FROM=>$index,WHERE=>"tbl='$table' and objectid=$uid and type>1"});
	
	$sth->finish();
	}
}

# get a list of synonyms for an object
#
sub getSynonymsList {
	my $id = shift;
	
	my $table = getConfig('en_tbl');

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'synonyms',FROM=>$table,WHERE=>"uid=$id"});
	my $row = $sth->fetchrow_hashref();
	my $string = $row->{synonyms};
	$sth->finish();
	if (nb($string)) {
		return [splitindexterms($string)];
	} else {
		return [()];
	}
}

# get a list of defines for an object
#
sub getDefinesList {
	my $id = shift;
	
	my $table = getConfig('en_tbl');

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'defines',FROM=>$table,WHERE=>"uid=$id"});
	my $row = $sth->fetchrow_hashref();
	my $string = $row->{defines};
	$sth->finish();
	
	if (nb($string)) {
		return [splitindexterms($string)];
	} else {
		return [()];
	}
}

# createSynonyms - set the synonym records for an object
#
sub createSynonyms {
	my $synonyms = shift;	# synonym string
	my $userid = shift;		# user id of creator
	my $title = shift;		# title of master object
	my $name = shift;		# unique name of master object
	my $uid = shift;		# unique id of master object 
	my $type = shift || 2;	# 2=synonym, 3=defines (1 is master object)
	my $source = shift || getConfig('proj_nickname'); # source collection
	
	my $table = getConfig('en_tbl');
	my $index = getConfig('index_tbl');

	# make synonym links 
	#
	if (nb($synonyms)) {
		my @syns = splitindexterms($synonyms);
		foreach my $syn (@syns) {
			#warn "processing synonym $syn";
			#dwarn "processing synonym (type=$type) $syn";
			$syn =~ s/^\s*//;
			$syn =~ s/\s*$//;	
			my $sname = uniquename(swaptitle($syn),$name);

			my $ichar = getIndexChar(mangleTitle($syn));
		
			# insert records into main object index table
			#
			my $sth = $dbh->prepare("insert into $index (objectid,tbl,userid,title,cname,type,source,ichar) values (?,?,?,?,?,?,?,?)");
			my $rv = $sth->execute($uid, $table, $userid, $syn, $sname, $type, $source, $ichar);
			$sth->finish();
		}
	}
}

# actually insert the item into the database
#
sub insertEncyclopedia {
	my ($params,$userinf) = @_;

	$params->{title} = htmlToLatin1($params->{title}); 
	$params->{title} =~ s/^\s*//;
	$params->{title} =~ s/\s*$//;
 
	my $thash = {reverse %{getConfig("typestrings")}};
	my $type = $thash->{$params->{type}}; 
	my $name = uniquename(swaptitle($params->{title}));

	# some browsers may be doing something weird and sending the POST data
	# twice, if this is the case, checking for $name in the database should stop
	# the second submit
	#
	# APK 2003-06-11 : this check has to be rewritten, it is flawed and cannot
	# possibly work (think about how names are generated)
	# 
	# APK 2003-10-12 : best way would be to get a new entry ID on the blank
	# submission form, then force the insert to use this ID.  multiple submits
	# would then have an ID collision. (duh)
	# 
	return errorMessage('Something strange happened; your browser may have sent your submission twice.	Check to make sure your object is there, and is there only once.') if (objectExistsByName($name));
	
	my $related = (defined($params->{related}))?$params->{related}:'';
	my $synonyms = (defined($params->{synonyms}))?$params->{synonyms}:'';
	my $defines = (defined($params->{defines}))?$params->{defines}:'';
	my $keywords = (defined($params->{keywords}))?$params->{keywords}:'';
	my $pronunciation = normalizePronunciation($params->{title}, $params->{pronounce});

	my $table = getConfig('en_tbl'); 
	my $next = nextval("${table}_uid_seq");
	
	my $cols = 'created, modified,uid,version,type,userid,title,preamble,data,name,related,synonyms,defines,keywords,pronounce,self, parentid';

	my $parentid = undef;
	if (nb($params->{'parent'})) {
		$parentid = getidbyname($params->{'parent'});
	}

	my $sth = $dbh->prepare("insert into $table ($cols) values (now(), now(), ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

	my $rv = $sth->execute($next, $type, $userinf->{'uid'}, $params->{'title'}, $params->{'preamble'}, $params->{'data'}, $name, $related, $synonyms, $defines, $keywords, $pronunciation, ($params->{'self'} eq 'on' ? 1 : 0), $parentid);

	if (! $rv) {
		return errorMessage("Couldn't insert your item");
	}

	$params->{id} = $next;

	# take care of files
	#
	moveTempFilesToBox($params,$next,getConfig('en_tbl'));

	# handle title indexing
	#
	indexTitle($table,$params->{id},$userinf->{uid},$params->{title},$name);
	deleteSynonyms($table,$params->{id});
	createSynonyms($synonyms,$userinf->{uid},$params->{title},$name,$params->{id},2);
	createSynonyms($defines,$userinf->{uid},$params->{title},$name,$params->{id},3);

	# handle scoring
	#
	changeUserScore($userinf->{uid},getScore('addgloss'));

	# new watch on the object
	#
	addWatchIfAllowed(getConfig('en_tbl'),$params->{id},$userinf,'objwatch');
	
	# index this entry (for linking)
	#
	wordIndexEntry(getConfig('en_tbl'),$params);

	# index this entry (for IR)
	#
	irIndex(getConfig('en_tbl'),$params);

	# handle classification
	#
	my $classcount = classify($table,$params->{id},$params->{class});

	# add an ACL record
	#
	installDefaultACL($table,$params->{id},$userinf->{uid});

	# invalidate objects based on title (for cross referencing)
	#
	xrefTitleInvalidate($params->{title},$table);

	# make "related" links symmetric
	#
	symmetricRelated($name,$related,$userinf);

	# add the user to the author list
	#
	addAuthorEntry($table,$params->{id},$userinf->{uid});

	# fill any requests
	#
	if ($params->{request} && $params->{request} != -1) {
		fillReq($params->{request},$userinf,$table,$params->{id});
	}

	# update statistics
	#
	$stats->invalidate('unproven_theorems') if ($type == THEOREM());
	$stats->invalidate('unclassified_objects') if (!$classcount);
	$stats->invalidate('latestadds');
	
	return paddingTable(clearBox('Added',"Thank you for your addition to ".getConfig('projname').".	Click <a href=\"".getConfig("main_url")."/?op=getobj&from=$table&name=$name\">here</a> to see it."));
}

# "publish" an item from a foreign collection.  note: need a local userid.
#
sub publishEncyclopedia {
	my ($params, $userid, $source) = @_;

	my $userinf = {userInfoById($userid)};

	$params->{title} = htmlToLatin1($params->{title}); 
	$params->{title} =~ s/^\s*//;
	$params->{title} =~ s/\s*$//;
 
	my $thash = {reverse %{getConfig("typestrings")}};
	my $type = $thash->{$params->{type}}; 
	my $name = uniquename(swaptitle($params->{title}));

	my $related = (defined($params->{related}))?$params->{related}:'';
	my $synonyms = (defined($params->{synonyms}))?$params->{synonyms}:'';
	my $defines = (defined($params->{defines}))?$params->{defines}:'';
	my $keywords = (defined($params->{keywords}))?$params->{keywords}:'';
	my $pronunciation = normalizePronunciation($params->{title}, $params->{pronounce});

	my $table = getConfig('en_tbl'); 
	my $next = nextval("${table}_uid_seq");
	
	my $cols = 'created, modified,uid,version,type,userid,title,preamble,data,name,related,synonyms,defines,keywords,pronounce,self, parentid';

	my $parentid = undef;
	if (nb($params->{'parent'})) {
		$parentid = getidbyname($params->{'parent'});
	}

	my $sth = $dbh->prepare("insert into $table ($cols) values (now(), now(), ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

	my $rv = $sth->execute($next, $type, $userinf->{'uid'}, $params->{'title'}, $params->{'preamble'}, $params->{'data'}, $name, $related, $synonyms, $defines, $keywords, $pronunciation, ($params->{'self'} eq 'on' ? 1 : 0), $parentid);

	if (! $rv) {
		return 0;
	}

	$params->{id} = $next;

	# handle title indexing
	#
	indexTitle($table,$params->{id},$userinf->{uid},$params->{title},$name, $source);
	deleteSynonyms($table,$params->{id});
	createSynonyms($synonyms,$userinf->{uid},$params->{title},$name,$params->{id},2, $source);
	createSynonyms($defines,$userinf->{uid},$params->{title},$name,$params->{id},3, $source);

	# handle scoring
	#
	changeUserScore($userinf->{uid},getScore('addgloss'));

	# new watch on the object
	#
	addWatchIfAllowed(getConfig('en_tbl'),$params->{id},$userinf,'objwatch');
	
	# index this entry (for linking)
	#
	wordIndexEntry(getConfig('en_tbl'),$params);

	# index this entry (for IR)
	#
	irIndex(getConfig('en_tbl'),$params);

	# handle classification
	#
	my $classcount = classify($table,$params->{id},$params->{class});

	# add an ACL record
	#
	installDefaultACL($table,$params->{id},$userinf->{uid});

	# invalidate objects based on title (for cross referencing)
	#
	xrefTitleInvalidate($params->{title},$table);

	# make "related" links symmetric
	#
	symmetricRelated($name,$related,$userinf);

	# add the user to the author list
	#
	addAuthorEntry($table,$params->{id},$userinf->{uid});

	# update statistics
	#
	$stats->invalidate('unproven_theorems') if ($type == THEOREM());
	$stats->invalidate('unclassified_objects') if (!$classcount);
	$stats->invalidate('latestadds');

	return 1;
}

# refreshAddEncyclopedia - carry over param values for the Add form
#
sub refreshAddEncyclopedia {
	my $template = shift;
	my $params = shift;
	
	my $type = $params->{type} || 'Definition';

	my $fillreq = getRequestFiller($params);

	my $ttext = gettypebox({reverse %{getConfig("typestrings")}}, $type);
	
	$template->setKeys('fillreq' => $fillreq, 'tbox' => $ttext, 'typeis' => $type);
	$template->setKeysIfUnset(%$params);
}

# preview the math item (render it) and handle the preview form
#
sub previewEncyclopedia {
	my ($template, $params, $userinf) = @_;
	
	my $name = normalize(swaptitle($params->{'title'}));
	my $error = '';
	my $warn = '';
	
	my $method = $userinf->{'prefs'}->{'method'} || 'l2h';
	
	# check for errors in entered data
	#
	($error,$warn) = checkEncyclopediaEntry($params,1);
	
	# do our rendering if there were no errors
	#
	if ($error eq '') {
		my $preview = renderEnPreview(1, $params, $method);
		$template->setKey('showpreview', $preview);

	}
 
	# if there were no errors, put up the "post" button.
	#
	if ($error eq '') {
		$template->setKey('post', '<input TYPE="submit" name="post" VALUE="post" />');
	}
	
	# insert error messages
	#
	$error .= $warn;	 # toss in warnings now
	if ($error ne '') { $error .= '<hr />'; }
	$template->setKey('error', $error);
}

# make sure encyclopedia metadata is kosher
#
sub checkEncyclopediaEntry {
	my $params = shift;
	my $checktitle = shift;

	$params->{title} = htmlToLatin1($params->{title});

	my $name = uniquename(swaptitle($params->{title}));
	my $error = '';
	my $warn = '';

	# check for lack of classification
	#
	if (blank($params->{class}) && getConfig('classification_supported') == 1) {
		$warn .= "Please classify your entry.	If you need help, try using the <a href=\"".getConfig("main_url")."/?op=mscbrowse\">MSC search</a>.<br />";
	}
	
	# check title
	#
	if ($checktitle == 1) {
		if (blank($params->{title})) {
			$error .= "Need a title!<br	/>";
		} else {
			# check for duplicate name
			#
			my $dname = normalize(swaptitle($params->{title}));
			if (objectExistsByName($dname)) {
				$warn .= "warning: Possible duplicate entry. Please check out <a href=\"/encyclopedia/$dname.html\" target=\"viewwin\">this</a> object, and related objects, to see if you really want to proceed.<br />";
			}
		}
	}
	
	# check content
	#
	if (blank($params->{data})) {
		$error .= "Need some content!<br />";
	}

	# clean up association fields
	#
	foreach my $key ('related','synonyms','keywords') {
		$params->{$key} =~ s/,\s+,/, /g;
	$params->{$key} =~ s/, *$//;
	}
	
	# check related's
	#
	if (nb($params->{related})) {
		my @rels=split(/\s*,\s*/,$params->{related});
		foreach my $rel (@rels) {
			if (not objectExistsByName($rel)) {
			$error .= "Cannot find related object '$rel'<br />";
		}
		}
	}

	# bad parent reference check 
	#
	if (isAttachmentType($params->{type})) {
		if (blank($params->{parent}) || !objectExistsByAny($params->{parent})) {
			$error .= "Need a valid parent object reference for that type of entry.<br />";
		}
	}

	# check for later version in database. for new addition, version will be 0
	# and this check will be skipped.
	#
	if ($params->{'version'}) {

		my $dbversion = lookupfield($params->{'from'}, 'version', "uid=$params->{id}");

		# if database verison is greater than checked out version, we're in
		# trouble. that means someone else did an update since we checked out.
		#
		if ($dbversion > $params->{'version'}) {

			$error .= "Someone else has checked in a more recent copy of this entry! To resolve any possible edit conflicts, you should open up a new edit window for this entry, integrate the new source with the current source you are working on, and check in the new version.<br />";
		}
	}

	return ($error,$warn);
}

# rendering wrapper - returns an error message if rendering fails.
#
sub renderEnPreview {
	my $newent = shift;	 # new entry flag
	my $params = shift;
	my $method = shift;
	
	my $title = swaptitle($params->{'title'});
	my $math = $params->{'data'};
	my $name = normalize(swaptitle($title));
	my $dir = '';
	my $root = getConfig('cache_root');
 
	# figure out cache dir. it really should already exist for us.
	#
	if (defined $params->{'tempdir'}) {
		$dir = $params->{'tempdir'};
	} else {
		$dir = makeTempCacheDir();
#	dwarn "temp cache dir = $dir";
		$params->{'tempdir'} = $dir;
	}
	#dwarn "going to try to render a preview to $dir";
 
	# copy files from main dir to method subdir
	#
	#dwarn "preview files go in $root/$dir/$method";
	if (not -e "$root/$dir/$method") {
		mkdir "$root/$dir/$method";
	}
	#dwarn "changing dir to $dir";
	chdir "$root/$dir";
	my @files = <*>;
	my @methoddirs = getMethods();
	foreach my $file (@files) {
		if (not inset($file,@methoddirs)) {
			`cp $file $method`;
		}
	}
	chdir "$root";
	
	# remove old rendering file if it exists
	#
	my $outfile = getConfig('rendering_output_file');
	if (-e "$root/$dir/$method/$outfile") {
		`rm $root/$dir/$method/$outfile`;
	}
	
	# do the rendering
	#
	my ($latex,$links) = prepareEntryForRendering($newent,
		$params->{'preamble'},
		$math,
		$method,
		$title,
		[splitindexterms($params->{synonyms}),
		 splitindexterms($params->{defines})],
		$params->{'table'},
		defined $params->{'id'} ? $params->{'id'} : '0',
		$params->{'class'});

	my $table = getConfig('en_tbl');
	renderLaTeX('.', $dir, $latex, $method, $name);
	
	# if we succeeded, show preview
	#
	my $file = "$root/$dir/$method/$outfile";
	#my $size = (stat($file))[7];
	#if ( defined($size) && $size > 0 ) {
		my $preview = mathBox(mathTitle($title,'title'),readFile($file));
		return $preview;
	#} 
}

# get a little associations guidelines screen 
#
sub getAssocGuidelines {
	my $guidelines = new Template('assoc_guidelines.html');

	return paddingTable(clearBox('Association Guidelines', $guidelines->expand()));
}

# get a little latex guidelines screen 
#
sub getLatexGuidelines {
	my $guidelines = new Template('latex_guidelines.html');
	my $file = getConfig('entry_template');
	my $latextemplate = new Template($file);

	$latextemplate->setKeys('packages' => '$packages', 'preamble' => '$preamble', 'math' => '$math');
	$guidelines->setKey('template', $latextemplate->expand());

	return paddingTable(clearBox('LaTeX Guidelines',$guidelines->expand()));
}

# make "related" links symmetric
#
sub symmetricRelated {
	my $name = shift;		# name of parent object
	my $related = shift; # related string
	my $userinf = shift; # user info

	# we only do this if the user wants it
	#
	return if (not $userinf->{prefs}->{symrelated});

	my @rels = split(/\s*,\s*/,$related);

	foreach my $rel (@rels) {
		my $id = getidbyname($rel);
	dwarn "*** related: checking id $id from related line";
	if ($id != -1) {
		my $userid = lookupfield(getConfig('en_tbl'),'userid',"uid=$id");
		
		# the only way we can set symmetric for sure is if the same user owns
		# both objects, and they have "accept related" on as well
		#
		if ($userid == $userinf->{uid} &&
				$userinf->{prefs}->{acceptrelated} eq 'on') {
			
				addRelated($id,$name); 
		}

		# send notice to user who owns the other entry
		#
		else {
			notifyRelated($rel,$id,$userid,$name,$userinf->{uid});
		}
	}
	}
}

# send a related notice, OR, if the user has auto-accept on, make the link 
# and send a notice
#	OR send them a prompt
#
sub notifyRelated {
	my $rel = shift;				# the related object (target) name
	my $id = shift;				 # the id of that object
	my $userid = shift;		 # the user who owns it
	my $name = shift;			 # name of the invoking (source) object
	my $owner = shift;			# owner of the invoking object

	my $en = getConfig('en_tbl');
	my $related = lookupfield($en,'related',"uid=$id");

	my $target_title = lookupfield(getConfig('index_tbl'), 'title', "objectid=$id and tbl='$en'");
	my $source_title = lookupfield(getConfig('index_tbl'), 'title', "cname='$name' and tbl='$en'");
	
	if (not inset($name,split(/\s*,\s*/,$related))) {

	# auto-accept is on, set the link and send a notice
	#
	my $relpref = userPref($userid,'acceptrelated');
	if ($relpref eq 'on') {
				fileNotice($userid,
									 $owner,
						 'An entry has been set as related to one of yours',
						 '(Your entry has automatically been set related to it.)',
						 [{id=>$id,table=>$en},
							{id=>getidbyname($name),table=>$en}]
						 );
				addRelated($id,$name); 
	} 
	
	# suggest
	#
	elsif ($relpref eq 'off') {
	
		if (not madeSuggestion($id,$en,$name)) {
				fileNotice($userid,
									 $owner,
						 'An entry has been set as related to one of yours',
						 '(you may want to set yours related to it as well.)',
						 [{id=>$id,table=>$en},
							{id=>getidbyname($name),table=>$en}]
						 );
			addSuggestion($id,$en,$name);
		}
	}

	# prompt
	#
	elsif ($relpref eq 'ask') {
		if (not madeSuggestion($id, $en, $name)) {
			filePrompt($userid,
				$owner, 
				'An entry has been set as related to one of yours',
				"Shall I set '$target_title' related to '$source_title'?",
				-1, # default = do nothing
				 [['make symmetric link', urlescape("op=make_symmetric&from=$en&id=$id&to=$name")]],
				[{id=>$id,table=>$en},
				 {id=>getidbyname($name),table=>$en}]
				 );

			addSuggestion($id,$en,$name);
		}
	}
	}
}

# complete the symmetry of a related link by adding the given name to the 
# related list of a target object.
#
# this is meant to be called from the notice options dispatch, not directly.
#
sub makeSymmetric {
	my $params = shift;
	my $userinf = shift;

	my %fields = getfieldsbyid($params->{id}, $params->{from}, 'title, userid');
	my $desttitle = lookupfield(getConfig('index_tbl'), 'title', "cname='".sq($params->{to})."'");
	
	return "You don't own '$fields{title}'!" if ($userinf->{uid} != $fields{userid});
	
	my $set = addRelated($params->{id}, $params->{to});	

	return $set 
					 ? "Related link added from '<a href=\"".getConfig("main_url")."/?op=getobj&from=$params->{from}&id=$params->{id}\">$fields{title}</a>' to '<a href=\"".getConfig("main_url")."/?op=getobj&from=&params->{from}&name=$params->{to}\">$desttitle</a>'" 
					 : "Related link to '<a href=\"".getConfig("main_url")."/?op=getobj&from=&params->{from}&name=$params->{to}\">$desttitle</a>' was already present in '<a href=\"".getConfig("main_url")."/?op=getobj&from=$params->{from}&id=$params->{id}\">$fields{title}</a>'!";
}

# add a related to a particular entry if it's not already there
#
sub addRelated {
	my $id = shift;	 # id of the target entry
	my $rel = shift;	# related name to add

	my $set = 0;	 # set flag
	
	my $related = lookupfield(getConfig('en_tbl'),'related',"uid=$id");

	if (! inset($rel,split(/\s*,\s*/,$related))) {
		if (nb($related)) {
		$related = "$related, $rel";		 
	} else {
		$related = "$rel";
	}
	
		my ($rv,$sth) = dbUpdate($dbh,{WHAT=>getConfig('en_tbl'),SET=>"related='$related'",WHERE=>"uid=$id"}); 
	$sth->finish();

	$set = 1;
	}

	return $set;
}

# see if a related link was already suggested
#
sub madeSuggestion {
	my $id = shift;			 # the object "address"
	my $tbl = shift; 
	my $name = shift;		 # canonical name of the related item

	my $table = getConfig('rsugg_tbl');

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'objectid',FROM=>$table,WHERE=>"objectid=$id and tbl='$tbl' and related='$name'"});
	my $count = $sth->rows();
	$sth->finish();

	return $count ? 1 : 0;
}

# add a record for a related suggestion
#
sub addSuggestion {
	my $id = shift;
	my $tbl = shift;
	my $name = shift;

	my $table = getConfig('rsugg_tbl');

	my ($rv,$sth) = dbInsert($dbh,{INTO=>$table,COLS=>'objectid,tbl,related',VALUES=>"$id,'$tbl','$name'"});
	$sth->finish();
}

1;
