#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::chdir;
use Fcntl qw(:flock);
use HTML::Entities;
use XML::LibXML;

# Run the renderer dispatch and output writer with a controlled compiler result,
# without requiring Apache, a database, or a TeX installation.
our $reruns = 'ref|eqref|cite';
my $root = tempdir(CLEANUP => 1);
my ($status, $stdout, $stderr) = (256, '', '');
my @warnings;
my $postprocessed = 0;
sub getConfig {
    my ($key) = @_;
    return $root if $key eq 'cache_root';
    return 'physicslibrary.html' if $key eq 'rendering_output_file';
    return 'https://example.org/cache' if $key eq 'cache_url';
    return '';
}
sub UTF8toTeX { return $_[0]; }
sub htmlescape { return encode_entities($_[0], '<>&'); }
sub latex_error_check { return 0; }
sub dwarn { push @warnings, $_[0]; }
sub runExternalCommand { return ($status, $stdout, $stderr); }
sub postProcess_make4htIndex {
    $postprocessed++;
    write_render_message('Successful preview');
    return 1;
}

open my $module, '<', "$FindBin::Bin/../../lib/Noosphere/Latex.pm" or die $!;
my $source = do { local $/; <$module> };
close $module;
for my $name (qw(renderLaTeX render_make4ht make4ht_error_details write_render_message write_out_latex)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?^\})/ms;
    die "$name not found" unless defined $sub;
    eval $sub;
    die $@ if $@;
}

sub rendered_output {
    my ($table, $id) = @_;
    open my $fh, '<', "$root/$table/$id/make4ht/physicslibrary.html" or die $!;
    return do { local $/; <$fh> };
}

my $dir = "$root/temp/preview/make4ht";
$stdout = "[STATUS] make4ht: Conversion started\n"
    . "\e[31m[ERROR] htlatex: $dir/TestTableFormatting.tex 90 Misplaced \\noalign.\e[0m\n"
    . "[ERROR] htlatex: $dir/TestTableFormatting.tex 91 Extra alignment tab has been changed to \\cr.\n"
    . "[ERROR] source: <script>alert(1)</script> & \\example\x01\n";
$stderr = "Compiler stderr: <problem> & details\n";
my $latex = "\\documentclass{article}\n\\begin{document}test\\end{document}\n";

is(renderLaTeX('.', 'temp/preview', $latex, 'make4ht', 'TestTableFormatting'), 0,
    'failed editor preview returns failure');
my $html = rendered_output('temp', 'preview');
like($html, qr/Rendering failed.*status 256/, 'failure summary retained');
like($html, qr/TestTableFormatting\.tex 90 Misplaced \\noalign\./,
    'compiler filename, line number and error saved in preview');
like($html, qr/91 Extra alignment tab/, 'subsequent errors retained');
like($html, qr/STDERR:.*Compiler stderr:/s, 'stderr saved alongside stdout');
like($html, qr/line numbers refer to the generated TeX file/, 'line number scope explained');
unlike($html, qr/\Q$root\E/, 'render directory removed from preview diagnostics');
unlike($html, qr/[\x01\x1B]/, 'terminal escapes and invalid XML controls removed');
like($html, qr/&lt;script&gt;alert\(1\)&lt;\/script&gt; &amp;/,
    'compiler source text is escaped');
my $xml = eval { XML::LibXML->load_xml(string => $html) };
ok($xml, 'failure output parses as XML for collaboration templates') or diag($@);
is($postprocessed, 0, 'failed converter output is not postprocessed');
like($warnings[-1], qr/\Q$dir\E/, 'full server diagnostics retained');

is(renderLaTeX('objects', 1017, $latex, 'make4ht', 'TestTableFormatting'), 0,
    'cached article failure still returns failure');
unlike(rendered_output('objects', 1017), qr/Compiler details|STDOUT|Misplaced/,
    'public cached failure does not expose preview diagnostics');

($stdout, $stderr) = ('', '');
renderLaTeX('.', 'temp/preview', $latex, 'make4ht', 'TestTableFormatting');
like(rendered_output('temp', 'preview'), qr/did not return diagnostic output/,
    'empty command output has a useful fallback');

($status, $stderr) = (31744, 'make4ht timed out');
renderLaTeX('.', 'temp/preview', $latex, 'make4ht', 'TestTableFormatting');
like(rendered_output('temp', 'preview'), qr/STDERR:.*make4ht timed out/s,
    'stderr-only failures are visible');

my $details = make4ht_error_details('x' x 20000, 'important stderr', $dir);
cmp_ok(length($details), '<', 8500, 'long stdout is bounded');
like($details, qr/Output truncated/, 'truncation is explicit');
like($details, qr/important stderr/, 'long stdout cannot hide stderr');

($status, $stdout, $stderr) = (0, '', '');
is(renderLaTeX('.', 'temp/preview', $latex, 'make4ht', 'TestTableFormatting'), 1,
    'successful render returns success');
is($postprocessed, 1, 'successful output follows normal postprocessing');
unlike(rendered_output('temp', 'preview'), qr/Compiler details|Rendering failed/,
    'successful rerender replaces old diagnostics');

done_testing();
