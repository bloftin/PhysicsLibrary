#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Template;

our $dbh;
my $record;
my $template_vars;
my $queries = 0;
my $saved_prefs;
my $email = 'profile-test@example.invalid';
my $base_record = {
    uid => 42, username => 'profile-test', active => 1, access => 0,
    email => $email, prefs => 'hideemail=on',
    password => 'not-a-real-password', lastip => '192.0.2.1',
};

sub getConfig {
    return {
        main_url => 'https://physicslibrary.org', index_tbl => 'objectindex',
        access_admin => 50, access_seehiddenemail => 100,
        template_path => "$FindBin::Bin/../../stemplates",
        prefs_schema => {hideemail => ['Hide email', 'check', 'on']},
    }->{$_[0]};
}
sub dbSelect { $queries++; return (1, bless({}, 'ProfileStatement')); }
{ package ProfileStatement;
  sub fetchrow_hashref { return $record; }
}
sub getrowcount { return 0; }
sub getCorrectionsReceivedCount { return 0; }
sub getCorrectionsFiledCount { return 0; }
sub urlescape { return $_[0]; }
sub errorMessage { return $_[0]; }
sub setUserPrefs { $saved_prefs = { %{$_[1]} }; }

# Exercise the production handler and preference code without the site database.
open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/UserData.pm" or die $!;
my $source = do { local $/; <$in> };
close $in;
for my $name (qw(validUserId parsePrefs changePrefs getUser)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name not found" unless defined $sub;
    eval $sub;
    die $@ if $@;
}

my $process = \&Template::process;
{
    no warnings 'redefine';
    *Template::process = sub {
        $template_vars = $_[2];
        return $process->(@_);
    };
}

sub render_profile {
    my ($prefs, $viewer_id, $access, $active) = @_;
    $record = {%$base_record, prefs => $prefs, active => $active // 1};
    $queries = 0;
    return getUser({id => 42}, {
        uid => $viewer_id, data => {access => $access},
        prefs => {hideemail => 'off'},
    });
}

for my $case (
    ['guest, hidden', 'hideemail=on', -1, 0, 0],
    ['guest, visible preference', 'hideemail=off', -1, 0, 0],
    ['zero-id guest', 'hideemail=off', 0, 0, 0],
    ['other member, hidden', 'hideemail=on', 7, 0, 0],
    ['other member, visible', 'hideemail=off', 7, 0, 1],
    ['owner, hidden', 'hideemail=on', 42, 0, 1],
    ['owner, visible', 'hideemail=off', 42, 0, 1],
    ['admin below email permission', 'hideemail=on', 7, 50, 0],
    ['admin at email permission', 'hideemail=on', 7, 100, 1],
    ['admin above email permission', 'hideemail=on', 7, 101, 1],
    ['guest cannot use admin exception', 'hideemail=on', -1, 100, 0],
    ['missing preference defaults to hidden', '', 7, 0, 0],
    ['malformed preference stays hidden', 'hideemail=unexpected', 7, 0, 0],
) {
    my ($label, $prefs, $uid, $access, $visible) = @$case;
    subtest $label => sub {
        my $html = render_profile($prefs, $uid, $access);
        is(index($html, $email) >= 0 ? 1 : 0, $visible, 'rendered email follows policy');
        is(exists($template_vars->{user}->{email}) ? 1 : 0, $visible,
            'unauthorized email never reaches the template');
        if ($uid <= 0) {
            unlike($html, qr/E-mail Address:/, 'guest has no email row');
        } elsif (!$visible) {
            like($html, qr/Email hidden by user preferences\./, 'member sees hidden notice');
        }
        unlike($html, qr/working preferences working right/, 'temporary disable removed');
        ok(!exists($template_vars->{user}->{password}) &&
            !exists($template_vars->{user}->{prefs}) &&
            !exists($template_vars->{user}->{lastip}), 'private account fields are not passed');
        is($queries, 1, 'profile loaded once, with no template database queries');
    };
}

my $html = render_profile('hideemail=off', 42, 100, 0);
like($html, qr/This account has been deactivated/, 'inactive account notice remains');
unlike($html, qr/\Q$email\E/, 'inactive profile does not display email');
ok(!exists($template_vars->{user}->{email}), 'inactive profile email is not passed');

$base_record->{email} = 'test+<tag>&"@example.invalid';
$html = render_profile('hideemail=off', 42, 0);
like($html, qr/test\+&lt;tag&gt;&amp;&quot;\@example\.invalid/, 'visible email is HTML escaped');
unlike($html, qr/<tag>/, 'email cannot add HTML markup');
$base_record->{email} = $email;

my $prefs = parsePrefs('hideemail=off');
changePrefs(42, {submit => 1, hideemail => 'on'}, $prefs);
is($saved_prefs->{hideemail}, 'on', 'checking privacy setting saves on');
$html = render_profile('hideemail=' . $saved_prefs->{hideemail}, 7, 0);
unlike($html, qr/\Q$email\E/, 'saved hidden setting hides email from another member');
changePrefs(42, {submit => 1}, $prefs);
is($saved_prefs->{hideemail}, 'off', 'unchecking privacy setting saves off');
$html = render_profile('hideemail=' . $saved_prefs->{hideemail}, 7, 0);
like($html, qr/\Q$email\E/, 'saved visible setting shows email to another member');

$queries = 0;
is(getUser({id => ''}, {uid => -1, data => {access => 0}}),
    'Invalid user id.', 'invalid profile request rejected');
is($queries, 0, 'invalid id does not query database');
$record = undef;
is(getUser({id => 999}, {uid => -1, data => {access => 0}}),
    'User not found.', 'missing profile handled before template');
done_testing();
