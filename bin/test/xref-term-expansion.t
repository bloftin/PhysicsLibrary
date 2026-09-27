#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RenderLog;
use Noosphere::Charset;
use Noosphere::Morphology;
use Unicode::String qw(latin1 utf8 utf16);
our (%ICHAR_TO_ASCII, $dbh);

sub load_source {
    my ($file, @names) = @_;
    open my $fh, '<', "$FindBin::Bin/../../lib/Noosphere/$file.pm" or die $!;
    my $source = do { local $/; <$fh> };
    close $fh;
    if ($file eq 'Util') {
        my ($map) = $source =~ /^(%ICHAR_TO_ASCII=\(.*?^\);)/ms;
        die 'Missing character map' unless defined $map;
        eval $map;
        die $@ if $@;
    }
    for my $name (@names) {
        my ($body) = $source =~ /^(sub \Q$name\E\s*\{.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless defined $body;
        eval $body;
        die $@ if $@;
    }
}
load_source('Util', qw(UTF8ToAscii UTF8ToLatin1 latin1ToAscii inset));
load_source('Latex', qw(escapeMathSimple unescapeMathSimple));
load_source('Indexing', qw(swaptitle));
load_source('Crossref', qw(addterm generateterms));

# Fail quickly on the old recursive path instead of exhausting the test host.
local $SIG{ALRM} = sub { die "term expansion timed out\n" };
alarm 10;
my @warnings;
local $SIG{__WARN__} = sub {
    die $_[0] if $_[0] =~ /Deep recursion/;
    push @warnings, $_[0];
};

for my $capture ('mechanics', "Euler's", '$x$') {
    for my $blank (undef, '', ' ', "\t\n") {
        my %terms;
        my $ok = eval {
            $capture =~ /(.+)/;
            addterm(\%terms, $blank, 0);
            1;
        };
        ok($ok, "blank term terminates with inherited capture $capture") or diag $@;
        is_deeply(\%terms, {}, 'blank term adds no index entry');
    }
}

my %terms;
addterm(\%terms, '  vector spaces  ', 1);
is_deeply($terms{vector}{'vector spaces'}, [1], 'outer whitespace is normalized');
is_deeply($terms{vector}{'vector space'}, [1], 'plural expansion still works');
addterm(\%terms, "Euler's equations", 2);
is_deeply($terms{euler}{'Euler equation'}, [2], 'converging possessive/plural paths expand once');
addterm(\%terms, 'Euler equation', 3);
is_deeply($terms{euler}{'Euler equation'}, [2, 3], 'distinct concepts sharing a title are retained');
addterm(\%terms, '$x$ spaces', 4);
ok(exists $terms{x}{'x space'}, 'math and plural aliases are retained');
addterm(\%terms, 'Euler, Leonhard', 5);
is_deeply($terms{leonhard}{'Leonhard Euler'}, [5], 'index-form title still swaps');
addterm(\%terms, 'Schr\"odinger equations', 6);
my $utf8_title = TeXtoUTF8('Schr\"odinger equation');
my ($utf8_prefix) = $utf8_title =~ /^(\S+)/;
ok(exists $terms{lc($utf8_prefix)}{$utf8_title}, 'TeX-to-UTF8 accent alias is retained');

{
    no warnings 'redefine';
    local *getnonmathy = sub { return $_[0] };
    my %cycle;
    my $ok = eval { addterm(\%cycle, '$x$', 7); 1 };
    ok($ok, 'unchanged recursive transformation terminates') or diag $@;
    is_deeply($cycle{'$x$'}{'$x$'}, [7], 'cycle does not duplicate concept references');
}

# Exercise the actual caller with a mocked DB, including a legacy blank defines row.
$INC{'Noosphere/Encyclopedia.pm'} = __FILE__;
sub getConfig { return $_[0] eq 'index_tbl' ? 'objindex' : 'objects' }
sub dbSelect { return (1, 'statement') }
sub dbGetRows {
    return (
        { objectid => 872, type => 1, title => 'Example' },
        { objectid => 1307, type => 1, title => 'Degrees of Freedom in Mechanics' },
        { objectid => 1307, type => 2, title => 'M00-07G' },
        { objectid => 872, type => 3, title => '' },
    );
}
for my $logging (0, 1) {
    local $Noosphere::RenderLog::CURRENT = Noosphere::RenderLog::context($logging, 'objects', 1307, 'make4ht');
    my @result;
    my $ok = eval {
        'mechanics' =~ /(.+)/;
        @result = Noosphere::RenderLog::run('xref.terms', sub {
            generateterms(1307, ['M00-07G', 'Degrees of Freedom in Mechanics', '']);
        });
        1;
    };
    ok($ok, "full term generation terminates with logging=$logging") or diag $@;
    ok($result[0] && exists $result[0]{degrees}, 'valid article remains indexed');
    ok($result[0] && !exists $result[0]{''}, 'no blank prefix is indexed');
}
my @unexpected = grep { !/^PL_RENDER / } @warnings;
is_deeply(\@unexpected, [], 'no undefined-capture or recursion warnings');
alarm 0;
done_testing();
