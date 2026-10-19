#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::Login;
use HTML::Parser;

our $request;
{
    package Noosphere;
    sub getConfig { return "$FindBin::Bin/../../stemplates" if $_[0] eq 'template_path'; }
    package Apache2::RequestUtil;
    sub request { return $main::request; }
    package ReturnRequest;
    sub method { return $_[0]->{method}; }
    sub unparsed_uri { return $_[0]->{uri}; }
}

sub fixture {
    $request = bless {method => $_[0] || 'GET', uri => $_[1] || '/'}, 'ReturnRequest';
    return {uid => -1, data => {}};
}

subtest 'safe navigation destinations' => sub {
    for my $url ('/', '/?op=correct&from=objects&id=209', '/?op=correct;from=objects;id=209',
        '/?op=settings', '/?op=edit&id=209&from=objects', '/?op=postmsg&id=0&replyto=395',
        '/encyclopedia/VectorTripleProduct.html', '/encyclopedia/V/',
        '/?op=search&q=calculus%20of%20variations&page=2', '/?op=getobj&from=objects&id=209') {
        is(Noosphere::loginReturnURL($url), $url, "navigation preserved: $url");
    }
    for my $url (undef, '', [], {}, 'https://elsewhere.invalid/', '//elsewhere.invalid/',
        '/\\elsewhere.invalid/', '/%2felsewhere.invalid/', '/%252felsewhere.invalid/',
        '/%5celsewhere.invalid/', '/%255celsewhere.invalid/', "/\r\nLocation:bad", '/%0d%0aLocation:bad',
        '/?op=settings%0d%0aInjected:bad', '/?op=logout', '/?op=login', '/?op=activate&token=private',
        '/?op=pwchange', '/?op=pwchangereq', '/?op=newuser', '/?op=correct&id=209&passwd=private',
        '/?op=correct&id=209&_form_token=private', '/?op=correct&id=209&post=1',
        '/?op=correct&id=209&data=draft', '/?op=getobj&id=209&watch=add',
        '/?op=edit&id=209&save=1', '/?op=rerender&id=209&from=objects',
        '/?op=delobj&id=209', '/?op=settings&op=logout', '/?op=settings&OP=logout',
        '/?OP=logout', '/?op=settings;op=logout', '/./?op=settings', '/x/../?op=settings',
        '/%2e%2e/elsewhere', '/?op=settings#fragment', '/' . ('x' x 4096)) {
        is(Noosphere::loginReturnURL($url), '/', 'unsafe, account, action or malformed destination falls back');
    }
};

subtest 'original GET URL and login retries, never submitted drafts' => sub {
    fixture('GET', '/?op=correct;from=objects;id=209');
    my $target = '/?op=correct;from=objects;id=209';
    is(Noosphere::loginReturnTarget($request, {op => 'correct', id => 209}), $target, 'original URL preserved');
    is(Noosphere::loginReturnTarget($request, {op => 'correct', url => '//elsewhere.invalid'}), $target, 'non-login url parameter cannot override current location');
    for my $method ('POST', 'GET') {
        fixture($method, '/');
        is(Noosphere::loginReturnTarget($request, {op => 'login', url => $target}), $target, 'retry carries the original destination');
    }
    fixture('POST', '/?op=correct&id=209');
    is(Noosphere::loginReturnTarget($request, {op => 'correct', id => 209, data => 'draft'}), '/', 'POST body and action are not resumed');
    fixture('HEAD', '/encyclopedia/VectorTripleProduct.html');
    is(Noosphere::loginReturnTarget($request, {}), $request->{uri}, 'HEAD navigation supported');
};

subtest 'real login sidebar keeps and escapes the return field' => sub {
    my $user = fixture('GET', '/?op=correct&from=objects&id=209');
    no warnings qw(redefine once);
    my $new = Template->can('new');
    local *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$FindBin::Bin/../../stemplates"}) };
    my $html = Noosphere::getLoginBox({op => 'correct'}, $user);
    like($html, qr/name="url" value="\/\?op=correct&amp;from=objects&amp;id=209"/, 'escaped correction destination in hidden input');
    my %fields;
    my $parser = HTML::Parser->new(api_version => 3);
    $parser->handler(start => sub { my ($tag, $a) = @_; $fields{$a->{name}} = $a->{value} if $tag eq 'input' && defined $a->{name}; }, 'tagname, attr');
    $parser->parse($html); $parser->eof;
    is($fields{url}, $request->{uri}, 'browser decoding preserves the exact destination');
    fixture('POST', '/');
    $html = Noosphere::getLoginBox({op => 'login', url => $fields{url}}, {%$user, login_failed => 1});
    like($html, qr/Unable to sign in/, 'failed login remains visible');
    like($html, qr/name="url" value="\/\?op=correct&amp;from=objects&amp;id=209"/, 'failed login preserves destination');
    $html = Noosphere::getLoginBox({op => 'login', url => $fields{url}}, {%$user, login_unavailable => 1});
    like($html, qr/Sign-in is temporarily unavailable\. Please try again\./, 'session creation error is visible and actionable');
    unlike($html, qr/Check your username and password/, 'server-side session failure does not blame the supplied credentials');
    like($html, qr/name="url" value="\/\?op=correct&amp;from=objects&amp;id=209"/, 'session creation error preserves destination');
    like($html, qr/button\.textContent = 'Signing in\.\.\.'/s, 'login has a pending submission indicator');
    like($html, qr/window\.addEventListener\('pageshow', resetLogin\)/, 'back-forward navigation restores the submit button');
    my $expected_scripts = () = $html =~ /<script\b/g;
    $html = Noosphere::getLoginBox({op => 'login', url => '/?op=search&q=%22%3E%3Cscript%3E'}, $user);
    is(scalar(() = $html =~ /<script\b/g), $expected_scripts, 'return URL cannot inject additional script markup');
    like($html, qr/name="url" value="\/\?op=search&amp;q=%22%3E%3Cscript%3E"/, 'encoded search value remains data');
};

done_testing();
