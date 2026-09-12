package Noosphere;

use strict;
use Noosphere::PasswordStorage;

use Digest::SHA qw(sha256_hex);

our $dbh;

sub registrationRequest {
    my $req = Apache2::RequestUtil->request;
    $req->headers_out->set('Cache-Control' => 'no-store');
    $req->headers_out->set('Referrer-Policy' => 'strict-origin');
    return $req->method;
}

sub getNewUser {
	my $params = shift;
	my $userinf = shift;	# just in case the user is logged in
	my $method = registrationRequest();
	return errorMessage('Use the registration form to create an account.')
		unless ($method eq 'GET' || $method eq 'POST') &&
			(!defined($params->{verify}) || $method eq 'POST');

	if ($userinf->{'uid'} > 0) {
	
		return errorMessage("Another account? Isn't one enough?");
	}

	my $error = '';
	my $template;
	my $addrs = getConfig('siteaddrs');
	my $boxtitle;

	if (!defined($params->{'verify'})) {
		$boxtitle = "Create New User Account";
		$template = new TemplateNS("new_user.html");
	} 
	
	# we just need to verify the information they submitted, then proceed 
	# to send the mail.
	#
	else {
		$error = eval { checkNewUserInfo($params) };
		return errorMessage('Could not process registration. Please try again later.') if $@;
		if ($error eq '') {
			my $body = new TemplateNS("newuseremail");
			my $hostname = $addrs->{'main'};
			my $hash = eval { createRegistrationTicket($params->{user}, $params->{email}) };
			return errorMessage('Could not process registration. Please try again later.')
				unless defined $hash;
			$body->setKeys('hash' => $hash, 'hostname' => $hostname);
			
			my $sent = eval { sendMail($params->{email}, $body->expand()); 1 };
			return errorMessage('Could not send registration email. Please try again later.') unless $sent;
			# TODO: figure out a way to see if the mail bounces and return error
			$boxtitle = "Mail Sent";
			$template = new TemplateNS("sentmail.html");
			$template->setKey('email', $params->{"email"});
		}
		else {
			$boxtitle = "Create New User Account";
			$template = new TemplateNS("new_user.html");
			$template->setKeys('error' => $error, 'user' => $params->{'user'}, 'email' => $params->{'email'});
		}
	}
	return paddingTable(makeBox($boxtitle, $template->expand())); 
}

sub getActivate {
    my ($params) = @_;
    my $method = registrationRequest();
    return errorMessage('Use the activation form to set your password.')
        unless ($method eq 'GET' || $method eq 'POST') &&
            (!defined($params->{setpass}) || $method eq 'POST');
    my $ticket = eval { registrationTicket($dbh, $params->{hash}) };
    return errorMessage('Could not process activation. Please try again later.') if $@;
    return errorMessage(registrationLinkError()) unless $ticket;
    my $error = '';
    if (defined $params->{setpass}) {
        $error = activateAccount($dbh, $params->{hash}, $params->{p1}, $params->{p2});
        return paddingTable(clearBox('Success', (new TemplateNS('success.html'))->expand()))
            if $error eq '';
    }
    my $template = new TemplateNS('activate.html');
    $template->setKeys(hash => $params->{hash}, error => $error);
    return paddingTable(clearBox('Activate Account', $template->expand()));
}

# make sure the user's application info is ok (input data is sane, no 
# collisions with other users)
#
sub checkNewUserInfo {
	my $params = shift;

	my $error = '';
	my $user = '';
	my $email	='';
	return 'Please enter a valid username and email address.<br/>'
		if ref($params->{user}) || ref($params->{email}) || ref($params->{license});
	
	if (!defined($params->{'license'}) || $params->{'license'} ne 'on') {
		$error .= "You must agree to the license for an account.<br/>";
	} 
	if (!defined($params->{'user'}) || $params->{'user'} eq '') {
		$error .= "You must enter a username<br/>"; 
	} else {
		$user = $params->{'user'};
		$error .= "Username is too long.<br/>" if length($user) > 32;
		if ($user =~ /[^\w\[\] ]/) {
			$error .= "Username contains invalid characters.<br/>"; }
		if ($user =~ /^ /) {
			$error .= "Username cannot begin with a space.<br/>"; }
		if ($user =~ / $/) {
			$error .= "Username cannot end with a space.<br/>"; }
		if ($user =~ / {2,}/) {
			$error .= "Username contains more than one space in a row.<br/>"; } 
	if (user_registered($params->{'user'},'username')) {
		$error .= "Sorry, that user name is taken.<br/>"; }
	}

	if (!defined($params->{'email'}) || $params->{'email'} eq '') {
		$error .= "You must enter an email address.<br/>"; 
	}
	else {
		$email = $params->{'email'};
		$error .= "Email address is too long.<br/>" if length($email) > 128;
		
	# TODO: add some real checks on email address here rfc 882
	#			 note: here is a fake check instead. this may be good enough.
	#
		if (not $email =~ /\A[\w\-.]+\@[\w\-.]+\z/ ) {
		$error .= "Please enter a <b>valid</b> email address.<br/>";
	}
	if (user_registered($email,'email')) {
			$error .= "Email address already in use.<br/>"; 
	}
	if (email_blacklisted($email)) {
		$error .= "That e-mail address is blacklisted! (shame on you!)<br />";
	}
	}

	return $error;
}

# check to see if an email address matches any of the blacklisted masks
#
sub email_blacklisted {
	my $address = shift;

	my ($rv, $sth) = dbSelect($dbh, {WHAT=>'mask', FROM=>getConfig('blist_tbl'), 'ORDER BY'=>'uid'});
	my @rows = dbGetRows($sth);
	
	foreach my $row (@rows) {
	
		my $mask = $row->{mask};

		return 1 if ($address =~ /$mask/);
	}

	return 0;
}

sub registrationLinkError {
    return 'This activation link is invalid, expired, or already used. Please request a new registration email.';
}

sub registrationTime {
    return time;
}

sub validRegistrationToken {
    my ($token) = @_;
    return defined($token) && !ref($token) && $token =~ /\A[0-9a-f]{64}\z/;
}

sub createRegistrationTicket {
    my ($user, $email) = @_;
    return undef if checkNewUserInfo({user => $user, email => $email, license => 'on'}) ne '';
    my $token = unpack('H*', passwordSalt() . passwordSalt());
    die "Registration unavailable.\n" unless validRegistrationToken($token);
    my $now = registrationTime();
    my $rv = dbExecuteBound($dbh,
        'INSERT INTO account_registration_tokens (token_hash, username, email, created, expires, used_at) VALUES (?, ?, ?, ?, ?, NULL)',
        sha256_hex('activation-v1:' . $token), $user, $email, $now, $now + 86400);
    return defined($rv) && $rv == 1 ? $token : undef;
}

sub registrationTicket {
    my ($db, $token) = @_;
    return undef unless validRegistrationToken($token);
    return dbSelectRowBound($db,
        'SELECT token_hash, username, email FROM account_registration_tokens WHERE token_hash = ? AND used_at IS NULL AND expires > ?',
        sha256_hex('activation-v1:' . $token), registrationTime());
}

sub withRegistrationLock {
    my ($db, $code) = @_;
    my $driver = $db->{Driver}->{Name} || '';
    my ($acquire, $release, @bind);
    if ($driver =~ /\A(?:mysql|MariaDB)\z/) {
        ($acquire, $release) = ('SELECT GET_LOCK(?, 5) AS acquired', 'SELECT RELEASE_LOCK(?) AS released');
        @bind = ('noosphere:account-registration-v1');
    } elsif ($driver eq 'Pg') {
        ($acquire, $release) = ('SELECT CAST(pg_try_advisory_lock(?, ?) AS integer) AS acquired',
            'SELECT CAST(pg_advisory_unlock(?, ?) AS integer) AS released');
        @bind = (1852796787, 1);
    } elsif ($driver eq 'SQLite') {
        dbExecuteBound($db, 'BEGIN IMMEDIATE');
    } else {
        die "Registration unavailable.\n";
    }
    if (defined $acquire) {
        my $row = dbSelectRowBound($db, $acquire, @bind);
        die "Registration unavailable.\n" unless $row && defined($row->{acquired}) && $row->{acquired} == 1;
    }
    my $result;
    my $ok = eval { $result = $code->(); 1 };
    my $released = eval {
        if (defined $release) {
            my $row = dbSelectRowBound($db, $release, @bind);
            die 'release failed' unless $row && defined($row->{released}) && $row->{released} == 1;
        } else {
            dbExecuteBound($db, $ok ? 'COMMIT' : 'ROLLBACK');
        }
        1;
    };
    eval { $db->disconnect } unless $released;
    die "Registration unavailable.\n" unless $ok && $released;
    return $result;
}

sub activateAccount {
	my $db = shift;
	my $hash = shift;
	my $p1 = shift;
	my $p2 = shift;
	
	return registrationLinkError() unless validRegistrationToken($hash);

	unless (defined($p1) && !ref($p1) && defined($p2) && !ref($p2) && $p1 eq $p2) {
	return("passwords are different, please reenter"); }

	unless ($p1 ne '' and $p2 ne '') {
	return("empty password, please reenter"); }

	local $dbh = $db;
	my ($newid, $user);
	my $error;
	my $ok = eval {
		my $ticket = registrationTicket($db, $hash);
		if (!$ticket) {
			$error = registrationLinkError();
		} else {
			my $encoded = hashAccountPassword($p1);
			my $defpreamble = (new TemplateNS(getConfig('default_preamble')))->expand();
			$error = withRegistrationLock($db, sub {
				# Recheck under the lock; separate emails may name the same account.
				$ticket = registrationTicket($db, $hash);
				return registrationLinkError() unless $ticket;
				return registrationLinkError() if checkNewUserInfo({user => $ticket->{username},
					email => $ticket->{email}, license => 'on'}) ne '';
				my $now = registrationTime();
				my $claimed = dbExecuteBound($db,
					'UPDATE account_registration_tokens SET used_at = ? WHERE token_hash = ? AND used_at IS NULL AND expires > ?',
					$now, $ticket->{token_hash}, $now);
				return registrationLinkError() unless defined($claimed) && $claimed == 1;
				$newid = nextval('users_uid_seq');
				die 'invalid account id' unless defined($newid) && $newid =~ /\A[1-9][0-9]*\z/;
				$user = $ticket->{username};
				my $rv = dbExecuteBound($db,
					"INSERT INTO users (uid, joined, username, password, password_hash, email, preamble) VALUES (?, CURRENT_TIMESTAMP, ?, '', ?, ?, ?)",
					$newid, $user, $encoded, $ticket->{email}, $defpreamble);
				die 'insert failed' unless defined($rv) && $rv == 1;
				return '';
			});
		}
		1;
	};
	return 'Could not activate the account. Please request a new registration email and try again.' unless $ok;
	return $error if $error ne '';

	# make the user's self-named default group and add them to it
	#
	makeDefaultGroup($newid);
	my $groupid = lookupfield(getConfig('groups_tbl'),"groupid","userid=$newid");
	addUserToGroup($groupid,$newid);
	
	# create the default ACL records
	#

	# rule : anyone can read
	addDefaultUserACL($newid,{default_or_normal=>'d',
							 user_or_group=>'u',
							 subjectid=>0,
							 perms=>{'read'=>1,'write'=>0,'acl'=>0}});

	# rule : people in self-named group can write
	addDefaultUserACL($newid,{default_or_normal=>'n',
							 user_or_group=>'g',
							 subjectid=>$groupid,
							 perms=>{'read'=>1,'write'=>1,'acl'=>0}});

	# add the user to the object title index
	#
	indexTitle(getConfig('user_tbl'), $newid, $newid, $user, $user);

	# index the user name in the search engine
	#
	irIndex(getConfig('user_tbl'), {uid=>$newid, username=>$user});
	
	return ''; 
}

1;
