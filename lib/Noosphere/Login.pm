package Noosphere;

use strict;

# handleLogin - main entry point for getting user information hash and 
#	processing logins.
#
sub handleLogin {
	my ($req, $params, $cookies) = @_;
	my $param_op = $params->{'op'};
	dwarn "handleLogin started";
	dwarn "params->{'op'} = $param_op";
	my %user_info = ('ticket' => undef, 'time' => time(), 'uid' => -1,
									 'ip' => $ENV{'REMOTE_ADDR'});

	# handle proxy-forwarded IP
	#
	my $fip = [split(/\s*,\s*/,$req->header_in('X-Forwarded-For'))]->[0];
	$user_info{'ip'} = $fip if ($fip);

	if (defined $cookies->{'ticket'}) {
		$user_info{'ticket'} = $cookies->{'ticket'}; 
	}
	
	my $user = $params->{'user'};
	my $passwd = $params->{'passwd'};

	# handle logging out: unset ticket
	#
	if ($params->{'op'} eq 'logout') {
		dwarn "logout selected";
		$user_info{'ticket'} = undef;
		$user_info{'uid'} = 0;

		
		clearCookie($req, 'ticket');

		dwarn 'got logout'; 
	}
 
	# handle login op
	#
	elsif ($params->{op} eq 'login' && $user && $passwd) {
		dwarn "handle login op";
		$user =~ s/^ +//;
		$user =~ s/ +$//;
		$user =~ s/ +/ /g;
	
		#dwarn "Attempting to log in $user with $passwd";
	 
		my ($rv,$dbq) = dbSelect($dbh,{
			WHAT => '*',
			FROM => 'users',
			WHERE => "lower(username)=lower('$user') AND password='$passwd' AND active=1",
			LIMIT => 1});
	 
		# error if exactly one row wasn't returned
		#
		if ($rv != 1) {
			$user_info{'ticket'} = undef;
			$user_info{'uid'} = 0;	
		}

		# otherwise we found the user, get their info
		#
		else {
			my $row = $dbq->fetchrow_hashref();
			$dbq->finish();
			$user_info{'uid'} = $row->{'uid'}; 
	 
			$user_info{'ticket'} = makeTicket($user_info{'uid'},
				$user_info{'ip'},
				getConfig('cookie_timeout'),
				$user_info{'time'});

			#my $timeout = $user_info{'time'} + (60 * getConfig('cookie_timeout'));

			my $timeout = 60 * getConfig('cookie_timeout');
			setCookie($req, 'ticket', $user_info{'ticket'}, $timeout); 
		}
	}

	# check for ticket holding login info for any other op
	#
	else {
		dwarn "Else ticket holding login";
		$user_info{'uid'} = checkTicket($user_info{'ticket'},
		$user_info{'ip'},
		getConfig('cookie_timeout'),
		$user_info{'time'});
	}

	# get data and prefs (even for anonymous user)
	#
	$user_info{'data'} = getUserData($user_info{'uid'});
	$user_info{'prefs'} = parsePrefs($user_info{'data'}->{'prefs'});

	# handle user last request statistics
	# 
	if ($user_info{'uid'} > 0) {
		dwarn "handle user last request statistics before";
		markUserAccess($user_info{'uid'}, $user_info{'ip'});
		dwarn "handle user last request statistics after";
	}

	# handle never logging out
	# 
	if ($user_info{'uid'} > 0 && $user_info{'prefs'}->{'neverlogout'} eq 'on') {
		dwarn "handle never logging out before";
		my $timeout =	(180*24*60*60);	# 6 months
			
		# set a new cookie that pushes expiry time back.
		#
		setCookie($req, 'ticket', $user_info{'ticket'}, $timeout); 
	}
	dwarn "handle never logging out after";
	return %user_info;
}

# get the contents of the login/logged-in box displayed on the left
#
sub getLoginBoxOld {
	my $params = shift;
	my $user_info = shift;

	my $data = $user_info->{'data'};
	
	my $boxtitle;
	my $login;
	my $template;

	if (defined $user_info->{'ticket'} && $user_info->{'uid'} > 0) {
		$boxtitle = $data->{'username'};
		$login = new TemplateNS('userbox.html');

		# handle counts 
		#
		my $count = getNewMailCount($user_info);
		if ($count > 0) {
			$login->setKey('messages', "($count)");
		}
		$count = countPendingCorrections($user_info);
		if ($count > 0) {
			$login->setKey('corrections', "($count)");
		}
		$count = getNoticeCount($user_info);
		if ($count > 0) {
			$login->setKey('notices', "($count)");
		}
	
		$login->setKey('bullet', getBullet());
		$login->setKey('id',$user_info->{uid});
	}
	else {
		$boxtitle = 'Login';
		$login = new TemplateNS('login.html');
		my $error = 'login error';

		# handle deactivated account situation
		#
		if (user_registered($params->{user}, 'username') &&
			!isUserActive($params->{user})) {
		
			$error = 'account deactivated';
		}

		$login->setKey('error', $params->{op} eq 'login' ? $error : '');
	}
	
	return makeBox($boxtitle, $login->expand());
}

sub getLoginBox {
	my $params = shift;
	my $user_info = shift;

	my $data = $user_info->{'data'};
	
	my $boxtitle;
	my $login = '';
	my $template;
	
	
	
	if (defined $user_info->{'ticket'} && $user_info->{'uid'} > 0) {
		my $file = 'loggedin.tt';
		my $mail = getNewMailCount($user_info);
		my $corrections = countPendingCorrections($user_info);
		my $notices = getNoticeCount($user_info);
		my $loginbox = '';
		my $username = $data->{'username'};
		
		my $vars = {
        	username       	=> $username,
			mail			=> $mail,
			corrections		=> $corrections,
			notices			=> $notices,
    	};

		my $tt = Template->new({
			INCLUDE_PATH => '/var/www/pp/stemplates',
		});

	
    	my $ret = $tt->process($file, $vars, \$loginbox) || die "Template process failed: ", $tt->error(), "\n";

		return $loginbox;

	} else {
		my $error = '';
		my $loginbox = '';
		my $file = 'login.tt';
		
		my $vars = {
        error       => $error,
    	};

		my $tt = Template->new({
			INCLUDE_PATH => '/var/www/pp/stemplates',
		});

	
    	my $ret = $tt->process($file, $vars, \$loginbox) || die "Template process failed: ", $tt->error(), "\n";

		return $loginbox;

	}
	

}

sub getLoginBoxHybrid {
	my $params = shift;
	my $user_info = shift;

	my $data = $user_info->{'data'};
	
	my $boxtitle;
	my $login = '';
	my $template;
	
	
	if (defined $user_info->{'ticket'} && $user_info->{'uid'} > 0) {
		my $mail = getNewMailCount($user_info);
		my $corrections = countPendingCorrections($user_info);
		my $notices = getNoticeCount($user_info);
		my $xml = '';
		my $username = $data->{'username'};
		my $writer = new XML::Writer(OUTPUT=>\$xml);
		$writer->startTag("logged_in");
		# BEN: Roles have not been upgraded to yet
		#if ( is_editor( $user_info->{'uid'} ) ) {
		#	$writer->startTag("editor");
		#	$writer->endTag("editor");	
		#}
		$writer->startTag("username");
		$writer->characters($username);
		$writer->endTag("username");
		$writer->startTag('mail');
		$writer->characters($mail);
		$writer->endTag('mail');
		$writer->startTag('notices');
		$writer->characters($notices);
		$writer->endTag('notices');
		$writer->startTag('corrections');
		$writer->characters($corrections);
		$writer->endTag('corrections');
	    $writer->endTag("logged_in");

		my $xslt = getConfig("stemplate_path") . "/loggedin.xsl";
		my $loginbox = buildStringUsingXSLT( $xml, $xslt );

		return $loginbox;
		return "ERROR\n";
		##$login = new TemplateNS('userbox.html');

#		$login->setKey('bullet', getBullet());
#		$login->setKey('id',$user_info->{uid});
#		$login->setKey('url', hashToParams($params));
	} else {
		my $error = '';
		my $loginbox = '';
		my $file = 'login.tt';
		
		my $vars = {
        error       => $error,
    	};

		my $tt = Template->new({
			INCLUDE_PATH => '/var/www/pp/stemplates',
		});

	
    	my $ret = $tt->process($file, $vars, \$loginbox) || die "Template process failed: ", $tt->error(), "\n";

		return $loginbox;

		##my $xml = '';
		##my $writer = new XML::Writer(OUTPUT=>\$xml);
		##$writer->startTag("login");
		##$writer->startTag("main_url");
		##$writer->characters(getConfig("main_url"));
		##$writer->endTag("main_url");
	    ##    $writer->endTag("login");

		##my $xslt = getConfig("stemplate_path") . "/login.xsl";
		##my $loginbox = buildStringUsingXSLT( $xml, $xslt );
		##return $loginbox;

		#$boxtitle = 'Login';
		#$login = new TemplateNS('login.html');
		#my $error = 'login error';

		# handle deactivated account situation
		#
		#if (user_registered($params->{user}, 'username') &&
		#	!isUserActive($params->{user})) {
		
		#	$error = 'account deactivated';
		#}

		#$login->setKey('url', hashToParams($params));
		#$login->setKey('error', $params->{op} eq 'login' ? $error : '');
	}
	
#	return $login->expand();
}

1;
