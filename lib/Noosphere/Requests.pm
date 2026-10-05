package Noosphere;

use strict;
use Encode;
use Noosphere::EntryInteractions;
# get requests "interact" box
#
sub getReqInteract {
	my $rec=shift;

	my $table=getConfig('req_tbl');

	my $title=urlescape($rec->{title});

	return makeBox('Interact',"<center><a href=\"".getConfig("main_url")."/?op=addreq\">add</a> | <a href=\"".getConfig("main_url")."/?op=adden&request=$rec->{uid}&title=$title\">fill</a> | <a href=\"".getConfig("main_url")."/?op=updatereq&request=$rec->{uid}\">update</a> | <a href=\"".getConfig("main_url")."/?op=postmsg&from=$table&id=$rec->{uid}\">post</a></center>");
}

# get a count of unfilled requests
#
sub getUnfilledReqCount {
	my $table=getConfig('req_tbl');
	
	my ($rv,$sth)=dbSelect($dbh,{WHAT=>'uid',FROM=>$table,WHERE=>'fulfilled is null'});
	my $count=$sth->rows();
	$sth->finish();

	return $count;
}

# view old (confirmed+filled) requests
#
sub oldReqs {
	my $params = shift;
	my $userinf = shift;
	my $table = getConfig('req_tbl');
	my $offset = defined($params->{offset}) && $params->{offset} =~ /\A\d+\z/ ? int($params->{offset}) : 0;
	my $total = defined($params->{total}) && $params->{total} =~ /\A[1-9]\d*\z/ ? int($params->{total}) : -1;
	my $limit = $userinf->{prefs}->{pagelength};
	$limit = 20 unless defined($limit) && $limit =~ /\A\d+\z/ && $limit > 0;

	if ($total == -1) {
		my ($rv, $sth) = dbSelect($dbh, {WHAT => 'uid', FROM => $table, WHERE => 'closed is not null'});
		return errorMessage('Request query failed!') unless $rv && $sth;
		$total = $sth->rows();
		$sth->finish();
	}

	my @requests;
	if ($total > 0) {
		my ($rv, $sth) = dbSelect($dbh, {
			WHAT => "$table.*, u1.username, u2.username as username2",
			FROM => "$table, users as u1, users as u2",
			WHERE => "closed is not null and u1.uid=$table.creatorid and u2.uid=$table.fulfillerid",
			'ORDER BY' => 'created', DESC => '', OFFSET => $offset, LIMIT => $limit,
		});
		return errorMessage('Request query failed!') unless $rv && $sth;
		for my $row (dbGetRows($sth)) {
			push @requests, {
				number => $offset + @requests + 1,
				title => $row->{title}, date => ymd($row->{created}),
				requester => $row->{username}, filler => $row->{username2},
				title_url => entryInteractionURL('getobj', from => $table, id => $row->{uid}),
				requester_url => entryInteractionURL('getuser', id => $row->{creatorid}),
				filler_url => entryInteractionURL('getuser', id => $row->{fulfillerid}),
			};
		}
	}
	$params->{total} = $total;
	$params->{offset} = $offset;
	my $pager = $total ? getPager({op => 'oldreqs', total => $total, offset => $offset},
		{%$userinf, prefs => {%{$userinf->{prefs}}, pagelength => $limit}}) : '';

	return entryInteractionTemplate('oldrequests.tt', {
		requests => \@requests, total => $total,
		start => @requests ? $offset + 1 : 0, finish => $offset + @requests,
		pager => $pager,
	});
}

# confirm ALL requests
#
sub confirmAllReq {
	my $params = shift;
	my $userinf = shift;

	my $table = getConfig('req_tbl');

	return errorMessage("Access too low to confirm requests!") if ($userinf->{data}->{access}<getConfig('access_admin'));

	my ($rv,$sth) = dbSelect($dbh,{WHAT => 'uid', FROM=>$table, WHERE => "closed is null and fulfilled is not null"});
	
	my @rows = dbGetRows($sth);
	
	foreach my $row (@rows) {
		dbConfirmReq($row->{uid}, $userinf); 
	}

	return reqList($params,$userinf);
}

# confirm a request fulfillment
#
sub confirmReq {
	my $params = shift;
	my $userinf = shift;

	return errorMessage("Access too low to confirm requests!") if ($userinf->{data}->{access}<getConfig('access_admin'));

	dbConfirmReq($params->{id}, $userinf);

	return reqList($params,$userinf);
}

# do db and back-end stuff for confirming a request
#
sub dbConfirmReq {
	my $rid = shift;
	my $userinf = shift;

	my $table = getConfig('req_tbl');

	# modify the request data
	#
	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>$table,SET=>'closed = CURRENT_TIMESTAMP',WHERE=>"uid=$rid"});

	# send out notices (this should get owner and filer too)
	#
	updateEventWatches($rid, 
										 $table, 
					 $userinf->{uid},
					 'Request fulfillment confirmed');
}

# form to get a reason before denying a request
#
sub denyReqForm {
	my $params = shift;
	my $userinf = shift;

	my $html = '';
	my $table = getConfig('req_tbl');

	return errorMessage("Access too low to deny requests!") if ($userinf->{data}->{access} < getConfig('access_admin'));

	# do the denial in the database
	#
	if ($params->{deny}) {
		denyReq($params->{id}, $userinf->{uid}, $params->{reason});
		$html = reqList($params,$userinf);
	} 
	
	# show the initial form
	# 
	else {
		my $title = lookupfield($table, 'title', "uid=$params->{id}");
		my $content = lookupfield($table, 'data', "uid=$params->{id}");
		my $clinks = printContextLinks($params->{id});

		my $template = new XSLTemplate('reqdeny.xsl');

		# send output data
		#
		$template->addText('<reqdeny>');
		$template->setKey('title', $title);
		$template->setKey('content', $content);
		$template->setKey('clinks', $clinks);
		$template->setKeys(%$params);
		$template->addText('</reqdeny>');

		$html = paddingTable(makeBox('Deny a Request Fulfillment', $template->expand()));
	}

	return $html;
}

# form to get a reason before deleting a request
#
sub deleteReqForm {
	my $params = shift;
	my $userinf = shift;

	my $html = '';
	my $table = getConfig('req_tbl');

	return errorMessage("Access too low to delete requests!") if ($userinf->{data}->{access} < getConfig('access_admin'));

	# do the deletion in the database
	#
	if ($params->{'delete'}) {
		deleteReq($params->{id}, $userinf->{uid}, $params->{reason});
		$html = reqList($params,$userinf);
	} 
	
	# show the initial form
	# 
	else {
		my $title = lookupfield($table, 'title', "uid=$params->{id}");
		my $content = lookupfield($table, 'data', "uid=$params->{id}");
		my $clinks = printContextLinks($params->{id});

		my $template = new XSLTemplate('reqdelete.xsl');

		# send output data
		#
		$template->addText('<reqdelete>');
		$template->setKey('title', $title);
		$template->setKey('content', $content);
		$template->setKey('clinks', $clinks);
		$template->setKeys(%$params);
		$template->addText('</reqdelete>');

		$html = paddingTable(makeBox('Delete a Request', $template->expand()));
	}

	return $html;
}

# deny a request fulfillment
#
sub denyReq {
	my $rid = shift;
	my $userid = shift;
	my $reason = shift;

	my $table = getConfig('req_tbl');

	# update the request record 
	#
	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>$table,SET=>'fulfilled = NULL, fulfillerid = NULL',WHERE=>"uid=$rid"});
 
	# send out notices
	#
	updateEventWatches($rid, 
										 $table, 
					 $userid,
					 'Request fulfillment has been rejected',
					 'Reason: '.$reason);
	
	# remove context links
	#
	($rv,$sth) = dbDelete($dbh,{FROM=>'objlinks',WHERE=>"srcid=$rid and srctbl='$table'"});
}

# delete a request
#
sub deleteReq {
	my $rid = shift;
	my $userid = shift;
	my $reason = shift;

	my $table = getConfig('req_tbl');

	# remove the request record 
	#
	my ($rv,$sth) = dbDelete($dbh,{FROM=>$table,WHERE=>"uid=$rid"});
	$sth->finish();
 
	# send out notices
	#
	updateEventWatches($rid, 
										 $table, 
					 $userid,
					 'Request has been deleted',
					 'Reason: '.$reason);
	
	# remove context links
	#
	($rv,$sth) = dbDelete($dbh,{FROM=>'objlinks',WHERE=>"srcid=$rid and srctbl='$table'"});
}

# add a request
#
sub addReq {
	my $params = shift;
	my $userinf = shift;

	return needAccount() if ($userinf->{'uid'} <= 0);
	
	my $template=new TemplateNS('addreq.html');
	my $error='';

	if (defined $params->{submit}) {
		foreach my $field ('text','title') {
			if (! nb($params->{$field})) {
			$error="Blank fields not allowed.<br>";
		}
	}
	if (!$error) {
			return insertRequest($params,$userinf);
	}
	} else {
		$template->unsetKeys('text','title','error')
	}
	
	if ($error) {
		$template->setKey('error', $error);
	}

	$template->setKeys(%$params);

	return paddingTable(makeBox("Make a Request",$template->expand()));
}

# actually make a database record
#
sub insertRequest {
	my $params = shift;
	my $userinf = shift;

	my $userid = $userinf->{data}->{uid};
	my $table = getConfig('req_tbl');

	# get a new UID for the entry
	#
	my $newid = nextval($table."_uid_seq");

	my ($rv,$sth) = dbInsert($dbh,{INTO=>$table,COLS=>'created,uid,creatorid,title,data',VALUES=>"now(),$newid,$userid,'".sq($params->{title})."','".sq($params->{text})."'"});

	# add a watch on the request (if the user has the auto-add option on)
	#
	addWatchIfAllowed($table,$newid,$userinf,'objwatch');

	return reqList($params,$userinf);	 # show the list
}

# update a request to be filled by a particular object
#
sub updateRequest { 
	my $params = shift;
	my $userinf = shift;
	
	my $table = getConfig('req_tbl');
	my $olinks = getConfig('olinks_tbl');

	my $identifier = $params->{identifier};
	my $rid = $params->{request};

	# resolve id
	#
	my $id = 0;
	if ($identifier=~/^[0-9]+$/) {
		$id = $identifier;
	} else {
		$id = getidbyname($identifier);
	}

	# see if the request is already filled
	#
	my $filled = lookupfield($table,'fulfilled',"uid=$rid");
	return reqList($params,$userinf) if ($filled);	 # should be undefined

	# get user id (from the object that fills the request)
	# 
	my $userid = lookupfield(getConfig('en_tbl'),'userid',"uid=$id");
	
	# fill the request
	#
	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>$table,SET=>"fulfilled=CURRENT_TIMESTAMP,fulfillerid=$userid",WHERE=>"uid=$rid"});

	# put in context link
	#
	my $en = getConfig('en_tbl');
	($rv,$sth) = dbInsert($dbh,{INTO=>$olinks,COLS=>'srctbl,srcid,desttbl,destid,note',VALUES=>"'$table',$rid,'$en',$id,'request fill'"});

	# send notices for this event
	#
	updateWatches($rid,		# request pointer
								$table,	
				$id,		 # fulfilling object pointer
				$en,
						$userinf->{uid},	# fulfilling user pointer
				'request reported as fulfilled');

	# add watch for fulfillment reporter
	#
	addWatchIfAllowed($table, $rid, $userinf, 'reqfywatch');

	# add watch for fulfillment object author
	#
	my $auid = lookupfield($en,'userid',"uid=$id");
	my $auserinf = {userInfoById($auid)};
	addWatchIfAllowed($table, $rid, $auserinf, 'reqfowatch');

	return reqList($params, $userinf);	 # show the list
}

# form interface for updating the status of a request 
#
sub updateReq {
	my $params = shift;
	my $userinf = shift;
	return errorMessage("You have to be logged in for this!") if ($userinf->{uid} <= 0);

	my @errors;
	my $selected = defined($params->{request}) ? $params->{request} : '-1';
	if (defined $params->{submit}) {
		push @errors, 'You must select a request.' unless $selected =~ /\A\d+\z/;
		push @errors, 'No object found for identifier.'
			unless nb($params->{identifier}) && objectExistsByAny($params->{identifier});
		return updateRequest($params, $userinf) unless @errors;
	}

	my $options = getUnfilledReqs();
	return errorMessage('Request query failed!') unless $options;
	my @options = map {{value => $_, label => $options->{$_}}}
		sort {humanReadableCmp($options->{$a}, $options->{$b}) || $a cmp $b} keys %$options;
	return entryInteractionTemplate('updaterequest.tt', {
		options => \@options, selected => $selected, errors => \@errors,
		identifier => defined($params->{identifier}) ? $params->{identifier} : '',
	});
}

# return html for self-contained request updater widget
#
sub getRequestUpdater {
	my $params = shift;

	my $html = '';
	my $options = getUnfilledReqs();
	my $request = $params->{request}||-1;

	$html = 'Update filled status for: '.getSelectBoxSortByValue('request',$options,$request);

	return $html;
}

# return html for a self-contained request filler widget
#
sub getRequestFiller {
	my $params = shift;

	my $html = '';
	my $options = getUnfilledReqs();

	$html = getSelectBox('request', $options, $params->{request}||-1);

	return $html;
}

sub getUnfilledReqsEscaped {
	my %hash;

	my $table=getConfig('req_tbl');
	
	my ($rv,$sth)=dbSelect($dbh,{WHAT=>'uid,title',FROM=>$table,WHERE=>'fulfilled is null'});  #,'ORDER BY'=>'lower(title)'});
	# BEN ADDING rows returned
	#my $returned=$sth->rows();
	my @rows=dbGetRows($sth);
	#$sth->finish();

	$hash{"-1"}="[none]";	 # default entry

	foreach my $row (@rows) {
		$hash{$row->{uid}}=encode("UTF-8",$row->{title});
	}

	return {%hash};
}

# get a list of currently unfulfilled requests (as an id->title hash)
#
sub getUnfilledReqs {
	my %hash;

	my $table=getConfig('req_tbl');
	
	my ($rv,$sth)=dbSelect($dbh,{WHAT=>'uid,title',FROM=>$table,WHERE=>'fulfilled is null'});  #,'ORDER BY'=>'lower(title)'});
	return undef unless $rv && $sth;
	# BEN ADDING rows returned
	#my $returned=$sth->rows();
	my @rows=dbGetRows($sth);
	#$sth->finish();

	$hash{"-1"}="[none]";	 # default entry

	foreach my $row (@rows) {
		$hash{$row->{uid}}=$row->{title};
	}

	return {%hash};
}

# fill a request (add a link to fulfilling object)
#
#	this should be called for a fulfillment by the action of the creation of
#	a new object, NOT by the linking of an existing object to a request by a
#	third party (see updateRequest for that)
#
sub fillReq {
	my $rid = shift;
	my $userinf = shift;
	my $objtbl = shift;
	my $objid = shift;

	my $rtbl = getConfig('req_tbl');
	my $otbl = getConfig('olinks_tbl');

	# set request to filled
	#
	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>$rtbl,SET=>"fulfillerid=$userinf->{uid},fulfilled=CURRENT_TIMESTAMP", WHERE=>"uid=$rid"}); 
	
	# add a context link from request object to object which fills it
	#
	($rv,$sth) = dbInsert($dbh,{INTO=>$otbl,COLS=>'srctbl,srcid,desttbl,destid,note',VALUES=>"'$rtbl',$rid,'$objtbl',$objid,'fulfilling request'"});

	# send notices for this event
	#
	updateWatches($rtbl,		# request pointer
								$rid, 
				$objtbl,	# fulfilling object pointer
								$objid,
						$userinf->{uid},	# fulfilling user pointer
				'request set as fulfilled',
				'a new object was created');
	
	# add another watch for fulfiller (if allowed). this allows them to later
	# be notified when their fulfillment is accepted or rejected.
	#
	addWatchIfAllowed($rtbl, $rid, $userinf, 'reqfwatch');
}

# get a list of currently active requests
#
sub reqList {
	my $params = shift;
	my $userinf = shift;
	my $table = getConfig('req_tbl');
	my ($rv, $sth) = dbSelect($dbh, {
		WHAT => "$table.*, users.username",
		FROM => "$table, users",
		WHERE => "closed is null and users.uid = $table.creatorid",
		'ORDER BY' => 'created',
		DESC => '',
	});
	my @rows = dbGetRows($sth);
	my (@open_requests, @fulfilled_requests);

	foreach my $row (@rows) {
		my $request = {
			date => ymd($row->{created}),
			title => qhtmlescape($row->{title}),
			titlehref => getConfig('main_url')."/?op=getobj&amp;from=$table&amp;id=$row->{uid}",
			requester => qhtmlescape($row->{username}),
			requesterhref => getConfig('main_url')."/?op=getuser&amp;id=$row->{creatorid}",
			message_total => getmsgcount($table, $row->{uid}),
			message_unseen => count_unseen($table, $row->{uid}, $userinf->{uid}),
		};

		if (defined $row->{fulfilled}) {
			($rv, $sth) = dbSelect($dbh, {
				WHAT => 'username',
				FROM => 'users',
				WHERE => "uid=$row->{fulfillerid}",
			});
			my $urec = $sth->fetchrow_hashref();
			$sth->finish();
			$request->{filler} = qhtmlescape($urec->{username});
			$request->{fillerhref} = getConfig('main_url')."/?op=getuser&amp;id=$row->{fulfillerid}";
			push @fulfilled_requests, $request;
		} else {
			my $title = urlescape($row->{title});
			$request->{fillhref} = getConfig('main_url')."/?op=adden;request=$row->{uid};title=$title";
			$request->{updatehref} = getConfig('main_url')."/?op=updatereq;request=$row->{uid}";
			push @open_requests, $request;
		}
	}

	my $tt = Template->new({ INCLUDE_PATH => '/var/www/pp/stemplates' });
	my $html = '';
	my $vars = {
		open_requests => \@open_requests,
		fulfilled_requests => \@fulfilled_requests,
		open_total => scalar @open_requests,
		fulfilled_total => scalar @fulfilled_requests,
		admin => ($userinf->{data}->{access} >= getConfig('access_admin')) ? 1 : 0,
	};
	my $ret = $tt->process('reqlist.tt', $vars, \$html)
		|| die "Template process failed: ", $tt->error(), "\n";

	return $html;
}

# Retained only as a reference while installations move from the XSL template.
sub reqListLegacy {
		my $params = shift;
		my $userinf = shift;
		my $table = getConfig('req_tbl');
		my $template = new XSLTemplate('reqlist.xsl');
		my ($rv, $sth) = dbSelect($dbh, { WHAT => "$table.*, users.username",
																			FROM => "$table, users",
																			WHERE => "closed is null and users.uid = $table.creatorid",
																			'ORDER BY' => 'created',
																			DESC => '' });
		my @rows = dbGetRows($sth);
		my @rowsa;
		my @rowsb;

		foreach my $row (@rows) {
				if(defined $row->{fulfilled}) {
						push @rowsb, $row;
				} else {
						push @rowsa, $row;
				}
		}
		$template->addText("<requests>");
		foreach my $row (@rowsa, @rowsb) {
				my $date = ymd($row->{created});

				# <request>
				#		 [<fillhref>...</fillhref>]
				#		 [<updatehref>...</updatehref>]
				#		 <date>YYYY-MM-DD</date>
				#		 <title href="...">...</title>
				#		 <requester href="...">...</requester>
				#		 [<filler href="...">...</filler>]
				#		 [<messages [unseen="n"] total="n"/>]
				# </request>
				$template->addText("<request>\n");
				if(not defined($row->{fulfilled})) {
						my $title = urlescape($row->{title});

						$template->setKey('fillhref', getConfig("main_url")."/?op=adden;request=$row->{uid};title=$title");
						$template->setKey('updatehref', getConfig("main_url")."/?op=updatereq;request=$row->{uid}");
		}
				$template->addText("<date>$date</date>\n");
				$template->addText("<title>\n");
				$template->setKey('href', getConfig("main_url")."/?op=getobj;from=$table;id=$row->{uid}");
				$template->setKey('text', $row->{title});
				$template->addText("</title>\n");
				$template->addText("<requester>\n");
				$template->setKey('href', getConfig("main_url")."/?op=getuser;id=$row->{creatorid}");
				$template->setKey('text', $row->{username});
				$template->addText("</requester>\n");
				$template->addText(msgCountWithNewXML($table, $row->{uid}, $userinf->{uid}));
				if(defined($row->{fulfilled})) {
						($rv, $sth) = dbSelect($dbh, { WHAT => 'username',
																					 FROM => 'users',
																					 WHERE => "uid=$row->{fulfillerid}" });
						my $urec = $sth->fetchrow_hashref();

						$sth->finish();
						$template->addText("<filler>\n");
						$template->setKey('href', getConfig("main_url")."/?op=getuser;id=$row->{fulfillerid}");
						$template->setKey('text', $urec->{username});
						$template->addText("</filler>\n");
				}
				$template->addText("</request>\n");
		}
		$template->setKey('admin', '1') unless $userinf->{data}->{access} < getConfig('access_admin');
		$template->addText("</requests>\n");
		return $template->expand();
}

# get printed context links
#
sub printContextLinks {
	my $id = shift;	# request id

	my $html = '';
	my $table = getConfig('req_tbl');

		my ($rv,$sth) = dbSelect($dbh,{WHAT=>"destid,desttbl",FROM=>'objlinks',WHERE=>"srcid=$id and srctbl='$table'"});

	if ($sth->rows()>0) {
		my @rows = dbGetRows($sth);

		foreach my $link (@rows) {
			my $title = lookupfield($link->{desttbl},'title',"uid=$link->{destid}");
			$html .= "<a href=\"".getConfig("main_url")."/?op=getobj&amp;from=$link->{desttbl}&amp;id=$link->{destid}\">$title</a> "
		}
	}

	return $html;
}

# view a single request record
#
sub getReq {
	my $params = shift;
	my $userinf = shift;

	my $id = $params->{id};

	my $template = new TemplateNS('reqobj.html');

	my $html = '';
	my $table = getConfig('req_tbl');

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>"$table.*,username as createname",FROM=>"$table,users",WHERE=>"$table.uid=$id and users.uid=creatorid"});

	return errorMessage('Error with query') if (!$rv); 
	return errorMessage('Couldn\'t find record!') if ($sth->rows()<1);

	my $row = $sth->fetchrow_hashref();
	$sth->finish();

	my $status = "opened";
	my $filledflag = 0;
	
	if (defined $row->{fulfilled}) {
		$status = "filled (unconfirmed)";
	$filledflag = 1;
	}
	if (defined $row->{closed}) {
		$status = "filled (confirmed)";
	}

	$html .= "Request by: $row->{createname}<br>";
	$html .= "Date: $row->{created}<br>";
	$html .= "Status: $status<br>";
	if ($filledflag) {
		$html .= "Date: $row->{fulfilled}<br>";
	}
	
	$html .= "<br>Title: $row->{title}<br>";

	$html .= "<br>Text:<br>";
	
	$html .= "<table width=\"100%\" cellpadding=\"5\">";
	$html .= "	<tr>";
	$html .= "		<td bgcolor=\"#ffffff\">";
	my $text = tohtmlascii($row->{data});
	$html .= "		$text";
	$html .= "		</td>";
	$html .= "	</tr>";
	$html .= "</table>";

	# show context links
	#
	if ($filledflag) {
	my $clinks = printContextLinks($id);

	if ($clinks) {
		$html .= "<br>Context: ";
		$html .= "<table cellpadding=\"5\"><td>$clinks</td></table>";
	}
	}

	# admin controls 
	#
	if ($userinf->{'data'}->{'access'} >= getConfig('access_admin')
		&& (not defined $row->{'closed'})) {

		$html .= "<center><br>";
		$html .= "[ ";

		if (defined $row->{'fulfilled'}) {
			$html .= "<a href=\"".getConfig("main_url")."/?op=confirmreq&id=$params->{id}\">confirm</a> | ";
			$html .= "<a href=\"".getConfig("main_url")."/?op=denyreq&id=$params->{id}\">deny</a> | ";
		}

		$html .= "<a href=\"".getConfig("main_url")."/?op=deletereq&id=$params->{id}\">delete</a>";
		$html .= " ]";
		$html .= "</center>";
		$html .= "<br>";
	}

	my $interact=getReqInteract($row);
	
	my $up='';
	if ($filledflag && defined $row->{closed}) {
		$up=getUpArrow("".getConfig("main_url")."/?op=oldreqs",'up');
	} else {
		$up=getUpArrow("".getConfig("main_url")."/?op=reqlist",'up');
	}
	
	$template->setKey('request',makeBox("$up Viewing Request",$html));
	$template->setKey('interact',$interact);

	return $template;
}

1;
