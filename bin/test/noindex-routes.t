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

my $history_request = IndexingRequest->new();
ok(applyIndexingPolicy($history_request, 'viewver'), 'existing history policy is retained');

my $article_request = IndexingRequest->new();
ok(!applyIndexingPolicy($article_request, 'getobj'), 'article pages remain indexable');
ok(!exists $article_request->{headers}->{'X-Robots-Tag'},
    'article pages do not receive a noindex response header');

open my $view, '<', "$FindBin::Bin/../../stemplates/view.tt" or die $!;
my $template = do { local $/; <$view> };
close $view;
like($template, qr{\[% IF no_index %\].*<meta name="robots" content="noindex,follow" />}s,
    'view template retains the conditional robots meta directive');

done_testing();
