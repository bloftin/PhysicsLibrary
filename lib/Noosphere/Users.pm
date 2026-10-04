package Noosphere;
use strict;

# showUserActivity - display user list sorted by last access time.
#
sub showUserActivity {
	my $params = shift;
	my $userinf = shift;

	return loginExpired() if ($userinf->{'uid'} <= 0);
	
	my ($rv, $sth);
	($rv,$sth) = dbSelect($dbh,{WHAT=>'uid,username,last,EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP-last)) as idle', FROM=>'users', WHERE=>"last is not null and uid != $userinf->{uid}", 'ORDER BY'=>'last', LIMIT=>getConfig('useractivity_max'), DESC=>''})
		if getConfig('dbms') eq 'pg';
	($rv,$sth) = dbSelect($dbh,{WHAT=>'uid,username,last,unix_timestamp(now())-unix_timestamp(last) as idle', FROM=>'users', WHERE=>"last is not null and uid != $userinf->{uid}", 'ORDER BY'=>'last', LIMIT=>getConfig('useractivity_max'), DESC=>''})
		if getConfig('dbms') eq 'mysql';
	($rv,$sth) = dbSelect($dbh,{WHAT=>'uid,username,last,unix_timestamp(now())-unix_timestamp(last) as idle', FROM=>'users', WHERE=>"last is not null and uid != $userinf->{uid}", 'ORDER BY'=>'last', LIMIT=>getConfig('useractivity_max'), DESC=>''})
        if getConfig('dbms') eq 'MariaDB';

	return errorMessage('Could not load user activity.') unless $rv;
	my @rows = dbGetRows($sth);
	my @members;
	my $main = getConfig('main_url');
	foreach my $row (@rows) {
		my $idle = int($row->{'idle'} || 0);
		$idle = 0 if $idle < 0;
		my $d = int($idle / 86400);
		my $r = $idle % 86400;

		my $h = int($r / 3600);
		$r = $r % 3600;

		my $m = int($r / 60);
		my $s = $r % 60;

		my @idlearray;
		push @idlearray, $d.'d' if $d > 0;
		push @idlearray, $h.'h' if $h > 0;
		push @idlearray, $m.'m' if $m > 0;
		push @idlearray, $s.'s';

		my $idlestring = join (' ', @idlearray);
		my $id = int($row->{uid});
		push @members, {
			username => qhtmlescape($row->{username}),
			profile_url => "$main/?op=getuser&amp;id=$id",
			idle => $idlestring,
			last => qhtmlescape($row->{last}),
		};
	}

	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	my $html = '';
	$tt->process('useractivity.tt', { members => \@members }, \$html)
		|| die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

# userList - get a user list
#
sub userList {
	my $params = shift;
	my $userinf = shift;
	
	$params->{'sortby'} = $params->{'sortby'} || 'uid';

	#dwarn "*** userlist: sorting by $params->{sortby}";

	# info needed to organize/sort by columns
	#
	my %cols = (
		'uid' => {heading => 'user id', 
				sortsql => ['uid ASC', 'uid DESC'],
				order => 1,
				align => 'center'},
		'username' => {heading => 'username', 
				sortsql => ['lower(username) ASC', 'lower(username) DESC'],
				order => 2,
				align => 'left'},
		'score' => {heading => 'score',
				sortsql => ['score DESC', 'score ASC'],
				order => 3,
				align => 'center'},
		'entries' => {heading => 'entries',
				sortsql => ['entries DESC', 'entries ASC'],
				order => 4,
				align => 'center'},
		'productivity' => {heading => 'productivity',
				sortsql => ['productivity DESC', 'productivity ASC'],
				order => 5,
				align => 'center'},
		'consistency' => {heading => 'consistency', 
				sortsql => ['consistency DESC', 'consistency ASC'],
				order => 6, 
				align => 'center'}, 
		'joined' => {heading => 'joined on',
				sortsql => ['joined ASC', 'joined DESC'],
				order => 7,
				align => 'center'}
			);

	my $limit = $userinf->{prefs}->{pagelength} || getConfig('listings_page');

	# get total if we don't have one
	#
	if (not defined $params->{total}) {
		my ($rv, $sth)=dbSelect($dbh,{WHAT=>'uid,username,joined,score', FROM=>'users', WHERE=>'uid > 0'});
		return errorMessage('Could not load user list.') unless $rv;
		$params->{total}=$sth->rows();
		$sth->finish();
	}

	my $sortkey = urlunescape($params->{'sortby'});
	$sortkey = 'uid' unless exists $cols{$sortkey};
	$params->{'offset'} = 0 unless defined $params->{'offset'} && $params->{'offset'} =~ /^\d+$/;
	$params->{'total'} = 0 unless defined $params->{'total'} && $params->{'total'} =~ /^\d+$/;
	$params->{'offset'} = 0 if $params->{'offset'} >= $params->{'total'};

	my ($rv, $sth);

	my $sortidx = (defined $params->{'sortidx'} && $params->{'sortidx'} =~ /^[01]$/ ? $params->{'sortidx'} : 0);
	my $sortstmt = $cols{$sortkey}->{'sortsql'}->[$sortidx];
	
	($rv, $sth) = dbSelect($dbh,{WHAT=>'users.uid,
		users.username,
		users.joined,
		users.score,
		users.score/(date_part(\'days\',now()-users.joined)+1) as productivity,
		2/(1/(users.score/(date_part(\'days\',now()-users.joined)+1)+1)+1/(date_part(\'days\',now()-users.joined)+1)) as consistency, 
		sum(objects.uid IS NOT NULL) as entries', FROM=>'users left outer join objects ON objects.userid = users.uid', WHERE=>'users.uid > 0', 'GROUP BY' => 'users.uid', 'ORDER BY'=>$sortstmt, OFFSET=>$params->{'offset'}, LIMIT=>$limit}) if getConfig('dbms') eq 'pg';
	
	($rv, $sth) = dbSelect($dbh,{WHAT=>'users.uid,
		users.username,
		users.joined,
		users.score,
		users.score/(round((unix_timestamp(now())-unix_timestamp(users.joined))/86400)+1) as productivity, 
		2/(1/(users.score/(round((unix_timestamp(now())-unix_timestamp(users.joined))/86400)+1)+1)+1/(round((unix_timestamp(now())-unix_timestamp(users.joined))/86400)+1)) as consistency, 
		sum(objects.uid is not null) as entries',
		FROM=>'users left outer join objects ON users.uid = objects.userid', WHERE=>'users.uid > 0', 'GROUP BY' => 'users.uid', 'ORDER BY'=>$sortstmt, OFFSET=>$params->{'offset'}, LIMIT=>$limit}) if getConfig('dbms') eq 'mysql';

	($rv, $sth) = dbSelect($dbh,{WHAT=>'users.uid,
        users.username,
        users.joined,                                                                                                           users.score,
        users.score/(round((unix_timestamp(now())-unix_timestamp(users.joined))/86400)+1) as productivity,
        2/(1/(users.score/(round((unix_timestamp(now())-unix_timestamp(users.joined))/86400)+1)+1)+1/(round((unix_timestamp(now())-unix_timestamp(users.joined))/86400)+1)) as consistency,                                                             sum(objects.uid is not null) as entries',
        FROM=>'users left outer join objects ON users.uid = objects.userid', WHERE=>'users.uid > 0', 'GROUP BY' => 'users.uid', 'ORDER BY'=>$sortstmt, OFFSET=>$params->{'offset'}, LIMIT=>$limit}) if getConfig('dbms') eq 'MariaDB';

	return errorMessage('Could not load user list.') unless $rv;
	my @rows = dbGetRows($sth);
	my $main_url = getConfig('main_url');
	my @columns;
	foreach my $key (sort { $cols{$a}->{order} <=> $cols{$b}->{order} } keys %cols) {
		my $selected = $key eq $sortkey;
		my $next_idx = $selected ? ($sortidx + 1) % 2 : 0;
		push @columns, {
			key => $key,
			label => $cols{$key}->{heading},
			url => "$main_url/?op=userlist&amp;sortby=$key&amp;sortidx=$next_idx",
			selected => $selected,
			direction => $selected && $sortstmt =~ / DESC$/ ? 'descending' : 'ascending',
		};
	}
	my @members;
	my $number = $params->{'offset'} + 1;
	foreach my $row (@rows) {
		my $uid = int($row->{uid});
		push @members, {
			number => $number++,
			uid => $uid,
			username => qhtmlescape($row->{username}),
			profile_url => "$main_url/?op=getuser&amp;id=$uid",
			score => qhtmlescape($row->{score}),
			entries => qhtmlescape($row->{entries}),
			productivity => sprintf('%.2f', $row->{productivity} || 0),
			consistency => sprintf('%.2f', $row->{consistency} || 0),
			joined => qhtmlescape(ymd($row->{joined})),
		};
	}
	my %pager_params = (
		op => 'userlist', sortby => $sortkey, sortidx => $sortidx,
		offset => $params->{'offset'}, total => $params->{'total'},
	);
	my $pager = getPager(\%pager_params, $userinf);
	$pager =~ s/items/people/g;
	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	my $html = '';
	$tt->process('userlist.tt', {
		columns => \@columns, members => \@members, total => $params->{'total'},
		first => @members ? $params->{'offset'} + 1 : 0,
		last => @members ? $params->{'offset'} + scalar(@members) : 0,
		pager => $pager,
	}, \$html) || die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

1;
