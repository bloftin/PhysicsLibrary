#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

sub load_sub {
	my ($file, $name) = @_;
	open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/$file" or die $!;
	my $source = do { local $/; <$in> };
	close $in;
	my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
	die "$name not found" unless defined $sub;
	eval $sub;
	die $@ if $@;
}

load_sub('Latex.pm', 'escapeMathSimple');
load_sub('Latex.pm', 'unescapeMathSimple');
load_sub('Indexing.pm', 'swaptitle');

is(swaptitle('Euler, Leonhard'), 'Leonhard Euler',
	'legacy two-part index titles are displayed inline');

my $article_title = 'Electromagnetic Waves, Antennas, and RF: Spatial Derivatives of Fields - Gradient, Divergence, and Curl';
is(swaptitle($article_title), $article_title,
	'comma-separated article titles are not truncated or reordered');

is(swaptitle('A title,, with a literal comma'), 'A title, with a literal comma',
	'double commas continue to escape literal commas');

is(swaptitle('Energy $E = mc^2$, mass, and momentum'),
	'Energy $E = mc^2$, mass, and momentum',
	'math chunks containing punctuation remain intact');

done_testing();
