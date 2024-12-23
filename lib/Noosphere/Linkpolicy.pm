package Noosphere;

###############################################################################
#
# Routines for handling linking policies.
# 
###############################################################################

use strict;

sub edit_linkpolicy {
	my $params = shift;
	my $userinf = shift;

	return loginExpired() if ($userinf->{'uid'} <= 0);

	my $en = getConfig('en_tbl');

	return errorMessage("You can't edit that object!") unless ((hasPermissionTo($en,$params->{'id'},$userinf,'write')) || ($userinf->{'data'}->{'access'} >= getConfig('access_admin')));

	my ($title, $linkpolicy) = lookupfields($en, 'title, linkpolicy', "uid=$params->{id}");

	my $template;

	if (defined $params->{'submit'}) {
	
		my $sth = $dbh->prepare("update $en set linkpolicy = ? where uid = ?");
		$sth->execute($params->{'policy'}, $params->{'id'});
		$sth->finish();

		$template = new XSLTemplate('linkpolicy_updated.xsl');

		$template->addText("<linkpolicy_updated title=\"".qhtmlescape($title)."\">");

		$template->setKeys(%$params);

		$template->addText('</linkpolicy_updated>');
	}

	else {
		$template = new XSLTemplate('linkpolicy.xsl');

		$template->addText("<linkpolicy title=\"".qhtmlescape($title)."\">");
		
		$template->setKeys(%$params);
		$template->setKey('policy', $linkpolicy);

		$template->addText('</linkpolicy>');
	}

	return $template->expand();
}

# decide which object to link to from the target object, given a list of 
# candidate object IDs and the concept label
# 
sub post_resolve_linkpolicy {
	my $target = shift;
	my $idmap = shift;		# maps concept IDs to object IDs
	my $concept = shift;
	my @pool = @_;

	my %policies;

	foreach my $pid (@pool) {
		$policies{$pid} = loadpolicy($idmap->{$pid});
	}

	# pull out link policy information and compare 
	#
	my %compare;

	foreach my $pid (@pool) {
		if (defined $policies{$pid}->{'priority'} &&
			(not defined $policies{$pid}->{'priority'}->{'concept'} ||
			$policies{$pid}->{'priority'}->{'concept'} eq $concept)) {
			
			$compare{$pid} = $policies{$pid}->{'priority'}->{'value'};

		} else {
			$compare{$pid} = 100; # default priority
		}
	}

	my @winners = ();

	my $topprio = 32768;
	foreach my $pid (sort { $compare{$a} <=> $compare{$b} } keys %compare) {
		if ($compare{$pid} <= $topprio) {
			push @winners, $pid;

			$topprio = $compare{$pid};
		} else {
			last;
		}
	}

	return @winners;	
}

# load a link policy (read from DB and parse it to a hash structure)
#
sub loadpolicy {
	my $objectid = shift;

	my $sth = $dbh->prepare("select linkpolicy from objects where uid = ?");
	$sth->execute($objectid);

	my $row = $sth->fetchrow_arrayref();
	$sth->finish();

	if (not defined $row) {

		return {};
	}
	
	my $policytext = $row->[0];

	my %policy;

	foreach my $line (split(/\s*\n+\s*/,$policytext)) {

		# parse out priority
		#
		if ($line =~ /^\s*priority\s+(\d+)(?:\s+("[\w\d\s]+"|[\w\d]))?/) {
			my $prio = $1;
			my $concept = $2;
			
			$policy{'priority'} = {value => $prio};
			$policy{'priority'}->{'concept'} = $concept if defined $concept;
		}

		# TODO: parse out other stuff.
	}

	return {%policy};
}

1;
