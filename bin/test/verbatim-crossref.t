#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Crossref.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;

for my $name (qw(splitPseudoLaTeX preprocessLaTeX postprocessLaTeX recombine)) {
	my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
	die "$name not found" unless defined $sub;
	eval $sub;
	die $@ if $@;
}

my $julia = <<'JULIA';
\begin{verbatim}
using Printf

c = 299792458.0
I = 1000.0

Rvals = [0.0, 0.25, 0.50, 0.75, 1.0]
thetas_deg = [0.0, 30.0, 60.0, 80.0]

pressure(R, theta_deg) =
    (1 + R) * I / c * cosd(theta_deg)^2

for theta in thetas_deg
    @printf("theta = %5.1f deg\n", theta)
    for R in Rvals
        @printf("  R = %.2f   p = %.6e Pa\n",
                R, pressure(R, theta))
    end
end

@printf("\nAbsorber, normal incidence: %.6e Pa\n",
        pressure(0.0, 0.0))
@printf("Mirror, normal incidence:   %.6e Pa\n",
        pressure(1.0, 0.0))
\end{verbatim}
JULIA

my ($protected, $escaped, $linkids) = splitPseudoLaTeX("Before\n$julia\nAfter", 'make4ht');
like($protected, qr/\@\@0\@\@/, 'verbatim code is replaced with an escaped placeholder');
my $environment = $julia;
$environment =~ s/\n\z//;
is_deeply($escaped, [$environment], 'Julia source is preserved verbatim before preprocessing');
is_deeply($linkids, [], 'verbatim code creates no manual links');

my $processed = postprocessLaTeX(preprocessLaTeX($protected));
my $restored = recombine($processed, [], $escaped);
like($restored, qr/\Q$julia\E/, 'Julia source survives the cross-reference text pipeline unchanged');

my ($listing, $listing_escaped) = splitPseudoLaTeX(
	'\begin{lstlisting}[language=Julia]' . "\n" . '@show pressure(1.0, 0.0)' . "\n" . '\end{lstlisting}',
	'make4ht');
like($listing, qr/\@\@0\@\@/, 'lstlisting is also protected');
like($listing_escaped->[0], qr/\@show pressure/, 'lstlisting content is retained');

done_testing();
