package Noosphere;

###############################################################################
#
# Owners.pm
#
# Subroutines for handling the past owner log which each object has.
#
###############################################################################

use strict;

# update the owner log 
#
sub addLastOwner {
	my $from = shift;
	my $objectid = shift;
	my $userid = shift;
	my $event = shift;  # a = abandon, o = orphan, t = transfer

	my $table = getConfig('ownerlog_tbl');

	my $sth = $dbh->prepare("insert into $table (objectid, tbl, userid, action, ts) values (?, ?, ?, ?, now())");
	$sth->execute($objectid, $from, $userid, $event);

	$sth->finish();
}

# get the id and object loss action for the last owner
#
sub getLastData {
	my $from = shift;
	my $objectid = shift;

	my $table = getConfig('ownerlog_tbl');

	my $sth = $dbh->prepare("select userid, action from $table where tbl = ? and objectid = ? order by ts desc limit 1");
	$sth->execute($from, $objectid);

	return undef if !$sth->rows();

	my $row = $sth->fetchrow_arrayref();
	$sth->finish();

	my $username = lookupfield(getConfig('user_tbl'), 'username', "uid=$row->[0]");

	return ($row->[0], $username, $row->[1]);
}

# return 1/0 depending on whether there are past owners for an object
#
sub hasPastOwners {
	my $from = shift;
	my $objectid = shift;

	my $table = getConfig('ownerlog_tbl');

	my $sth = $dbh->prepare("select userid from $table where tbl = ? and objectid = ? order by ts desc");
	$sth->execute($from, $objectid);

	my $count = $sth->rows();
	$sth->finish();

	return $count;
}

# get a count of past owners
#
sub getPastOwnerCount {
	my $from = shift;
	my $objectid = shift;

	return hasPastOwners($from, $objectid);
}

# get a list of past owners (arrayref of hashes {userid, username, date, action})
#
sub getPastOwners {
	my $from = shift;
	my $objectid = shift;

	my $table = getConfig('ownerlog_tbl');

	my @list;

	my $sth = $dbh->prepare("select userid, ts, action from $table where tbl = ? and objectid = ? order by ts desc");
	$sth->execute($from, $objectid);

	while (my $row = $sth->fetchrow_hashref()) {
		
		my $date = ymd($row->{'ts'});
		my $username = lookupfield(getConfig('user_tbl'), 'username', "uid=$row->{userid}");

		push @list, {userid => $row->{'userid'}, 
			username => $username, 
			date => $date, 
			action => $row->{'action'}};
	}

	$sth->finish();

	return [@list];
}

# display the owner history for an object
#
sub showOwnerHistory {
	my $params = shift;
	my $userinf = shift;

	my $from = $params->{'from'};
	my $objectid = $params->{'id'};
	my $html_out = '';
	my @owners_array = ();
	my $tt_file = 'ownerhistory.tt';
	my $template = new XSLTemplate('ownerhistory.xsl');

	my $list = getPastOwners($from, $objectid);

	my $title = lookupfield(getConfig('index_tbl'), 'title', "objectid=$objectid and tbl=\"$from\"");

	$template->addText("<ownerhistory title=\"$title\" table=\"$from\" objectid=\"$objectid\">");

	foreach my $owner (@$list) {

		$template->addText('<owner>');
		push(@owners_array,{ 
				username 		=> $owner->{username},
				date 			=> $owner->{date},
				userid			=> $owner->{userid},
				action			=> $owner->{action},
		});

		foreach my $key (keys %$owner) {
			$template->setKey($key, $owner->{$key});
		}
		
		$template->addText('</owner>');
	}
	
	$template->addText('</ownerhistory>');

	my $vars = {
        	title       	=> $title,
			objectid		=> $objectid,
			table			=> $from,
			owners			=> \@owners_array,
    };

	my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
	my $ret = $tt->process($tt_file, $vars, \$html_out) || die "Template process failed: ", $tt->error(), "\n";

	#return $template->expand();
	return $html_out;
}




1;
