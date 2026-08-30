package Noosphere;
use strict;
use Noosphere::TemplateNS;
use vars qw($NoosphereTitle);

sub getObjTableIsAllowed {
	my $table = shift;

	return 0 if (!defined($table) || $table eq '');

	my %allowed = map { $_ => 1 } grep { defined($_) && $_ ne '' } (
		getConfig('news_tbl'),
		getConfig('en_tbl'),
		getConfig('collab_tbl'),
		getConfig('forum_tbl'),
		getConfig('papers_tbl'),
		getConfig('exp_tbl'),
		getConfig('books_tbl'),
		getConfig('polls_tbl'),
		getConfig('req_tbl'),
		getConfig('user_tbl'),
		getConfig('cor_tbl'),
	);

	return $allowed{$table};
}

sub getObjIdIsValid {
	my $id = shift;

	return (defined($id) && $id =~ /^\d+$/);
}

# getObj - main object retrieval point, calls more specialized functions
#
sub getObj {
	my $params = shift;
	my $userinf = shift;
	#dwarn "getObj Started";
	my $html = '';
	my $html_obj = '';
	my $admin = '';
	my $watch = '';
	my $author ='';
	my $corrections = '';
	my $messages = '';
	my $interact = '';
	my $id = $params->{'id'};
	my $name = $params->{'name'};
	my $from = $params->{'from'};
	my $desc = 0;
	my $nomsg = 0;
	my $file = 'getobj.tt';

	return errorMessage('Unknown object type.') if (!getObjTableIsAllowed($from));

	my $is_generic_library_item = (
		$from eq getConfig('papers_tbl') ||
		$from eq getConfig('exp_tbl') ||
		$from eq getConfig('books_tbl')
	);
	#dwarn "name";
	#dwarn $name;
	#dwarn "id";
	#dwarn $id;

	my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	# resolve name query into id so we only have one method to write code for
	#
	if (defined($name)) {
		$id = getidbyname($name);
	}		
	return errorMessage('Could not find object! Contact an admin!') if ($id == -1);
	return errorMessage('Invalid object id.') if (!getObjIdIsValid($id));

	# query up the object
	#
	(my $rv, my $sth) = dbSelect($dbh,{WHAT =>'*', 
									 FROM => $from,
									 WHERE => "uid=$id"});
	if (! $rv || $sth->rows()<1) {
		#dwarn "object not found!";
		return errorMessage("Object not found! Please <a href=\"".getConfig('bug_url')."\">report this</a> to us!");
	}

	my $rec = $sth->fetchrow_hashref();	

	# handle access to the object
	#
	if (!hasPermissionTo($from,$id,$userinf,'read')) {

		my $msg = "You don't have permission to view that object.<p>";
		$msg .= "This may be a mistake.  Try contacting the <a href=\"".getConfig('main_url')."/?op=getuser&id=$rec->{userid}\">object owner</a> (preferably) or <a href=\"mailto:".getAddr('feedback')."\">administration</a> (if the owner is unresponsive).";
		return errorMessage($msg);
	}

	# handle watch changing
	#
	changeWatch($params, $userinf, $from, $id);
	
	# hit the object
	#
	hitObject($id,$from,'hits');

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
	if ($from eq getConfig('news_tbl')) {
		#dwarn "renderNews";
		$html = renderNews($rec);
	} 
	elsif ($from eq getConfig('en_tbl')) {
		#dwarn "renderEncyclopediaObj";
		$html = renderEncyclopediaObj($rec, $params, $userinf);
	}
	elsif ($from eq getConfig('collab_tbl')) {
		#dwarn "renderCollab";
		$html = renderCollab($rec, $params, $userinf);
	}
	elsif ($from eq getConfig('forum_tbl')) {
		#dwarn "renderForum";
		$html = renderForum($rec);
		# Should newest-first be forced here?	-LBH
		#$desc=1;
	} 
	elsif ($from eq getConfig('papers_tbl') ||
		$from eq getConfig('exp_tbl') ||
		$from eq getConfig('books_tbl')) {
		#dwarn "renderGeneric";	
		$html = renderGeneric($params,$userinf, $rec);
	} 
	elsif ($from eq getConfig('polls_tbl')) {
		#dwarn "viewPoll";
		$html = viewPoll($params,$userinf);
	}
	elsif ($from eq getConfig('req_tbl')) {
		#dwarn "getReq";
		$html = getReq($params,$userinf);
	}
	elsif ($from eq getConfig('user_tbl')) {
		#dwarn "getUser";
		$html = getUser($params,$userinf);
	}
	elsif ($from eq getConfig('cor_tbl')) {
		#dwarn "renderCorrection";
		$html = renderCorrection($params,$userinf);
	}
	else {
		#dwarn "object type not supported for viewing yet";
		return errorMessage('object type not supported for viewing yet.'); 
	}
 
	return $html if ($nomsg);
	
	# handle messages - this is unified accross object types. we know the object
	# supports messages based on whether the template contains a $messages flag.
	#
	#dwarn "start requestsKeyTT";
	#dwarn "html:\n $html";
	if (!$is_generic_library_item) {
		#dwarn "OBJECT REQUESTS messages";
		#dwarn "**** OBJECT REQUESTS messages; $id\n", 3;
		my $lastmsg = get_lastseen($from,$id,$userinf->{'uid'});
		#dwarn "lastmsg:\n $lastmsg";

		$messages = clearBox('Discussion',getMessages($from,$id,$desc,$params,$userinf,($userinf->{'uid'} < 0 ) ? undef : $lastmsg));
		##$html->setKey('messages', $messages);
		#dwarn "messages\n: $messages";
		my $curlast = get_lastmsg($from,$id);
		update_lastseen($from,$id,$userinf->{'uid'},$curlast);
	}


	##if (1) {
	##	$params->{'id'} = $id;
	##	my $watchwidget = getWatchWidget($params, $userinf);
	##	$watch = $watchwidget;
		##$html->setKey('watch', $watchwidget);
	##}

	# likewise for corrections
	#
	##if(1) {
	#	$corrections = clearBox('Pending Errata and Addenda',getPendingCorrections($id));
		##$html->setKey('corrections', $corrections);
	##} 

	# admin metadata editing
	#
	
	if ($from eq getConfig('en_tbl')) {
		$admin = getEncyclopediaAdminControls($userinf,$from,$id,$params->{'method'});
		$interact = makeBox('Interact',getEncyclopediaInteract($rec));
	}
	elsif ($from eq getConfig('papers_tbl') ||
		$from eq getConfig('exp_tbl') ||
		$from eq getConfig('books_tbl')) {
		$admin = getGenericAdmin($params, $userinf, $rec);
	}

	# get owner controls
	if ($userinf->{'uid'} == $rec->{'userid'}) {
		$author = getOwnerControls($from,$rec->{'uid'});
	}
	# or author controls
	elsif ($userinf->{'uid'} > 0 && hasPermissionTo($from,$id,$userinf,'write')) {
		$author = getAuthorControls($from,$rec->{'uid'},$userinf);
	}

	if ($from eq getConfig('en_tbl')) {
		$corrections = clearBox('Pending Errata and Addenda',getPendingCorrections($id));
	}
	$params->{'id'} = $id;
	$watch = getWatchWidget($params, $userinf);

	##$html->setKey('author', $author);

	
	##$html = $html->expand();

	if (ref($html) && $html->can('expand')) {
		my %common = (
			watch       => $watch,
			admin       => $admin,
			author      => $author,
			corrections => $corrections,
			messages    => $messages,
			interact    => $interact,
		);

		foreach my $key (keys %common) {
			next if (!defined($common{$key}) || $common{$key} eq '');
			$html->setKey($key, $common{$key});
		}

		return $html->expand();
	}

	my $vars = {
        renderObj       => $html,
		watch           => $watch,
		admin           => $admin,
		author          => $author,
		corrections     => $corrections,
		messages        => $messages,
		interact        => $interact,
    };

    

	
    my $ret = $tt->process($file, $vars, \$html_obj) || die "Template process failed: ", $tt->error(), "\n";

	
	
	
	return $html_obj;
}

sub renderNews {
	my $rec = shift;

	my $html = new TemplateNS('newsobj.html');

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

