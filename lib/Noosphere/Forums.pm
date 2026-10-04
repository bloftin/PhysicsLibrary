package Noosphere;
use strict;
use Noosphere::EntryInteractions;

# get a top view list of forums
#
sub getForumsTop {
	my $params = shift;	 # not used currently
	my $userinf = shift;

	my $table=getConfig('forum_tbl');

	(my $rv,my $sth)=dbSelect($dbh,{WHAT=>'uid,title,data',
																	FROM=>$table,
									WHERE=>'parentid is null',
									'ORDER BY'=>'lower(title)'});

	if (! $rv) {
		dwarn "error querying forums\n";
	return "error querying forums!";
	}

	my @rows = dbGetRows($sth);
	my @forums;
	my $main = getConfig('main_url');
	foreach my $row (@rows) {
		my $id = int($row->{uid});
		push @forums, {
			title => qhtmlescape($row->{title}),
			description => qhtmlescape($row->{data}),
			url => "$main/?op=getobj&amp;from=$table&amp;id=$id",
			messages => getmsgcount($table, $id),
			unread => count_unseen($table, $id, $userinf->{uid}),
		};
	}

	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	my $html = '';
	$tt->process('forumslist.tt', { forums => \@forums }, \$html)
		|| die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

# called by getobj, this interprets the object table entry in terms of a forum
#
sub renderForum {
	my $rec = shift;
	my $table = getConfig('forum_tbl');
	return entryInteractionTemplate('forumobj.tt', {
		title => "Forum: $rec->{title}", forum_title => $rec->{title},
		data => $rec->{data}, forums_url => entryInteractionURL('forums'),
		commands => entryInteractionSection('Interact', entryInteractionActions([
			{label => 'Post', url => entryInteractionURL('postmsg', from => $table, id => $rec->{uid})},
		], 'Forum actions')),
	});
}

sub getForumInteract {

}

1;
