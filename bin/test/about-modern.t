#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Test::More;
use Template;
use HTML::Parser;

my $root = "$FindBin::Bin/../..";
sub read_file {
    my ($path) = @_;
    open my $fh, '<', "$root/$path" or die "$path: $!";
    return do { local $/; <$fh> };
}

sub page_content {
    my ($html) = @_;
    my ($text, $hidden) = ('', 0);
    my @links;
    my $parser = HTML::Parser->new(api_version => 3,
        start_h => [sub {
            my ($tag, $attrs) = @_;
            $hidden = 1 if $tag eq 'style' || $tag eq 'script';
            push @links, $attrs->{href} if $tag eq 'a';
        }, 'tagname, attr'],
        end_h => [sub { $hidden = 0 if $_[0] eq 'style' || $_[0] eq 'script' }, 'tagname'],
        text_h => [sub { $text .= $_[0] unless $hidden }, 'dtext'],
    );
    $parser->parse($html);
    $parser->eof;
    $text =~ s/\s+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return ($text, \@links);
}

my $docs = read_file('lib/Noosphere/Docs.pm');
my ($handler) = $docs =~ /^(sub getAbout \{.*?)(?=^sub |\z)/ms;
ok(defined($handler), 'About handler is available');
{
    package Noosphere;
    sub getConfig { return "$root/stemplates" }
    sub paddingTable { die 'About must not add a spacing wrapper' }
    sub clearBox { die 'About must not add a second title box' }
}
ok(eval('package Noosphere; use strict; ' . $handler . '; 1'),
    'About handler compiles') or diag($@);
my $html = Noosphere::getAbout({});
like($html, qr/<header class="pl-modern-box-header"><h1>The Physics Library Story<\/h1><\/header>/,
    'About uses the compact shared blue header');
like($html, qr/background: #003399/, 'About matches the sidebar header blue');
is(scalar(() = $html =~ /<h1\b/g), 1, 'About has one page heading');
like($html, qr/<section[^>]*aria-labelledby="about-credits-heading"/,
    'credits have a labelled section');
is(scalar(() = $html =~ /<li>/g), 12, 'all twelve credit entries are retained');
unlike($html, qr/<font\b|<table\b/, 'About has no legacy font tags or spacing table');

# The unchanged legacy template is the baseline for wording and links.
my ($original_text, $original_links) = page_content(read_file('stemplates/about.html'));
my ($new_text, $new_links) = page_content($html);
is($new_text, $original_text, 'all original visible words remain in their original order');
is_deeply($new_links, $original_links, 'all original link destinations are unchanged');
unlike($html, qr/grid-template-columns|column-count|columns:/,
    'credits remain a single-column list at every screen size');

done_testing();
