#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RenderLog;

my $enabled = 1;
my $fail = 0;
sub getConfig { return {render_stage_logging => $enabled, en_tbl => 'objects', main_url => 'https://example.test', dontlink => [], entry_template => 'entry.tex'}->{$_[0]}; }
sub xrefDeleteLinksFrom {}
sub getEscapedWords { return ($_[0]); }
sub splitPseudoLaTeX { return ($_[0], [], []); }
sub preprocessLaTeX { return $_[0]; }
sub splitLaTeX { return ($_[0], []); }
sub doManualLinks {}
sub generateterms { return ({target => {target => [0, 1]}}, {0 => 2, 1 => 3}, {}, []); }
sub findmatches { return {0 => {term => 'target', length => 1, tags => ['', '']}}; }
sub inset { return 0; }
sub getanchor { return 'target'; }
sub normalizeclass { return $_[0]; }
sub disambiguate_subcollection { return (0, 1); }
sub disambiguate_classification { die "private source content\n" if $fail; return (0); }
sub getnamebyid { return 'Target'; }
sub outertags { return ('', ''); }
sub taganchor { return $_[1]; }
sub mathTitle { return $_[0]; }
sub xrefAddLink {}
sub recombine { return $_[0]; }
sub postprocessLaTeX { return $_[0]; }
sub dolinktofile { return $_[0]; }
sub prepareYouTubeEmbeds { return ($_[0], 0); }
sub convertHyperrefRenderLinks { return $_[0]; }
sub stripHtmlPackage { return $_[0]; }
sub stripCommentEnvironments { return $_[0]; }
sub nb { return length($_[0] || ''); }
sub dwarn {}
{
    package TemplateNS;
    sub new { bless {}, shift }
    sub setKeys { my ($self, %keys) = @_; %$self = %keys; }
    sub expand { return $_[0]->{math}; }
}
for my $file ('Crossref.pm', 'Cache.pm') {
    open my $fh, '<', "$FindBin::Bin/../../lib/Noosphere/$file" or die $!;
    my $source = do { local $/; <$fh> };
    close $fh;
    my @names = $file eq 'Crossref.pm'
        ? qw(crossReferenceLaTeX makelinks disambiguate)
        : qw(prepareEntryForRendering);
    for my $name (@names) {
        my ($body) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless defined $body;
        eval $body;
        die $@ if $@;
    }
}
my @lines;
local $SIG{__WARN__} = sub { push @lines, $_[0] };
my @output = prepareEntryForRendering(0, '', 'target', 'make4ht', 'source', [], 'objects', 376, '');
like($output[0], qr/\\htmladdnormallink\{Target\}\{https:\/\/example.test\/encyclopedia\/Target.html\}/,
    'real preparation and linking dispatch preserve generated document');
like($output[1], qr/<a href="https:\/\/example.test\/encyclopedia\/Target.html">target<\/a>/,
    'reference-list return value is preserved');
for my $stage (qw(prepare.entry prepare.crossref xref.terms xref.matches xref.make_links xref.disambiguate xref.collections xref.classification xref.math_title xref.save_link prepare.template_expand)) {
    like(join('', @lines), qr/stage=\Q$stage\E event=begin.*stage=\Q$stage\E event=end/s, "$stage is bracketed");
}
my %traces = map { /trace=(\S+)/; $1 => 1 } @lines;
is(scalar keys %traces, 1, 'all preparation and linking stages share one trace');
ok(!defined $Noosphere::RenderLog::CURRENT, 'preparation clears context on return');
$fail = 1;
eval { prepareEntryForRendering(0, '', 'target', 'make4ht', 'source', [], 'objects', 376, '') };
is($@, "private source content\n", 'link-resolution exception reaches caller unchanged');
like(join('', @lines), qr/stage=xref.classification event=error/, 'deep failing stage is identifiable');
unlike(join('', @lines), qr/private source content|example.test/, 'breadcrumbs omit content and URLs');
ok(!defined $Noosphere::RenderLog::CURRENT, 'exception clears context');
$fail = 0;
$enabled = 0;
@lines = ();
is_deeply([prepareEntryForRendering(0, '', 'target', 'make4ht', 'source', [], 'objects', 376, '')], \@output,
    'disabled tracing produces identical document and references');
is(scalar @lines, 0, 'disabled preparation emits no breadcrumbs');
done_testing();
