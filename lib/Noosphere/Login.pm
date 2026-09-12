package Noosphere;

use strict;
use Noosphere::PasswordStorage;
use Noosphere::Ticket;

our $dbh;

sub findLoginUser {
 my ($username, $password) = @_;
 return undef unless defined($username) && !ref($username) && length($username) &&
   defined($password) && !ref($password) && length($password);
 $username =~ s/^ +//;
 $username =~ s/ +$//;
 $username =~ s/ +/ /g;
 return eval {
   my $row = dbSelectRowBound($dbh,
     'SELECT uid, password_hash, access FROM users WHERE lower(username) = lower(?) AND active = 1 LIMIT 1',
     $username);
   $row && verifyAccountPassword($row->{password_hash}, $password) ? $row : undef;
 };
}

# handleLogin - main entry point for getting user information hash and 
#	processing logins.
#
sub handleLogin {
	my ($req, $params, $cookies) = @_;
	my $param_op = $params->{'op'};
	#dwarn "handleLogin started";
	#dwarn "params->{'op'} = $param_op";
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
	if ($params->{'op'} eq 'logout' && $req->method eq 'POST' &&
        validSessionToken($user_info{'ticket'}) &&
        defined($params->{logout_token}) && !ref($params->{logout_token}) &&
        $params->{logout_token} eq logoutFormToken($user_info{'ticket'})) {
		#dwarn "logout selected";
		revokeTicket($user_info{'ticket'});
		$user_info{'ticket'} = undef;
		$user_info{'uid'} = 0;

		#dwarn 'got logout'; 
	}
 
	# handle login op
	#
	elsif ($params->{op} eq 'login') {
		my $row = $req->method eq 'POST' ? findLoginUser($user, $passwd) : undef;
	 
		# error if exactly one row wasn't returned
		#
		if (!$row) {
			$user_info{'ticket'} = undef;
			$user_info{'uid'} = 0;	
		}

		# otherwise we found the user, get their info
		#
		else {
			my $ticket = eval {
                revokeTicket($user_info{'ticket'});
                makeTicket($row->{uid}, $user_info{'ip'}, getConfig('cookie_timeout'),
                    $user_info{'time'}, $row->{password_hash}, $row->{access});
            };
            $user_info{'ticket'} = $ticket;
            $user_info{'uid'} = defined($ticket) ? $row->{uid} : 0;
            setCookie($req, 'ticket', $ticket, sessionLifetime()) if defined $ticket;
		}
	}

	# check for ticket holding login info for any other op
	#
	else {
		#dwarn "Else ticket holding login";
		$user_info{'uid'} = checkTicket($user_info{'ticket'},
		$user_info{'ip'},
		getConfig('cookie_timeout'),
		$user_info{'time'});
	}

    if ($user_info{'uid'} <= 0) {
        $user_info{'ticket'} = undef;
        clearCookie($req, 'ticket') if defined($cookies->{ticket}) || $params->{op} eq 'login';
    }
    if ($user_info{'uid'} > 0 || $params->{op} =~ /\A(?:login|logout|newuser|activate|edituser|pwchange|pwchangereq)\z/) {
        $req->headers_out->set('Cache-Control' => 'no-store');
        $req->headers_out->set('Referrer-Policy' => 'same-origin');
    }
	# get data and prefs (even for anonymous user)
	#
	$user_info{'data'} = getUserData($user_info{'uid'});
	$user_info{'prefs'} = parsePrefs($user_info{'data'}->{'prefs'});

	# handle user last request statistics
	# 
	if ($user_info{'uid'} > 0) {
		#dwarn "handle user last request statistics before";
		markUserAccess($user_info{'uid'}, $user_info{'ip'});
		#dwarn "handle user last request statistics after";
	}

	return %user_info;
}

sub logoutPage {
    my ($params, $user_info) = @_;
    return paddingTable(makeBox('Logout', 'You are signed out.')) unless $user_info->{uid} > 0;
    my $token = logoutFormToken($user_info->{ticket});
    return paddingTable(makeBox('Logout',
        '<form method="post" action="/"><p>Sign out of this browser?</p>'.
        '<input type="hidden" name="op" value="logout" />'.
        '<input type="hidden" name="logout_token" value="'.$token.'" />'.
        '<button type="submit">Logout</button></form>'));
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
