#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Test::More;
use Template;
use HTML::Parser;

my $root = "$FindBin::Bin/../..";
my $title = 'Creative Commons Attribution-ShareAlike CC BY-SA 4.0 License';
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
my ($handler) = $docs =~ /^(sub getLicense \{.*?)(?=^sub |\z)/ms;
ok(defined($handler), 'license handler is available');
{
    package Noosphere;
    sub getConfig { return "$root/stemplates" }
    sub paddingTable { die 'License must not add a spacing wrapper' }
    sub clearBox { die 'License must not add a second title box' }
}
ok(eval('package Noosphere; use strict; ' . $handler . '; 1'),
    'license handler compiles') or diag($@);
like($handler, qr/INCLUDE_PATH => getConfig\('template_path'\)/,
    'license uses the configured template directory');
my $html = Noosphere::getLicense();
like($html, qr/<header class="pl-modern-box-header"><h1>\Q$title\E<\/h1><\/header>/,
    'license retains its title in the shared blue header');
like($html, qr/background: #003399/, 'license matches the sidebar header blue');
is(scalar(() = $html =~ /<h1\b/g), 1, 'license has one page heading');
unlike($html, qr/<font\b|<center\b|<table\b/,
    'license uses no legacy font, centering, or spacing-table markup');
is(scalar(() = $html =~ /<p>/g), 2, 'notice has two readable paragraphs');

my ($original_text, $original_links) = page_content(read_file('stemplates/license.html'));
my ($new_text, $new_links) = page_content($html);
is($new_text, "$title $original_text", 'license title and every original notice word are preserved');
is_deeply($new_links, $original_links, 'original license link is unchanged');
like(read_file('lib/Noosphere/Dispatch.pm'), qr/'license'\s*=>\s*\\&getLicense/,
    'existing public license route remains unchanged');

done_testing();
