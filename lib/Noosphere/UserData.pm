package Noosphere;

use strict;
use Socket;
use Template;
use Encode;

# a settings "main menu" screen.  enables us to unload things from the userbox.
#
sub getSettings {
	my $params = shift;
	my $userinf = shift;

	my $template = new XSLTemplate('settings.xsl');
	
	$template->addText('<settings>');

	$template->setKey('id', $userinf->{'uid'});

	$template->addText('</settings>');

	return $template->expand();

}

# return 1 if the user is active, 0 if account is deactivated (by user name)
#
sub isUserActive {
	my $username = shift;

	my $val = lookupfield(getConfig('user_tbl'), 'active', "username='$username'");

	return $val;
}

# markUserAccess - mark a user as having accessed Noosphere at the current time
#
sub markUserAccess {
	my $uid = shift;
	my $ip = shift;

	my $sth = $dbh->prepare("update users set last = CURRENT_TIMESTAMP, lastip=? where uid=$uid");
	$sth->execute($ip);
	$sth->finish();
}

# changeUserScore - change a user's score. keeps score table updated.
#
sub changeUserScore {
	my $id = shift;
	my $delta = shift;
 
	# TODO - we need a transaction here for updating both rows at the same time
	#
	my ($rv,$sth)=dbUpdate($dbh,{WHAT=>'users',SET=>"score=score+$delta",WHERE=>"uid=$id"});
	$sth->finish();
	($rv,$sth)=dbInsert($dbh,{INTO=>'score',COLS=>'userid,delta',VALUES=>"$id,$delta"});
	$sth->finish();

	# invalidate top user statistics
	#
	$stats->invalidate('topusers');
}

# user object edit list
# 
sub userEditObjectList {
	
	my $params = shift;
	my $userinf = shift;

	dwarn "Enter userEditObjectList!!!!!!!!!!!!\n";
	my $tt_file = 'usereditobjlist.tt'; 
	my $template = new XSLTemplate("usereditobjlist.xsl");
	
	my $html = '';
	my $html_pager = '';
	my $offset = $params->{'offset'} || 0;
	my $total = $params->{'total'} || -1;
	my $scale = 1;
	my $limit = $userinf->{'prefs'}->{'pagelength'};
	my $uid = $userinf->{'uid'};
	my $table = getConfig('index_tbl');
	my $en = getConfig('en_tbl');
	my @objects_array = ();

	# basic object selection filter: object owner
	#
	my $filter = "userid = $uid";

	# build object selection filters for "exotic" ACL criterion
	#
	if ($params->{'qtype'} eq 'coauthor' || $params->{'qtype'} eq 'world') {
		my $sth;
		if ($params->{'qtype'} eq 'coauthor') {

			my $glist = join(', ', getMemberGroupIDs($uid));
			
			my $gq = $glist ? "or (subjectid in ($glist) and user_or_group = 'g')" : "";

			# build object id retrieval query
			#
			$sth = $dbh->prepare("select tbl, objectid from acl where _write = 1 and default_or_normal = 'n' and ((subjectid = $uid and user_or_group = 'u') $gq)");
		} 
		elsif ($params->{'qtype'} eq 'world') {

			# build world-editable object id retrieval query
			$sth = $dbh->prepare("select tbl, objectid from acl where (_write = 1 and default_or_normal = 'd')");
		}
		
		$sth->execute();

		my %lists;

		while (my $row = $sth->fetchrow_hashref()) {
			if (exists $lists{$row->{'tbl'}}) {
				push @{$lists{$row->{'tbl'}}}, $row->{'objectid'};
			} else {
				$lists{$row->{'tbl'}} = [$row->{'objectid'}];
			}
		}

		$sth->finish();

		# build filter clause of the form 
		# (
		#  (tbl = 'foo' and objectid in (1, 2, ...)) or 
		#  (tbl = 'bar' and objectid in (3, 4, ...)) or
		#   ...
		# )
		#
		$filter = "(".join(' or ', (map "(tbl = '$_' and objectid in (".join(', ', @{$lists{$_}})."))", keys %lists)).")";
	}

	# this is kind of a hack for when there are no matching objects
	$filter = 0 if ($filter eq '()');

	# get total
	# 
	my ($rv,$sth) = dbLowLevelSelect($dbh,"select userid from $table where $filter and tbl != 'users' and type = 1");
	$total = $sth->rows();
	$sth->finish();
	
	# query up the data
	#
	($rv,$sth) = dbLowLevelSelect($dbh,"select title, objectid, tbl, userid from $table where $filter tbl != 'users' and type = 1 order by lower(title) offset $offset limit $limit")
		if (getConfig('dbms') eq 'pg');
	($rv,$sth) = dbLowLevelSelect($dbh,"select title, objectid, tbl, userid from $table where $filter and tbl != 'users' and type = 1 order by lower(title) limit $offset, $limit")
		if (getConfig('dbms') eq 'mysql');
	($rv,$sth) = dbLowLevelSelect($dbh,"select title, objectid, tbl, userid from $table where $filter and tbl != 'users' and type = 1 order by lower(title) limit $offset, $limit")
        if (getConfig('dbms') eq 'MariaDB');

	if (not defined $rv) {
		dwarn "error getting objects for user $uid";
		return errorMessage("Error with object query. contact an admin.");
	}

	# get the rows
	# 
	my @rows = dbGetRows($sth);

	# gather in additional data from the individual tables
	#
	dbGather(\@rows, 'tbl', 'objectid', 
		{
		 getConfig('exp_tbl') => {'select'=>'created', 'idfield'=>'uid'}, 
		 getConfig('books_tbl') => {'select'=>'created', 'idfield'=>'uid'},
		 getConfig('papers_tbl') => {'select'=>'created', 'idfield'=>'uid'}, 
		 getConfig('en_tbl') => {'select'=>'created, type as etype', 'idfield'=>'uid'}, 
	});
	 
	$template->addText("<usereditobjs qtype=\"$params->{qtype}\">");

	if (scalar @rows > 0) {
		
		my $ord = 1;

		foreach my $row (@rows) {
			my $date = ymd($row->{'created'});
			
			$template->addText("<object date=\"$date\"");

			$template->addText(" ord=\"$ord\"");
			$template->addText(" id=\"$row->{objectid}\"");
			$template->addText(" table=\"$row->{tbl}\"");

			$template->addText(" edithref=\"".getConfig("main_url")."/?op=edit;from=$row->{tbl};id=$row->{objectid}\""); 
			$template->addText(" aclhref=\"".getConfig("main_url")."/?op=acledit;from=$row->{tbl};id=$row->{objectid}\""); 

			if ($row->{'tbl'} eq $en) {
				$template->addText(" historyhref=\"".getConfig("main_url")."/?op=vbrowser;from=$row->{tbl};id=$row->{objectid}\""); 
				$template->addText(" linkhref=\"".getConfig("main_url")."/?op=linkpolicy;from=$row->{tbl};id=$row->{objectid}\""); 
		 	}

			$template->addText(" href=\"".getConfig("main_url")."/?op=getobj&amp;from=$row->{tbl}&amp;id=$row->{objectid}\""); 

			# There must be some bigger UTF8 issue going on, so temp fix
			my $title = encode("UTF-8",$row->{'title'});
			dwarn "tile: $title";
			$template->addText(" title=\"$title\""); 
			#$template->addText(" title=\"".qhtmlescape($row->{'title'})."\""); 

			# 	# find flags
		 	#
			my $flags = '';
			my $unclassified = (isclassified($row->{'tbl'},$row->{'objectid'}) ? '' : 'u');
			my $messages = (count_unseen($row->{'tbl'}, $row->{'objectid'}, $userinf->{'uid'}) > 0 ? 'm' : '');
			my $corrections = 0;

		 	if ($row->{'tbl'} eq $en) {
		 		$corrections = (hascorrections($row->{'tbl'},$row->{'objectid'}) ? 'c' : '');
		 	}

			$template->addText(" unclassified=\"1\"") if ($unclassified);
			$template->addText(" hasmessages=\"1\"") if ($messages);
			$template->addText(" hascorrections=\"1\"") if ($corrections);
			$template->addText(" isowner=\"1\"") if ($row->{'userid'} == $uid);

			$template->addText("/>\n");
			my $obj_url = getConfig("main_url")."/?op=getobj&amp;from=$row->{tbl}&amp;id=$row->{objectid}";
			my $edithref = getConfig("main_url")."/?op=edit;from=$row->{tbl};id=$row->{objectid}";
			my $aclhref = getConfig("main_url")."/?op=acledit;from=$row->{tbl};id=$row->{objectid}";
			my $linkhref = getConfig("main_url")."/?op=linkpolicy;from=$row->{tbl};id=$row->{objectid}";
			my $historyhref = getConfig("main_url")."/?op=vbrowser;from=$row->{tbl};id=$row->{objectid}";

			push(@objects_array,{ 
				title 		=> $title, 
				obj_url 	=> $obj_url, 
				date 		=> $date, 
				ord 		=> $ord, 
				id 			=> $row->{objectid}, 
				table 		=> $row->{tbl},
				edithref 	=> $edithref,
				aclhref  	=> $aclhref,
				linkhref    => $linkhref,
				historyhref	=> $historyhref,	
				 });

			$ord++;


		}
		
		$params->{'offset'} = $offset;
		$params->{'total'} = $total;

		#getPageWidgetXSLT($template, $params, $userinf);
		$html_pager = getPager($params, $userinf, $scale);
	}

	$template->addText("</usereditobjs>");

	dwarn "userEditObjectList end";
	my $template_txt = $template->{'TEXT'};
	dwarn "userEditObjectList template:\n $template_txt";

	my $vars = {
        	total       				=> $params->{'total'},
			objects						=> \@objects_array,
			pager						=> $html_pager,
    };

	my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
	my $ret = $tt->process($tt_file, $vars, \$html) || die "Template process failed: ", $tt->error(), "\n";

	return paddingTable(clearBox('Your Objects',$html));
}

sub userEditObjectListOld {
	
	my $params = shift;
	my $userinf = shift;
	
	dwarn "Enter userEditObjectList!!!!!!!!!!!!\n";

	my $template = new XSLTemplate("usereditobjlist.xsl");
	
	my $offset = $params->{'offset'} || 0;
	my $total = $params->{'total'} || -1;
	my $limit = $userinf->{'prefs'}->{'pagelength'};
	my $uid = $userinf->{'uid'};
	my $table = getConfig('index_tbl');
	my $en = getConfig('en_tbl');

	# basic object selection filter: object owner
	#
	my $filter = "userid = $uid";

	# build object selection filters for "exotic" ACL criterion
	#
	if ($params->{'qtype'} eq 'coauthor' || $params->{'qtype'} eq 'world') {
		my $sth;
		if ($params->{'qtype'} eq 'coauthor') {

			my $glist = join(', ', getMemberGroupIDs($uid));
			
			my $gq = $glist ? "or (subjectid in ($glist) and user_or_group = 'g')" : "";

			# build object id retrieval query
			#
			$sth = $dbh->prepare("select tbl, objectid from acl where _write = 1 and default_or_normal = 'n' and ((subjectid = $uid and user_or_group = 'u') $gq)");
		} 
		elsif ($params->{'qtype'} eq 'world') {

			# build world-editable object id retrieval query
			$sth = $dbh->prepare("select tbl, objectid from acl where (_write = 1 and default_or_normal = 'd')");
		}
		
		$sth->execute();

		my %lists;

		while (my $row = $sth->fetchrow_hashref()) {
			if (exists $lists{$row->{'tbl'}}) {
				push @{$lists{$row->{'tbl'}}}, $row->{'objectid'};
			} else {
				$lists{$row->{'tbl'}} = [$row->{'objectid'}];
			}
		}

		$sth->finish();

		# build filter clause of the form 
		# (
		#  (tbl = 'foo' and objectid in (1, 2, ...)) or 
		#  (tbl = 'bar' and objectid in (3, 4, ...)) or
		#   ...
		# )
		#
		$filter = "(".join(' or ', (map "(tbl = '$_' and objectid in (".join(', ', @{$lists{$_}})."))", keys %lists)).")";
	}

	# this is kind of a hack for when there are no matching objects
	$filter = 0 if ($filter eq '()');

	# get total
	# 
	my ($rv,$sth) = dbLowLevelSelect($dbh,"select userid from $table where $filter and tbl != 'users' and type = 1");
	$total = $sth->rows();
	$sth->finish();
	
	# query up the data
	#
	($rv,$sth) = dbLowLevelSelect($dbh,"select title, objectid, tbl, userid from $table where $filter tbl != 'users' and type = 1 order by lower(title) offset $offset limit $limit")
		if (getConfig('dbms') eq 'pg');
	($rv,$sth) = dbLowLevelSelect($dbh,"select title, objectid, tbl, userid from $table where $filter and tbl != 'users' and type = 1 order by lower(title) limit $offset, $limit")
		if (getConfig('dbms') eq 'mysql');
	($rv,$sth) = dbLowLevelSelect($dbh,"select title, objectid, tbl, userid from $table where $filter and tbl != 'users' and type = 1 order by lower(title) limit $offset, $limit")
        if (getConfig('dbms') eq 'MariaDB');

	if (not defined $rv) {
		dwarn "error getting objects for user $uid";
		return errorMessage("Error with object query. contact an admin.");
	}

	# get the rows
	# 
	my @rows = dbGetRows($sth);

	# gather in additional data from the individual tables
	#
	dbGather(\@rows, 'tbl', 'objectid', 
		{
		 getConfig('exp_tbl') => {'select'=>'created', 'idfield'=>'uid'}, 
		 getConfig('books_tbl') => {'select'=>'created', 'idfield'=>'uid'},
		 getConfig('papers_tbl') => {'select'=>'created', 'idfield'=>'uid'}, 
		 getConfig('en_tbl') => {'select'=>'created, type as etype', 'idfield'=>'uid'}, 
	});
	 
	$template->addText("<usereditobjs qtype=\"$params->{qtype}\">");

	if (scalar @rows > 0) {
		
		my $ord = 1;

		foreach my $row (@rows) {
			my $date = ymd($row->{'created'});
			$template->addText("<object date=\"$date\"");

			$template->addText(" ord=\"$ord\"");
			$template->addText(" id=\"$row->{objectid}\"");
			$template->addText(" table=\"$row->{tbl}\"");

			$template->addText(" edithref=\"".getConfig("main_url")."/?op=edit;from=$row->{tbl};id=$row->{objectid}\""); 
			$template->addText(" aclhref=\"".getConfig("main_url")."/?op=acledit;from=$row->{tbl};id=$row->{objectid}\""); 

			if ($row->{'tbl'} eq $en) {
				$template->addText(" historyhref=\"".getConfig("main_url")."/?op=vbrowser;from=$row->{tbl};id=$row->{objectid}\""); 
				$template->addText(" linkhref=\"".getConfig("main_url")."/?op=linkpolicy;from=$row->{tbl};id=$row->{objectid}\""); 
		 	}

			$template->addText(" href=\"".getConfig("main_url")."/?op=getobj&amp;from=$row->{tbl}&amp;id=$row->{objectid}\""); 

			# There must be some bigger UTF8 issue going on, so temp fix
			my $title = encode("UTF-8",$row->{'title'});
			dwarn "tile: $title";
			$template->addText(" title=\"$title\""); 
			#$template->addText(" title=\"".qhtmlescape($row->{'title'})."\""); 

			# 	# find flags
		 	#
			my $flags = '';
			my $unclassified = (isclassified($row->{'tbl'},$row->{'objectid'}) ? '' : 'u');
			my $messages = (count_unseen($row->{'tbl'}, $row->{'objectid'}, $userinf->{'uid'}) > 0 ? 'm' : '');
			my $corrections = 0;

		 	if ($row->{'tbl'} eq $en) {
		 		$corrections = (hascorrections($row->{'tbl'},$row->{'objectid'}) ? 'c' : '');
		 	}

			$template->addText(" unclassified=\"1\"") if ($unclassified);
			$template->addText(" hasmessages=\"1\"") if ($messages);
			$template->addText(" hascorrections=\"1\"") if ($corrections);
			$template->addText(" isowner=\"1\"") if ($row->{'userid'} == $uid);

			$template->addText("/>\n");
			
			$ord++;

		}
		
		$params->{'offset'} = $offset;
		$params->{'total'} = $total;

		getPageWidgetXSLT($template, $params, $userinf);
	}

	$template->addText("</usereditobjs>");

	dwarn "userEditObjectList end";
	my $template_txt = $template->{'TEXT'};
	dwarn "userEditObjectList template:\n $template_txt";

	return paddingTable(clearBox('Your Objects',$template->expand()));
}

# format a user's message record for list display
#
sub formatUserMessageRec {
	my ($rec, $ord) = @_;

	my $xml = '';
	
	my $title = qhtmlescape(lookupfield($rec->{tbl},'title',"uid=$rec->{objectid}"));
	my $date = ymd($rec->{created});
	
	$xml .= "		<series ord=\"$ord\"/>";
	$xml .= "		<message date=\"$date\" title=\"".qhtmlescape($rec->{subject})."\" href=\"".getConfig("main_url")."/?op=getmsg;id=$rec->{uid}\"/>";
	$xml .= "		<object title=\"$title\" href=\"".getConfig("main_url")."/?op=getobj;from=$rec->{tbl};id=$rec->{objectid}\"/>";

	return $xml;
}

# format a user's object record for a list display
#
sub formatUserObjectRec {
	my ($rec, $ord) = @_;

	my $xml = '';
	
	$xml .= "		<series ord=\"$ord\"/>";
	$xml .= "		<object title=\"".qhtmlescape($rec->{title})."\" href=\"".getConfig("main_url")."/?op=getobj;from=$rec->{tbl};id=$rec->{objectid}\" table=\"$rec->{tbl}\"/>";

	return $xml;
}

sub formatUserCorrectionFiledRec { 
	my ($rec, $ord) = @_;
 
	my $xml = '';
	
	my $date = ymd($rec->{filed});
	my $title = lookupfield(getConfig('en_tbl'),'title',"uid=$rec->{objectid}");
	
	$xml .= "		<series ord=\"$ord\"/>";
	$xml .= "		<object title=\"".qhtmlescape($title)."\" href=\"".getConfig("main_url")."/?op=getobj;from=".getConfig('en_tbl').";id=$rec->{objectid}\"/>";
	$xml .= "		<correction date=\"$date\" title=\"".qhtmlescape($rec->{title})."\" href=\"".getConfig("main_url")."/?op=getobj;from=".getConfig('cor_tbl').";id=$rec->{uid}\"/>";
	
	return $xml;
}

sub formatUserCorrectionReceivedRec { 
	my ($rec, $ord) = @_;
 
	my $xml = '';
	
	my $date = ymd($rec->{filed});
	my $username = lookupfield(getConfig('user_tbl'),'username',"uid=$rec->{userid}");
	my $title = qhtmlescape(lookupfield(getConfig('en_tbl'),'title',"uid=$rec->{objectid}"));
	
	$xml .= "		<series ord=\"$ord\"/>";
	$xml .= "		<object title=\"$title\" href=\"".getConfig("main_url")."/?op=getobj;from=".getConfig('en_tbl').";id=$rec->{objectid}\"/>";
	$xml .= "		<correction date=\"$date\" title=\"".qhtmlescape($rec->{title})."\" href=\"".getConfig("main_url")."/?op=getobj;from=".getConfig('cor_tbl').";id=$rec->{uid}\"/>";
	$xml .= "		<user name=\"$username\" href=\"".getConfig("main_url")."/?op=getuser;id=$rec->{userid}\"/>";
	
	return $xml;
}

sub getCorrectionsReceivedCount {
	my $userid = shift;

	my ($rv,$sth) = dbLowLevelSelect($dbh,"select distinct corrections.uid from objindex, corrections where objindex.userid=$userid and objindex.tbl='".getConfig('en_tbl')."' and corrections.objectid=objindex.objectid");
	my $count = $sth->rows();
	$sth->finish();

	return $count;
}

sub getCorrectionsFiledCount {
	my $userid = shift;

	my ($rv,$sth) = dbLowLevelSelect($dbh, "select uid from corrections where userid=$userid");
	my $count = $sth->rows();
	$sth->finish();

	return $count;
}

# answer whether user has created any objects in the system
#
sub userCreatedObjects {
	my $userid = shift;

	my @statements = (
		# count messages
		"select uid from messages where messages.userid=$userid",
			# count primary objects
		"select userid from objindex where userid=$userid and tbl != 'users' and type = 1",
			# count corrections files
		"select uid from corrections where userid=$userid"
	),

	my $count = 0;

	# count all types of objects the user has created
	#
	foreach	my $statement (@statements) {
		my ($rv, $sth) = dbLowLevelSelect($dbh, $statement);
		$count += $sth->rows();
		$sth->finish();
	}
		
	return $count;
}

# a generic list of a user's objects
#
sub userGenericList {
	my $params = shift;
	my $userinf = shift;

	my $html_out = '';
	my @objects_array = ();
	my $op = $params->{op};
	my $offset = $params->{offset}||0;
	my $total = $params->{total}||-1;
	my $limit = $userinf->{'prefs'}->{'pagelength'};	
	my $uid = $params->{id};
	my $title = '';
	my $tt_file = 'usergeneric.tt';
 	my $template = new XSLTemplate("usergeneric.xsl");

	# database invariance (this is ugly)
	#
	my ($q_usermsgs, $q_userobjs, $q_usercorsf, $q_usercorsr);

	$q_usermsgs = "select messages.created, messages.objectid, messages.uid, messages.subject, messages.tbl from messages where messages.userid=$uid order by created desc limit $limit offset $offset" if getConfig('dbms') eq 'pg';
	$q_usermsgs = "select messages.created, messages.objectid, messages.uid, messages.subject, messages.tbl from messages where messages.userid=$uid order by created desc limit $offset, $limit" if getConfig('dbms') eq 'mysql';
	$q_usermsgs = "select messages.created, messages.objectid, messages.uid, messages.subject, messages.tbl from messages where messages.userid=$uid order by created desc limit $offset, $limit" if getConfig('dbms') eq 'MariaDB';

	$q_userobjs = "select objectid,title,tbl from ".getConfig('index_tbl')." where userid=$uid and tbl != 'users' and type = 1 order by lower(title) offset $offset limit $limit"  if getConfig('dbms') eq 'pg';
	$q_userobjs = "select objectid,title,tbl from ".getConfig('index_tbl')." where userid=$uid and tbl != 'users' and type = 1 order by lower(title) limit $offset, $limit"  if getConfig('dbms') eq 'mysql';
	$q_userobjs = "select objectid,title,tbl from ".getConfig('index_tbl')." where userid=$uid and tbl != 'users' and type = 1 order by lower(title) limit $offset, $limit"  if getConfig('dbms') eq 'MariaDB';

	$q_usercorsf = "select uid, objectid, filed, title from corrections where userid=$uid order by filed desc limit $limit offset $offset" if getConfig('dbms') eq 'pg';
	$q_usercorsf = "select uid, objectid, filed, title from corrections where userid=$uid order by filed desc limit $offset, $limit" if getConfig('dbms') eq 'mysql';
	$q_usercorsf = "select uid, objectid, filed, title from corrections where userid=$uid order by filed desc limit $offset, $limit" if getConfig('dbms') eq 'MariaDB';

	$q_usercorsr = "select distinct corrections.objectid, corrections.title, corrections.uid, corrections.userid, corrections.filed from objindex, corrections where objindex.userid=$uid and objindex.tbl='".getConfig('en_tbl')."' and corrections.objectid=objindex.objectid order by corrections.filed desc limit $limit offset $offset" if getConfig('dbms') eq 'pg';
	$q_usercorsr = "select distinct corrections.objectid, corrections.title, corrections.uid, corrections.userid, corrections.filed from objindex, corrections where objindex.userid=$uid and objindex.tbl='".getConfig('en_tbl')."' and corrections.objectid=objindex.objectid order by corrections.filed desc limit $offset, $limit" if getConfig('dbms') eq 'mysql';
	$q_usercorsr = "select distinct corrections.objectid, corrections.title, corrections.uid, corrections.userid, corrections.filed from objindex, corrections where objindex.userid=$uid and objindex.tbl='".getConfig('en_tbl')."' and corrections.objectid=objindex.objectid order by corrections.filed desc limit $offset, $limit" if getConfig('dbms') eq 'MariaDB';

	# structure holding the specifics
	#
	my $specifics = {
		'usermsgs'=>[
		"select uid from messages where messages.userid=$uid",
		$q_usermsgs,
		\&formatUserMessageRec
	 ],

	 'userobjs'=>[
		"select userid from objindex where userid=$uid and tbl != 'users' and type = 1",
		$q_userobjs,
		\&formatUserObjectRec
	 ],

	 'usercorsf'=>[
		"select uid from corrections where userid=$uid",
		$q_usercorsf,
		\&formatUserCorrectionFiledRec
	 ],

	 'usercorsr'=>[
		"select distinct corrections.uid from objindex, corrections where objindex.userid=$uid and objindex.tbl='".getConfig('en_tbl')."' and corrections.objectid=objindex.objectid",
		$q_usercorsr,
		\&formatUserCorrectionReceivedRec
	 ]
	};
	
	# get total if we're lacking it
	#
	if ($total < 0) {
		my ($rv,$sth) = dbLowLevelSelect($dbh,$specifics->{$op}->[0]);
		$total = $sth->rows();
		$sth->finish();
	}
	
	# actual retrieve the info
	#
	my ($rv,$sth) = dbLowLevelSelect($dbh,$specifics->{$op}->[1]);
	
	if (! $rv) {
		dwarn "error with query for user $uid";
		return errorMessage("error with query. contact an admin.");
	}

	my @rows = dbGetRows($sth);
 
	$params->{offset} = $offset;
	$params->{total} = $total;

	# print out the XML
	#
	$template->addText("<$op>");
	if ($#rows >= 0 ) {
	my $num = $offset+1;
	
		foreach my $row (@rows) {
			$template->addText("	<item_$op>");
			my $xml=&{$specifics->{$op}->[2]}($row,$num);
			$template->addText($xml);
			dwarn "adding [$xml] to template";
			#$template->addText(&{$specifics->{$op}->[2]}($row,$num));
			$template->addText("	</item_$op>");

			push(@objects_array,{ 
				title 		=> $row->{title}, 
				date		=> ymd($row->{'created'}),
				ord 		=> $num, 
				table 		=> $row->{tbl},	
				href		=> getConfig("main_url")."/?op=getobj;from=$row->{tbl};id=$row->{objectid}", 
			});
			
			$num++;
		}
	}
	$template->addText("</$op>");

	#getPageWidgetXSLT($template, $params, $userinf);
	my $factor = 1;
	my $html_pager = getPager($params, $userinf, $factor);

	# return $template->expand();
	my $vars = {
        	name       				=> 'name',
			objects					=> \@objects_array,
			pager					=> $html_pager,
			item_userobjs			=> "item_$op",
    };

	my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
	my $ret = $tt->process($tt_file, $vars, \$html_out) || die "Template process failed: ", $tt->error(), "\n";

	#return paddingTable($template->expand());
	return $html_out;
}


# edit prefs interface
#
sub editUserPrefs {
	my ($params, $user_info) = @_;
 
	my $content = new TemplateNS('editprefs.html');
	my $prefs = $user_info->{'prefs'};
	my $groupings = getConfig('prefs_groupings');
	my $inputs = '';
	my $html = '';

	if ($user_info->{uid} < 1 ) { return loginExpired(); }

	my $error = changePrefs($user_info->{uid},$params,$prefs);
	$content->setKeys('error' => $error, 'id' => $user_info->{"uid"});
	$user_info->{prefs} = getUserPrefs($user_info->{'uid'});
	$prefs = $user_info->{prefs};
 
	foreach my $group (@$groupings) {
		my $groupname = $group->[0];

		$inputs .= "<tr><td bgcolor=\"#eeeeee\">";
		$inputs .= "<font size=\"+1\">$groupname</font>";
		$inputs .= "</td></tr>";

		$inputs .= "<tr><td><br />";
		$inputs .= "<table align=\"center\">";
		foreach my $key (@{$group->[1]}) {
			my ($widget,$desc) = getPrefsWidget($user_info,$key);
			if ($widget ne '') {
				$inputs .= "<tr><td>$desc:</td><td align=\"center\">$widget</td></tr>";
			}
		}
		$inputs .= "</table>";
		$inputs .= "<br/></td></tr>";
	}
	$content->setKey('inputs', $inputs);
 
	$html = makeBox("Edit Preferences for <b>".$user_info->{'data'}->{'username'}."</b>",$content->expand()); 

	return paddingTable($html); 
}

# the user data editor (data other than prefs)
# 
sub editUserData {
 my ($params, $user_info) = @_;
 
 my $content = new TemplateNS('edituser.html');
 my $data = $user_info->{'data'};
 my $html = '';

 if ($user_info->{uid} == -1 ) { return loginExpired(); }

 my $error = changeUserData($params,$data);
 $content->setKeys('error' => $error, 'id' => $user_info->{"uid"});
 $data = $user_info->{"data"} = getUserData($user_info->{"uid"});
 $content->setKeys(%$data);
 
 $html = makeBox("Edit User Info for <b>".$data->{'username'}."</b>",$content->expand()); 
 return paddingTable($html); 
}

# the user prefs editor
# 
sub changePrefs {
	my $uid = shift;
	my $params = shift;
	my $prefs = shift;
	my $changed = '';
	my $message = '';		# error message to return, "" is no error
	
	# see if we submitted any changes at all
	#
	if (not defined($params->{submit})) { return ""; };
	
	# go through and look for changed fields
	#
	foreach my $key (keys %$prefs) {
		if (not defined($params->{$key})) {
		if ($prefs->{$key} eq "on") {
			$changed="$changed $key";
		$prefs->{$key}="off";
		}
	} else {
		if ($params->{$key} ne $prefs->{$key}) {
				$changed="$changed $key";
			$prefs->{$key}=$params->{$key};
 		}
		}
	}

	# handle changes
	#
	if ($changed eq "") {
		$message .= "No changes";
	} else {
		# message here is for debug purposes, we might want to take it out
		$message .= "changed $changed";
	
		# do the database update
		setUserPrefs($uid,$prefs);
	}
	
	return $message;			
}

# make sure user data is vaild
#
sub checkUserData {
	my $params = shift;

	my $error = "";

	if (not ($params->{email} =~ /^\s*[\w.\-]+@[\w.\-]+\s*$/)) {
		$error .= "Need a valid e-mail address!<br>";
	}

	return $error;
}

sub changeUserData {
	my $params = shift;
	my $data = shift;
	my $changed = 0;
	my $message = "";		# error message to return, "" is no error
	my @keys = (keys %$params);
	my @fields = ();
	
	# see if we are submitting any fields for changing, if not, just exit
	#
	if ($#keys == 0) {
		return $message;
	}

	# go through and look for changed fields
	#
	for my $key (@keys) {
		$params->{$key}='' if (not defined $params->{$key}); # no NULL fields

		if (exists $data->{$key} && ($params->{$key} ne $data->{$key})) {
			$changed=1;
			push @fields,$key;
		}
	}

	# handle changes
	#
	if ($changed == 0) {
		$message.="No changes";
	} else {

		my $error = checkUserData($params);

		if ($error eq '') {
			$message .= 'changed';
			my $set = '';
			foreach my $field (@fields) {
				$message .= " $field";
				$set .= "$field=\'".sq($params->{$field})."\',";
			}
			$set =~ s/,$//;	 # kill trailing ,
	
			#dwarn $set;
		
			# do the database update
			(my $rv,my $sth) = dbUpdate($dbh,{WHAT => 'users',
			SET => $set,
			WHERE => 'uid='.$data->{'uid'}});
			$sth->finish();
		}

		# there was an error, can't accept changes
		#
		else {
			$message = $error;
		}
	}
	
	return $message;			
}

# a wrapper to expand the template returned by the getUser sub.
#
sub getUser_wrapper {
	my $params = shift;
	my $userinf = shift;

	my $template = getUser($params, $userinf);

	return $template;
}

# getUser - get/display a user's info
#
sub getUser {
	my $params = shift;
	my $userinf = shift;

	dwarn "getUser start";
	my $id = $params->{id};
	my $htmlout = '';

	my $isadmin = ($userinf->{data}->{access} >= getConfig('access_admin'));
	my $loggedin = ($userinf->{uid} > 0);
	my $loggedinvalue = $userinf->{uid};
	dwarn "logged in: $loggedinvalue";

	# extract info
	#
	(my $rv, my $sth) = dbSelect($dbh,{WHAT => '*', 
									FROM => 'users',
									WHERE => "users.uid=$id"});

	my $rec = $sth->fetchrow_hashref();	

	my $mc = getrowcount('messages',"userid=$rec->{uid}");
	my $msg_link = "".getConfig("main_url")."/?op=usermsgs;id=$rec->{uid}";
	my $oc = getrowcount(getConfig('index_tbl'),"userid=$rec->{uid} and type = 1 and tbl != 'users'");
	my $obj_link = "".getConfig("main_url")."/?op=userobjs;id=$rec->{uid}";
	my $crc = getCorrectionsReceivedCount($rec->{uid});
	my $crc_link = "".getConfig("main_url")."/?op=usercorsr;id=$rec->{uid}";
	my $cfc = getCorrectionsFiledCount($rec->{uid});
	my $cfc_link = "".getConfig("main_url")."/?op=usercorsf;id=$rec->{uid}";
	my $uname = urlescape($rec->{'username'});
	my $pmail = getConfig("main_url")."/?op=sendmail&amp;sendto=$uname";
	
	my $file = 'dispuser.tt';

	my $vars = {
        userID        => $id,
		isadmin       => $isadmin,
		loggedin      => $loggedin,
		parsePrefs    => \&parsePrefs,
		mc            => $mc,
		oc            => $oc,
		crc           => $crc,
		cfc           => $cfc,
		pmail         => $pmail,
		msg_link      => $msg_link,
		obj_link      => $obj_link,
		crc_link      => $crc_link,
		cfc_link      => $cfc_link,
		my_dbh_ref    => $dbh,
    };

    my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
    my $ret = $tt->process($file, $vars, \$htmlout) || die "Template process failed: ", $tt->error(), "\n";
	dwarn "template html:\n$htmlout\nreturn value:\n$ret";
	dwarn "getUser end";
    return $htmlout;

}
sub getUserOld {
	my $params = shift;
	my $userinf = shift;
	
	my $id = $params->{id};
	my $html = '';

	my $isadmin = ($userinf->{data}->{access} >= getConfig('access_admin'));
	my $loggedin = ($userinf->{uid} > 0);
	
	my $template = new XSLTemplate('dispuser.xsl');

	(my $rv, my $sth) = dbSelect($dbh,{WHAT => '*', 
									FROM => 'users',
									WHERE => "users.uid=$id"});


	if (! $rv) {
		$template->addText("<nouser>1</nouser>");
		return $template;
	}

	my $rec = $sth->fetchrow_hashref();	
	my $prefs = parsePrefs($rec->{prefs});
	
	my %basicinfo;
	foreach my $key (keys %$rec) {
		my $val = $rec->{$key};
		if ($key eq "homepage" && nb($val)) { $val=~/^http:\/\// or $val="http://$val"; }
		if ($key eq "email" && 
			$prefs->{hideemail} eq 'on' && 
			$userinf->{uid} != $id &&
			$userinf->{data}->{access} < getConfig('access_seehiddenemail')) { $val="[hidden]"; } 

		$basicinfo{$key} = $val;
	}

	my $iaddr = inet_aton($basicinfo{'lastip'});
	$basicinfo{'hostname'} = gethostbyaddr($iaddr,Socket::AF_INET());

	# extract info
	#
	my $mc = getrowcount('messages',"userid=$rec->{uid}");
	my $oc = getrowcount(getConfig('index_tbl'),"userid=$rec->{uid} and type = 1 and tbl != 'users'");
	my $crc = getCorrectionsReceivedCount($rec->{uid});
	my $cfc = getCorrectionsFiledCount($rec->{uid});
	my $uname = urlescape($rec->{'username'});
	my $pmail = getConfig("main_url")."/?op=sendmail&amp;sendto=$uname";

	# get group-add info
	#
	my $groups = {};
	if ($userinf->{uid} > 0) {
		$groups = getAdminGroupHash($userinf->{uid});
		subtractUserFromGroupHash($id, $groups);
	}

	# output XML for user record
	#
	$template->addText("<user adminview=\"$isadmin\" loggedin=\"$loggedin\" active=\"$rec->{active}\">");
	$template->addText("	<username>".htmlescape($rec->{username})."</username>");
	$template->addText("	<counts>");
	$template->addText("		 <item label=\"messages\" count=\"$mc\" href=\"".getConfig("main_url")."/?op=usermsgs;id=$rec->{uid}\"/>");
	$template->addText("		 <item label=\"objects\" count=\"$oc\" href=\"".getConfig("main_url")."/?op=userobjs;id=$rec->{uid}\"/>");
	$template->addText("		 <item label=\"corrections filed\" count=\"$cfc\" href=\"".getConfig("main_url")."/?op=usercorsf;id=$rec->{uid}\"/>");
	$template->addText("		 <item label=\"corrections received\" count=\"$crc\" href=\"".getConfig("main_url")."/?op=usercorsr;id=$rec->{uid}\"/>");
	$template->addText("	</counts>");
	$template->addText("	<bio>".htmlcheck($rec->{'bio'})."</bio>");
	$template->addText("	<mailurl>$pmail</mailurl>");
	foreach my $key (keys %basicinfo) {
		if ($key ne 'bio') {
			$template->addText("	<$key>".htmlescape($basicinfo{$key})."</$key>");
		}
	}

	foreach my $gid (keys %$groups) {
		$template->addText("	<addablegroup name=\"$groups->{$gid}\" id=\"$gid\"/>");
	}
	$template->addText("</user>");
 
	return $template;
}

# getUserData - grab user data from database to hash
#
sub getUserData {
	my $uid = shift;
 
	#dwarn "uid is $uid!!!";
	
	my ($rv,$dbq) = dbSelect($dbh,{
	 WHAT => '*',
	 FROM => 'users',
	 WHERE => qq|uid='$uid'|});
	
	my $data = $dbq->fetchrow_hashref();
	$dbq->finish();
 
	return $data; 
}

# get a partial user info line from an ID
# 
sub userInfoById {
	my $userid = shift;

	my %user_info;
 
	$user_info{'uid'} = $userid;
	$user_info{'data'} = getUserData($user_info{'uid'});
	$user_info{'prefs'} = parsePrefs($user_info{'data'}->{'prefs'});

	return %user_info;
}

# get the value of a user's preference for some key
#
sub userPref {
	my $userid = shift;
	my $key = shift;

	my %userinf = userInfoById($userid);

	return $userinf{'prefs'}->{$key};
} 

# look up user fields by id. (pass in uid,field1,field2,...)
#	 
sub _userfields_by_id {
	my $uid = shift;
	my @fields = shift;
	
	(my $rv, my $sth) = dbSelect($dbh,
		{WHAT => join(',',@fields), 
		 FROM => 'users', 
		 WHERE => "uid = $uid"}
		); 

	my $row = $sth->fetchrow_hashref(); 
	
	$sth->finish(); 
	
	return $row; 
}

# parse user prefs data -- includes filling in defaults.
#
sub parsePrefs {
	my $raw = shift;
 
	my %prefs;
	my $defaults = getConfig('prefs_schema');

	# split the string into a hash
	#
	foreach my $keyval (split(/;/,$raw)) {
		my ($key,$val) = split(/=/,$keyval);
		$prefs{$key} = $val;
	}

	# fill in missing fields from defaults.
	#
	foreach my $key (keys %$defaults) {
		if (not defined($prefs{$key})) {
			my $prefarray = $defaults->{$key};
			$prefs{$key} = $prefarray->[2];
		}		
	}
 
	# return a hashref
	#
	return {%prefs};
}


1;
