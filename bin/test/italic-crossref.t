#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Crossref.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;

sub getConfig { return 'objects'; }

our %LINKABLETAGS;
my ($tags) = $source =~ /^(%LINKABLETAGS = \(.*?^\);)/ms;
die 'LINKABLETAGS not found' unless defined $tags;
eval $tags;
die $@ if $@;

for my $name (qw(splitPseudoLaTeX fragmentpseudos splitLaTeX preprocessLaTeX postprocessLaTeX recombine)) {
	my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
	die "$name not found" unless defined $sub;
	eval $sub;
	die $@ if $@;
}

my $input = 'This article focuses on derivatives of \textit{vector-valued functions}.';
my ($text, $escaped) = splitPseudoLaTeX($input, 'make4ht');
my ($linkable, $math) = splitLaTeX(preprocessLaTeX($text), $escaped);

unlike($linkable, qr/vector-valued|functions/, 'italicized prose is excluded from automatic matching');
is_deeply(
	$escaped,
	['\textit{vector-valued functions}'],
	'italicized prose is preserved as one escaped fragment',
);

my $restored = postprocessLaTeX(recombine($linkable, $math, $escaped));
$restored =~ s/\A\s+|\s+\z//g;
is($restored, $input, 'italicized prose survives the cross-reference pipeline unchanged');

done_testing();
