package Noosphere;

use strict;

# handleLogin - main entry point for getting user information hash and 
#	processing logins.
#
sub handleLogin {
	my ($req, $params, $cookies) = @_;
	
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
		$user_info{'ticket'} = undef;
		$user_info{'uid'} = 0;

		clearCookie($req, 'ticket');

		dwarn 'got logout'; 
	}
 
	# handle login op
	#
	elsif ($params->{op} eq 'login' && $user && $passwd) {
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
		markUserAccess($user_info{'uid'}, $user_info{'ip'});
	}

	# handle never logging out
	# 
	if ($user_info{'uid'} > 0 && $user_info{'prefs'}->{'neverlogout'} eq 'on') {
		my $timeout =	(180*24*60*60);	# 6 months
			
		# set a new cookie that pushes expiry time back.
		#
		setCookie($req, 'ticket', $user_info{'ticket'}, $timeout); 
	}

	return %user_info;
}

# get the contents of the login/logged-in box displayed on the left
#
sub getLoginBox {
	my $params = shift;
	my $user_info = shift;

	my $data = $user_info->{'data'};
	
	my $boxtitle;
	my $login;
	my $template;

	if (defined $user_info->{'ticket'} && $user_info->{'uid'} > 0) {
		$boxtitle = $data->{'username'};
		$login = new Template('userbox.html');

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
		$login = new Template('login.html');
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

1;
