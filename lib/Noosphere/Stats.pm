package Noosphere;
#use strict;

use Noosphere::StatCache;

# get count of unproven theorems
#
sub unprovenCount {
	my $en = getConfig('en_tbl');
	my ($rv, $sth) = dbLowLevelSelect($dbh, "select o1.uid from $en as o1 left outer join $en as o2 on (o1.uid=o2.parentid and o2.type=".PROOF.") where o1.type=".THEOREM." and (o1.self is NULL or o1.self = 0) and o2.uid is NULL");
	my $total = $sth->rows();
	$sth->finish();

	return $total;
}

# getUnprovenTheorems - returns a hash containing all theorem objects that
# do not have any proof objects attached to them
#
sub getUnprovenTheorems
{
		my $en = getConfig('en_tbl');
		my ($rv, $sth) = dbLowLevelSelect($dbh, "select o1.* from $en as o1 left outer join $en as o2 on (o1.uid=o2.parentid and o2.type=".PROOF.") where o1.type=".THEOREM." and (o1.self is NULL or o1.self = 0) and o2.uid is NULL");
	my @rows = dbGetRows($sth);
		my $theorems = {};

		foreach my $row (@rows) {
			$theorems->{$row->{'uid'}} = $row;
		}
		return $theorems;
}

# unprovenTheorems - lists theorems that have not yet been proven
#
sub unprovenTheorems {
	my ($params, $userinf) = @_;

	my $limit = $userinf->{'prefs'}->{'pagelength'};
	my $offset = $params->{'offset'} || 0;

	my $unpts = getUnprovenTheorems();
	my %bytitle;
	my @titles;
	my $html = "";

	foreach my $uid (keys(%$unpts)) {
		my $i = "";
		my $title = $unpts->{$uid}->{title};

		$i++ while $bytitle{"$title$i"};
		push @titles, "$title$i";
		$bytitle{"$title$i"} = $uid;
	}

	@titles = sort { humanReadableCmp($a, $b); } @titles;
	my $total = scalar @titles;

	my $template = new XSLTemplate('unproven.xsl');

	$template->addText('<unprovenlist>');

	for (my $i = 0; $i < $limit && $offset + $i < scalar @titles; $i++) {
		my $row = $unpts->{$bytitle{$titles[$i + $offset]}};
		my $uenct = urlescape($row->{'title'});

		my $ord = $offset + $i + 1;
		my $ourl = getConfig("main_url")."/?op=getobj&amp;from=objects&amp;id=$row->{uid}";
		my $purl = getConfig("main_url")."/?op=adden&amp;request=$row->{uid}&amp;title=proof+of+$uenct&amp;type=Proof&amp;parent=$row->{name}";

		my $mathtitle = mathTitleXSL($row->{'title'}, 'highlight');

		$template->addText("	<item>");
		$template->addText("		<series ord=\"$ord\"/>");
		$template->addText("		<object href=\"$ourl\"/>");
		$template->addText("		<prove href=\"$purl\"/>");
		$template->addText("		<title>$mathtitle</title>");
		#$template->addText("		<user name=\"".qhtmlescape($row->{'username'})."\" href=\"".getConfig("main_url")."/?op=getuser;id=$row->{userid}\"/>");
		$template->addText("	</item>");

		$ord++;
	}

	$template->addText('</unprovenlist>');

	$params->{'total'} = $total;
	$params->{'offset'} = $offset;

	getPageWidgetXSLT($template, $params, $userinf);

	return $template->expand();
}


# show hit statistics
#
sub getHitInfo {
	my $params = shift;

	my $periods = [
		['total',"<=CURRENT_TIMESTAMP"],
		['last day',">CURRENT_TIMESTAMP+'-1 day'"],
		['last week',">CURRENT_TIMESTAMP+'-1 week'"],
		['last month',">CURRENT_TIMESTAMP+'-1 month'"],
		['last year',">CURRENT_TIMESTAMP+'-1 year'"]
	];
	
	my $html="";

	$html .= "<table align=\"center\" cellpadding=\"5\" cellspacing=\"0\">";
	$html .= "<tr bgcolor=\"#eeeeee\">";
	$html .= "<td>&nbsp;</td>";
	$html .= "<td>hits</td>";
	$html .= "</tr>";
	foreach my $period (@$periods) {
		my $tid = tableid($params->{'from'});

		$html .= "<tr>"; 
		$html .= "<td bgcolor=\"#eeeeee\">$period->[0]</td>";
		my $cnt = dbRowCount(getConfig('hit_tbl'),"objectid=$params->{id} and tblid=$tid and at$period->[1]");
		$html .= "<td align=\"center\">$cnt</td>";
		$html .= "</tr>";
	}
	$html .= "</table>";

	my $title = lookupfield($params->{from},'title',"uid=$params->{id}");
	return paddingTable(clearBox("Access Stats for '$title'",$html));
}

# get a count of unclassified objects
#
sub unclassifiedCount {
	my ($rv,$sth) = dbLowLevelSelect($dbh,"select distinct o.uid from objects as o left outer join classification as c on (o.uid=c.objectid) where c.objectid is null");
	my $total = $sth->rows();
	
	$sth->finish();

	return $total;
}

# get a list of unclassified objects
#
sub unclassifiedObjects {
	my $params = shift;
	my $userinf = shift;

	my $template = new XSLTemplate("unclassified.xsl");

	# init paging
	my $total = $params->{'total'} || -1;
	my $offset = $params->{'offset'} || 0;		
	my $limit = $userinf->{'prefs'}->{'pagelength'};

	# get total
	#
	if ($total == -1) {
		$total = unclassifiedCount();
	}
	
	# grab the data
	#
	my ($rv, $sth);
	($rv,$sth) = dbLowLevelSelect($dbh,"select distinct o.title, lower(o.title), o.uid, o.userid, u.username from users as u, objects as o left outer join classification as c on (o.uid=c.objectid) where c.objectid is null and u.uid=o.userid order by lower(o.title) limit $limit offset $offset")
		if (getConfig('dbms') eq 'pg');
	($rv,$sth) = dbLowLevelSelect($dbh,"select distinct o.title, lower(o.title), o.uid, o.userid, u.username from users as u, objects as o left outer join classification as c on (o.uid=c.objectid) where c.objectid is null and u.uid=o.userid order by lower(o.title) limit $offset, $limit")
		if (getConfig('dbms') eq 'mysql');

	($rv,$sth) = dbLowLevelSelect($dbh,"select distinct o.title, lower(o.title), o.uid, o.userid, u.username from users as u, objects as o left outer join classification as c on (o.uid=c.objectid) where c.objectid is null and u.uid=o.userid order by lower(o.title) limit $offset, $limit")
        if (getConfig('dbms') eq 'MariaDB');

	#my $total = $sth->rows();
	$template->addText("<unclassifiedlist>");
	
	my $ord = $offset + 1;
	while (my $row = $sth->fetchrow_hashref()) {
		my $mathtitle = mathTitleXSL($row->{'title'}, 'highlight');

		$template->addText("	<item>");
		$template->addText("		<series ord=\"$ord\"/>");
		#$template->addText("		<object title=\"".qhtmlescape($row->{'title'})."\" href=\"".getConfig("main_url")."/?op=getobj;from=".getConfig('en_tbl').";id=$row->{uid}\"/>");
		$template->addText("		<object href=\"".getConfig("main_url")."/?op=getobj;from=".getConfig('en_tbl').";id=$row->{uid}\"/>");
		$template->addText("		<title>$mathtitle</title>");
		$template->addText("		<user name=\"".qhtmlescape($row->{'username'})."\" href=\"".getConfig("main_url")."/?op=getuser;id=$row->{userid}\"/>");
		$template->addText("	</item>");

		$ord++;
	}
	$sth->finish();
	
	$template->addText("</unclassifiedlist>");
	
	$params->{'offset'} = $offset;
	$params->{'total'} = $total;

	getPageWidgetXSLT($template, $params, $userinf);
	
	return $template->expand();
}


# hitObject - add a hit for an object
#
sub hitObject { 
	my $objectid = shift;# uid of object
	my $table = shift;	 # table object is in
	my $field = shift;	 # field to increment in object (optional)

	#TODO: we need a transaction to both increment field and add to 
	# hits table at the same time

	# add to hits table
	#
	my $tid = tableid($table);
	my ($rv,$sth) = dbInsert($dbh,{
		INTO => 'hits',
		COLS => 'objectid,tblid',
		VALUES => "$objectid,$tid"});

	$sth->finish();
 
	# increment hit count in the object (we dont *really* need this, but it
	# saves us from doing a possibly huge summation over a huge table later)
	# 
	if (defined $field) {
		($rv,$sth) = dbUpdate($dbh,{
		 WHAT=>$table,
		 SET=>'hits=hits+1',
		 WHERE=>"uid=$objectid"});
		 
		 $sth->finish();
	}
}

# getSystemStats - get the system stats page
#
sub getSystemStats {
	my $html = '';
	my $periods;
	
	$periods = [
		['total',"<=CURRENT_TIMESTAMP"],
		['last day',">CURRENT_TIMESTAMP+'-1 day'"],
		['last week',">CURRENT_TIMESTAMP+'-1 week'"],
		['last month',">CURRENT_TIMESTAMP+'-1 month'"],
		['last year',">CURRENT_TIMESTAMP+'-1 year'"]
	] if getConfig('dbms') eq 'pg';

	$periods = [
		['total',"<= now()"],
		['last day',">now() - interval 1 DAY"],
		['last week',">now() - interval 7 DAY"],
		['last month',">now() - interval 30 DAY"],
		['last year',">now() - interval 365 DAY"]
	] if getConfig('dbms') eq 'mysql';
	
	$periods = [
        ['total',"<= now()"],                                                                                                   ['last day',">now() - interval 1 DAY"],                                                                                 ['last week',">now() - interval 7 DAY"],                                                                                ['last month',">now() - interval 30 DAY"],
        ['last year',">now() - interval 365 DAY"]
    ] if getConfig('dbms') eq 'MariaDB';

	my $timefields = {
		'objects'=>'created',
		'users'=>'joined',
		'corrections'=>'filed',
		'messages'=>'created',
		'hits'=>'at'
	};

	$html .= "<table align=\"center\" cellpadding=\"5\" cellspacing=\"0\">";
	$html .= "<tr bgcolor=\"#eeeeee\">";
	$html .= "<td>&nbsp;</td>";
	foreach my $table (keys %$timefields) {
		$html .= "<td>$table</td>";
	}
	$html .= "</tr>";
	foreach my $period (@$periods) {
		$html .= "<tr>"; 
		$html .= "<td bgcolor=\"#eeeeee\">$period->[0]</td>";
		foreach my $lookup (keys %$timefields) {
			my $cnt = dbRowCount($lookup,"$timefields->{$lookup}$period->[1]");
			$html .= "<td align=\"center\">$cnt</td>";
		}
		$html .= "</tr>";
	}
	$html .= "</table>";

	$html .= "<center>";

	my $uptime = `/usr/bin/uptime`;
	$uptime =~ /up ([0-9]+ [a-z]+),/;
	$html .= "<br>System uptime : $1<br><br>";

	$html .= "</center>";

	return paddingTable(clearBox(getConfig('projname').' Stats',$html));
}

# getTopUsers - get the top users box that shows top users by score
#
sub getTopUsers {
        #dwarn "getTopUsers!!!!!!!!!!!!!!!!!!!!!";
	# grab the cached statistics
	#
	#my $topusers = $stats->get('topusers');
        my $topusers = $stats->get('topusers');
	# BEN TESTING
	#my $topusers = getTopUsers();
	# TODO - redo this all with XML and XSLT

	my $topa = '';
	my $topw = '';

	# do top users of all time 
	#
	my $rows = $topusers->{'toparows'};
 
	if (@$rows) {
		$topa .= "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">";
		foreach my $row (@$rows) {
                        #dwarn "ROW ++++++";
			if ($row->{'uid'} > 0) {
				$topa .= "<tr>";

				$topa .= "<td align=\"left\"><font size=\"-1\">";
				$topa .= "<a href=\"".getConfig("main_url")."/?op=getuser&id=".$row->{'uid'}."\">".$row->{'username'}."</a>";
				$topa .= "</font></td>";
				$topa .= "<td align=\"right\"><font size=\"-1\">".$row->{'score'}."</font></td>";
				$topa .= "</tr>";
			}
		}
		$topa .= "</table>";
	} else {
		$topa = "<font size=\"-1\">No data.";
	}

	# do top users of the past 2 weeks
	#
	$rows = $topusers->{'topwrows'};

	if (@$rows) {
		$topw .= "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">";
		foreach my $row (@$rows) {

			if ($row->{uid} > 0 && $row->{sum} > 0) {
				$topw .= "<tr>";

				$topw .= "<td align=\"left\"><font size=\"-1\">";
				$topw .= "<a href=\"".getConfig("main_url")."/?op=getuser&id=".$row->{'uid'}."\">".$row->{'username'}."</a>";
				$topw .= "</font></td>";
				$topw .= "<td align=\"right\"><font size=\"-1\">".$row->{'sum'}."</font></td>";
				$topw .= "</tr>";
			}
		}
		$topw .= "</table>";
	} else {
		$topw = "<font size=\"-1\">No data.";
	}

	$topa .= "</font>";
	$topw .= "</font>";

	my $template = new Template("topusers.html");

	$template->setKeys('alltime' => $topa, 'twoweeks' => $topw);

	return clearBox("Top Users", $template->expand()); 
}

# grab the data needed to print top users statistics.	returns a hashref to two
#	arrayrefs
#
sub getTopUsers_callback {
	#dwarn "Top User STATS *************";
        my $limita = getConfig('topusers_alltime');
	my $limitw = getConfig('topusers_2weeks');
 
	(my $rv, my $sth) = dbSelect($dbh,{WHAT => 'username,uid,score',
		 FROM => 'users',
		 'ORDER BY' => 'score',
		 'DESC' => '',
		 LIMIT => $limita});

	if (! $rv) {
		dwarn "no users found for top users statistics!\n";
	return [];
	}

	my $where;
	$where = "score.userid=users.uid and occured>(CURRENT_TIMESTAMP+'-2 weeks')" if getConfig('dbms') eq 'pg';
	$where = "score.userid=users.uid and occured>now()-interval 14 DAY" if getConfig('dbms') eq 'mysql';
	$where = "score.userid=users.uid and occured>now()-interval 14 DAY" if getConfig('dbms') eq 'MariaDB';

	my ($rv2, $sth2) = dbSelect($dbh,{WHAT => 'sum(score.delta) as sum,users.username,users.uid',
		FROM => 'score,users',
		WHERE => $where,
		'ORDER BY'=> 'sum',
		'GROUP BY'=> 'users.username,users.uid',
		DESC => '',
		LIMIT => $limitw});
	
	my @toparows = dbGetRows($sth);
 
	my @topwrows = dbGetRows($sth2);

	return {toparows=>[@toparows], topwrows=>[@topwrows]}; 
}

# get and prepare the data for the latest additions/modifications marquee
#
# this returns a structure of the form:
# 
# [ 
#	{dateheader1 => [
#		{objtitle1 => url},
#		{objtitle2 => url},
#		{objtitle3 => url},
#				... ]
#	},
#	{dateheader2 => [
#		{objtitle1 => url},
#		{objtitle2 => url},
#		{objtitle3 => url},
#				... ]
#	},
#	...
# ]
# 
sub getLatest_data {
	my $type = shift || 'additions';

	my $limit = getConfig('latest_additions');
	if ($type ne 'additions') {
		$limit = getConfig('latest_revisions');
	}
	my $html = '';

	my $datefield = ($type eq 'additions') ? 'created' : 'modified';

	my ($rv, $sth);
	
	($rv, $sth) = dbSelect($dbh,{WHAT=>"uid,name,title,date_part('dow',$datefield) as dow, date_part('year',$datefield)||'-'||date_part('month',$datefield)||'-'||date_part('day', $datefield) as ymd", FROM=>getConfig('en_tbl'), 'ORDER BY'=>$datefield, DESC=>'', WHERE=>($type eq 'modifications' ? 'modified > created' : ''), LIMIT=>$limit})
		if getConfig('dbms') eq 'pg';

	($rv, $sth) = dbSelect($dbh,{WHAT=>"uid,name,title,dayofweek($datefield)-1 as dow, concat(extract(YEAR from $datefield), '-', extract(MONTH from $datefield), '-', extract(DAY from $datefield)) as ymd", FROM=>getConfig('en_tbl'), 'ORDER BY'=>$datefield, DESC=>'', WHERE=>($type eq 'modifications' ? 'modified > created' : ''), LIMIT=>$limit})
		if getConfig('dbms') eq 'mysql';
	
	($rv, $sth) = dbSelect($dbh,{WHAT=>"uid,name,title,dayofweek($datefield)-1 as dow, concat(extract(YEAR from $datefield), '-', extract(MONTH from $datefield), '-', extract(DAY from $datefield)) as ymd", FROM=>getConfig('en_tbl'), 'ORDER BY'=>$datefield, DESC=>'', WHERE=>($type eq 'modifications' ? 'modified > created' : ''), LIMIT=>$limit})
        if getConfig('dbms') eq 'MariaDB';

	if (! $rv) {
		dwarn "latest $type query error\n";
		return "query error";
	}
 
	my @rows = dbGetRows($sth);

	my @daystruct;
	
	my $date = '';
	my $daylist;

	foreach my $row (@rows) {

		# create a day list
		#
		my $day = dowtoa($row->{dow},'long');
		if ($row->{ymd} ne $date) {
			$date = $row->{ymd};
			my $dateheader = "$day, $date";
			$daylist = [];
			push @daystruct, {$dateheader => $daylist};
		}

		# create the new object entry and add to list for this day
		# 
		my $url = "/encyclopedia/$row->{name}.html";
		my $title = $row->{title};

		push @$daylist, {$title => $url};
	}

	# return a ref to the statistics
	return [@daystruct];
}

# pass-throughs to call the above for either modifications or additions
#
sub getLatestAdditions_data {
	return getLatest_data('additions');
}
sub getLatestModifications_data {
	return getLatest_data('modifications');
}

# format and output the data from above for either additions or modifications
#
sub getLatest {
	my $type = shift || 'additions';

	my $limit = getConfig('latest_additions');
	if ($type ne 'additions') {
		$limit = getConfig('latest_revisions');
	}
	my $html = '';

	my $statkey = ($type eq 'additions' ? 'latestadds' : 'latestmods');
	my $latestadds = $stats->get($statkey);
	
	my $date = '';
	my $table = '';
	foreach my $daylist (@$latestadds) {
		my ($day) = keys %$daylist;
	
		$table .= "<tr><td bgcolor=\"#ffffff\"><font size=\"-2\">";
		$table .= "<center><font color=\"#888888\"><i>$day</i></font></center>";
		$table .= "</font></td></tr>";

		my ($items) = $daylist->{$day};

		foreach my $item (@$items) {
	 
			my ($title) = keys %$item;
			my $url = $item->{$title};

			$table .= "<tr><td><font size=\"-2\">";
			$table .= "<div class=\"tickeritem\">";
			$table .= "[&nbsp;<a href=\"$url\">".mathTitle($title, 'highlight')."</a>&nbsp;]";
			$table .= "</div>";
			$table .= "</font></td></tr>";
		}
	}

	if ($table) {
		$html .= "<table width=\"100%\" cellpadding=\"\" cellspacing=\"0\">$table";
		$html .= "</table>";
	} else {
		$html .= "<font size=\"-1\">No data.</a>";
	}

	my $title = ($type eq 'additions' ? 'Latest Additions' : 'Latest Revisions');
	
	return clearBox($title ,$html);
}

# pass-throughs to call the above for either additions or modifications
#
sub getLatestAdditions {
	return getLatest('additions');
}
sub getLatestModifications {
	return getLatest('modifications');
}

1;

