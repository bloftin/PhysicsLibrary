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

load_sub('Cache.pm', 'readBracedLaTeXArgument');
load_sub('Cache.pm', 'replaceTwoArgRenderCommand');
load_sub('Cache.pm', 'youtubeVideoId');
load_sub('Cache.pm', 'prepareYouTubeEmbeds');
load_sub('Cache.pm', 'youtubeEmbedMacro');
sub addHyperrefPackage { return "HYPERREF\n" . $_[0]; }
sub addPDFLinkSupportToDocument { return "LINKS\n" . $_[0]; }
load_sub('Cache.pm', 'addYouTubeEmbedSupport');
load_sub('Cache.pm', 'addYouTubeEmbedSupportToDocument');

is(youtubeVideoId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ', 'bare YouTube IDs are accepted');
is(youtubeVideoId('https://youtu.be/dQw4w9WgXcQ?t=1'), 'dQw4w9WgXcQ', 'short YouTube URLs are accepted');
is(youtubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=share'), 'dQw4w9WgXcQ', 'watch URLs are accepted');
is(youtubeVideoId('https://youtube.example/dQw4w9WgXcQ'), undef, 'other hosts are rejected');

my ($html, $has_embed) = prepareYouTubeEmbeds(
	'Before \\PMyoutube{https://youtu.be/dQw4w9WgXcQ}{A {nested} caption} after', 'make4ht');
is($html, 'Before \\PLYouTubeEmbed{dQw4w9WgXcQ}{A {nested} caption} after',
	'make4ht receives the validated embed command');
ok($has_embed, 'make4ht reports an iframe requirement');

my ($pdf, $pdf_has_embed) = prepareYouTubeEmbeds(
	'\\PMyoutube{dQw4w9WgXcQ}{Video caption}', 'pdf');
is($pdf, '\\PMlinkexternal{Video caption}{https://www.youtube.com/watch?v=dQw4w9WgXcQ}',
	'PDF receives a normal external link');
ok(!$pdf_has_embed, 'PDF does not request an iframe macro');

my ($invalid, $invalid_has_embed) = prepareYouTubeEmbeds(
	'\\PMyoutube{https://example.com/not-a-video}{Caption}', 'make4ht');
is($invalid, '\\textbf{[Invalid YouTube video URL or ID]}',
	'invalid video sources do not reach HTML output');
ok(!$invalid_has_embed, 'invalid video sources do not request an iframe');

my $macro = youtubeEmbedMacro();
like($macro, qr{youtube-nocookie\.com/embed/#1}, 'privacy-enhanced player is used');
like($macro, qr{\\edef\\PLYouTubeEmbedCode}, 'video IDs are expanded before TeX4ht receives the iframe HTML');
like($macro, qr{\\PLYouTubeEmbedHTML\{#1\}}, 'iframe emission uses the expanded video ID helper');
like($macro, qr{loading="lazy"}, 'player loads lazily');
unlike($macro, qr{<script\b}i, 'embed macro adds no scripts');

my $preamble = addYouTubeEmbedSupport('author preamble');
like($preamble, qr/^HYPERREF/m, 'embed support ensures hyperref is available');
like($preamble, qr{\\providecommand\{\\PLYouTubeEmbed\}}, 'embed macro is added to article preambles');

my $document = addYouTubeEmbedSupportToDocument("\\documentclass{article}\n\\begin{document}\nbody\n\\end{document}\n");
like($document, qr/^LINKS/m, 'collaboration documents receive link support');
like($document, qr{\\PLYouTubeEmbed.*\\begin\{document\}}s, 'embed macro is inserted before the document body');

done_testing();
