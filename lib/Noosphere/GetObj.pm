package Noosphere;
use strict;

# getObj - main object retrieval point, calls more specialized functions
#
sub getObj {
	my $params = shift;
	my $userinf = shift;
	
	my $html = '';
	my $id = $params->{'id'};
	my $name = $params->{'name'};
	my $desc = 0;
	my $nomsg = 0;
	
	dwarn "name";
	dwarn $name;
	dwarn "id";
	dwarn $id;

	# resolve name query into id so we only have one method to write code for
	#
	if (defined($name)) {
		$id = getidbyname($name);
	}		
	return errorMessage('Could not find object! Contact an admin!') if ($id == -1);

	# query up the object
	#
	(my $rv, my $sth) = dbSelect($dbh,{WHAT =>'*', 
									 FROM => $params->{from},
									 WHERE => "uid=$id"});
	if (! $rv || $sth->rows()<1) {
		dwarn "object not found!";
		return errorMessage("Object not found! Please <a href=\"".getConfig('bug_url')."\">report this</a> to us!");
	}

	my $rec = $sth->fetchrow_hashref();	

	# handle access to the object
	#
	if (!hasPermissionTo($params->{'from'},$id,$userinf,'read')) {

		my $msg = "You don't have permission to view that object.<p>";
		$msg .= "This may be a mistake.  Try contacting the <a href=\"".getConfig('main_url')."/?op=getuser&id=$rec->{userid}\">object owner</a> (preferably) or <a href=\"mailto:".getAddr('feedback')."\">administration</a> (if the owner is unresponsive).";
		return errorMessage($msg);
	}

	# handle watch changing
	#
	changeWatch($params, $userinf, $params->{'from'}, $id);
	
	# hit the object
	#
	hitObject($id,$params->{'from'},'hits');

	# get user name (handle negative user id)
	#
	if ($rec->{'userid'} <= 0) {
		$rec->{'username'} = "nobody";
	} else {
		$rec->{'username'} = lookupfield('users','username',"uid=$rec->{userid}");
	}

	# set title
	#
	if (nb($rec->{'title'})) {
		$NoosphereTitle = TeXtoUTF8($rec->{'title'});
	}
	
	# render object type specific stuff
	#
	if ($params->{'from'} eq 'news') {
		dwarn "renderNews";
		$html = renderNews($rec);
	} 
	elsif ($params->{'from'} eq getConfig('en_tbl')) {
		dwarn "renderEncyclopediaObj";
		$html = renderEncyclopediaObj($rec, $params, $userinf);
	}
	elsif ($params->{'from'} eq getConfig('collab_tbl')) {
		dwarn "renderCollab";
		$html = renderCollab($rec, $params, $userinf);
	}
	elsif ($params->{'from'} eq 'forums') {
		dwarn "renderForum";
		$html = renderForum($rec);
		# Should newest-first be forced here?	-LBH
		#$desc=1;
	} 
	elsif ($params->{'from'} eq getConfig('papers_tbl') || 
		$params->{'from'} eq getConfig('exp_tbl') ||
		$params->{'from'} eq getConfig('books_tbl')) {
		dwarn "renderGeneric";	
		$html = renderGeneric($params,$userinf, $rec);
	} 
	elsif ($params->{'from'} eq getConfig('polls_tbl')) {
		dwarn "viewPoll";
		$html = viewPoll($params,$userinf);
	}
	elsif ($params->{'from'} eq getConfig('req_tbl')) {
		dwarn "getReq";
		$html = getReq($params,$userinf);
	}
	elsif ($params->{'from'} eq getConfig('user_tbl')) {
		dwarn "getUser";
		$html = getUser($params,$userinf);
	}
	elsif ($params->{'from'} eq getConfig('cor_tbl')) {
		dwarn "renderCorrection";
		$html = renderCorrection($params,$userinf);
	}
	else {
		dwarn "object type not supported for viewing yet";
		return errorMessage('object type not supported for viewing yet.'); 
	}
 
	return $html if ($nomsg);
	
	# handle messages - this is unified accross object types. we know the object
	# supports messages based on whether the template contains a $messages flag.
	#
	if ($html->requestsKey('messages')) {
		dwarn "**** OBJECT REQUESTS messages; $id\n", 3;
		my $lastmsg = get_lastseen($params->{'from'},$id,$userinf->{'uid'});
		my $messages = clearBox('Discussion',getMessages($params->{'from'},$id,$desc,$params,$userinf,($userinf->{'uid'} < 0 ) ? undef : $lastmsg));
	$html->setKey('messages', $messages);
		my $curlast = get_lastmsg($params->{'from'},$id);
		update_lastseen($params->{'from'},$id,$userinf->{'uid'},$curlast);
	}

	if ($html->requestsKey('watch')) {
		$params->{'id'} = $id;
		my $watchwidget = getWatchWidget($params, $userinf);
		$html->setKey('watch', $watchwidget);
	}

	# likewise for corrections
	#
	if($html->requestsKey('corrections')) {
		my $corrections = clearBox('Pending Errata and Addenda',getPendingCorrections($id));
	$html->setKey('corrections', $corrections);
	} 

	# admin metadata editing
	#
	if ($params->{'from'} eq getConfig('en_tbl')) {
		getEncyclopediaAdminControls($html,$userinf,$params->{'from'},$id,$params->{'method'});
	}

	# get owner controls
	# 
	my $author = '';
	if ($userinf->{'uid'} == $rec->{'userid'}) {
		$author = getOwnerControls($params->{'from'},$rec->{'uid'});
	}
	
	# or author controls
	#
	elsif ($userinf->{'uid'} > 0 && hasPermissionTo($params->{'from'},$id,$userinf,'write')) {
		$author = getAuthorControls($params->{'from'},$rec->{'uid'},$userinf);
	}
	
	$html->setKey('author', $author);

	
	return $html->expand();
}

sub renderNews {
	my $rec = shift;

	my $html = new Template('newsobj.html');

	my $newsbox = clearBox($rec->{'title'},formatnewsitem_full($rec));
	my $interact = makeBox('Interact',getNewsInteract($rec));
	$html->setKeys('newsbox' => $newsbox, 'interact' => $interact);

	return $html;
}

# get the author controls menu
#
sub getAuthorControls {
	my $table = shift;
	my $id = shift;
	my $userinf = shift;

	my $html = '';

	$html .= "<center>";
	$html .= "<a href=\"".getConfig("main_url")."/?op=edit&amp;from=$table&amp;id=$id\">edit content</a> ";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=linkpolicy&amp;from=$table&amp;id=$id\">edit linking policy</a> ";
	if (hasPermissionTo($table,$id,$userinf,'acl')) {
		$html .= "| <a href=\"".getConfig("main_url")."/?op=acledit&amp;from=$table&amp;id=$id\">change access</a>";
	}
	$html .= "</center>";

	return makeBox('Author Controls',$html);
}

# get the owner controls menu
#
sub getOwnerControls {
	my $table = shift;
	my $id = shift;

	my $html = '';

	$html .= "<center>";
	$html .= "<a href=\"".getConfig("main_url")."/?op=edit&amp;from=$table&amp;id=$id\">edit content</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=rerender&amp;from=$table&amp;id=$id\">rerender</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=linkpolicy&amp;from=$table&amp;id=$id\">edit linking policy</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=acledit&amp;from=$table&amp;id=$id\">change access</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=creategroup&amp;from=$table&amp;id=$id\">create editor group</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=transfer&amp;from=$table&amp;id=$id\">transfer</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=delobj&amp;from=$table&amp;id=$id&amp;ask=yes\">delete</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=abandon&amp;from=$table&amp;id=$id&amp;ask=yes\">abandon</a>" if $table ne getConfig('collab_tbl');
	$html .= "</center>";

	return makeBox('Owner Controls',$html);
}

# get interact menu for encyc
#
sub getEncyclopediaInteract {
	my $rec = shift;
	my $html = "";
	my $table = getConfig('en_tbl');

	# get classification string, so we can propegate it to attachments
	#
	my $class = urlescape(classstring($table,$rec->{uid}));
	
	$html .= "<center>rate";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=postmsg&amp;from=$table&amp;id=$rec->{uid}\">post</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=correct&amp;from=$table&amp;id=$rec->{uid}\">correct</a>";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=updatereq&amp;identifier=$rec->{name}\">update request</a>";

	if ($rec->{type} == THEOREM() || $rec->{type} == CONJECTURE() ) {
		$html .= " | <a href=\"".getConfig("main_url")."/?op=adden&amp;class=$class&amp;type=Proof&amp;parent=$rec->{name}&title=".urlescape("proof of ".$rec->{title})."\">prove</a>";
		$html .= " | <a href=\"".getConfig("main_url")."/?op=adden&amp;class=$class&amp;type=Result&amp;parent=$rec->{name}&amp;title=".urlescape($rec->{title}." result")."\">add result</a>";
		$html .= " | <a href=\"".getConfig("main_url")."/?op=adden&amp;class=$class&amp;type=Corollary&amp;parent=$rec->{name}&amp;title=".urlescape("corollary of ".$rec->{title})."\">add corollary</a>";
	}

	if ($rec->{type} == DEFINITION() ) {
		$html .= " | <a href=\"".getConfig("main_url")."/?op=adden&amp;class=$class&amp;type=Derivation&amp;parent=$rec->{name}&amp;title=".urlescape("derivation of ".$rec->{title})."\">add derivation</a>";
	}
	
	$html .= " | <a href=\"".getConfig("main_url")."/?op=adden&amp;class=$class&amp;type=Example&amp;parent=$rec->{name}&amp;title=".urlescape("example of ".$rec->{title})."\">add example</a>";

	$html .= " | <a href=\"".getConfig("main_url")."/?op=adden&amp;class=$class&amp;parent=$rec->{name}&amp;title=".urlescape("something related to ".$rec->{title})."\">add (any)</a>";
	
	$html .= "</center>";

	return $html;
}

# get interact menu for collab 
#
sub getCollabInteract {
	my $rec = shift;

	my $html = "";
	my $table = getConfig('collab_tbl');

	$html .= "<center>";
	$html .= " <a href=\"".getConfig("main_url")."/?op=postmsg&amp;from=$table&amp;id=$rec->{uid}\">post</a>";

	$html .= "</center>";

	return $html;
}

# get interact menu for lectures
#
sub getExpInteract {
	my $rec = shift;
	my $html = "";
	my $table = getConfig('exp_tbl');

	$html .= "<center>rate";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=postmsg&amp;from=$table&amp;id=$rec->{uid}\">post</a>";

	return $html;
}

# get interact menu for books
#
sub getBookInteract {
	my $rec = shift;

	my $html = '';
	my $table = getConfig('books_tbl');

	$html .= "<center>rate";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=postmsg&amp;from=$table&amp;id=$rec->{uid}\">post</a>";

	return $html;
}

# get interact menu for papers
#
sub getPaperInteract {
	my $rec = shift;
	
	my $html = '';
	my $table = getConfig('papers_tbl');

	$html .= "<center>rate";
	$html .= " | <a href=\"".getConfig("main_url")."/?op=postmsg&amp;from=$table&amp;id=$rec->{uid}\">post</a>";

	return $html;
}

sub getNewsInteract {
	my $rec = shift;
	my $html = "";
	my $table = getConfig('news_tbl');

	$html .= "<center> ";
	$html .= "<a href=\"".getConfig("main_url")."/?op=postmsg&amp;from=$table&amp;id=".$rec->{'uid'}."\">post</a>";
	$html .= "</center>";
}


1;

