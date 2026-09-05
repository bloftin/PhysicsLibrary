#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

# Exercise the pure preprocessor without requiring Apache or a database.
open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Latex.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;
my ($preprocess) = $source =~ /^(sub png_preprocess \{.*?^\})/ms;
die 'png_preprocess not found' unless defined $preprocess;
eval $preprocess;
die $@ if $@;

my $body = <<'TEX';
\begin{document}
\htmladdnormallink{equivalence \htmladdnormallink{relation}{https://example.org/inner}}{https://example.org/outer}
\htmladdnormallinkfoot{\textbf{visible foot link}}{https://example.org/foot}
\end{document}
TEX
my $plain = "\\documentclass{article}\n" . $body;
my $prepared = png_preprocess($plain);
like($prepared, qr/\\providecommand\{\\htmladdnormallink\}\[2\]\{#1\}/,
    'normal links have a text-only fallback');
like($prepared, qr/\\providecommand\{\\htmladdnormallinkfoot\}\[2\]\{#1\}/,
    'foot links have a text-only fallback');
like($prepared, qr/\A\\documentclass\{article\}.*\\providecommand.*\\begin\{document\}/s,
    'fallbacks are placed in the preamble');
ok(index($prepared, $body) >= 0, 'nested anchors and body are preserved');
unlike($prepared, qr/\\usepackage/, 'no extra package dependency');

my $custom = "\\documentclass{article}\n"
    . "\\newcommand{\\htmladdnormallink}[2]{CUSTOM #1}\n" . $body;
my $prepared_custom = png_preprocess($custom);
like($prepared_custom, qr/\\newcommand\{\\htmladdnormallink\}\[2\]\{CUSTOM #1\}.*\\providecommand/s,
    'author definition precedes the fallback');
my $commented = png_preprocess("\\documentclass{article}\n% \\begin{document}\n" . $body);
like($commented, qr/% \\begin\{document\}\n\\providecommand/,
    'commented document marker is not used for insertion');

SKIP: {
    my ($engine) = grep { -x "$_/pdflatex" } split /:/, ($ENV{PATH} || '');
    skip 'pdflatex unavailable; run on the render server for compilation checks', 2
        unless defined $engine;
    my $dir = tempdir(CLEANUP => 1);
    my $cwd = getcwd();
    chdir $dir or die $!;
    for my $case (['nested', $prepared], ['custom', $prepared_custom]) {
        my ($name, $tex) = @$case;
        open my $out, '>', "$name.tex" or die $!;
        print {$out} $tex;
        close $out;
        my $status = system("$engine/pdflatex", '-interaction=batchmode',
            '-halt-on-error', '-no-shell-escape', "$name.tex");
        ok($status == 0 && -s "$name.pdf", "$name links compile with pdfLaTeX");
    }
    chdir $cwd or die $!;
}

done_testing();
