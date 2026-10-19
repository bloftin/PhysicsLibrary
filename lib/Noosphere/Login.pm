package Noosphere;

use strict;
use Template;
use Noosphere::PasswordStorage;
use Noosphere::Ticket;
use Noosphere::RequestForm;
use URI;
use URI::Escape ();

our $dbh;

# Only return to local navigation, never credentials or an action submission.
sub loginReturnURL {
    my ($value) = @_;
    return '/' unless defined($value) && !ref($value) && length($value) <= 4096 &&
        $value =~ m{\A/(?!/)} && $value !~ /[\x00-\x20\x7f\\]/;
    my $uri = eval { URI->new($value) };
    return '/' unless $uri && !defined($uri->scheme) && !defined($uri->authority) &&
        !defined($uri->fragment);
    my $path = $uri->path;
    for (1 .. 4) {
        return '/' if $path !~ m{\A/(?!/)} || $path =~ /[\x00-\x20\x7f\\]/ ||
            $path =~ m{(?:\A|/)\.\.?(?:/|\z)};
        my $decoded = URI::Escape::uri_unescape($path);
        last if $decoded eq $path;
        return '/' if $_ == 4;
        $path = $decoded;
    }
    my (@query, %params);
    @query = $uri->query_form;
    while (@query) {
        my ($key, $v) = splice(@query, 0, 2);
        $key = lc($key);
        return '/' if exists($params{$key}) || $key =~ /[\x00-\x20\x7f]/ ||
            $key =~ /(?:passwd|password|token|ticket|secret|credential)/ ||
            $key =~ /\A(?:user|url|post|submit\d*|save|confirm|watch)\z/ ||
            $v =~ /[\x00-\x1f\x7f]/;
        $params{$key} = $v;
    }
    my $op = $params{op} || '';
    return '/' if $op =~ /\A(?:login|logout|newuser|activate|pwchange|pwchangereq)\z/;
    # Existing GET rules distinguish read/editor pages from mutating actions.
    return '/' if requestFormNeedsProtection({%params, op => $op || 'getobj'}, 'GET');
    return "$uri";
}

sub loginReturnTarget {
    my ($req, $params) = @_;
    return loginReturnURL($params->{url}) if ($params->{op} || '') eq 'login';
    return '/' unless $req && $req->method =~ /\A(?:GET|HEAD)\z/;
    # Preserve the original pretty URL and query, not parsed or POST form data.
    return loginReturnURL($req->unparsed_uri);
}

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
	my $signed_out = 0;
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
		$signed_out = 1;
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
			$user_info{'login_failed'} = 1 if $req->method eq 'POST';
		}

		# otherwise we found the user, get their info
		#
		else {
			my $ticket = eval {
                my $new_ticket = makeTicket($row->{uid}, $user_info{'ip'}, getConfig('cookie_timeout'),
                    $user_info{'time'}, $row->{password_hash}, $row->{access});
                revokeTicket($user_info{'ticket'}) if defined $new_ticket;
                $new_ticket;
            };
            $user_info{'ticket'} = $ticket;
            $user_info{'uid'} = defined($ticket) ? $row->{uid} : 0;
            $user_info{'login_unavailable'} = 1 unless defined $ticket;
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
        # A delayed response cannot know whether this browser has since signed in.
        # Reject the request, but only an explicit logout may expire its cookie.
        clearCookie($req, 'ticket') if $signed_out;
    }
    if ($user_info{'uid'} > 0 || defined($cookies->{ticket}) ||
        $params->{op} =~ /\A(?:login|logout|newuser|activate|edituser|pwchange|pwchangereq)\z/) {
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
    my $content = 'You are signed out.';
    if ($user_info->{uid} > 0) {
        my $token = logoutFormToken($user_info->{ticket});
        $content =
        '<form method="post" action="/"><p>Sign out of this browser?</p>'.
        '<input type="hidden" name="op" value="logout" />'.
        '<input type="hidden" name="logout_token" value="'.$token.'" />'.
        '<button type="submit">Logout</button></form>';
    }
    my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
    my $html = '';
    $tt->process('accountpage.tt', {title => 'Logout', content => $content}, \$html)
        || die "Template process failed: ", $tt->error(), "\n";
    return $html;
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
		my $error = $user_info->{login_unavailable}
            ? 'Sign-in is temporarily unavailable. Please try again.'
            : $user_info->{login_failed}
			? 'Unable to sign in. Check your username and password, then try again.'
			: '';
		my $loginbox = '';
		my $file = 'login.tt';
		
		my $vars = {
			Error       => $error,
            ReturnURL   => loginReturnTarget(scalar(eval { Apache2::RequestUtil->request }), $params),
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
