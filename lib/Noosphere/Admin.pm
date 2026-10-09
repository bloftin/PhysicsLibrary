package Noosphere;
use strict;
use Template;
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;

use Noosphere::IR;
use Noosphere::Ticket;

# take a collab and add it as a site doc
#
sub addSiteDoc {
	my $params = shift;
	my $userinf = shift;
	
	return loginExpired() if ($userinf->{'uid'} <= 0);
	
	return errorMessage("You don't have access to that function") if ($userinf->{data}->{access} < getConfig('access_admin'));

	# process an addition
	#
	if (defined $params->{'id'}) {
		
		my $collab = getConfig('collab_tbl');

		# set site doc flag
		#
		my $sth = $dbh->prepare("update $collab set sitedoc = 1 where uid = $params->{id}");
		$sth->execute();
		$sth->finish();

		# update ACL to ensure world-writeable flag
		#
		my $acl = getConfig('acl_tbl');
		$sth = $dbh->prepare("update acl set _write = 1 where tbl='$collab' and objectid = $params->{id} and default_or_normal = 'd'");
		$sth->execute();
		$sth->finish();
	}

	my $template = new XSLTemplate('addsitedoc.xsl');

	$template->addText('<addsitedoc>');

	$template->addText("	<loggedin>1</loggedin>") if $userinf->{'uid'} > 0;

	my $collab = getConfig('collab_tbl');

	# get the intersection of the above list of IDs and the collaborations
	# that are site docs
	#
	#dwarn "getCollabObjList before";
	my $xml = getCollabObjList($userinf, "sitedoc = 0 and published = 1");
	#dwarn "getCollabObjList after";
	$template->addText($xml);

	$template->addText('</addsitedoc>');

	return $template->expand();
}


# admin score editing function
#
sub editScore {
	my $params = shift;
	my $userinf = shift;

	my $html = '';
	my $error = '';

	return loginExpired() if ($userinf->{'uid'} <= 0);
	
	return errorMessage("You don't have access to that function") if ($userinf->{data}->{access} < getConfig('access_admin'));

	my $user = $params->{'user'} || '';
	my $delta = $params->{'delta'} || '';

	# process submission 
	#
	if (defined $params->{'submit'}) {
		
		if ($user && $delta) {
			my $userid = 0;

			# try to resolve the user
			#
			if ($user !~ /^\s*(\d+)\s*$/) {
				my $uid = lookupfield(getConfig('user_tbl'), 'userid', "username='$user'");	

				$error .= "Could not find user '$user'!<br/>" if (not defined $uid);
			} else {
				$userid = $1;
			}

			# look up the user and process score
			#
			if ($userid) {
				
				if (lookupfield(getConfig('user_tbl'), 'username', "uid=$userid")) {
					# do the score delta
					#
					changeUserScore($userid, $delta);

					my $root = getConfig('web_root');
					return paddingTable(makeBox('Changed score', "Changed the score for user $userid.  <p/> Quick links: <p/> 
	<ul>
		<li>Go to the user's <a href=\"$root/?op=getuser&amp;id=$userid\">info page</a></li>
	</ul>"));

				} else {
					$error .= "Could not resolve the user with id $userid!<br/>";
				}

			} 

		} else {
			$error .= "Need a user id or name!<br/>" if (!$user);
			$error .= "Need a score delta!<br/>" if (!$delta);
		}
	}

	$html .= "<table cellpadding=\"2\" border=\"0\" width=\"100%\"><tr><td>";

	# show error
	#
	if ($error) {
		$html .= "<center>";
		$html .= "<font size=\"+1\" color=\"#ff0000\">";
		$html .= $error;
		$html .= "</font>";
		$html .= "</center>";
		$html .= "<br/>";
	}
	
	# show form
	#
	$html .= "<form action=\"".getConfig('web_root')."\" method=\"post\">";
	$html .= "User name or id: <br/>";
	$html .= "<input type=\"text\" name=\"user\" value=\"$user\" size=\"30\"/>";
	$html .= "<br/><br/>";
	$html .= "Score delta (+/- #): <br/>";
	$html .= "<input type=\"text\" name=\"delta\" value=\"$delta\" size=\"10\"/>";
	$html .= "<center>";
	$html .= "<input type=\"submit\" name=\"submit\" value=\"change\"/>";
	$html .= "</center>";
	$html .= "</form>";

	$html .= "</td></tr></table>";

	return paddingTable(makeBox('Change User Score', $html));
}

# the admin email blacklist editor
#
sub blacklistEditor {
	my $params = shift;
	my $userinf = shift;

	my $feedback = '';

	return loginExpired() if ($userinf->{uid} <= 0);
	
	return noAccess() if ($userinf->{data}->{access} < getConfig('access_admin'));

	# handle deletions/updates
	#
	foreach my $key (keys %$params) {

		if ($key =~ /^delete_(\d+)$/) {

			my $id = $1;
			my $mask = lookupfield(getConfig('blist_tbl'), 'mask', "uid=$id");

			my ($rv, $sth) = dbDelete($dbh, {FROM=>getConfig('blist_tbl'), WHERE=>"uid=$id"});
			$sth->finish();

			$feedback = "Mask '".$mask."' deleted.";
				
		}
		elsif ($key =~ /^update_(\d+)$/) {
			my $id = $1;

			my $oldmask = lookupfield(getConfig('blist_tbl'), 'mask', "uid=$id");
			my $newmask = $params->{"mask_$id"};

			my $sth = $dbh->prepare("update ".getConfig('blist_tbl')." set mask=? where uid=$id");
			my $rv = $sth->execute($params->{"mask_$id"});

			$sth->finish();

			$feedback = "Record $id modified.";
			$feedback = "Mask '".$oldmask."' changed to '".$newmask."'.";
		}
	}

	# add a record
	#
	if ($params->{'add'}) {

		my $tbl = getConfig('blist_tbl');
		my $nextid = nextval($tbl.'_uid_seq');
		my $sth = $dbh->prepare("insert into $tbl (uid, mask) values (?, ?)");
		$sth->execute($nextid, $params->{'new_mask'});

		$sth->finish();

		$feedback = "Mask '".$params->{'new_mask'}."' added.";
	}

	my ($rv, $sth) = dbSelect($dbh, {WHAT => '*', FROM => getConfig('blist_tbl'), 'ORDER BY' => 'uid'});
	return errorMessage('Blacklist query failed.') unless $rv && $sth;
	my @rows = dbGetRows($sth);
	return entryInteractionTemplate('adminblacklist.tt', {rows => \@rows, feedback => $feedback});
}


# reactivate a user. allows them to log in again.
#
sub reactivate {
	my $params = shift;
	my $userinf = shift;

	my $utbl = getConfig('user_tbl');

	return loginExpired() if ($userinf->{uid} <= 0);
	return errorMessage('Invalid account.') unless defined($params->{id}) && !ref($params->{id}) && $params->{id} =~ /\A[1-9][0-9]*\z/;
	
	my $isadmin = ($userinf->{data}->{access}>=getConfig('access_admin'));
	
	if (!$isadmin) {
		return errorMessage("Only admins can reactivate users.");
	}
 
	if (($params->{ask} || '') eq "yes") {
		return requestFormConfirmation({%$params, op => 'reactivate'}, requestFormToken($userinf));
	}

	if (!objectExistsByUid($params->{id},$utbl)) {
		return errorMessage("User doesn't exist! Something might be broken.");
	}

	# change the "active" flag.
	#
	return errorMessage('Could not update account. Please try again.')
        unless eval { setAccountActive($params->{id}, 1) };

	return requestFormComplete('reactivate', $params);
}

# deactivate a user. this just prevents them from ever logging in.
#
sub deactivate {
	my $params = shift;
	my $userinf = shift;

	my $utbl = getConfig('user_tbl');

	return loginExpired() if ($userinf->{uid} <= 0);
	return errorMessage('Invalid account.') unless defined($params->{id}) && !ref($params->{id}) && $params->{id} =~ /\A[1-9][0-9]*\z/;
	
	my $isadmin = ($userinf->{data}->{access}>=getConfig('access_admin'));
	
	if (!$isadmin) {
		return errorMessage("Only admins can deactivate users.");
	}
 
	if (($params->{ask} || '') eq "yes") {
		return requestFormConfirmation({%$params, op => 'deactivate'}, requestFormToken($userinf));
	}

	if (!objectExistsByUid($params->{id},$utbl)) {
		return errorMessage("User doesn't exist! Something might be broken.");
	}

	# change the "active" flag.
	#
	return errorMessage('Could not update account. Please try again.')
        unless eval { setAccountActive($params->{id}, 0) };

	return requestFormComplete('deactivate', $params);
}

# delete a user
#
sub delUser {
	my $params = shift;
	my $userinf = shift;

	my $utbl = getConfig('user_tbl');

	return loginExpired() if ($userinf->{uid} <= 0);
	
	my $isadmin = ($userinf->{data}->{access}>=getConfig('access_admin'));
	
	if (!$isadmin) {
		return errorMessage("You can't delete other people!");
	}
 
	if (($params->{ask} || '') eq "yes") {
		return requestFormConfirmation({%$params, op => 'deluser'}, requestFormToken($userinf));
	}

	if (!objectExistsByUid($params->{id},$utbl)) {
		return errorMessage("User doesn't exist! Something might be broken.");
	}

	# handle situation where a user has created some objects
	#
	if (userCreatedObjects($params->{id})) {

		return errorMessage("User has created objects! Deleting will put the system in an inconsistent state.	Please <a href=\"".getConfig('main_url')."/?op=deactivate&id=$params->{id}&ask=yes\">deactive</a> the account instead.");
	}

	my $rv;
	
	# generic row delete
	#
	$rv = delrows($utbl,"uid=$params->{id}");

	# delete the user's watches
	#
	delUserWatches($params->{'id'});

	# delete the user's ACL stuff
	#
	deleteUserDefaultACL($params->{'id'});

	# delete from object index
	# 
	deleteTitle($utbl,$params->{'id'});
		
	# delete from search engine
	#
	irUnindex($params->{'from'}, $params->{'id'});

	return requestFormComplete('deluser', $params);
}

# cache control - ability to selectively invalidated cache groups
#
sub cacheControl {
	my $params = shift;
	my $userinf = shift;
	return noAccess() if ($userinf->{data}->{access} < getConfig('access_admin'));
	my $group = $params->{group} || '';
	my %vars = (group => $group, title => 'Cache Control', feedback => '');
	if ($group eq 'stats') {
		if ($params->{invalidate}) {
			$stats->invalidate($params->{key});
			$vars{feedback} = "Invalidated key $params->{key}";
		}
		my ($rv, $sth) = dbSelect($dbh, {WHAT => '_key, valid, lastupdate', FROM => getConfig('storage_tbl')});
		return errorMessage('Cache query failed.') unless $rv && $sth;
		my @rows = dbGetRows($sth);
		for my $row (@rows) {
			$row->{key} = $row->{_key};
			$row->{date} = makeDate($row->{lastupdate}, 1);
		}
		$vars{rows} = \@rows;
		$vars{title} .= ' : Statistics';
		$vars{edit_url} = entryInteractionURL('dbadmin', freeform => 1, query => 'select * from '.getConfig('storage_tbl'));
	} elsif ($group eq 'en') {
		my $scale = 1/2;
		my $method = $params->{method} || getDefaultRenderMethod();
		$method = getDefaultRenderMethod() unless inset($method, getMethods());
		my $offset = defined($params->{offset}) && $params->{offset} =~ /\A\d+\z/ ? int($params->{offset}) : 0;
		my $pagelength = $userinf->{prefs}->{pagelength};
		$pagelength = 20 unless defined($pagelength) && $pagelength =~ /\A[1-9]\d*\z/;
		my $limit = int($pagelength / $scale);
		my $total = getrowcount(getConfig('cache_tbl'), "method='$method'");
		if ($params->{invalidate}) {
			setbuildflag_off($params->{from}, $params->{id}, $method);
			setvalidflag_off($params->{from}, $params->{id}, $method);
			my $title = lookupfield($params->{from}, 'title', "uid=$params->{id}");
			$vars{feedback} = "Invalidated entry '$title'";
		}
		my $cache = getConfig('cache_tbl');
		my $en = getConfig('en_tbl');
		my $sql = "select e.title, c.* from $en as e,$cache as c where e.uid=c.objectid and c.method='$method' order by lower(e.title)";
		$sql .= getConfig('dbms') eq 'pg' ? " offset $offset limit $limit" : " limit $offset, $limit";
		my ($rv, $sth) = dbLowLevelSelect($dbh, $sql);
		return errorMessage('Cache query failed.') unless $rv && $sth;
		my @rows = dbGetRows($sth);
		for my $row (@rows) {
			$row->{date} = mdhm($row->{touched});
			$row->{url} = entryInteractionURL('getobj', from => $row->{tbl}, id => $row->{objectid});
		}
		$params->{total} = $total;
		my @methods = map {{value => $_, label => getConfig('prefs_schema')->{method}->[3]->{$_}}} getMethods();
		%vars = (%vars, rows => \@rows, method => $method, methods => \@methods, offset => $offset,
			pager => getPager({op => 'cachecont', group => 'en', method => $method, offset => $offset, total => $total},
				{%$userinf, prefs => {%{$userinf->{prefs}}, pagelength => $pagelength}}, $scale));
		$vars{title} .= ' : Encyclopedia Entries';
	} elsif ($group eq 'files') {
		$vars{title} .= ' : Files';
	}
	return entryInteractionTemplate('admincache.tt', \%vars);
}

# database admin interface (really this is a slightly specialized web version 
#	of a query client)
#
sub dbAdmin {
	my $params = shift;
	my $userinf = shift;

	my $history_max = 15;

	return noAccess() if ($userinf->{data}->{access} < getConfig('access_admin'));
	
	my $output = '';
	my $rv = 0;		 # query return value
	my $table = ''; # table for select query
	my $legacy_oid = getConfig('dbms') eq 'pg';
	local $dbh->{RaiseError} = 0;
	local $dbh->{PrintError} = 0;
	my @tables = sort { $a cmp $b } dbGetTables($dbh);

	my $query = $params->{query} || '';

	# update query history 
	#
	my @history = map { urlunescape($_); } split(/;/, ($params->{qhist} || ''));
	if (nb($query)) {
		splice @history, 0, 0, $query;	# "push" onto front latest entry
	}
	if (scalar @history > $history_max) {	# remove overfill entries
		my $over = scalar @history - $history_max;
		splice @history, scalar @history - $over, $over;
	}
	my $firstval = scalar @history > 0 ? $history[0] : '';
	my $newqhist = join(';', map { urlescape($_); } @history);

	# process a query
	#
	my @resultset = ();		 # result row set

	# process schema query 
	#
	if ($params->{'schema'}) {
		if (!defined($params->{table}) || !grep { $_ eq $params->{table} } @tables) {
			$output = '<p class="pl-admin-error">Unknown table.</p>';
		} else {
			my ($cols, $indices) = dbGetSchema($dbh, $params->{table});
			if (!$cols || !$indices) {
				$output = '<p class="pl-admin-error">'.requestFormEscape($dbh->errstr || 'Schema query failed.').'</p>';
			} else {
				$output .= "<h2>Schema for table '".requestFormEscape($params->{table})."':</h2>";
				$output .= printTabular($cols, ['colname', 'typename', 'notnull', 'default']);
				if (@$indices) {
					$output .= "<h2>Indices on table '".requestFormEscape($params->{table})."':</h2>";
					$output .= printTabular($indices, ['indname', 'oncol', 'primary', 'unique']);
				}
				my $name = $legacy_oid ? $params->{table} : $dbh->quote_identifier($params->{table});
				my $sth = $dbh->prepare("select count(*) as cnt from $name");
				my $row = $sth && $sth->execute() ? $sth->fetchrow_hashref() : undef;
				$output .= $row ? '<h2>Rows in table:</h2><p>'.requestFormEscape($row->{cnt}).'</p>'
					: '<p class="pl-admin-error">'.requestFormEscape($dbh->errstr || 'Row count failed.').'</p>';
				$sth->finish() if $sth;
			}
		}
	}
	
	# handle a result set delete
	#
	elsif (($params->{delete} || $params->{update}) && !$legacy_oid) {
		$output = '<p class="pl-admin-error">Inline row editing is not available for this database.</p>';
	}
	elsif ($params->{'delete'}) {

		my $sth = $dbh->prepare("delete from $params->{table} where oid=$params->{oid}");
	$rv = $sth ? $sth->execute() : undef;

	if ($rv) {
			$output = "Delete successful.";
	} else {
		$output = '<p class="pl-admin-error">'.requestFormEscape($dbh->errstr || 'Delete failed.').'</p>';
	}
	$sth->finish() if $sth;
	}

	# handle a query result update
	#
	elsif ($params->{'update'}) {

	my @sets = ();
	my @vals = ();
	
	# look for params of form col_fieldname
	#
	foreach my $key (keys %$params) {
			if ($key =~ /^col_(.+)$/) {
				my $colname = $1;
			push @sets, "$colname=?";
		push @vals, $params->{$key};
		}
	}
	my $set = join (', ', @sets);
	
		my $sth = $dbh->prepare("update $params->{table} set $set where oid=$params->{oid}");
	$rv = $sth ? $sth->execute(@vals) : undef;

	if ($rv) {
			$output = "Update successful.";
	} else {
		$output = '<p class="pl-admin-error">'.requestFormEscape($dbh->errstr || 'Update failed.').'</p>';
	}
	$sth->finish() if $sth;
	}

	# handle a freeform query
	#
	elsif ($params->{freeform}) {

	my $query = $params->{query};
	my $showoid = 0;

	if ($legacy_oid && $query =~ /^\s*select\s+(.+?)\s+from\s+(\w+)(.*)$/is) {
		my $rowlist = $1;
		$table = $2;
		my $rest = $3;

			# if oid is in query, make it visible
			if ($rowlist =~ /(^|\W)oid(\W|$)/i) {
			$showoid = 1;
		} 
		
		# otherwise, add it to query, keep it invisible, assuming this isn't
		# an aggregate query
		#
		elsif (not $rowlist =~ /(^|\W)(avg|count|max|min|stddev|sum|variance)(\W|$)/i) {
			$query = "select $rowlist, $table.oid from $table$rest";
		}
	}

		my $sth = $dbh->prepare($query);
	$rv = $sth ? $sth->execute() : undef;
	my $query_error = $rv ? '' : ($dbh->errstr || 'Query failed.');
	my $has_fields = $sth && $sth->{NUM_OF_FIELDS};
	if ($rv && $has_fields) {
		my $rows = $sth->fetchall_arrayref({});
		if (!defined($rows) || $sth->err) {
			$rv = undef;
			$query_error = $sth->errstr || $dbh->errstr || 'Result fetch failed.';
		} else {
			@resultset = @$rows;
		}
	}
	$sth->finish() if $sth;
		
	if (scalar @resultset > 0) {
		$output = printResultRows(\@resultset, $table, $showoid, $newqhist);
	} else {
		if (!$rv) {
		$output = '<p class="pl-admin-error">'.requestFormEscape($query_error).'</p>';
		} else {
			if ($has_fields) {
				$output = "No matching rows.";
			} else {
				$output = '<p class="pl-admin-notice">Query successful ('.requestFormEscape(0 + $rv).' rows affected).</p>';
			}
		}
	}
	}

	my @history_options = map {{value => urlescape($_), label => $_}} @history;
	$output = '<p class="pl-admin-error">Query error.</p>' if !$output && nb($params->{query}) && !$rv;
	return entryInteractionTemplate('admindatabase.tt', {
		tables => \@tables, selected_table => $params->{table}, query => $query,
		history => \@history_options, first_history => urlescape($firstval), qhist => $newqhist, output => $output,
	});
}

# do a tabular html print, using an arrayref to hashrefs, all of which have
# the same keys
#
sub printTabular {
	my ($rows, $order) = @_;
	my @columns = $order ? @$order : @$rows ? sort keys %{$rows->[0]} : ();
	my @cells = map { my $row = $_; [map { $row->{$_} } @columns] } @$rows;
	return entryInteractionTemplate('admintabular.tt', {cells => \@cells, columns => \@columns});
}

# prints dbadmin select query result rows, augmented with update/delete 
# controls.
#
sub printResultRows {
	my ($resultset, $table, $showoid, $qhist) = @_;
	if (getConfig('dbms') ne 'pg') {
		return '<h2>Results ('.scalar(@$resultset).'):</h2>'.printTabular($resultset);
	}
	my @records;
	for my $row (@$resultset) {
		my $index = @records;
		my @fields = map {{
			name => $_, value => $row->{$_}, id => 'pl-db-field-'.$index.'-'.$_,
		}} grep {$_ ne 'oid' || $showoid} sort keys %$row;
		push @records, {fields => \@fields, oid => $row->{oid}};
	}
	return entryInteractionTemplate('admindbresults.tt', {records => \@records, table => $table, qhist => $qhist});
}

# encyclopedia-specific admin controls
#
sub getEncyclopediaAdminControls {
	my $userinf = shift;
	my $from = shift;
	my $id = shift;
	my $method = shift;
	my $modern = shift;

	my $methodstr = "";
	$methodstr = "&method=$method" if ($method);

	if ($userinf->{data}->{access} >= getConfig('access_admin')) {
		if ($modern) {
			my @actions = (
				{label => 'Rerender', url => entryInteractionURL('rerender', from => $from, id => $id,
					$method ? (method => $method) : ())},
				{label => 'Quick edit', url => entryInteractionURL('adminedit', from => $from, id => $id)},
				{label => 'Edit linking policy', url => entryInteractionURL('linkpolicy', from => $from, id => $id)},
			);
			push @actions, {label => 'Classify', url => entryInteractionURL('adminclassify', from => $from, id => $id)}
				if getConfig('classification_supported');
			push @actions, {label => 'Delete', danger => 1,
				url => entryInteractionURL('delobj', from => $from, id => $id, ask => 'yes')};
			return entryInteractionSection('Admin Controls', entryInteractionActions(\@actions, 'Admin actions'), 1);
		}
		my $admin = '';

		$admin .= "<center> \n";

		$admin .= "<a href=\"".getConfig("main_url")."/?op=rerender&amp;from=$from&amp;id=$id$methodstr\">rerender</a> | ";

		$admin .= "<a href=\"".getConfig("main_url")."/?op=adminedit&amp;from=$from&amp;id=$id\">qwik-edit</a> | ";
		$admin .= " <a href=\"".getConfig("main_url")."/?op=linkpolicy&amp;from=$from&amp;id=$id\">edit linking policy</a> | ";

		if (getConfig('classification_supported')) {
			$admin .= "<a href=\"".getConfig("main_url")."/?op=adminclassify&amp;from=$from&amp;id=$id\">classify</a> | ";
		}

		$admin .= "<a href=\"".getConfig("main_url")."/?op=delobj&amp;from=$from&amp;id=$id&amp;ask=yes\">delete</a>";

		$admin .= "</center>";

		#$template->setKey('admin', adminBox('Admin Controls', $admin));
		return adminBox('Admin Controls', $admin);
	}
}

# getAdminMenu - get the administrator toolbar menu
#								TODO: show varying options based on access level
#
sub getAdminMenu {
	my $access = shift;
	return '' unless defined $access && $access >= getConfig('access_admin');
	my $html;
	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	$tt->process('adminmenu.tt', { main_url => getConfig('main_url') }, \$html)
		|| die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

# invalidate an object's cache and re-view it.
#
sub reRenderObj {
	my $params = shift;
	my $userinf = shift;

	setvalidflag_off($params->{'from'},$params->{'id'});
	setbuildflag_off($params->{'from'},$params->{'id'});

	return requestFormComplete('rerender', $params);
}

# Admin object metadata editor
#
sub adminObjectEditor {
	my $params = shift;
	my $userinf = shift;
	my $upload = shift;

	return noAccess() if ($userinf->{data}->{access} < getConfig('access_editobj'));

	my $schema;
	if ($params->{from} eq getConfig('en_tbl')) {
		$schema = getConfig('en_schema'); 
	}
	else {
	$schema = getConfig('generic_schema')->{$params->{from}};
	}

	return errorMessage('Invalid object.') unless $schema &&
		defined($params->{id}) && $params->{id} =~ /\A[0-9]+\z/;

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'*',FROM=>$params->{from},WHERE=>"uid=$params->{id}"});
	my $rec = $sth->fetchrow_hashref();
	$sth->finish();
	return errorMessage('Object not found.') unless $rec;
	
	my $html = '';
	my $filebox = '';
	my $error = '';
	my $submitted = defined($params->{submit}) || defined($params->{submit2});
	my $refresh = $submitted || defined($params->{filebox});
	if ($params->{from} eq getConfig('en_tbl')) {
		my $tempdir = $params->{tempdir};
		return errorMessage('Invalid temporary file area.') if $refresh &&
			nb($tempdir) && $tempdir !~ m{\Atemp/[0-9]+\z};
		if (!$refresh || !nb($tempdir) || !-d (getConfig('cache_root')."/$tempdir")) {
			if ($refresh && (nb($tempdir) || nb($params->{filechanges}) || defined($params->{filebox}))) {
				$error = 'The temporary file area expired. Existing files have been restored; please reapply your file changes before submitting.';
			}
			copyBoxFilesToTemp($params->{from}, $params);
			delete $params->{filechanges};
			delete $params->{filelist};
		}
		# Filebox actions stage changes; only the main Submit commits them.
		my %fileparams = %$params;
		delete $fileparams{remove} unless ($params->{filebox} || '') eq 'remove';
		delete $fileparams{filebox} if $error;
		delete $fileparams{remove} if $error;
		my $template = templateFromText('');
		my $fileerror = '';
		(undef, $filebox) = handleFileManager($template, \%fileparams,
			$error ? undef : $upload, \$fileerror);
		$params->{tempdir} = $fileparams{tempdir};
		$params->{filechanges} = $fileparams{filechanges};
		$error ||= 'Please resolve the filebox errors before submitting.' if $fileerror;
	}

	if ($submitted && !$error) {
		my $homeflag = defined $params->{submit2} ? 1 : 0;
		if (nb($params->{remark})) {
			return adminUpdateObjectMetadata($schema,$params,$userinf,$rec, $homeflag);
		} else {
			$error = 'You must enter a remark for your modification.';
		}
	}
	my $title = $params->{from} eq getConfig('en_tbl') ? 'Qwik-editing' : 'Editing metadata';
	my %values = %{ $refresh ? $params : $rec };
	foreach my $key (keys %$schema) {
		$values{$key} = 0 if $schema->{$key}->[1] eq 'check' && !defined($values{$key});
	}
	$html = paddingTable(makeBox($title, ($error ? errorMessage($error) : '') .
		getAdminMetadataEditor($params,$schema,\%values,$filebox)));

	return $html;
}

# Admin classifier
#
sub adminClassify {
	my $params = shift;
	my $userinf = shift;
	
	my $template = new XSLTemplate('adminclassify.xsl');

	return noAccess() if ($userinf->{data}->{access} < getConfig('access_editobj'));

	$template->addText('<adminclassify>');

	my $title = lookupfield($params->{from},'title',"uid=$params->{id}");
	my $userid = lookupfield($params->{from},'userid',"uid=$params->{id}");

	if (defined $params->{submit}) {
	if ($params->{invalidate} eq 'on') {
			setvalidflag_off($params->{from},$params->{id});
	}
		classify($params->{from},$params->{id},$params->{class});

	# send notice
	#
	if ($userid != $userinf->{uid}) {
		fileNotice($userid,
							 $userinf->{uid},
					 'Entry classified (or reclassified)',
					 'You may want to inspect the new classification.',
					 [{id=>$params->{id},table=>$params->{from}}]);
		}
	return paddingTable(makeBox('Object Classified',"To go back to the object, click <a href=\"".getConfig("main_url")."/?op=getobj&from=$params->{from}&id=$params->{id}\">here</a>.
	<meta http-equiv=\"refresh\" content=\"0; url=".getConfig("main_url")."/?op=getobj&from=$params->{from}&id=$params->{id}\">"));
	} else {
		$template->setKeys(%$params);
	$template->setKey('class', classstring($params->{from},$params->{id}));
	}

	$template->setKey('hascache', 1) if ($params->{from} eq getConfig('en_tbl'));
	$template->setKey('title', $title);
	$template->addText('</adminclassify>');

	return $template->expand();
}

# get the form for editing metadata
# 
sub getAdminMetadataEditor {
	my $params = shift;
	my $schema = shift;
	my $rec = shift;
	my $filebox = shift || '';
	
	my $html = '';

	# initial form output
	#
	$html .= "<form method=\"post\" action=\"/\" enctype=\"multipart/form-data\">";

	# build metadata editing portion of form
	#
	foreach my $key (sort { humanReadableCmp $a, $b } keys %$schema) {
		my ($widget,$desc) = getFormWidget($schema,$key,$rec);
	next if (blank($widget) || blank($desc));
		$html .= "$desc:<br> $widget <br>";
	}

	# add editing fields
	#
	$html .= "<br>Editing remark: <br><textarea name=\"remark\" rows=\"5\" cols=\"50\">" . qhtmlescape($params->{remark} || '') . "</textarea>";
	$html .= $filebox;
	$html .= "<input type=\"hidden\" name=\"op\" value=\"adminedit\">";
	$html .= "<input type=\"hidden\" name=\"id\" value=\"$params->{id}\">";
	$html .= "<input type=\"hidden\" name=\"from\" value=\"$params->{from}\">";
	$html .= "<br><br>";
	$html .= "<center><input type=\"submit\" name=\"submit\" value=\"submit\">";
	$html .= " <input type=\"submit\" name=\"submit2\" value=\"submit and go to home\"></center>";
	$html .= "</form>";
	
	return $html;
}

sub adminUpdateObjectMetadata {
	my $schema = shift;
	my $params = shift;
	my $userinf = shift;
	my $rec = shift;
	my $gohome = shift;

	my @update;
	
	# find fields which have changed
	#
	foreach my $key (keys %$schema) {
		my $val = $params->{$key};

		# convert checkbox values to boolean 0/1
		if ($schema->{$key}->[1] eq 'check') {
			if (defined $val) {
				$val = ($val eq 'on')?1:0;
			}
		}
	
		if (defined $val && ($val ne $rec->{$key})) {
			#dwarn "*** admin edit: going to update $key to $val";
			push @update,"$key='".sq($val)."'";
		} 
	
		elsif (not defined $val) {
			if ($schema->{$key}->[1] eq 'check') {
				#dwarn "*** admin edit: going to update $key to 0";
				push @update,"$key=0";
			} elsif ($schema->{$key}->[1] eq 'text' ||
						 $schema->{$key}->[1] eq 'tbox') { 
				#dwarn "*** admin edit: going to update $key to ''";
				push @update,"$key=''";
			}
		}
	}

	# make the changes
	#
	my $filechanges = $params->{from} eq getConfig('en_tbl') &&
		($params->{filechanges} || '') eq 'yes';
	if ($#update >= 0 || $filechanges) {

		# encyclopedia stuff
		if ($params->{from} eq getConfig('en_tbl')) {
			# save a snapshot of the current version
			snapshot($params->{from}, $rec->{uid}, "$rec->{name}_$rec->{version}", $userinf->{uid}, $params->{remark});
			if ($filechanges && !moveTempFilesToBox($params, $params->{id}, $params->{from})) {
				return errorMessage('Could not save the filebox. Please return to the editor and try again.');
			}
			
			# increment version
			my ($rv, $sth) = dbUpdate($dbh,{WHAT=> $params->{from}, SET => 'version=version+1', WHERE=>"uid=$params->{id}"});
		}
	
		# generic field updating
		if (@update) {
			my $search_resource = grep { my $table = getConfig($_); defined($table) && $params->{from} eq $table } qw(books_tbl papers_tbl exp_tbl);
			push @update, 'modified=CURRENT_TIMESTAMP' if $search_resource;
			my ($rv,$sth) = dbUpdate($dbh,{
				WHAT => $params->{from},
				SET => join(',',@update),
				WHERE => "uid=$params->{id}"
			});
			$sth->finish();
			nativeSearchForgetDocument($dbh, $params->{from}, $params->{id}) if $search_resource && getConfig('native_fulltext_enabled');
		}

		# do stuff for updating of encyclopedia objects. (invalidate, xref, etc) 
		#
		if ($params->{from} eq getConfig('en_tbl')) {
			handleEncyclopediaChange($params,$rec);
		}
	}
	if ($params->{from} eq getConfig('en_tbl') && !$filechanges && nb($params->{tempdir})) {
		removeTempCacheDir($params->{tempdir});
	}

	# build the notice and send it out
	#
	my $nid = adminEditNote($userinf,$rec->{userid},$params->{remark});
	makeObjLink('notices',$nid,$params->{from},$rec->{uid},(defined $rec->{title}?$rec->{title}:'object'));

	# give some points
	#
	changeUserScore($userinf->{uid},getScore('edit_en_minor'));

	# update stats
	#
	$stats->invalidate('latestadds');
	$stats->invalidate('latestmods');

	# finish up
	#
	if (! $gohome) {
		return paddingTable(makeBox('Update Successful',"You will now be redirected back to the object. If this does not work, click <a href=\"".getConfig("main_url")."/?op=getobj&from=$params->{from}&id=$params->{id}\">here</a>.
		<meta http-equiv=\"refresh\" content=\"0; url=".getConfig("main_url")."/?op=getobj&from=$params->{from}&id=$params->{id}\">"));
	} else {
		return paddingTable(makeBox('Update Successful',"You will now be redirected back home. If this does not work, click on the ".getConfig('projname')." logo or just do something else.
		<meta http-equiv=\"refresh\" content=\"0; url=/\">"));
	}
}

# file notice for admin edit 
#
sub adminEditNote {
	my $userinf = shift;
	my $userto = shift;
	my $remark = shift||'';
	
	# get the insert id so we can return it
	#
	my $id = nextval('notices_uid_seq');

	# do the insert
	#
	my ($rv,$sth) = dbInsert($dbh,{
	INTO => 'notices',
	COLS => 'uid,userid,userfrom,title,data',
	VALUES => "$id,$userto,$userinf->{uid},'Your object was edited','".sq($remark)."'"
	});
	$sth->finish();
	
	return $id;
}

sub adminStats {
	my ($params, $userinf) = @_;
	return noAccess() if ($userinf->{data}->{access} < getConfig('access_editobj'));
	my $fields = adminDBStats();
	my @rows = map {{label => $_, value => $fields->{$_}}} sort keys %$fields;
	return entryInteractionTemplate('adminstatistics.tt', {rows => \@rows});
}

sub webStats
{
	my $params = shift;
	my $userinf = shift;

	return noAccess() if ($userinf->{data}->{access} < getConfig('access_admin'));

	my $statsurl = 'https://aux.physicslibrary.org/stats/awstats.physicslibrary.org.html';
	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	my $html = '';
	$tt->process('webstats.tt', { stats_url => $statsurl }, \$html)
		|| die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

sub adminDBStats
{
	my $template = shift;
	my @countstats = (
			[ 'Objects', '*', getConfig('en_tbl'), '' ],
			[ 'Invalid Objects', 'distinct objectid', getConfig('cache_tbl'), 'valid = 0 and method=\'make4ht\'' ],
			[ 'Objects in Build', 'distinct objectid', getConfig('cache_tbl'), 'not build = 0 and method=\'make4ht\'' ],
			[ 'Cross References', '*', getConfig('xref_tbl'), '' ],
			[ 'Users', '*', 'users', '' ],
		);
	my %fields;

	foreach my $ot (keys(%{getConfig("typechars")})) {
		push @countstats, [ getConfig("typestrings")->{$ot}, '*', getConfig('en_tbl'), "type = '$ot'" ];
	}
	foreach my $s (@countstats) {
		$fields{$s->[0]} = dbRowCountWithWhat($s->[1], $s->[2], $s->[3]);
	}
	
	# BB: avoid division by zero on empty database
	if ($fields{"Objects"}!=0) {
	$fields{"Cross-references/Object"} = sprintf("%.02f", $fields{"Cross References"} / $fields{"Objects"});
	} else { 
	$fields{"Cross-references/Objects"} = "Undefined"
	}

	$fields{"Unproven Theorems"} = scalar keys(%{getUnprovenTheorems()});
#$template->setKeys(%fields);

	return \%fields unless $template;
	foreach my $key (keys(%fields)) {
			$template->addText("<stat name=\"$key\">$fields{$key}</stat>\n");
	}
	return $template;
}

1;

