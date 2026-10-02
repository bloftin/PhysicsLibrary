package Noosphere;
use strict;

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
	return paddingTable($html);
}

# called by getobj, this interprets the object table entry in terms of a forum
#
sub renderForum {
	my $rec = shift;

	my $file = 'forumobj.tt';
	my $html_obj = '';
	#dwarn "renderForum start";
	my $table = getConfig('forum_tbl');
	my $title = $rec->{title};
	#dwarn "rec title:\n $title";
	my $rec_data = $rec->{data};
	#dwarn "rec data:\n $rec_data";

	##my $template = new TemplateNS('forumobj.html');

	my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
	my $forumobj = clearBox("Forum: $rec->{title}","<center>Welcome to the $rec->{title} forum!</center><hr width=\"100%\" size=1 noshade>".$rec->{data}."<p><center>[ <a href=\"".getConfig("main_url")."/?op=forums\">back to forums top</a> ]</center>");
	
	#dwarn "forumobj:\n $forumobj";

	my $interact = makeBox("Interact","<center><a href=\"".getConfig("main_url")."/?op=postmsg&from=$table&id=$rec->{uid}\">post</a></center>");
	
	#dwarn "interact:\n $interact";

	##$template->setKeys('forumobj' => $forumobj, 'commands' => $interact);
	my $vars = {
        forumobj        => $forumobj,
		commands        => $interact,
    };

	my $ret = $tt->process($file, $vars, \$html_obj) || die "Template process failed: ", $tt->error(), "\n";

	#dwarn "renderForum end";
	return $html_obj;
}

sub getForumInteract {

}

1;
