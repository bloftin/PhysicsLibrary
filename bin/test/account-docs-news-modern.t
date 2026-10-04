#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use Test::More;
use Template;
use XML::Writer;
use XML::LibXML;
use XML::LibXSLT;
use HTML::TreeBuilder;
use HTML::Parser;
use lib "$FindBin::Bin/../../lib";
use Noosphere::TemplateNS;

my $root = "$FindBin::Bin/../..";
our $dbh = bless {}, 'PageTestDatabase';
my (%headers, @mail, @queries);
my ($method, $identity_exists, $reset_exists, $news_ok, $doc_xml, @news);
sub getConfig {
    return {template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
        template_cmd_prefix => 'NS', main_url => 'https://example.invalid',
        projname => 'PhysicsLibrary', siteaddrs => {main => 'example.invalid'},
        user_tbl => 'users', news_tbl => 'news', collab_tbl => 'collab', acl_tbl => 'acl'}->{$_[0]};
}
sub readFile { open my $fh, '<', $_[0] or die $!; return do {local $/; <$fh>}; }
sub htmlescape {
    my $v = defined $_[0] ? $_[0] : '';
    $v =~ s/&/&amp;/g; $v =~ s/</&lt;/g; $v =~ s/>/&gt;/g;
    return $v;
}
sub errorMessage { return $_[0]; }
sub paddingTable { die 'legacy spacing wrapper used'; }
sub makeBox { die 'legacy account box used'; }
sub clearBox { die 'legacy documentation box used'; }
sub registrationIdentityExists { return $identity_exists; }
sub email_blacklisted { return 0; }
sub createRegistrationTicket { return 'a' x 64; }
sub sendMail { push @mail, [@_]; }
sub logoutFormToken { return 'b' x 64; }
sub dbSelectRowBound {
    push @queries, [@_];
    return $reset_exists ? {username => 'Example Member', email => 'member@example.invalid'} : undef;
}
sub createPasswordResetTicket { return 'c' x 64; }
sub sendPwChangeMail { push @mail, [@_]; }
sub getNewUserGuide { return 'local guide'; }
sub getCollabObjList {
    is($_[1], 'sitedoc = 1', 'only published site documentation is requested');
    return $doc_xml;
}
sub buildStringUsingXSLT {
    my ($xml, $path) = @_;
    my $parser = XML::LibXML->new;
    my $sheet = XML::LibXSLT->new->parse_stylesheet($parser->parse_file($path));
    return $sheet->output_string($sheet->transform($parser->parse_string($xml)));
}
sub dbSelect { push @queries, [@_]; return ($news_ok, 'statement'); }
sub dbGetRows { return map {+{%$_}} @news; }
sub getPager { return '<a href="/?op=oldnews&amp;offset=20">Next</a>'; }
sub mdhm { return 'Oct 4, 12:30'; }
sub dwarn { return; }

{
    package Apache2::RequestUtil;
    sub request { return bless {}, 'PageTestRequest'; }
    package PageTestRequest;
    sub method { return $method; }
    sub headers_out { return $_[0]; }
    sub set { $headers{$_[1]} = $_[2]; }
    package PageTestDatabase;
    sub prepare { return bless {}, 'PageTestStatement'; }
    package PageTestStatement;
    sub execute { return 1; }
    sub fetchrow_arrayref { return undef; }
    sub finish { return 1; }
}
for my $spec (
    ['Login', qw(logoutPage)],
    ['NewUser', qw(registrationRequestMessage registrationRequest getNewUser checkNewUserInfo)],
    ['Password', qw(passwordResetRequestMessage pwChangeRequest)],
    ['Encyclopedia', qw(getAssocGuidelines)],
    ['Collab', qw(siteDoc)],
    ['News', qw(getNewsSummary)],
) {
    my ($module, @names) = @$spec;
    my $source = readFile("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body;
        die $@ if $@;
    }
}
sub tree {
    my $dom = HTML::TreeBuilder->new(ignore_unknown => 0);
    $dom->parse_content($_[0]);
    return $dom;
}
sub heading {
    my ($html, $title) = @_;
    my $dom = tree($html);
    my @titles = $dom->look_down(_tag => 'h1');
    is(scalar @titles, 1, "$title has one page heading");
    is($titles[0]->as_text, $title, 'original page title retained');
    my $bar = $dom->look_down(_tag => 'header', class => 'pl-modern-box-header');
    ok($bar, 'compact shared blue header');
    $dom->delete;
}
my %previews;
$method = 'GET';
my $newuser = getNewUser({}, {uid => -1});
$previews{newuser} = $newuser;
heading($newuser, 'Create New User Account');
my $dom = tree($newuser);
my $form = $dom->look_down(_tag => 'form');
is($form->attr('method'), 'post', 'registration still uses POST');
is($form->attr('action'), '/', 'registration posts to same route');
for my $spec (['user', 32], ['email', 128], ['license', undef], ['op', undef], ['verify', undef]) {
    my $input = $form->look_down(_tag => 'input', name => $spec->[0]);
    ok($input, "$spec->[0] retained");
    is($input->attr('maxlength'), $spec->[1], 'original field length limit retained') if $spec->[1];
}
is($form->look_down(name => 'license')->attr('type'), 'checkbox', 'license remains opt-in');
ok(!$form->look_down(name => 'license')->attr('checked'), 'license not preaccepted');
is($form->look_down(name => 'op')->attr('value'), 'newuser', 'registration route unchanged');
is($form->look_down(name => 'verify')->attr('value'), '1', 'registration submit marker unchanged');
like($form->as_text, qr/Permission is granted to copy, distribute and\/or modify any material/, 'license wording retained');
is($form->look_down(_tag => 'a')->attr('href'), 'https://creativecommons.org/licenses/by-sa/4.0/', 'license link unchanged');
$dom->delete;
@mail = ();
like(getNewUser({verify => 1}, {uid => -1}), qr/Use the registration form/, 'GET submit cannot send mail');
is(scalar @mail, 0, 'GET registration has no mail side effect');
$method = 'POST';
my $invalid = getNewUser({verify => 1, user => q{"><script>x</script>}, email => q{"><script>y</script>}}, {uid => -1});
$previews{'newuser-error'} = $invalid;
heading($invalid, 'Create New User Account');
like($invalid, qr/You must agree to the license/, 'validation errors remain visible');
unlike($invalid, qr/<script>/, 'redisplayed input cannot inject markup');
is(scalar @mail, 0, 'invalid registration sends no mail');
my $params = {verify => 1, user => 'Example Member', email => 'member@example.invalid', license => 'on'};
$identity_exists = 0;
my $sent = getNewUser($params, {uid => -1});
$previews{'registration-sent'} = $sent;
heading($sent, 'Mail Sent');
is(scalar @mail, 1, 'valid registration retains mail workflow');
$identity_exists = 1;
is(getNewUser($params, {uid => -1}), $sent, 'duplicate identity has identical generic confirmation');
is(scalar @mail, 1, 'duplicate identity does not send extra mail');
unlike($sent, qr/Example Member|member\@example/, 'confirmation does not reveal identity');

my $reset = pwChangeRequest({username => q{"><script>x</script>}});
$previews{pwchangereq} = pwChangeRequest({});
heading($reset, 'Request a Password Change');
unlike($reset, qr/<script>/, 'reset username remains escaped');
$dom = tree($reset);
$form = $dom->look_down(_tag => 'form');
is($form->attr('method'), 'post', 'reset form uses POST');
is($form->attr('action'), '/', 'reset form action unchanged');
is($form->look_down(name => 'op')->attr('value'), 'pwchangereq', 'reset route unchanged');
is($form->look_down(name => 'submit')->attr('value'), 'submit', 'reset submission field retained');
like($form->as_text, qr/An e-mail message will be sent to the address you registered with, containing further instructions\./, 'reset instructions retained');
$dom->delete;
@mail = ();
$reset_exists = 0;
my $missing = pwChangeRequest({submit => 1, username => 'missing'});
is(scalar @mail, 0, 'unknown username sends no mail');
$reset_exists = 1;
is(pwChangeRequest({submit => 1, username => 'Example Member'}), $missing, 'known and unknown accounts have identical reset response');
is(scalar @mail, 1, 'known account still requests reset mail');
heading($missing, 'Mail Sent');
$previews{'reset-sent'} = $missing;

my $logout = logoutPage({}, {uid => 1, ticket => 'synthetic-session'});
$previews{logout} = $logout;
heading($logout, 'Logout');
like($logout, qr/<form method="post" action="\/">/, 'logout confirmation still posts');
like($logout, qr/name="logout_token" value="b{64}"/, 'logout form token preserved');
unlike($logout, qr/synthetic-session/, 'session credential is not exposed');
my $signedout = logoutPage({}, {uid => -1});
$previews{'logged-out'} = $signedout;
like($signedout, qr/You are signed out\./, 'signed-out message unchanged');
unlike($signedout, qr/<form/, 'signed-out view has no logout form');
heading($signedout, 'Logout');

my $guidelines = getAssocGuidelines();
$previews{assocguidelines} = $guidelines;
heading($guidelines, 'Association Guidelines');
like($guidelines, qr/The Collatz Problem.*Ulam's Problem.*Kakutani's Problem/s, 'synonym examples preserved');
like($guidelines, qr/comma-separated lists/, 'association input convention preserved');
like($guidelines, qr/JordansTotientFunction/, 'canonical-name example preserved');
unlike($guidelines, qr/<NS:template/, 'site-name placeholders expanded');

$doc_xml = '';
my $docs = siteDoc({}, {uid => -1});
$previews{'sitedoc-empty'} = $docs;
heading($docs, 'PhysicsLibrary Documentation');
like($docs, qr/No collaborative documentation entries have been published yet\./, 'documentation empty state retained');
my $legacy = buildStringUsingXSLT('<sitedoc><items/></sitedoc>', "$root/bin/test/fixtures/sitedoc-legacy.xsl");
sub normalized_words {
    my ($html) = @_;
    my ($text, $skip) = ('', 0);
    my $parser = HTML::Parser->new(api_version => 3);
    $parser->handler(start => sub { $skip++ if $_[0] =~ /\A(?:h1|style|script)\z/; }, 'tagname');
    $parser->handler(end => sub { $skip-- if $_[0] =~ /\A(?:h1|style|script)\z/; }, 'tagname');
    $parser->handler(text => sub { $text .= $_[0] unless $skip; }, 'dtext');
    $parser->parse($html); $parser->eof;
    $text =~ s/\s+//g;
    return $text;
}
is(normalized_words($docs), normalized_words($legacy), 'all original documentation words and examples retained');
sub links {
    my $dom = tree($_[0]);
    my @links = map {$_->attr('href')} $dom->look_down(_tag => 'a');
    $dom->delete;
    return \@links;
}
is_deeply(links($docs), links($legacy), 'every original documentation link retained');
$doc_xml = '<docitem><uid>28</uid><title>Style &amp; Figures &lt;script&gt;</title><abstract>Practical &lt;b&gt;notes&lt;/b&gt;</abstract><lastedit><when>Oct 4</when><who>Example Member</who></lastedit></docitem><docitem><uid>29</uid><title>Second guide</title></docitem>';
my $published = siteDoc({}, {uid => -1});
$previews{sitedoc} = $published;
like($published, qr/Style &amp; Figures &lt;script&gt;/, 'doc title escaped by real XSL');
like($published, qr/Practical &lt;b&gt;notes&lt;\/b&gt;/, 'doc abstract remains escaped text');
like($published, qr/Last edit: Oct 4 by Example Member/, 'last-edit attribution retained');
like($published, qr/No description given\./, 'missing abstract fallback retained');
like($published, qr/from=collab&amp;id=28/, 'collaborative doc link unchanged');
is(siteDoc({guide => 'newuser'}, {uid => -1}), 'local guide', 'local guide route still works');

$news_ok = 1;
@news = ({uid => 7, title => 'Physics & <script>news</script>', username => '<b>Editor</b>', created => '2026-10-04'},
         {uid => 8, title => 'Community update', username => 'Example Member', created => '2026-10-03'});
@queries = ();
my $news = getNewsSummary({offset => 10}, {prefs => {pagelength => 10}});
$previews{oldnews} = $news;
heading($news, 'Old News');
is($queries[0]->[1]->{OFFSET}, 10, 'news offset unchanged');
is($queries[0]->[1]->{LIMIT}, 10, 'news respects user page length');
is($queries[0]->[1]->{'ORDER BY'}, 'created', 'news order unchanged');
like($news, qr/>11\.<\/span>/, 'row numbering starts at current offset');
like($news, qr/Physics &amp; &lt;script&gt;news&lt;\/script&gt;/, 'news title escaped');
like($news, qr/by &lt;b&gt;Editor&lt;\/b&gt;/, 'news author escaped');
like($news, qr/from=news&amp;id=7/, 'news article link preserved');
like($news, qr/op=oldnews&amp;offset=20/, 'existing pager retained');
like($news, qr/Oct 4, 12:30/, 'news timestamp retained');
@news = ();
$previews{'oldnews-empty'} = getNewsSummary({}, {prefs => {pagelength => 10}});
like($previews{'oldnews-empty'}, qr/no news items to summarize!/, 'empty news is readable');
$news_ok = 0;
my $failed = getNewsSummary({}, {prefs => {pagelength => 10}});
heading($failed, 'Old News');
like($failed, qr/no news items to summarize!/, 'failed news query retains original message');
unlike($failed, qr/>Next</, 'failed query does not offer a misleading pager');

if (my $dir = $ENV{ACCOUNT_DOCS_NEWS_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu}, \$sidebar) or die $tt->error;
    for my $name (sort keys %previews) {
        my $page = '';
        $tt->process('view.tt', {title => $name, site_name => 'Physics Library',
            content => $previews{$name}, sidebar => $sidebar,
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $page;
        close $out;
    }
}
done_testing();
