#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

{
    package IndexingRequest;
    sub new { return bless {headers => bless({}, 'IndexingHeaders')}, shift; }
    sub headers_out { return $_[0]->{headers}; }
}
{
    package IndexingHeaders;
    sub set { $_[0]->{$_[1]} = $_[2]; }
}

open my $in, '<', "$FindBin::Bin/../../lib/Noosphere.pm" or die $!;
my $source = do { local $/; <$in> };
close $in;
my ($sub) = $source =~ /^(sub applyIndexingPolicy \{.*?)(?=^sub |\z)/ms;
die 'applyIndexingPolicy not found' unless defined $sub;
eval $sub;
die $@ if $@;

my $user_request = IndexingRequest->new();
ok(applyIndexingPolicy($user_request, 'userobjs'), 'user object listings are not indexed');
is($user_request->{headers}->{'X-Robots-Tag'}, 'noindex, follow',
    'user object listings send the robots response header');

my $article_request = IndexingRequest->new();
ok(applyIndexingPolicy($article_request, 'edituserobjs'), 'My Articles listings are not indexed');
is($article_request->{headers}->{'X-Robots-Tag'}, 'noindex, follow',
    'My Articles listings send the robots response header');

my $beta_request = IndexingRequest->new();
ok(applyIndexingPolicy($beta_request, 'edituserobjsbeta'), 'beta user article listings are not indexed');
is($beta_request->{headers}->{'X-Robots-Tag'}, 'noindex, follow',
    'beta user article listings send the robots response header');

my $collab_request = IndexingRequest->new();
ok(applyIndexingPolicy($collab_request, 'collab'), 'collaboration workspaces are not indexed');
is($collab_request->{headers}->{'X-Robots-Tag'}, 'noindex, follow',
    'collaboration workspaces send the robots response header');

my $history_request = IndexingRequest->new();
ok(applyIndexingPolicy($history_request, 'viewver'), 'existing history policy is retained');

my $preamble_request = IndexingRequest->new();
ok(applyIndexingPolicy($preamble_request, 'preamble'), 'article preamble pages are not indexed');
is($preamble_request->{headers}->{'X-Robots-Tag'}, 'noindex, follow',
    'article preamble pages send the robots response header');

my $published_article_request = IndexingRequest->new();
ok(!applyIndexingPolicy($published_article_request, 'getobj'), 'article pages remain indexable');
ok(!exists $published_article_request->{headers}->{'X-Robots-Tag'},
    'article pages do not receive a noindex response header');

for my $table (qw(objects papers books lec)) {
    for my $query ('', 'polar', '0') {
        my $params = {from => $table, q => $query, offset => 910, op => 'listobj', total => 1119, sort => 'created_desc'};
        my $request = IndexingRequest->new();
        ok(applyIndexingPolicy($request, $params->{op}), "$table listing q='$query' is not indexed");
        is($request->{headers}->{'X-Robots-Tag'}, 'noindex, follow', 'listing sends noindex header even without a query');
    }
    my $request = IndexingRequest->new();
    ok(!applyIndexingPolicy($request, 'getobj'), "$table individual content remains indexable");
}
for my $op (qw(search oldsearch adv_search pacssearch)) {
    my $request = IndexingRequest->new();
    ok(applyIndexingPolicy($request, $op), "$op is not indexed");
    is($request->{headers}->{'X-Robots-Tag'}, 'noindex, follow', "$op sends the response header");
}
for my $op ('', qw(main en browse pacsbrowse)) {
    my $request = IndexingRequest->new();
    ok(!applyIndexingPolicy($request, $op), "ordinary '$op' page remains indexable");
    ok(!exists $request->{headers}->{'X-Robots-Tag'}, 'no header leaks from earlier search requests');
}
my $google_request = IndexingRequest->new();
ok(applyIndexingPolicy($google_request, '', 'Search'), 'Google results using the front-page fallback are not indexed');
is($google_request->{headers}->{'X-Robots-Tag'}, 'noindex, follow', 'Google results send the response header');
ok(!applyIndexingPolicy(IndexingRequest->new(), '', ''), 'homepage without Google results remains indexable');
like($source, qr/applyIndexingPolicy\(\$req, \$params->\{op\}, \$params->\{sa\}\)/,
    'front-page branch applies the policy using the same search flag as its template');
like($source, qr/buildMainPageTT\(\$params, \\%user_info, \$no_index\)/,
    'front-page branch passes the policy to the template builder');

open my $view, '<', "$FindBin::Bin/../../stemplates/view.tt" or die $!;
my $template = do { local $/; <$view> };
close $view;
like($template, qr{\[% IF no_index %\].*<meta name="robots" content="noindex,follow" />}s,
    'view template retains the conditional robots meta directive');

require Template;
{
    package TemplateNS;
    sub new { bless {}, shift }
    sub expand { return '' }
}
sub getLoginBox { return '' }
sub getAdminMenu { return '' }
sub getMainMenu { return '' }
sub getLatestAdditions { return '' }
sub getLatestModifications { return '' }
sub getLatestMessages { return '' }
sub getTopUsers { return '' }
sub getCurrentPoll { return '' }
sub getHomeNews { return '<p>Homepage news</p>' }
my ($builder) = $source =~ /^(sub buildMainPageTT \{.*?)(?=^sub |\z)/ms;
die 'buildMainPageTT not found' unless defined $builder;
eval $builder;
die $@ if $@;
{
    no warnings qw(redefine once);
    my $new = Template->can('new');
    local *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$FindBin::Bin/../../stemplates"}) };
    for my $sa ('', 'Search') {
        my $request = IndexingRequest->new();
        my $no_index = applyIndexingPolicy($request, '', $sa);
        my $html = buildMainPageTT({sa => $sa, q => 'polar'}, {data => {access => 0}}, $no_index);
        like($html, qr/<p>Homepage news<\/p>/, 'real homepage builder connects news to the sidebar');
        if ($sa) {
            like($html, qr/name="robots" content="noindex,follow"/, 'real front-page builder passes the noindex flag');
            like($html, qr/class="gcse-searchresults-only"/, 'Google search widget is still rendered');
        } else {
            unlike($html, qr/name="robots" content="noindex/, 'real homepage builder remains indexable');
        }
    }
}
my $tt = Template->new({INCLUDE_PATH => "$FindBin::Bin/../../stemplates"});
for my $file ('view.tt', 'mainpage.tt') {
    for my $no_index (0, 1) {
        my $html = '';
        ok($tt->process($file, {no_index => $no_index, search_results => $no_index}, \$html),
            "$file renders with no_index=$no_index") or diag $tt->error();
        if ($no_index) {
            like($html, qr{<head>.*?<meta name="robots" content="noindex,follow"\s*/>.*?</head>}s,
                'noindex appears in the document head');
        } else {
            unlike($html, qr/name="robots" content="noindex/, 'normal page has no noindex meta tag');
        }
    }
}

done_testing();
