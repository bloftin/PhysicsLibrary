#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use Cwd qw(abs_path getcwd);
use lib "$FindBin::Bin/../../lib";
require Noosphere::PDF;

my $logo = abs_path("$FindBin::Bin/../../data/images/physicslibrarylogotransparent.png");
my $meta = {
    title => 'First variation', uid => 1142, userid => 1, version => 3,
    modified => '2026-09-07 12:00:00', logo => $logo,
    url => 'https://physicslibrary.org/?op=getobj&from=objects&id=1142',
    owner => {active => 1, username => 'example_user', forename => 'Ada', surname => 'Example'},
};
my $original = <<'TEX';
\documentclass[12pt]{article}
\pagestyle{empty}
\usepackage[colorlinks=true]{hyperref}
\begin{document}
\section*{First variation}
First page body. A mathematical expression: $J[y+\epsilon\eta]$.
\newpage
Second page body.
\end{document}
TEX
my $public = Noosphere::pdfDocumentPresentation($original, $meta);
like($public, qr/\\includegraphics.*physicslibrarylogotransparent\.png/, 'uses the existing PL logo');
like($public, qr/An open source physics library/, 'includes the tagline');
is(scalar(() = $public =~ /First variation/g), 1, 'does not duplicate the existing article title');
like($public, qr/First variation.*Maintained by Ada Example.*First page body/s,
    'public profile name appears beneath the title');
like($public, qr/\\pagestyle\{plpdf\}\\thispagestyle\{plpdf\}/, 'enables first and subsequent page numbers');
like($public, qr/Second page body.*Source:.*from=objects&id=1142.*Version 3.*Updated 2026-09-07/s,
    'source and revision details follow the article');
unlike($public, qr/example_user/, 'named owner does not get a duplicate account byline');
like($public, qr/\\usepackage\[colorlinks=true\]\{hyperref\}/, 'author hyperlink settings are preserved');

my $private_meta = {%$meta, owner => {%{$meta->{owner}}, active => 0}};
my $private = Noosphere::pdfDocumentPresentation($original, $private_meta);
unlike($private, qr/Ada|Example/, 'inactive profile personal names never enter the PDF source');
like($private, qr/Second page body.*Maintained by example\\_user \(user 1\)/s,
    'account-only attribution goes in the source block');
my $unnamed = Noosphere::pdfDocumentPresentation($original,
    {%$meta, owner => {active => 1, username => 'example_user'}});
unlike($unnamed, qr/Maintained by.*First page body/s, 'empty name does not create a top byline');
like($unnamed, qr/Maintained by example\\_user \(user 1\)/, 'empty public name uses the username');
my $orphan = Noosphere::pdfDocumentPresentation($original, {%$meta, userid => 0, owner => {}});
unlike($orphan, qr/Maintained by/, 'unowned article has no invented author');
my $no_logo = Noosphere::pdfDocumentPresentation($original, {%$meta, logo => '/missing/pl-logo.png'});
like($no_logo, qr/PhysicsLibrary\.org/, 'missing asset falls back to a text wordmark');
unlike($no_logo, qr/\\includegraphics/, 'missing logo does not break compilation');
is(Noosphere::pdfDocumentPresentation('not a full document', $meta), 'not a full document',
    'does not modify incomplete TeX');

my $text = 'A & B_50% #1 $ {test} \\input{private}';
is(Noosphere::pdfText($text), 'A \\& B\\_50\\% \\#1 \\$ \\{test\\} \\textbackslash{}input\\{private\\}',
    'profile values are escaped as text');
my $unicode = Noosphere::pdfText("Ren\x{e9} M\x{fc}ller");
like($unicode, qr/\\'e/, 'accented names use existing TeX mappings');
my $math_title = 'The $L^{2}$ norm';
my $nested = $original;
$nested =~ s/First variation/$math_title/;
my $math = Noosphere::pdfDocumentPresentation($nested, {%$meta, title => $math_title});
is(scalar(() = $math =~ /\Q$math_title\E/g), 1, 'nested math braces in a title are preserved without duplication');
my $other_heading = $original;
$other_heading =~ s/First variation/Introduction/;
like(Noosphere::pdfDocumentPresentation($other_heading, $meta), qr/\\section\*\{Introduction\}/,
    'unrelated introductory heading stays in the article');

my $collab = <<'TEX';
\documentclass{article}
\pagestyle{empty}
\title{Collaboration title}
\author{Explicit document author}
\date{}
% \begin{document} is only an example in this comment.
\begin{document}
\maketitle
Collaboration body.
\end{document}
TEX
my $collab_pdf = Noosphere::pdfDocumentPresentation($collab, $meta);
like($collab_pdf, qr/\\author\{Explicit document author\}/, 'collaboration author-supplied title metadata is preserved');
like($collab_pdf, qr/\\maketitle\s*\{\\small Maintained by Ada Example/, 'public maintainer follows a native title');
unlike($collab_pdf, qr/First variation/, 'does not add a second title to a maketitle document');

SKIP: {
    skip 'pdflatex and pdftotext required for PDF checks', 14
        unless -x '/usr/bin/pdflatex' && -x '/usr/bin/pdftotext';
    my $dir = tempdir(CLEANUP => 1);
    my $cwd = getcwd();
    chdir $dir or die $!;
    for my $case (['public', $public], ['private', $private], ['fallback', $no_logo],
        ['math', $math], ['collab', $collab_pdf]) {
        my ($name, $tex) = @$case;
        open my $out, '>', "$name.tex" or die $!;
        print {$out} $tex;
        close $out;
        my $status = system('/usr/bin/pdflatex', '-interaction=batchmode', '-halt-on-error',
            '-no-shell-escape', "$name.tex");
        ok($status == 0 && -s "$name.pdf", "$name PDF compiles with pdfLaTeX");
    }
    system('/usr/bin/pdftotext', '-layout', 'public.pdf', 'public.txt');
    open my $in, '<', 'public.txt' or die $!;
    my $text = do { local $/; <$in> };
    close $in;
    my @pages = split /\f/, $text;
    is(scalar(@pages), 2, 'branding and source block fit the two-page fixture');
    like($pages[0], qr/\b1\s*$/, 'first page has a page number');
    like($pages[1], qr/\b2\s*$/, 'second page has a page number');
    like($pages[0], qr/Maintained by Ada Example/, 'public byline is visible in the compiled PDF');
    like($pages[1], qr/Source:.*https:\/\/physicslibrary\.org/s, 'source URL is visible in the compiled PDF');
    like($pages[1], qr/Version 3/, 'revision is visible in the compiled PDF');
    system('/usr/bin/pdftotext', '-layout', 'private.pdf', 'private.txt');
    open $in, '<', 'private.txt' or die $!;
    my $private_text = do { local $/; <$in> };
    close $in;
    unlike($private_text, qr/Ada|Example/, 'inactive name is absent from compiled output');
    # OT1 draws underscores as rules, which pdftotext may extract as spaces.
    like($private_text, qr/Maintained by example[ _]user \(user 1\)/, 'account attribution is readable');
    open $in, '<', 'public.log' or die $!;
    my $log = do { local $/; <$in> };
    close $in;
    unlike($log, qr/Overfull \\[hv]box/, 'fixture has no overflowing boxes');
    chdir $cwd or die $!;
}
done_testing();
