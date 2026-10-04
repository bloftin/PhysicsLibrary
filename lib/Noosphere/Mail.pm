package Noosphere;

use strict;
use Template;
use URI;

sub renderMailPage {
	my ($file, $vars) = @_;
	my $html = '';
	my $tt = Template->new({INCLUDE_PATH => getConfig('template_path')});
	$tt->process($file, {main_url => getConfig('main_url'), %$vars}, \$html)
		|| die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

sub getMailRecord {
	my ($id, $userinf) = @_;
	return (undef, errorMessage('Missing id parameter.')) unless defined $id;
	return (undef, errorMessage('Invalid message id.')) if ref($id) || $id !~ /\A[0-9]+\z/;
	my ($rv, $sth) = dbSelect($dbh, {
		WHAT => 'mail.*,u1.username as fromname, u2.username as toname',
		FROM => 'mail,users as u1, users as u2',
		WHERE => "mail.userfrom=u1.uid and mail.userto=u2.uid and mail.uid=$id and (mail.userfrom=$userinf->{uid} or mail.userto=$userinf->{uid})",
	});
	return (undef, errorMessage('Query error, contact admin.')) unless $rv;
	my $rec = $sth->fetchrow_hashref();
	$sth->finish();
	return (undef, errorMessage('Message could not be found.')) unless $rec;
	return (undef, errorMessage('You cannot view mail you did not send or receive.'))
		if $rec->{userfrom} != $userinf->{uid} && $rec->{userto} != $userinf->{uid};
	return ($rec, '');
}

# replyMail - reply to a message
# 
sub replyMail	{
	my ($params, $userinf) = @_;
	return needAccount() if $userinf->{uid} <= 0;
	my ($rec, $error) = getMailRecord($params->{id}, $userinf);
	return $error unless $rec;
	return errorMessage('You cannot reply to mail you sent.') if $rec->{userfrom} == $userinf->{uid};
	# Derive the recipient and quoted original from the authorized record, not hidden fields.
	my %values = (%$params, sendto => $rec->{fromname});
	my $spell = '';
	if (defined $params->{post}) {
		$error = checkSendMail(\%values, $userinf);
		if ($error eq '') {
			insertMail(\%values, $userinf);
			return renderMailPage('mailnotice.tt', {title => 'Reply Sent'});
		}
	} elsif (defined $params->{spell}) {
		my $text = $params->{body} || '';
		$text =~ s/>.*?\n//gs;
		$text =~ s/^\s*//s;
		$spell = checkdoc($text);
	} elsif (defined $params->{quote}) {
		$values{body} = getquoted($rec->{body})."\n\n".($params->{body} || '');
	} else {
		$values{subject} = $rec->{subject} || '';
		$values{subject} = "Re: $values{subject}" unless $values{subject} =~ /^\s*Re:/i;
		$values{body} = '';
	}
	return renderMailPage('mailcompose.tt', {title => 'Reply to Mail Message', reply => 1,
		values => \%values, original => $rec->{body}, error => $error, spell => $spell});
}

# unsendMail - unsend a mail message
#
sub unsendMail {
	my $params = shift;
	my $userinf = shift;
	
	my $id = $params->{id};

	return needAccount() if $userinf->{'uid'} <= 0;

	my ($row, $error) = getMailRecord($id, $userinf);
	return $error unless $row;

	return errorMessage("You cannot unsend mail you did not send.") if ($row->{userfrom} != $userinf->{uid});

	return errorMessage("You cannot unsend mail that has been read.") if (defined($row->{_read}) && $row->{_read} == 1);
 
	# if we're still here, go ahead and "unsend" (i.e., delete the record)
	#
	my ($rv,$sth) = dbDelete($dbh,{
						FROM=>'mail',
						WHERE=>"uid=$id"});
	$sth->finish();

	return renderMailPage('mailnotice.tt', {title => 'Mail Unsent', unsent => 1});
}

# getNewMailCount - get a count of new (unread) mail messages
#
sub getNewMailCount {
	my $userinf = shift;

	return -1 if ($userinf->{uid} < 1);

	my ($rv,$sth) = dbSelect($dbh,{
			WHAT=>'count(uid) as cnt',
			FROM=>'mail',
			WHERE=>"mail.userto=$userinf->{uid} and _read is null"});

	return -1 if (!$rv);
	my $row = $sth->fetchrow_hashref();

	return $row->{cnt};
}

# getMail - get/display a mail message
#
sub getMail {
	my ($params, $userinf) = @_;
	return needAccount() if $userinf->{uid} <= 0;
	my ($rec, $error) = getMailRecord($params->{id}, $userinf);
	return $error unless $rec;
	my $recipient = $rec->{userto} == $userinf->{uid};
	markMailRead($rec->{uid}) if $recipient && !defined $rec->{_read};
	my $reply = URI->new('/');
	$reply->query_form(op => 'replymail', id => $rec->{uid}, rsubject => $rec->{subject});
	return renderMailPage('mailview.tt', {title => 'Viewing Mail Message', rec => $rec,
		reply => $rec->{userfrom} != $userinf->{uid}, reply_url => "$reply",
		unsend => !$recipient && !defined $rec->{_read}});
}

# markMailread - set the "read" flag of a mail message, no questions asked
#
sub markMailRead {
	my $id = shift;

	my ($rv,$sth) = dbUpdate($dbh,{WHAT=>'mail',SET=>'_read=1',WHERE=>"uid=$id"});
	$sth->finish();
}

# mailBox - get mail box screen
#
sub mailBox {
	my $params = shift;
	my $userinf = shift;
	
	return errorMessage('Must be logged in to use mail') if ($userinf->{uid} < 1);

	my ($rv,$sth) = dbSelect($dbh,{
			WHAT=>'mail.subject,mail.sent,mail.uid,mail.userfrom,users.username',
			FROM=>'mail,users',
			WHERE=>"users.uid=mail.userfrom and mail.userto=$userinf->{uid} and _read is null",
			'ORDER BY'=>'sent',
			DESC=>''});

	return errorMessage("Query error, contact admin.") if (!$rv);
 
	my @rows = dbGetRows($sth);
 
	foreach my $row (@rows) {
		$row->{date} = ymd($row->{sent});
	}
	my $html;
	my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
	$tt->process('mailbox.tt', {
		title => 'Your '.getConfig('projname').' Mail Box',
		main_url => getConfig('main_url'), rows => \@rows, count => scalar @rows
	}, \$html) || die "Template process failed: ", $tt->error(), "\n";
	return $html;
}

# sentMail - get mail box screen
#
sub sentMail {
	return mailFolder($_[0], $_[1], 'sentmail');
}

# oldMail - get Old Mail list
#
sub oldMail {
	return mailFolder($_[0], $_[1], 'oldmail');
}

sub mailFolder {
	my ($params, $userinf, $folder) = @_;
	return errorMessage('Must be logged in to use '.getConfig('projname').' mail') if $userinf->{uid} < 1;
	my $sent = $folder eq 'sentmail';
	my $scope = $sent ? "mail.userfrom=$userinf->{uid}" : "mail.userto=$userinf->{uid} and _read=1";
	my $participant = $sent ? 'userto' : 'userfrom';
	my $total = dbRowCount('mail', $scope);
	my ($rv, $sth) = dbSelect($dbh, {
		WHAT => $sent ? 'mail.*,users.username' : 'mail.subject,mail.sent,mail.uid,mail.userfrom,users.username',
		FROM => 'mail,users', WHERE => "users.uid=mail.$participant and $scope",
		'ORDER BY' => 'sent', DESC => '', OFFSET => $params->{offset} || 0,
		LIMIT => int($userinf->{prefs}->{pagelength} / 2),
	});
	return errorMessage('Query error, contact admin.') unless $rv;
	my @rows = dbGetRows($sth);
	foreach my $row (@rows) {
		$row->{date} = ymd($row->{sent});
		$row->{read_label} = defined($row->{_read}) && $row->{_read} == 1 ? 'Read' : 'Unread' if $sent;
	}
	my $pager = @rows ? getPager({op => $folder, total => $total, offset => $params->{offset} || 0}, $userinf, 2) : '';
	return renderMailPage('mailbox.tt', {title => 'Your '.getConfig('projname').' Mail Box',
		folder => $folder, rows => \@rows, count => $total, pager => $pager});
}

sub sendMailForm {
	my ($params, $userinf) = @_;
	return needAccount() if $userinf->{uid} <= 0;
	my %values = %$params;
	my ($error, $spell) = ('', '');
	if (defined $params->{post}) {
		$error = checkSendMail($params, $userinf);
		if ($error eq '') {
			insertMail($params, $userinf);
			return renderMailPage('mailnotice.tt', {title => 'Mail Sent'});
		}
	} elsif (defined $params->{spell}) {
		my $text = $params->{body} || '';
		$text =~ s/>.*?\n//gs;
		$text =~ s/^\s*//s;
		$spell = checkdoc($text);
	} else {
		delete @values{qw(subject body)};
	}
	return renderMailPage('mailcompose.tt', {title => 'Send Mail', folder => 'sendmail',
		values => \%values, error => $error, spell => $spell});
}

sub checkSendMail {
	my $params = shift;
	my $userinf = shift;
	
	my $error = '';
	
	# check for non-blank fields 
	#
	$error .= "Need a user to send to!<br />" if (blank($params->{sendto}));
	$error .= "Need a subject!<br />" if (blank($params->{subject}));
	$error .= "Need a message!<br />" if (blank($params->{body}));

	# check for valid user
	#
	$error .= "Need a registered ".getConfig('projname')." user for 'To:' field.<br />" if (not user_registered($params->{sendto},'username'));

	$error .= "<br />" if (nb($error));
	return $error;
}

# insertMail - actually "send" it (put it in the database)
#
sub insertMail {
	my $params = shift;
	my $userinf = shift;
	
	return errorMessage('Must be logged in to use '.getConfig('projname').' mail') if ($userinf->{uid} < 1);
	
	my $recipient = getuidbyusername($params->{sendto});
	
	my $nextid = nextval('mail_uid_seq');

	my ($rv,$sth) = dbInsert($dbh,{
			INTO=>'mail',
			COLS=>'sent,uid,userto,userfrom,subject,body',
			VALUES=>"now(),$nextid,$recipient,$userinf->{uid},".quotefields($params->{'subject'},$params->{'body'})});
	$sth->finish();

	# send e-mail notification for system mail if desired
	#
	my %recipientinf = userInfoById($recipient);
	if ($recipientinf{'prefs'}->{'sysemail'} eq 'on') {

		my $userfromname = $userinf->{'data'}->{'username'};

		my $proj = getConfig('projname');
		my $root = getConfig('main_url');

		my $subject = "You have received $proj mail";
		my $body = "Subject: $subject 
From user: $userfromname

Message:

$params->{body}

";

		$body .= "To reply, go to $root/?op=getmail&id=$nextid

NOTE: You can turn these email notifications off  by toggling the corresponding
option in your preferences ( $root/?op=editprefs ).
";
		
		sendMail($recipientinf{'data'}->{'email'},$body,$subject);
	} 
}

1;
