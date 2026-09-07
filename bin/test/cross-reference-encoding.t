#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Encode qw(encode decode FB_CROAK);
use lib "$FindBin::Bin/../../lib";
require Noosphere::Charset;

my $root = tempdir(CLEANUP => 1);
my @warnings;
sub getConfig { return $root; }
sub dwarn { push @warnings, $_[0]; }
sub swaptitle { return $_[0]; }

# Load the actual cache boundary and title conversion without Apache or a DB.
for my $spec (
    ['Latex.pm', qw(writeLinksToFile getRenderedObjectLinks decodeRenderedHTML escapeNonAsciiAsHTMLEntities)],
    ['Layout.pm', 'mathTitle'],
    ['Util.pm', 'readFile'],
) {
    my ($file, @names) = @$spec;
    open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/$file" or die $!;
    my $source = do { local $/; <$in> };
    close $in;
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "$name not found" unless defined $sub;
        eval $sub;
        die $@ if $@;
    }
}
sub TeXtoUTF8 { return Noosphere::TeXtoUTF8(@_); }
sub write_links {
    my $debug = '';
    open my $capture, '>', \$debug or die $!;
    local *STDOUT = $capture;
    writeLinksToFile(@_);
}

my $prefix = '<a href="https://physicslibrary.org/encyclopedia/Hamiltonian2.html">';
my $tex = $prefix . 'Schr\"odinger operator</a>';
my $expected = $prefix . 'Schr&#246;dinger operator</a>';
my $title = mathTitle($tex);
is($title, $prefix . "Schr\x{f6}dinger operator</a>", 'real title conversion produces an umlaut');

for my $method (qw(make4ht pdf png src l2h)) {
    make_path("$root/objects/314/$method");
    write_links('objects', 314, $method, $title);
    is(readFile("$root/objects/314/$method/pmlinks.html"), $expected,
        "$method stores the accent as an ASCII entity");
    is(getRenderedObjectLinks('objects', 314, $method), $expected,
        "$method serves the correct label and destination");
}

my $path = "$root/objects/314/make4ht/pmlinks.html";
for my $encoding ('ISO-8859-1', 'UTF-8') {
    open my $out, '>:raw', $path or die $!;
    print {$out} encode($encoding, $title);
    close $out;
    is(getRenderedObjectLinks('objects', 314, 'make4ht'), $expected,
        "existing $encoding cache is readable without rerendering");
    write_links('objects', 314, 'make4ht', encode($encoding, $title));
    is(readFile($path), $expected, "$encoding byte input is normalized on write");
}

my $unicode = $prefix . "Schr\x{f6}dinger \x{3b1} \x{153}</a>";
my $entities = $prefix . 'Schr&#246;dinger &#945; &#339;</a>';
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0]; };
    write_links('objects', 314, 'make4ht', $unicode);
}
is(readFile($path), $entities, 'decoded Unicode is not decoded a second time');
write_links('objects', 314, 'make4ht', encode('UTF-8', $unicode));
is(getRenderedObjectLinks('objects', 314, 'make4ht'), $entities,
    'UTF-8 characters beyond Latin-1 survive the cache round trip');

my $markup = '<a href="/?op=getobj&amp;id=301">Schr&#246;dinger &amp; <i>H</i></a>';
write_links('objects', 314, 'make4ht', $markup);
is(getRenderedObjectLinks('objects', 314, 'make4ht'), $markup,
    'existing entities, links, and inline markup are preserved');
write_links('objects', 314, 'make4ht', '');
is(getRenderedObjectLinks('objects', 314, 'make4ht'), '', 'empty reference list stays empty');
is_deeply(\@warnings, [], 'cache operations emit no encoding warnings');
done_testing();
