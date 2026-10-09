#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);
use lib "$FindBin::Bin/../../lib";
use Noosphere::NativeSearch;
use Noosphere::SearchIndex;

my %config = (search_pandoc=>$ENV{SEARCH_TEST_PANDOC} || '/usr/bin/pandoc');
{ package Noosphere; sub getConfig { $config{$_[0]} } }
is(Noosphere::nativeSearchBooleanQuery(Noosphere::nativeSearchQuery('"calculus of variations"')),
    '+calculus +variations', 'safe indexed candidates; short words verified separately');
is(Noosphere::nativeSearchBooleanQuery(Noosphere::nativeSearchQuery('-vector +waves* ~orbit >target')),
    '+vector +waves +orbit +target', 'operators cannot exclude/broaden matches');
is(Noosphere::nativeSearchBooleanQuery(Noosphere::nativeSearchQuery('EM of a')),'','all short words retain metadata path');
is(Noosphere::nativeSearchBooleanQuery(Noosphere::nativeSearchQuery('Über über')),'+über','Unicode words and deduplication');
is(Noosphere::nativeSearchBooleanQuery(Noosphere::nativeSearchQuery('x'x85)), '', 'overlong engine token not passed');
like(Noosphere::nativeSearchFreshSql('s',1),qr/o.version/,'articles check revision');
unlike(Noosphere::nativeSearchFreshSql('s',0),qr/o.version/,'resources do not require nonexistent revision field');
eval { Noosphere::searchIndexCollection('mail') };
like($@,qr/Invalid index collection/,'private message collection cannot be indexed');

SKIP: {
    skip 'Set SEARCH_TEST_PANDOC to Pandoc with --sandbox support', 15 unless -x $config{search_pandoc};
    my ($outside, $path) = tempfile();
    print $outside 'PRIVATE_FILE_SENTINEL'; close $outside;
    my $source = <<'TEX';
\section{Variational principles}
Prose includes \emph{nested \textbf{important} physics},
and \PMlinkname{center of mass relation}{CenterOfMass}.
% DO NOT INDEX COMMENT
\PMlinkexternal{Fermilab}{https://www.youtube.com/@fermilab}
\PMlinkescapephrase{ESCAPE_SENTINEL}
\begin{equation}F=ma\end{equation}
End of the article.
TEX
    my $text = Noosphere::searchIndexText($source.'\\input{'.$path.'}', 'objects');
    like($text,qr/Variational principles/,'headings included');
    like($text,qr/nested important physics/,'nested TeX formatting parsed');
    like($text,qr/center of mass relation/,'PM link label retained');
    like($text,qr/Fermilab/,'external link label retained');
    unlike($text,qr/PRIVATE_FILE_SENTINEL/,'sandbox prevents arbitrary local input');
    unlike($text,qr/DO NOT INDEX COMMENT/,'TeX comments excluded without swallowing following lines');
    unlike($text,qr/ESCAPE_SENTINEL/,'xref directives not prose');
    unlike($text,qr/\\(?:section|emph|PMlink)/,'no TeX commands in plain text');
    like($text,qr/End of the article/,'entire source parsed beyond header');
    my $unicode = Noosphere::searchIndexText('Über waves and naïve models.', 'objects');
    like($unicode,qr/Über.*naïve/,'UTF-8 plain-text output');
    my $html = Noosphere::searchIndexText('<h2>Abstract</h2><p>Velocity <b>and acceleration</b> &amp; torque.</p><script>EVIL_SCRIPT</script>', 'papers');
    like($html,qr/Abstract.*Velocity and acceleration & torque/s,'HTML abstracts parsed');
    unlike($html,qr/EVIL_SCRIPT|<p>|<b>/,'scripts and HTML tags excluded');
    eval { Noosphere::searchIndexText('a'x(Noosphere::searchIndexSourceLimit()+1),'objects') };
    like($@,qr/exceeds limit/,'oversize source rejected');
    local $config{search_pandoc}='/does/not/exist';
    eval { Noosphere::searchIndexText('test','objects') };
    like($@,qr/Invalid Pandoc path/,'missing parser reported');
    is(Noosphere::searchIndexSourceLimit(),262144,'fixed input/output byte budget');
}
my $root="$FindBin::Bin/../..";
for my $file ('SearchIndex.pm', 'NativeSearch.pm') {
    open my $fh,'<',"$root/lib/Noosphere/$file" or die $!; local $/; my $source=<$fh>;
    unlike($source,qr/\b(?:renderLaTeX|cacheObject|wordIndexEntry|invalidateCache)\s*\(/,"$file never renders/reindexes xrefs or invalidates render cache");
}
open my $fh,'<',"$root/bin/update-search-index" or die $!; local $/; my $cli=<$fh>;
like($cli,qr/GET_LOCK\(\?,0\)/,'nonblocking worker exclusion');
like($cli,qr/limit >= 1 && \$limit <= 50/,'bounded batch');
unlike($cli,qr/nativeSearchDisplayText\(\$record->\{source\}/,'source newlines preserved for TeX comments');
done_testing;
