package Noosphere;

##############################################################################
# 
# this is the ACL (Access Control List) module.	It defines all of the 
# interface functions to handle access control lists for users and objects.
#
##############################################################################

use Noosphere::Groups;
use strict;

# get an ACL editor for an object
#
sub ACLEditor {
	my $params = shift;
	my $userinf = shift;

	my $template = new XSLTemplate('acleditor.xsl');

	my $error = '';

	my $objectid = $params->{id};
	my $table = $params->{from};

	my $default = ($table eq getConfig('dacl_tbl') ? 1 : 0);
	
	# get user's permissions for this object. 
	#
	if (!$default) {
		my $perms = getPermissions($table,$params->{id},$userinf);

		return errorMessage("You don't have permissions to modify the ACL for that object.") unless ($perms->{acl});
	}

	$template->addText('<acleditor>');

	# process global default application: replace all existing ACLs
	#
	if (defined $params->{replaceall}) {
		my $count = globalInstallDefaultACL($userinf->{uid}, 1);
		if ($count == 0) {
			$error .= "No objects to update!<br />";
		} else {
			$error .= "ACL updated (replaced) for $count objects.<br />";
		}
	}

	# combine new rules with existing ACLs, will not wipe out special 
	# access rules
	#
	if (defined $params->{combineall}) {
		my $count = globalInstallDefaultACL($userinf->{uid}, 1);
	if ($count == 0) {
			$error .= "No objects to update!<br />";
	} else {
		$error .= "ACL updated (combined) for $count objects.<br />";
	}
	}
	
	# process addition
	#
	if (defined $params->{addrule}) {
		my $subjectid = -1;

		# check for errors in adding
	#
		if (not defined $params->{default_new}) {
		if (not defined $params->{uog_new}) {
				$error .= "Need to select 'user' or 'group' for a valid rule.<br />";
		}

			# check/resolve subject id
		$subjectid = getSubjectId($params->{subjectid_new}, $params->{uog_new});
		if ($subjectid == -1) {
				$error .= "That is not a valid subject name or ID!<br />";
		}
	}
	if ($error eq '') {
			if ($default) {
				addACL_default($userinf->{uid}, {subjectid=>$subjectid, user_or_group=>$params->{uog_new}, default_or_normal=>($params->{default_new} eq 'on'?'d':'n'), perms=>{'read'=>($params->{read_new} eq 'on'?1:0), 'write'=>($params->{write_new} eq 'on'?1:0), 'acl'=>($params->{acl_new} eq 'on'?1:0)}});	
		} else {
				addACL($table,$objectid,{subjectid=>$subjectid, user_or_group=>$params->{uog_new}, default_or_normal=>($params->{default_new} eq 'on'?'d':'n'), perms=>{'read'=>($params->{read_new} eq 'on'?1:0), 'write'=>($params->{write_new} eq 'on'?1:0), 'acl'=>($params->{acl_new} eq 'on'?1:0)}});	
		}
	}
	}

	# look for updates/deletions
	#
	foreach my $key (keys %$params) {
		# deletion 
	#
	if ($key =~ /^delete_([0-9]+)$/) {
			my $aclid = $1;

			# do the deletion
		if ($default) {
				deleteACL_default($aclid);
		} else {
			deleteACL($aclid);	 
		}
		$error .= "Rule deleted.<br />";
	}

	# update 
	#
	if ($key =~ /^update_([0-9]+)$/) {
			my $aclid = $1;
		if ($default) {
				updateACL_default({subjectid=>$params->{"subjectid_$aclid"}, user_or_group=>$params->{"uog_$aclid"}, default_or_normal=>($params->{"default_$aclid"} eq 'on'?'d':'n'), perms=>{'read'=>($params->{"read_$aclid"} eq 'on'?1:0), 'write'=>($params->{"write_$aclid"} eq 'on'?1:0), 'acl'=>($params->{"acl_$aclid"} eq 'on'?1:0)}},$aclid);	
		} else {
				updateACL($table,$objectid,{subjectid=>$params->{"subjectid_$aclid"}, user_or_group=>$params->{"uog_$aclid"}, default_or_normal=>($params->{"default_$aclid"} eq 'on'?'d':'n'), perms=>{'read'=>($params->{"read_$aclid"} eq 'on'?1:0), 'write'=>($params->{"write_$aclid"} eq 'on'?1:0), 'acl'=>($params->{"acl_$aclid"} eq 'on'?1:0)}},$aclid);	
		}
		$error .= "Rule updated.<br />";
	}
	}
	
	# set the default selector html based on whether or not a default rule 
	#	exists for this object
	#
	my $defaultsel = '';
	my $hasdef = $default ? hasDefaultDefaultRule($userinf->{uid}) 
											: hasDefaultRule($table,$objectid);
	
	$template->setKey('hasdef', $hasdef);
	
	# get the editable list of existing ACL rules for this object
	#
	my $acllist = $default ? getDefaultACLRules($userinf->{uid})
											 : getACLRules($table,$objectid);

	$template->setKey('acllist',$acllist);

	# get the group quick-selector
	#
	my $ghash = getAdminGroupHash($userinf->{uid});
	$ghash->{''} = "[ please select ]";
	my $gsel = getSelectBox('gselbox', $ghash, '', 'onChange="document.newaclform.subjectid_new.value=this.value; document.newaclform.uog_new[1].checked=true;"');
	$template->setKey('gselect', $gsel);
	
	# get the object's name
	#
	my $objname = lookupfield($table,'title',"uid=$objectid") if (!$default);

	# set error
	#
	$error .= '<br />' if ($error);
	$template->setKey('error',$error);

	# set other keys
	#
	$template->setKey('default', $default) if $default;
	$template->setKeys(%$params);
	
	my $title = $default ? 'Editing default Access Control List' 
										 : "Editing Access Control List for '$objname'";

	$template->addText('</acleditor>');

	return paddingTable(makeBox($title, $template->expand())); 
}

# get the ACL rule widgets for this object
#
sub getACLRules {
	my $table = shift;
	my $objectid = shift;

	my $tacl = getConfig('acl_tbl');
	
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'*',FROM=>$tacl,WHERE=>"tbl='$table' and objectid=$objectid"});	

	my @rows;
	while (my $row = $sth->fetchrow_hashref()) {
	
		my %temp = %$row;
		$temp{'read'} = $row->{'_read'};
		$temp{'write'} = $row->{'_write'};
		$temp{'acl'} = $row->{'_acl'};

		push @rows, {%temp};
	}

	return getAccessRuleEditor(@rows);
}

# get the default ACL rule widgets for a user
#
sub getDefaultACLRules {
	my $userid = shift;

	my $tacl = getConfig('dacl_tbl');
	
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'*',FROM=>$tacl,WHERE=>"userid=$userid"});	
	my @rows;
	while (my $row = $sth->fetchrow_hashref()) {
	
		my %temp = %$row;
		$temp{'read'} = $row->{'_read'};
		$temp{'write'} = $row->{'_write'};
		$temp{'acl'} = $row->{'_acl'};

		push @rows, {%temp};
	}

	return getAccessRuleEditor(@rows);
}

# print out ACL rules in an "editing" table
# 
sub getAccessRuleEditor {
	my @rules = @_;

	my $html = '';

	$html .= "<table width=\"100%\" cellpadding=\"2\" border=\"0\">";

	# output the header
	#
	$html .= "<tr>";
	$html .= "<td align=\"center\" bgcolor=\"#EEEEEE\">";
	$html .= "Subject Name</td>";
	$html .= "<td align=\"center\" bgcolor=\"#EEEEEE\">";
	$html .= "Subject ID</td>";
	$html .= "<td align=\"center\" bgcolor=\"#EEEEEE\">";
	$html .= "Default?</td>";
	$html .= "<td align=\"center\" bgcolor=\"#EEEEEE\">";
	$html .= "User/Group</td>";
	$html .= "<td align=\"center\" bgcolor=\"#EEEEEE\">";
	$html .= "Permissions (R/W/A)</td>";
	$html .= "<td colspan=\"2\" align=\"center\" bgcolor=\"#EEEEEE\">";
	$html .= "&nbsp;";
	$html .= "&nbsp;</td>";
	$html .= "</tr>";
	
	# output the rows
	#
	foreach my $row (@rules) {
		$html .= "<tr>";
		$html .= aclWidget($row);
		$html .= "</tr>";
	}
	
	$html .= "</table>";

	return $html;
}

# format an ACL record as an ACL editor form entry.
#
sub aclWidget {
	my $rec = shift;			# the database record hash.

	my $html = '';
 
	# output subject name
	#
	my $subjectname = getSubjectName($rec);
	$html .= "<td align=\"center\">$subjectname</td>";
	
	# output subject id display/editor
	#
	$html .= "<td align=\"center\">";
	$html .= "<input type=\"text\" name=\"subjectid_$rec->{uid}\" size=\"6\" value=\"".($rec->{default_or_normal} eq 'd'?'[default]':$rec->{subjectid})."\"/></td>";

	# output default/normal display/editor
	#
	$html .= "<td align=\"center\">";
	$html .= "<input type=\"checkbox\" name=\"default_$rec->{uid}\" ".($rec->{default_or_normal} eq 'd'?'checked="checked"':'')."/>";
	$html .= "</td>";
	
	# output user/group display/editor
	#
	$html .= "<td align=\"center\">";
	$html .= "<input type=\"radio\" name=\"uog_$rec->{uid}\" value=\"u\" ".($rec->{user_or_group} eq 'u'?'checked="checked"':'')."/> u";
	$html .= "<input type=\"radio\" name=\"uog_$rec->{uid}\" value=\"g\" ".($rec->{user_or_group} eq 'g'?'checked="checked"':'')."/> g";
	$html .= "</td>";

	# output user/group display/editor
	#
	$html .= "<td align=\"center\">";
	$html .= "<input type=\"checkbox\" name=\"read_$rec->{uid}\" ".($rec->{'read'}?'checked="checked"':'')."/> ";
	$html .= "<input type=\"checkbox\" name=\"write_$rec->{uid}\" ".($rec->{'write'}?'checked="checked"':'')."/> ";
	$html .= "<input type=\"checkbox\" name=\"acl_$rec->{uid}\" ".($rec->{'acl'}?'checked="checked"':'')."/>";
	$html .= "</td>";

	# output display/update buttons
	#
	$html .= "<td align=\"center\">";
	$html .= "<input type=\"submit\" name=\"update_$rec->{uid}\" value=\"update\"/>";
	$html .= "</td>";
	$html .= "<td align=\"center\">";
	$html .= "<input type=\"submit\" name=\"delete_$rec->{uid}\" value=\"delete\"/>";
	$html .= "</td>";
	
	return $html;
}

# return bool on subject existing; takes id and 'u'/'g'
#
sub subjectExists {
	my $subjectid = shift;
	my $user_or_group = shift;

	if ($user_or_group eq 'u') {
		return (defined lookupfield(getConfig('user_tbl'),'username',"uid=$subjectid"));
	} else {
		return (defined lookupfield(getConfig('groups_tbl'),'groupname',"groupid=$subjectid"));
	}
}

# check/resolve subject id.	
#
sub getSubjectId {
	my $subjectid = shift;
	my $user_or_group = shift;

	# input was numerical 
	#
	if ($subjectid =~ /^\d+$/) {
		my $id;
		if ($user_or_group eq 'u') {
			$id = lookupfield(getConfig('user_tbl'),'uid',"uid=$subjectid");
		} else {
			$id = lookupfield(getConfig('groups_tbl'),'groupid',"groupid=$subjectid");
		}

		return defined $id ? $id : -1;
	}

	# input was wordical
	#
	else {
		my $id;
		if ($user_or_group eq 'u') {
			$id = lookupfield(getConfig('user_tbl'),'uid',"username='".sq($subjectid)."'");
		} else {
			$id = lookupfield(getConfig('groups_tbl'),'groupid',"groupname='".sq($subjectid)."'");
		}

		return defined $id ? $id : -1;
	}
}

# get a subject name for a user or group. takes an ACL record.
#
sub getSubjectName {
	my $rec = shift;

	my $name = '';
	
	if ($rec->{'default_or_normal'} eq 'd') {
		return '[anyone]';
	}

	if ($rec->{'user_or_group'} eq 'u') {
		$name = lookupfield(getConfig('user_tbl'),'username',"uid=$rec->{subjectid}");
	} else {
		$name = lookupfield(getConfig('groups_tbl'),'groupname',"groupid=$rec->{subjectid}");
	}
	
	return $name;
}

# see if user has read/write/acl access to a particular object
#
sub hasPermissionTo {
	my $table = shift;
	my $objectid = shift;
	my $userinf = shift;
	my $action = shift || 'read';	# 'read', 'write', or 'acl'

	my $perms = getPermissions($table,$objectid,$userinf);

	return $perms->{$action};
}

# get the permissions for a particular object and particular user
#
# if $table is set to the default acl table, then we get permissions from there
# directly instead of the ACL table.
#
sub getPermissions {
	my $table = shift;
	my $objectid = shift;
	my $userinf = shift;
	
	my $userid = $userinf->{uid};

	my $acltbl = getConfig("acl_tbl");
	
	# for some objects (messages, corrections, etc) we return readable always
	#
	return {'read'=>1, 'write'=>0, 'acl'=>0} unless
		(getConfig('acl_tables')->{$table});

	# if the user is the owner of the object, they automatically have 1/1/1 
	# perms
	#
	my $ownerid = lookupfield($table,'userid',"uid=$objectid");
	$ownerid = -$ownerid if ($ownerid < 0);
	return {'read'=>1, 'write'=>1, 'acl'=>1} if ($userid == $ownerid);

	# TODO: 1/1/1 for admin?

	# get list of groups the user is in
	#
	my @groups = getUserGroupids($userid);
	my $groupq = "-1";
	
	if ($#groups >= 0) {
		$groupq = join(', ',@groups);
	}

	# find a matching access specifier.	
	#
	#	- we check user first, then group.
	#	- normal first, then default.
	#	- further conflicts resolved by db order.
	#
	# (do a union select of 3 separate queries to perform the above ordering)
	#
#	my ($rv,$sth) = dbLowLevelSelect($dbh,
# "select _read, _write, _acl, default_or_normal from $acltbl where objectid=$objectid and tbl='$table' and subjectid=$userid and user_or_group='u' and default_or_normal='n' union 
#	select _read, _write, _acl, default_or_normal from $acltbl where objectid=$objectid and tbl='$table' and subjectid in ($groupq) and user_or_group='g' and default_or_normal='n' union
#	select _read, _write, _acl, default_or_normal from $acltbl where objectid=$objectid and tbl='$table' and default_or_normal='d' order by default_or_normal desc	
#	limit 1
#	");

	my ($rv,$sth) = dbLowLevelSelect($dbh,
 "select _read, _write, _acl, default_or_normal from $acltbl where 
 		(objectid=$objectid and tbl='$table' and subjectid=$userid and user_or_group='u' and default_or_normal='n') or 
		(objectid=$objectid and tbl='$table' and subjectid in ($groupq) and user_or_group='g' and default_or_normal='n') or 
		(objectid=$objectid and tbl='$table' and default_or_normal='d')
	order by default_or_normal desc	
	limit 1
	");

	# if there were any matching ACLs, we'll be returning a single best-fit ACL.
	#
	my $acl;
	if ($sth->rows() == 1) {
		my $row = $sth->fetchrow_hashref();
		$acl = {%$row};
		$acl->{'read'} = $row->{'_read'};
		$acl->{'write'} = $row->{'_write'};
		$acl->{'acl'} = $row->{'_acl'};
	}
	$sth->finish();

	return $acl;	# will be undefined if we found nothing 
}

# check to see if an object has a default access rule
#
sub hasDefaultRule {
	my $table = shift;
	my $objectid = shift;

	my $acltbl = getConfig("acl_tbl");

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'uid',FROM=>$acltbl,WHERE=>"tbl='$table' and objectid=$objectid and default_or_normal='d'"});

	my $count = $sth->rows();
	$sth->finish();

	return 1 if ($count >= 1);

	return 0;
}

# check to see if an object is world-editable (has a default access rule, and
#  this rule allows writing)
#
sub isWorldWriteable {
	my $table = shift;
	my $objectid = shift;

	my $acltbl = getConfig("acl_tbl");

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'_write',FROM=>$acltbl,WHERE=>"tbl='$table' and objectid=$objectid and default_or_normal='d'"});

	return 0 if ($sth->rows() <= 0);

	my $row = $sth->fetchrow_hashref();
	$sth->finish();

	return $row->{'_write'};
}

# check to see if a user has a default access rule in their "default" table
#
sub hasDefaultDefaultRule {
	my $userid = shift;

	my $acltbl = getConfig("dacl_tbl");

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'uid',FROM=>$acltbl,WHERE=>"userid=$userid and default_or_normal='d'"});

	my $count = $sth->rows();
	$sth->finish();

	return 1 if ($count >= 1);

	return 0;
}

# add (or update) a users's default ACL spec
#
sub addDefaultUserACL {
	my $userid = shift;
	my $spec = shift;	 # hash of ACL spec
		
	my $perms = $spec->{perms};

	my $acltbl = getConfig("dacl_tbl");
	
	# try to update first
	#
	my ($rv, $sth) = dbUpdate($dbh,{WHAT=>$acltbl, SET=>"user_or_group='$spec->{user_or_group}', default_or_normal='$spec->{default_or_normal}', subjectid=$spec->{subjectid}, _read=$perms->{read}, _write=$perms->{write}, _acl=$perms->{acl}", WHERE=>"userid=$userid and user_or_group='$spec->{user_or_group}' and default_or_normal='$spec->{default_or_normal}' and subjectid=$spec->{subjectid} and _read=$perms->{read} and _write=$perms->{write} and _acl=$perms->{acl}"});

	# if failed, add new row
	#
	if ($rv == 0) {
		my $nextid = nextval($acltbl.'_uid_seq');
		my ($rv, $sth) = dbInsert($dbh,{INTO=>$acltbl, COLS=>"uid, userid, user_or_group, default_or_normal, subjectid, _read, _write, _acl", VALUES=>"$nextid, $userid, '$spec->{user_or_group}', '$spec->{default_or_normal}', $spec->{subjectid}, $perms->{read}, $perms->{write}, $perms->{acl}"});
	}

	$sth->finish();
}

# wrapper to call the above
#
sub updateDefaultUserACL {

	addDefaultUserACL(@_);
}

# install a default ACL for a new object, given some user
#
sub installDefaultACL {
	my $table = shift;
	my $objectid = shift;
	my $userid = shift;
	
	my $dacl = getConfig('dacl_tbl');
	
	# query up the user's default ACL spec
	#
	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'*',FROM=>$dacl,WHERE=>"userid=$userid"});
	my @defaults = dbGetRows($sth);

	foreach my $default (@defaults) {
	
		# insert each rule for the given object 
		#
		addACL($table,$objectid,
			{subjectid=>$default->{subjectid},
			 user_or_group=>$default->{user_or_group},
			 default_or_normal=>$default->{default_or_normal},
			 perms=>{'read'=>$default->{'_read'}, 'write'=>$default->{'_write'}, 'acl'=>$default->{'_acl'}}
			});
	}
}

# install default ACL for every object owned by a user. we go through object
# index for this.
#
sub globalInstallDefaultACL {
	my $userid = shift;
	my $delete = shift || 0;	# erase existing ACLs?

	my $table = getConfig('index_tbl');

	# select only on tables which ACLs apply to
	# 
	my $aclwhere = join (', ', map { sqq($_) } keys %{getConfig('acl_tables')});
	
	my ($rv, $sth) = dbSelect($dbh, {WHAT=>'tbl, objectid', FROM=>$table, WHERE=>"userid=$userid and tbl in ($aclwhere)"});
	
	my @rows = dbGetRows($sth);

	# start from a clean slate
	#
	if ($delete) {
		foreach my $row (@rows) {
			deleteObjectACL($row->{tbl}, $row->{objectid});
		}
	}

	# install default ACL for each object
	#
	foreach my $row (@rows) {
		installDefaultACL($row->{tbl}, $row->{objectid}, $userid);
	}

	return scalar @rows;	# return # of changes
}

# update an ACL - expects to access a specific ACL id
#
sub updateACL {
	my $table = shift;
	my $objectid = shift;
	my $aclspec = shift;
	my $aclid = shift;

	my $acltbl = getConfig("acl_tbl");
	
	# do the update
	#
	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>$acltbl,SET=>"_read=$aclspec->{perms}->{read}, _write=$aclspec->{perms}->{write}, _acl=$aclspec->{perms}->{acl}, user_or_group='$aclspec->{user_or_group}', default_or_normal='$aclspec->{default_or_normal}'", WHERE=>"uid=$aclid"});
}

# update a default ACL - expects to access a specific ACL id
#
sub updateACL_default {
	my $aclspec = shift;
	my $aclid = shift;

	my $acltbl = getConfig("dacl_tbl");
	
	# do the update
	#
	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>$acltbl,SET=>"_read=$aclspec->{perms}->{read}, _write=$aclspec->{perms}->{write}, _acl=$aclspec->{perms}->{acl}, user_or_group='$aclspec->{user_or_group}', default_or_normal='$aclspec->{default_or_normal}'", WHERE=>"uid=$aclid"});
}

# remove an ACL record for an object
#
sub deleteObjectACL {
	my $table = shift;
	my $objectid = shift;

	my $acl = getConfig('acl_tbl');

	my ($rv, $sth) = dbDelete($dbh, {FROM=>$acl, WHERE=>"objectid=$objectid and tbl='$table'"});

	my $count = $sth->rows();

	$sth->finish();

	return $count;	# number of rules deleted
}

# remove an ACL record, by id
#
sub deleteACL {
	my $aclid = shift;

	my $acltbl = getConfig("acl_tbl");

	# do the delete
	#
	my ($rv,$sth) = dbDelete($dbh,{FROM=>$acltbl,WHERE=>"uid=$aclid"});
}

# remove a default ACL record, by id
#
sub deleteACL_default {
	my $aclid = shift;

	my $acltbl = getConfig("dacl_tbl");

	# do the delete
	#
	my ($rv,$sth) = dbDelete($dbh,{FROM=>$acltbl,WHERE=>"uid=$aclid"});
}

# delete default ACL records for a user
#
sub deleteUserDefaultACL {
	my $userid = shift;

	my $acltbl = getConfig("dacl_tbl");

	my ($rv,$sth) = dbDelete($dbh,{FROM=>$acltbl,WHERE=>"userid=$userid"});
}

# add or update an ACL spec for an object
#
#	aclspec = {subjectid =>, 
#						 perms => {read =>, write =>, acl =>}, 
#						 user_or_group =>, 
#						 default_or_normal =>}
#
sub addACL {
	my $table = shift;
	my $objectid = shift;
	my $aclspec = shift;

	my $acltbl = getConfig("acl_tbl");
	
	# fill in faux subjectid
	#
	if (not defined $aclspec->{subjectid}) {
		$aclspec->{subjectid} = 0;
	}
	
	# try to update first
	#
	my ($rv,$sth);
	
	if ($aclspec->{default_or_normal} eq 'd') {
		($rv,$sth) = dbUpdate($dbh,{WHAT=>$acltbl,SET=>"_read=$aclspec->{perms}->{read}, _write=$aclspec->{perms}->{write}, _acl=$aclspec->{perms}->{acl}, user_or_group='$aclspec->{user_or_group}', default_or_normal='$aclspec->{default_or_normal}'", WHERE=>"tbl='$table' and objectid=$objectid and default_or_normal='d'"});
	} else {
		($rv,$sth) = dbUpdate($dbh,{WHAT=>$acltbl,SET=>"_read=$aclspec->{perms}->{read}, _write=$aclspec->{perms}->{write}, _acl=$aclspec->{perms}->{acl}, user_or_group='$aclspec->{user_or_group}', default_or_normal='$aclspec->{default_or_normal}'", WHERE=>"tbl='$table' and objectid=$objectid and subjectid=$aclspec->{subjectid} and user_or_group='$aclspec->{user_or_group}'"});
	}
	
	# add if not present
	#
	if ($rv == 0) {
		my $nextid = nextval($acltbl.'_uid_seq');

		my ($rv,$sth) = dbInsert($dbh,{INTO=>$acltbl,COLS=>"uid, tbl, objectid, subjectid, _read, _write, _acl, user_or_group, default_or_normal",VALUES=>"$nextid, '$table', $objectid, $aclspec->{subjectid}, $aclspec->{perms}->{read}, $aclspec->{perms}->{write}, $aclspec->{perms}->{acl}, '$aclspec->{user_or_group}', '$aclspec->{default_or_normal}'"});
	} 

	$sth->finish();
}

# add or update a default ACL spec for a user
#
#	aclspec = {subjectid =>, 
#						 perms => {read =>, write =>, acl =>}, 
#						 user_or_group =>, 
#						 default_or_normal =>}
#
sub addACL_default {
	my $userid = shift;
	my $aclspec = shift;

	my $acltbl = getConfig("dacl_tbl");
	
	# fill in faux subjectid
	#
	if (not defined $aclspec->{subjectid}) {
		$aclspec->{subjectid} = 0;
	}
	
	# try to update first
	#
	my ($rv,$sth);
	
	if ($aclspec->{default_or_normal} eq 'd') {
		($rv,$sth) = dbUpdate($dbh,{WHAT=>$acltbl,SET=>"_read=$aclspec->{perms}->{read}, _write=$aclspec->{perms}->{write}, _acl=$aclspec->{perms}->{acl}, user_or_group='$aclspec->{user_or_group}', default_or_normal='$aclspec->{default_or_normal}'", WHERE=>"userid=$userid and default_or_normal='d'"});
	} else {
		($rv,$sth) = dbUpdate($dbh,{WHAT=>$acltbl,SET=>"_read=$aclspec->{perms}->{read}, _write=$aclspec->{perms}->{write}, _acl=$aclspec->{perms}->{acl}, user_or_group='$aclspec->{user_or_group}', default_or_normal='$aclspec->{default_or_normal}'", WHERE=>"userid=$userid and subjectid=$aclspec->{subjectid} and user_or_group='$aclspec->{user_or_group}'"});
	}
	
	# add if not present
	#
	if ($rv == 0) {
		my ($rv,$sth)=dbInsert($dbh,{INTO=>$acltbl,COLS=>"userid, subjectid, _read, _write, _acl, user_or_group, default_or_normal",VALUES=>"$userid, $aclspec->{subjectid}, $aclspec->{perms}->{read}, $aclspec->{perms}->{write}, $aclspec->{perms}->{acl}, '$aclspec->{user_or_group}', '$aclspec->{default_or_normal}'"});
	} 

	$sth->finish();
}

1;
