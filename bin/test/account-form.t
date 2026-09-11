#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

our ($request, $record, $saved, $query, $failure, $reads, $template_vars);
our $secret = 'synthetic-test-key-not-a-deployment-value';

{
    package Noosphere;
    use Digest::SHA qw(hmac_sha256_hex);
    use Noosphere::TemplateNS;
    our $dbh = bless {}, 'AccountDatabase';
    sub SECRET { return $main::secret; }
    sub getUserData { $main::reads++; return $main::record; }
    sub loginExpired { return 'Please sign in again.'; }
    sub errorMessage { return $_[0]; }
    sub makeBox { return join('', @_); }
    sub paddingTable { return $_[0]; }
    sub getConfig {
        return {
            stemplate_path => "$FindBin::Bin/../../stemplates", siteaddrs => {},
            main_url => 'https://example.invalid', template_cmd_prefix => 'NS',
        }->{$_[0]};
    }
    sub readFile {
        open my $in, '<', $_[0] or die $!;
        local $/;
        return <$in>;
    }
    sub htmlescape {
        my $value = defined($_[0]) ? $_[0] : '';
        $value =~ s/&/&amp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
        return $value;
    }
    sub urlescape { die 'unexpected query interpolation'; }
}
{
    package Apache2::RequestUtil;
    sub request { return $main::request; }
    package AccountRequest;
    sub method { return $_[0]->{method}; }
    sub headers_out { return $_[0]; }
    sub set { $_[0]->{$_[1]} = $_[2]; }
    package AccountDatabase;
    sub prepare {
        $main::query = $_[1];
        return undef if $main::failure eq 'prepare';
        return bless {}, 'AccountStatement';
    }
    package AccountStatement;
    sub execute {
        die 'synthetic database detail' if $main::failure eq 'exception';
        return undef if $main::failure eq 'execute';
        return '0E0' if $main::failure eq 'zero';
        $main::saved = [@_[1 .. $#_]];
        my @fields = $main::query =~ /(?:SET |, )(\w+) = \?/g;
        @{$main::record}{@fields} = @{$main::saved}[0 .. $#fields];
        return 1;
    }
    sub finish { return 1; }
}

open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/UserData.pm" or die $!;
my $source = do { local $/; <$in> };
close $in;
for my $name (qw(profileEditableFields profileUserValid profileFormToken
        profileTokenMatches changeUserData editUserData)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name not found" unless defined $sub;
    eval "package Noosphere; our \$dbh; $sub";
    die $@ if $@;
}
my $expand = \&TemplateNS::expand;
{
    no warnings 'redefine';
    *TemplateNS::expand = sub {
        $template_vars = {%{$_[0]->{VALUES}}};
        return $expand->(@_);
    };
}

sub fixture {
    $record = {
        uid => 42, active => 1, username => 'test-user', access => 10,
        email => 'test@example.invalid', password => 'synthetic-password',
        prefs => 'hideemail=on', score => 7, lastip => '192.0.2.1',
        forename => 'Before', surname => 'Example', bio => 'Old bio',
    };
    $request = bless {method => 'POST'}, 'AccountRequest';
    ($saved, $query, $template_vars) = (undef, undef, undef);
    ($failure, $reads) = ('', 0);
    $secret = 'synthetic-test-key-not-a-deployment-value';
    return {uid => 42, ticket => 'synthetic-session-one', data => {%$record}};
}
sub params {
    my ($user, %extra) = @_;
    return {profile_token => Noosphere::profileFormToken($user), %extra};
}

subtest 'normal profile saves' => sub {
    my $user = fixture();
    my $values = params($user, forename => "O'Neil", surname => "Garc\x{ed}a",
        city => 'Denver', state => 'CO', country => 'US', homepage => 'https://example.invalid',
        sig => 'Regards', bio => '<b>Physics</b>', preamble => '\\usepackage{amsmath}');
    is(Noosphere::changeUserData($values, $user), 'Profile updated.', 'save succeeds');
    is($query, 'UPDATE users SET forename = ?, surname = ?, city = ?, state = ?, country = ?, homepage = ?, sig = ?, bio = ?, preamble = ? WHERE uid = ? AND active = 1',
        'fixed columns and bound values');
    is_deeply($saved, [@{$values}{Noosphere::profileEditableFields()}, 42],
        'all ordinary fields bound unchanged to signed-in user');
    is($values->{forename}, "O'Neil", 'input is not rewritten');
    ($saved, $query) = (undef, undef);
    is(Noosphere::changeUserData(params($user, forename => ''), $user), 'Profile updated.',
        'explicit clearing works');
    is($record->{surname}, "Garc\x{ed}a", 'omitted field retained');
    ($saved, $query) = (undef, undef);
    is(Noosphere::changeUserData(params($user, forename => ''), $user), 'No changes', 'unchanged save');
    ok(!defined($query), 'no unnecessary update');
};

subtest 'account fields are not profile fields' => sub {
    for my $access (10, 100) {
        my $user = fixture();
        $user->{data}->{access} = $record->{access} = $access;
        my %attempt = map { $_ => 'changed-value' } qw(uid username access password active
            email prefs score joined last lastip future_column);
        $attempt{id} = 99;
        my $values = params($user, %attempt, forename => 'After');
        is(Noosphere::changeUserData($values, $user), 'Profile updated.', 'ordinary field still saves');
        is($query, 'UPDATE users SET forename = ? WHERE uid = ? AND active = 1',
            'no extra columns, including for administrators');
        is_deeply($saved, ['After', 42], 'submitted identifiers never select another account');
        is($record->{email}, 'test@example.invalid', 'recovery address unchanged');
        is($record->{access}, $access, 'authorization unchanged');
        ($saved, $query) = (undef, undef);
        is(Noosphere::changeUserData(params($user, %attempt), $user), 'No changes',
            'account-only submission has no effect');
        ok(!defined($query), 'no database update');
    }
};

subtest 'request method and token' => sub {
    for my $method (qw(GET HEAD PUT PATCH DELETE OPTIONS)) {
        my $user = fixture();
        $request->{method} = $method;
        like(Noosphere::changeUserData(params($user, forename => 'After', method => 'POST'), $user),
            qr/Use the profile form/, "$method cannot update");
        ok(!defined($query), 'no write');
    }
    for my $token (undef, '', 'bad', 'a' x 64, ['a' x 64], ('a' x 64)."\n") {
        my $user = fixture();
        like(Noosphere::changeUserData({profile_token => $token, forename => 'After'}, $user),
            qr/form has expired/, 'invalid token rejected');
        is($reads, 0, 'no database access');
    }
    my $user = fixture();
    my $token = Noosphere::profileFormToken($user);
    like($token, qr/\A[0-9a-f]{64}\z/, 'opaque token');
    for my $i (0, 31, 63) {
        my $altered = $token;
        substr($altered, $i, 1) = substr($token, $i, 1) eq 'a' ? 'b' : 'a';
        ok(!Noosphere::profileTokenMatches($altered, $token), 'all positions compared');
    }
    my $other = {%$user, uid => 43, data => {%{$user->{data}}, uid => 43}};
    isnt(Noosphere::profileFormToken($other), $token, 'user-bound');
    like(Noosphere::changeUserData({profile_token => Noosphere::profileFormToken($other)}, $user),
        qr/form has expired/, 'another user token rejected');
    $user->{ticket} = 'synthetic-session-two';
    isnt(Noosphere::profileFormToken($user), $token, 'session-bound');
    like(Noosphere::changeUserData({profile_token => $token}, $user), qr/form has expired/,
        'previous login token rejected');
    $secret = '';
    ok(!defined(Noosphere::profileFormToken($user)), 'missing key fails closed');
    like(Noosphere::changeUserData({profile_token => $token}, $user), qr/form has expired/,
        'missing key cannot authorize a save');
};

subtest 'authenticated active account required' => sub {
    for my $case (qw(guest zero malformed missing mismatched inactive ticket)) {
        my $user = fixture();
        my $values = params($user, forename => 'After');
        $user->{uid} = -1 if $case eq 'guest';
        $user->{uid} = 0 if $case eq 'zero';
        $user->{uid} = "42\n" if $case eq 'malformed';
        $user->{data} = undef if $case eq 'missing';
        $user->{data}->{uid} = 99 if $case eq 'mismatched';
        $user->{data}->{active} = 0 if $case eq 'inactive';
        $user->{ticket} = undef if $case eq 'ticket';
        like(Noosphere::changeUserData($values, $user), qr/sign in again/, "$case blocked");
        like(Noosphere::editUserData($values, $user), qr/sign in again/, 'form also blocked');
        ok(!defined($query), 'no write');
    }
    for my $state ('inactive', 'deleted') {
        my $user = fixture();
        my $values = params($user, forename => 'After');
        $state eq 'deleted' ? ($record = undef) : ($record->{active} = 0);
        like(Noosphere::changeUserData($values, $user), qr/sign in again/, 'fresh account state checked');
        ok(!defined($query), 'no write');
    }
};

subtest 'validation and database failures' => sub {
    for my $value (['invalid'], {invalid => 1}, 'x' x 65) {
        my $user = fixture();
        like(Noosphere::changeUserData(params($user, forename => $value), $user),
            qr/Invalid profile field|too long/, 'invalid value rejected');
        ok(!defined($query), 'no write');
    }
    for my $mode (qw(prepare execute exception zero)) {
        my $user = fixture();
        $failure = $mode;
        is(Noosphere::changeUserData(params($user, forename => 'After'), $user),
            'Could not save your profile. Please try again.', "$mode not reported as success");
    }
};

subtest 'render and submit actual form template' => sub {
    my $user = fixture();
    $request->{method} = 'GET';
    $record->{username} = '<script>not markup</script>';
    $record->{bio} = '</textarea><script>not markup</script>';
    my $html = Noosphere::editUserData(params($user, forename => 'Ignored'), $user);
    ok(!defined($query), 'GET with update parameters does not write');
    is($request->{'Cache-Control'}, 'no-store', 'form response is not cached');
    like($html, qr/method="post" action="https:\/\/example.invalid\/\?op=edituser"/, 'POST to own-profile route');
    my ($token) = $html =~ /name="profile_token" value="([0-9a-f]{64})"/;
    is($token, Noosphere::profileFormToken($user), 'hidden session-bound token');
    unlike($html, qr/name="(?:id|uid|email|password|access|active)"/, 'no editable account controls');
    like($html, qr/test\@example.invalid/, 'existing email is read-only');
    unlike($html, qr/<script>/, 'profile text is escaped in the form');
    for my $key (qw(uid username password access active prefs lastip ticket)) {
        ok(!exists($template_vars->{$key}), "$key not passed to template");
    }
    unlike($html, qr/synthetic-session|synthetic-test-key|synthetic-password/, 'no session or credentials in HTML');
    $request->{method} = 'POST';
    $html = Noosphere::editUserData({profile_token => $token, forename => 'After'}, $user);
    like($html, qr/Profile updated\./, 'form round trip succeeds');
    like($html, qr/name="forename" value="After"/, 'saved value is shown');
    is($user->{data}->{forename}, 'After', 'request user data refreshed');
    ($saved, $query) = (undef, undef);
    $html = Noosphere::editUserData({forename => 'Ignored'}, $user);
    like($html, qr/form has expired/, 'missing token has a useful error');
    ok(!defined($query), 'missing token does not write');
    $request->{method} = 'PUT';
    like(Noosphere::editUserData({}, $user), qr/Use the profile form/, 'other methods rejected by form handler');
};

done_testing();
