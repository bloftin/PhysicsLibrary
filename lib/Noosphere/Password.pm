package Noosphere;

use strict;

use Digest::SHA1 qw(sha1_hex);

# change the password
#
sub pwChange {
  my $params = shift; 
  
  my $error = "";
  return errorMessage("Invalid password change URL.")
    unless defined($params->{hash}) && !ref($params->{hash});
  my $hash = urlunescape($params->{"hash"});
 
  # check for a valid hash
  #
  my $herr = checkHash($hash);
  if ($herr eq 'invalid hash') { 
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
      return changePassword($hash,$params->{pw1});
	}
  }
  
  # initial form and error handling
  #
  $template->setKey('error',$error);
  $template->setKey('hash',$hash);

  return paddingTable(makeBox('Change Your Password',$template->expand()));
}

# actual database change of password, plus return acknowledgement form 
#
sub changePassword {
  my $hash = shift;
  my $password = shift;

  return errorMessage('Invalid password change URL.') unless checkHash($hash) eq '';
  return errorMessage('Please enter a password.')
    unless defined($password) && !ref($password) && length($password);
  my ($username, $email) = split(/:/,$hash);
  my $rv = eval { dbExecuteBound($dbh, 'UPDATE '.getConfig('user_tbl').
    ' SET password = ? WHERE username = ? AND email = ?', $password, $username, $email) };
  return errorMessage('Could not change the password. Please request a new link and try again.')
    unless defined($rv) && $rv > 0;

  # return an acknowledgement
  return paddingTable(makeBox('Password Changed','The password for <b>'.htmlescape($username).
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
           ' WHERE username = ? LIMIT 1', $username);
         1;
       };
       return errorMessage('Could not process the request. Please try again later.') unless $ok;
     }
	 my $email = $row ? $row->{email} : undef;
	 if (!$email) {
	   $error .= "Cannot find that user!<br>";
	 }
     if (!$error) {
	   # make the hash
	   my $hash=sha1_hex(join(':',$row->{username},$email),SECRET);
	   #dwarn "HASH for a pwchange is\n";
	   #dwarn $hash;
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

  $hash = urlescape($username.':'.$email.':'.$hash);
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

1;
