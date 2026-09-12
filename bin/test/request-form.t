#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RequestForm;
use Noosphere::Dispatch;
use HTML::Parser;
use Encode ();
use bytes ();

our $request;
{
    package Noosphere;
    sub dwarn { die 'unexpected diagnostic'; }
    sub getConfig { return 'https://example.invalid' if $_[0] eq 'main_url'; }
    package Apache2::RequestUtil;
    sub request { return $main::request; }
    package FormRequest;
    sub method { return $_[0]->{method}; }
    sub header_in { return $_[0]->{headers}{$_[1]}; }
    sub args { return $_[0]->{args}; }
    sub content { return %{$_[0]->{body} || {}}; }
    sub read { $_[1] = $_[0]->{raw_body}; return length($_[1]); }
    sub unparsed_uri { return '/'; }
    sub uri { return '/'; }
    sub headers_out { return $_[0]; }
    sub set { $_[0]->{out}{$_[1]} = $_[2]; }
    sub add { $_[0]->set($_[1], $_[2]); }
    sub status { $_[0]->{status} = $_[1] if @_ > 1; return $_[0]->{status}; }
    sub content_type { return 'text/html'; }
    sub print { $_[0]->{output} = $_[1]; }
    sub rflush { }
}

sub fixture {
    $request = bless {method => 'POST', headers => {}}, 'FormRequest';
    $Noosphere::RequestFormStatus = undef;
    return {uid => 42, ticket => 'a' x 64, data => {uid => 42, active => 1}};
}

subtest 'session binding' => sub {
    my $user = fixture();
    my $token = Noosphere::requestFormToken($user);
    like($token, qr/\A[0-9a-f]{64}\z/, 'opaque form token');
    isnt($token, $user->{ticket}, 'session cookie is not the form token');
    isnt($token, Noosphere::requestFormToken({%$user, uid => 43}), 'bound to account');
    isnt($token, Noosphere::requestFormToken({%$user, ticket => 'b' x 64}), 'bound to login');
    for my $value (undef, '', [], 'a', $token.'x', uc($token), '0' x 64) {
        ok(!Noosphere::requestFormTokenMatches($value, $token), 'invalid token rejected');
    }
    ok(!defined Noosphere::requestFormToken({%$user, data => {active => 0}}), 'inactive account');
    ok(!defined Noosphere::requestFormToken({uid => -1}), 'anonymous account');
};

subtest 'mutations stop before dispatch' => sub {
    my $user = fixture();
    my @cases = (
        [editprefs => {submit => 1}], [postmsg => {body => 'hello', subject => 'test'}],
        [sendmail => {post => 1}], [replymail => {post => 1}], [vote => {option => 1}],
        [getobj => {watch => 'add'}], [getmsg => {watch => 1, watch_42 => 1}],
        [viewobj => {watch => 'remove'}], [viewpoll => {watch => 'add'}],
        [notices => {delall => ''}], [watches => {delsel => 1}],
        [edit => {lock => 1}], [edit => {remove => 'figure.png'}],
        [edit => {filebox => 'upload', fb_urls => 'https://example.invalid/image.png'}],
        [edit => {post => 1}], [edit => {save => 1}], [adden => {post => 1}],
        [editcollab => {save => 1}], [collab_edit_comment => {save => 1}],
        [collab_publish => {}], [collab_release_lock => {}], [addsitedoc => {id => 22}],
        [acledit => {addrule => 1}], [acledit => {replaceall => 1}],
        [acledit => {delete_42 => 1}], [memberedit => {del_42 => 1}],
        [groupedit => {delgroup => 1}], [creategroup => {}], [addusertogroup => {}],
        [rerender => {}], [delobj => {}], [rollback => {confirm => 1}],
        [adminedit => {submit2 => 1}], [adminclassify => {submit => 1}],
        [dbadmin => {freeform => 1}], [blacklist => {add => 1}],
        [deactivate => {}], [reactivate => {}], [deluser => {}],
        [confirmreq => {}], [confirmallreq => {}], [denyreq => {submit => 1}],
        [deletereq => {submit => 1}], [updatereq => {submit => 1}],
        [cachecont => {invalidate => 1}], [exercise_option => {params => 'op=sendobj'}],
        [abandon => {}], [adopt => {}], [sendobj => {}], [acceptobj => {}],
        [rejectobj => {}], [unsend => {}], [new_route => {submit => 1}],
    );
    for my $case (@cases) {
        my ($op, $extra) = @$case;
        my $calls = 0;
        my $handlers = {$op => sub { $calls++; return 'saved'; }};
        my $params = {op => $op, %$extra};
        for my $method (qw(GET HEAD POST PUT DELETE)) {
            $request->{method} = $method;
            Noosphere::dispatch($handlers, {%$params}, $user);
            is($calls, 0, "$op: $method without token never calls handler");
        }
        $request->{method} = 'POST';
        is(Noosphere::dispatch($handlers, {%$params,
            _form_token => Noosphere::requestFormToken($user)}, $user), 'saved', "$op: valid form works");
        is($calls, 1, "$op: called once");
    }
};

subtest 'read routes and editor navigation' => sub {
    my $user = fixture();
    $request->{method} = 'GET';
    is(Noosphere::dispatch(\%Noosphere::HANDLERS, {}, $user), '', 'bare home URL uses normal fallback');
    for my $op (Noosphere::requestFormReadRoutes(), qw(notices watches)) {
        ok(!Noosphere::requestFormNeedsProtection({op => $op}, 'GET'), "$op can be viewed");
    }
    for my $params ({op => 'editprefs'}, {op => 'edit', from => 'objects', id => 1017},
            {op => 'acledit', from => 'collab', id => 22}, {op => 'memberedit', gid => 1},
            {op => 'postmsg', from => 'objects', id => 1017, replyto => 42},
            {op => 'adden', class => 'pacs:46.40.Cd, pacs:46.40.-f, pacs:02.30.Jr',
                type => 'Example',
                parent => 'WaveMechanicsDerivingThe1DStringWaveEquationFromNewtonsSecondLaw',
                title => "example of Wave Mechanics: Deriving the 1D String Wave Equation from Newton's Second Law"},
            {op => 'adden', request => 18, title => 'proof of a request', type => 'Proof',
                parent => 'SomeArticle'}) {
        is(Noosphere::requestFormGuard($request, $params, $user), undef, 'initial form opens directly');
        ok(Noosphere::requestFormNeedsProtection({%$params, unexpected_action => 1}, 'GET'),
            'extra navigation parameter requires confirmation');
        ok(Noosphere::requestFormNeedsProtection($params, 'POST'), 'POST to editor requires token');
    }
};

subtest 'origin checks' => sub {
    my $user = fixture();
    my $params = {op => 'editprefs', submit => 1, _form_token => Noosphere::requestFormToken($user)};
    for my $origin ('https://other.invalid', 'https://example.invalid.evil.test',
            'http://example.invalid', 'https://example.invalid:444', 'null',
            'https://evil.test@example.invalid', 'https://example.invalid https://other.invalid') {
        $request->{headers} = {Origin => $origin};
        ok(defined Noosphere::requestFormGuard($request, $params, $user), "reject $origin");
    }
    for my $headers ({Origin => 'https://example.invalid'},
            {Referer => 'https://example.invalid/?op=editprefs'}, {}) {
        $request->{headers} = $headers;
        is(Noosphere::requestFormGuard($request, $params, $user), undef, 'valid token with compatible headers');
    }
    for my $site ('same-site', 'cross-site') {
        $request->{headers} = {'Sec-Fetch-Site' => $site};
        ok(defined Noosphere::requestFormGuard($request, $params, $user), 'foreign fetch rejected');
    }
    for my $op (qw(login logout newuser activate pwchangereq pwchange)) {
        $request->{headers} = {};
        ok(length Noosphere::requestAccountOriginError($request, {op => $op}), "$op POST needs origin evidence");
        $request->{headers} = {Origin => 'https://example.invalid'};
        is(Noosphere::requestAccountOriginError($request, {op => $op}), '', "$op same-origin POST");
    }
    $request->{method} = 'GET';
    ok(length Noosphere::requestAccountOriginError($request, {op => 'login'}), 'GET cannot switch login');
    is(Noosphere::requestAccountOriginError($request, {op => 'activate'}), '', 'emailed activation link still opens');
};

subtest 'confirmation and nested notice actions' => sub {
    my $user = fixture();
    $request->{method} = 'GET';
    my $token = Noosphere::requestFormToken($user);
    my $page = Noosphere::requestFormGuard($request,
        {op => 'rerender', id => 1017, from => 'objects', value => '"><script>alert(1)</script>'}, $user);
    like($page, qr/Confirm Action/, 'GET shows a confirmation');
    like($page, qr/method="post"/, 'confirmation uses POST');
    like($page, qr/name="_form_token" value="$token"/, 'confirmation has session token');
    unlike($page, qr/<script>/, 'request data escaped');
    unlike($page, qr/(?:href|action)="[^"]*\Q$token\E/, 'token never placed in link');
    $request->{method} = 'POST';
    my $calls = 0;
    my $nested = {sendobj => sub { $calls++; return 'nested'; }};
    my $outer = {exercise_option => sub {
        ok(!exists $_[0]->{_form_token}, 'token removed before legacy code');
        return Noosphere::dispatch($nested, {op => 'sendobj'}, $_[1]);
    }};
    is(Noosphere::dispatch($outer, {op => 'exercise_option', _form_token => $token}, $user),
        'nested', 'validated notice may call nested handler');
    is($calls, 1, 'nested call executed once');
    Noosphere::dispatch($nested, {op => 'sendobj'}, $user);
    is($calls, 1, 'validation context does not persist to next dispatch');
};

subtest 'forms preserve content and do not leak tokens' => sub {
    my $user = fixture();
    my $token = Noosphere::requestFormToken($user);
    my $body = q{<script>var a = '<form method="post">';</script>}.
        q{<pre>TeX &lt;form&gt; \begin{align} x&amp;=y \end{align}</pre>}.
        q{<form method="post" action="/?op=editprefs" enctype="multipart/form-data">}.
        q{<textarea name="data">a &lt; b, "quotes", \end{document}</textarea>}.
        q{<input name="submit" type="submit" value="Save"></form>}.
        q{<form method=get action="/"><input name=op value=vote><input name=option value=1></form>}.
        q{<form method=get action="/"><input name=op value=search></form>}.
        q{<form method=post action="https://other.invalid/"><input name=op value=editprefs></form>}.
        q{<form method=post action="https://example.invalid.evil.test/"><input name=op value=editprefs></form>}.
        q{<form method=post action="https://example.invalid/cache/x"><input name=op value=editprefs></form>}.
        q{<form method=post action="/"><input name=op value=editprefs><button formaction="https://other.invalid">Go</button></form>}.
        q{<form method=post id=outside action="/"><input name=op value=editprefs></form>}.
        q{<button form=outside formmethod=get>Go</button>}.
        q{<form method=post action="/"><input name=op value=editprefs><input name=_form_token value=old></form>};
    my $html = Noosphere::requestFormDecorate($body, $user, '/');
    my $count = () = $html =~ /name="_form_token" value="$token"/g;
    is($count, 3, 'only eligible local forms carry a token');
    like($html, qr/method="post"[^>]*><input type="hidden" name="_form_token"[^>]*><input name=op value=vote>/,
        'legacy voting GET form converted');
    like($html, qr{<form method=get action="/"><input name=op value=search></form>}, 'search unchanged');
    like($html, qr/\Q<script>var a = '<form method="post">';<\/script>\E/, 'script content preserved');
    like($html, qr{\Q<textarea name="data">a &lt; b, "quotes", \end{document}</textarea>\E}, 'source preserved');
    like($html, qr/enctype="multipart\/form-data"/, 'upload encoding preserved');
    unlike($html, qr/value=old/, 'stale hidden token replaced');
    is(Noosphere::requestFormDecorate($html, $user, '/'), $html, 'decoration is idempotent');
    is(Noosphere::requestFormDecorate($body, {uid => -1}, '/'), $body, 'no anonymous token');
    my $query = Noosphere::requestFormDecorate(
        '<form method=post action="/?op=editprefs&amp;_form_token=old"><button>Save</button></form>', $user, '/');
    unlike($query, qr/action="[^"]*_form_token/, 'old query token removed');
    $query = Noosphere::requestFormDecorate(
        '<form method=post action="/?_form_token=old"><input name=op value=editprefs></form>', $user, '/');
    unlike($query, qr/action="[^"]*_form_token/, 'token-only query is cleared');
};

subtest 'query tokens cannot authorize body submissions' => sub {
    require CGI::Util;
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/Params.pm" or die $!;
    my $source = do { local $/; <$in> };
    for my $name (qw(ismime parseMime readMime parseGetArgs parseParams)) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "missing $name" unless $sub;
        eval "package Noosphere; no warnings 'uninitialized'; $sub";
        die $@ if $@;
    }
    my $user = fixture();
    my $token = Noosphere::requestFormToken($user);
    $request->{args} = "op=editprefs&_form_token=$token";
    $request->{body} = {submit => 1};
    my ($params) = Noosphere::parseParams($request);
    ok(!exists $params->{_form_token}, 'query token discarded');
    ok(defined Noosphere::requestFormGuard($request, $params, $user), 'query-only token rejected');
    $request->{body}{_form_token} = $token;
    ($params) = Noosphere::parseParams($request);
    is(Noosphere::requestFormGuard($request, $params, $user), undef, 'body token accepted');

    my $boundary = 'test-form-boundary';
    $request->{raw_body} = join('', map {
        "--$boundary\r\nContent-Disposition: form-data; name=\"$_->[0]\"\r\n\r\n$_->[1]\r\n"
    } ['op', 'edit'], ['save', '1'], ['_form_token', $token])."--$boundary--\r\n";
    $request->{headers} = {'Content-type' => "multipart/form-data; boundary=$boundary",
        'Content-Length' => length($request->{raw_body})};
    $request->{args} = '';
    ($params) = Noosphere::parseParams($request);
    is($params->{op}, 'edit', 'multipart action parsed');
    is($params->{_form_token}, $token, 'multipart token preserved');
    is(Noosphere::requestFormGuard($request, $params, $user), undef, 'multipart form accepted');
    $request->{raw_body} =~ s/\Q$token\E/invalid/;
    ($params) = Noosphere::parseParams($request);
    ok(defined Noosphere::requestFormGuard($request, $params, $user), 'multipart invalid token rejected');
};

subtest 'actual response writer decorates only the delivered page' => sub {
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere.pm" or die $!;
    my $source = do { local $/; <$in> };
    my ($sub) = $source =~ /^(sub sendOutput \{.*?)(?=^sub |\z)/ms;
    require Noosphere::SecurityHeaders;
    eval "package Noosphere; our (\$RequestFormStatus, \$RequestFormUser); $sub";
    die $@ if $@;
    my $user = fixture();
    my $html = '<form method=post action="/?op=editprefs"><button>Save</button></form>'.chr(0x3b1);
    local $Noosphere::RequestFormUser = $user;
    local $Noosphere::RequestFormStatus = 403;
    Noosphere::sendOutput($request, $html);
    is($request->{status}, 403, 'dispatch rejection reaches HTTP status');
    is($request->{out}{'Cache-Control'}, 'no-store', 'personal response is not cached');
    is($request->{out}{'X-Frame-Options'}, 'SAMEORIGIN', 'confirmation cannot be framed by another origin');
    is($request->{out}{'X-Content-Type-Options'}, 'nosniff', 'content type sniffing disabled');
    is($request->{out}{'Referrer-Policy'}, 'same-origin', 'referrers stay same-origin by default');
    like($request->{output}, qr/name="_form_token"/, 'delivered form contains token');
    is($request->{out}{'content-length'}, length($request->{output}), 'byte length computed after decoration');
    unlike($html, qr/_form_token/, 'input template/cached fragment not modified');
    $Noosphere::RequestFormUser = {uid => -1};
    $Noosphere::RequestFormStatus = undef;
    Noosphere::sendOutput($request, $html);
    unlike($request->{output}, qr/_form_token/, 'following anonymous output has no previous user token');
    is($request->{status}, 200, 'following request has independent status');
};

subtest 'HTTP handler integration with synthetic services' => sub {
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere.pm" or die $!;
    my $source = do { local $/; <$in> };
    for my $name (qw(getNoTemplateContent getViewTemplateContent handler)) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "missing $name" unless $sub;
        eval "package Noosphere; no warnings 'uninitialized'; our (\$dbh, \$stats, \$AllowCache, \$MAINTENANCE, \$NoosphereTitle, \$RequestFormUser, \$RequestFormStatus, \$RequestFormValidated, %HANDLERS, %NONTEMPLATE); $sub";
        die $@ if $@;
    }
    my $user = fixture();
    my $params = {};
    my ($logins, $writes) = (0, 0);
    no warnings 'redefine';
    no warnings 'once';
    local *Noosphere::getConfig = sub {
        return {main_url => 'https://example.invalid', bannedips => {}, screen_scrapers => [],
            projname => 'Physics Library'}->{$_[0]};
    };
    local *Noosphere::parseParams = sub { return ({%$params}, {}); };
    local *Noosphere::parseCookies = sub { return (); };
    local *Noosphere::inMaintenance = sub { return 0; };
    local *Noosphere::dbConnect = sub { return 'synthetic-database'; };
    local *Noosphere::handleLogin = sub { $logins++; return %$user; };
    local *Noosphere::fillInLeftBar = sub { return ''; };
    local *Noosphere::buildMainPageTT = sub { return '<h1>Home</h1>'; };
    local *TemplateNS::new = sub { return bless {}, 'TemplateNS'; };
    local *TemplateNS::expand = sub { return ''; };
    local *Template::new = sub { return bless {}, 'Template'; };
    local *Template::process = sub { ${$_[3]} = '<html>'.$_[2]{content}.'</html>'; return 1; };
    local $Noosphere::stats = 1;
    local $Noosphere::MAINTENANCE = 0;
    local %Noosphere::HANDLERS = (editprefs => sub {
        $writes++ if exists $_[0]->{submit};
        return '<form method=post action="/?op=editprefs"><button name=submit>Save</button></form>';
    });
    local %Noosphere::NONTEMPLATE = (httpupload => sub { $writes++; return 'upload'; });
    local $ENV{REMOTE_ADDR} = '192.0.2.1';
    local $ENV{HTTP_USER_AGENT} = 'test';
    $request->{method} = 'GET';
    {
        local $SIG{__WARN__} = sub { die $_[0] unless $_[0] =~ /got past opening main.html/; };
        Noosphere::handler();
    }
    like($request->{output}, qr/Home/, 'home without op still renders');
    $params = {op => 'editprefs'};
    Noosphere::handler();
    is($writes, 0, 'opening editor does not save');
    like($request->{output}, qr/name="_form_token"/, 'editor delivered with token');
    $params->{submit} = 1;
    Noosphere::handler();
    is($writes, 0, 'GET mutation did not reach editor');
    like($request->{output}, qr/Confirm Action/, 'GET mutation delivers confirmation');
    $request->{method} = 'POST';
    Noosphere::handler();
    is($writes, 0, 'POST without token did not reach editor');
    is($request->{status}, 403, 'HTTP 403 returned');
    $params->{_form_token} = Noosphere::requestFormToken($user);
    Noosphere::handler();
    is($writes, 1, 'valid POST saved once');
    is($request->{status}, 200, 'HTTP status reset for next request');
    $request->{method} = 'GET';
    $params = {op => 'login'};
    Noosphere::handler();
    is($request->{status}, 403, 'GET login switch rejected');
    is($request->{out}{'Cache-Control'}, 'no-store', 'rejected account operation is not cached');
    $params = {op => 'httpupload', submit => 1};
    $request->{method} = 'POST';
    Noosphere::handler();
    is($writes, 1, 'raw upload route also blocked before handler');
    is($request->{status}, 403, 'raw route returns rejection body and status');
    $params = {op => 'login', user => 'test', passwd => 'synthetic'};
    my $before = $logins;
    $request->{headers} = {Origin => 'https://other.invalid'};
    Noosphere::handler();
    is($logins, $before, 'foreign login rejected before cookie/account changes');
    is($request->{status}, 403, 'foreign login response');
    ok(!defined $Noosphere::RequestFormUser, 'request user does not survive handler return');
    ok(!$Noosphere::RequestFormValidated, 'validation does not survive handler return');
};

done_testing();
