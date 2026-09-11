package Noosphere;

use strict;
use Noosphere::PasswordStorage;

use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);

our $dbh;

use constant PASSWORD_RESET_TOKEN_BYTES => 32;
use constant DEFAULT_PASSWORD_RESET_TOKEN_LIFETIME => 2 * 60 * 60;

# change the password
#
sub pwChange {
  my $params = shift; 
  
  my $error = "";
  return errorMessage("Invalid password change URL.")
    unless defined($params->{hash}) && !ref($params->{hash});
  my $token = urlunescape($params->{"hash"});
 
  return errorMessage("Invalid password change URL.") unless validPasswordResetToken($token);
  my $ticket = eval { passwordResetTicket($token) };
  return errorMessage("Could not process the request. Please try again later.") if $@;
  if (!$ticket) {
    return errorMessage("Invalid password change URL.");
  }
  
  my $template = new TemplateNS('pwchange.html');

  # handle submission
  #
  if (defined $params->{submit}) {
    if (!defined($params->{pw1}) || ref($params->{pw1}) ||
        !defined($params->{pw2}) || ref($params->{pw2}) ||
        $params->{pw1} ne $params->{pw2}) {
	  $error .= "passwords don't match!<br>";
	}

    # make the password change
	if (!$error) {
      return changePassword($token,$params->{pw1});
	}
  }
  
  # initial form and error handling
  #
  $template->setKey('error',$error);
  $template->setKey('hash',$token);

  return paddingTable(makeBox('Change Your Password',$template->expand()));
}

# actual database change of password, plus return acknowledgement form 
#
sub changePassword {
  my $token = shift;
  my $password = shift;

  return errorMessage('Invalid password change URL.') unless validPasswordResetToken($token);
  my $ticket = eval { passwordResetTicket($token) };
  return errorMessage('Could not change the password. Please request a new link and try again.') if $@;
  return errorMessage('Invalid password change URL.') unless $ticket;
  return errorMessage('Please enter a password.')
    unless defined($password) && !ref($password) && length($password);
  my $rv = eval {
    my $encoded = hashAccountPassword($password);
    consumePasswordResetTicket($ticket, $encoded);
  };
  return errorMessage('Could not change the password. Please request a new link and try again.')
    unless defined($rv) && $rv > 0;

  # return an acknowledgement
  return paddingTable(makeBox('Password Changed','The password for <b>'.htmlescape($ticket->{username}).
    '</b> has been changed. <p> You may now log in using the new password.'));
}

# request a password change.  
#
sub pwChangeRequest {
  my $params = shift;

  my $template = new TemplateNS('reqpwchange.html');
  my $error = "";

  if (defined $params->{submit}) {
     my $username = $params->{username};
     my $row;
     if (defined($username) && !ref($username) && length($username)) {
       my $ok = eval {
         $row = dbSelectRowBound($dbh, 'SELECT username, email FROM '.getConfig('user_tbl').
           ' WHERE username = ? AND active = 1 LIMIT 1', $username);
         1;
       };
       return errorMessage('Could not process the request. Please try again later.') unless $ok;
     }
	 my $email = $row ? $row->{email} : undef;
	 if (!$email) {
	   $error .= "Cannot find that user!<br>";
	 }
     if (!$error) {
	   my $hash = eval { createPasswordResetTicket($row->{username}); };
	   return errorMessage('Could not process the request. Please try again later.')
	     unless defined($hash);
       # send out the message
	   return sendPwChangeMail($row->{username},$email, $hash);
	 }
  } 

  # return initial form
  #
  $template->setKey('username',ref($params->{username}) ? '' : $params->{username});
  $template->setKey('error',$error);
  
  return paddingTable(makeBox('Request a Password Change',$template->expand()));
}

# send out the message with further instructions, return an acknowledgement
#
sub sendPwChangeMail {
  my $username = shift;
  my $email = shift;
  my $hash = shift;

  $hash = urlescape($hash);
  #dwarn "HASH FOR PW CHANGE IS\n";
  #dwarn $hash; 
  # send the mail
  sendMail($email, "
  
Somebody (hopefully you) has requested a password change for the account \"$username.\"  To complete this change, go to the following URL:

 ".getConfig("main_url")."/?op=pwchange&hash=$hash

If you received this message without requesting it, it is possible someone is doing something malicious.  Let us know at ".getAddr('feedback').".
  
  ", getConfig('projname').": password change");

  return paddingTable(makeBox('Mail Sent',"A message was sent to <b>$email</b> with further instructions.  Please follow them to change your password."));
}

sub passwordResetTokenLifetime {
  my $seconds = eval { getConfig('password_reset_token_lifetime') };
  return DEFAULT_PASSWORD_RESET_TOKEN_LIFETIME
    unless defined($seconds) && !ref($seconds) && $seconds =~ /\A[1-9][0-9]*\z/;
  return $seconds;
}

sub passwordResetTime {
  my $offset = shift || 0;
  return strftime('%Y-%m-%d %H:%M:%S', gmtime(time + $offset));
}

sub newPasswordResetToken {
  my $bytes = '';
  while (length($bytes) < PASSWORD_RESET_TOKEN_BYTES) {
    $bytes .= passwordSalt();
  }
  return unpack('H*', substr($bytes, 0, PASSWORD_RESET_TOKEN_BYTES));
}

sub validPasswordResetToken {
  my $token = shift;
  return defined($token) && !ref($token) && $token =~ /\A[0-9a-f]{64}\z/;
}

sub passwordResetCredentialStamp {
  my ($password_hash) = @_;
  return undef unless validPasswordHash($password_hash);
  return sha256_hex('reset-v1:' . $password_hash);
}

sub createPasswordResetTicket {
  my $username = shift;
  return undef unless defined($username) && !ref($username) && length($username);
  my $user = dbSelectRowBound($dbh, 'SELECT uid, password_hash FROM '.getConfig('user_tbl').
    ' WHERE username = ? AND active = 1 LIMIT 1', $username);
  return undef unless $user;
  my $stamp = passwordResetCredentialStamp($user->{password_hash});
  return undef unless defined $stamp;
  my $token = newPasswordResetToken();
  my $now = passwordResetTime();
  my $expires = passwordResetTime(passwordResetTokenLifetime());
  dbExecuteBound($dbh,
    'DELETE FROM password_reset_tokens WHERE uid = ? AND (used_at IS NOT NULL OR expires < ?)',
    $user->{uid}, $now);
  my $rv = dbExecuteBound($dbh,
    'INSERT INTO password_reset_tokens (uid, token_hash, created, expires, used_at, credential_stamp) VALUES (?, ?, ?, ?, NULL, ?)',
    $user->{uid}, sha256_hex($token), $now, $expires, $stamp);
  return defined($rv) && $rv > 0 ? $token : undef;
}

sub passwordResetTicket {
  my $token = shift;
  return undef unless validPasswordResetToken($token);
  my $ticket = dbSelectRowBound($dbh, 'SELECT pr.uid, pr.token_hash, pr.credential_stamp, u.username, u.password_hash FROM password_reset_tokens pr '.
    'JOIN '.getConfig('user_tbl').' u ON u.uid = pr.uid '.
    'WHERE pr.token_hash = ? AND pr.used_at IS NULL AND pr.expires >= ? AND u.active = 1 LIMIT 1',
    sha256_hex($token), passwordResetTime());
  return undef unless $ticket && defined($ticket->{credential_stamp});
  my $stamp = passwordResetCredentialStamp($ticket->{password_hash});
  return defined($stamp) && $stamp eq $ticket->{credential_stamp} ? $ticket : undef;
}

sub consumePasswordResetTicket {
  my ($ticket, $password_hash) = @_;
  return 0 unless $ticket && $ticket->{uid} && $ticket->{token_hash};
  my $stamp = passwordResetCredentialStamp($ticket->{password_hash});
  return 0 unless defined($stamp) && defined($ticket->{credential_stamp}) &&
    $stamp eq $ticket->{credential_stamp} && validPasswordHash($password_hash);
  my $used = passwordResetTime();
  my $rv = dbExecuteBound($dbh,
    'UPDATE password_reset_tokens SET used_at = ? WHERE token_hash = ? AND used_at IS NULL AND expires >= ?',
    $used, $ticket->{token_hash}, $used);
  return 0 unless defined($rv) && $rv == 1;
  # Compare and update in one statement so prevalidated sibling links cannot race.
  my $match = ($dbh->{Driver}->{Name} || '') =~ /\A(?:mysql|MariaDB)\z/
    ? 'BINARY password_hash = BINARY ?' : 'password_hash = ?';
  return dbExecuteBound($dbh, 'UPDATE '.getConfig('user_tbl').
    " SET password_hash = ?, password = '' WHERE uid = ? AND active = 1 AND $match",
    $password_hash, $ticket->{uid}, $ticket->{password_hash});
}

1;
