package Noosphere;
use strict;
use Encode ();
use HTML::Parser;

# Use existing rendered prose, never another render or a raw-TeX conversion.
sub getArticleDescription {
    my ($html, $method) = @_;
    return '' unless defined($html) && !ref($html) && length($html)
        && defined($method) && $method =~ /\A(?:make4ht|l2h)\z/;
    my $sample = substr($html, 0, 65536);
    if (!Encode::is_utf8($sample)) {
        # A byte-limited sample can end partway through a UTF-8 character.
        $sample = Encode::decode('UTF-8', $sample, Encode::FB_QUIET());
    }
    return '' if $sample =~ /rendering\s+failed|on-demand rendering is temporarily disabled|rendering is already in progress|missing cached output/i;

    my ($text, @skip) = ('');
    my $parser = HTML::Parser->new(api_version => 3);
    $parser->handler(start => sub {
        my ($tag, $attr) = @_;
        if (@skip) {
            push @skip, $tag unless $tag =~ /\A(?:area|base|br|col|embed|hr|img|input|link|meta|param|source|track|wbr)\z/;
            return;
        }
        if ($tag =~ /\A(?:head|script|style|nav|form|pre|code|math|h[1-6])\z/
            || exists($attr->{hidden}) || ($attr->{'aria-hidden'} || '') eq 'true'
            || ($attr->{class} || '') =~ /(?:\A|\s)(?:tableofcontents|crosslinks|math|equation|eqnarray)(?:\s|\z)/
            || ($attr->{style} || '') =~ /(?:display\s*:\s*none|visibility\s*:\s*hidden)/i) {
            push @skip, $tag unless $tag =~ /\A(?:img|input|br|hr|meta|link)\z/;
            $text .= ' ';
            return;
        }
        $text .= ' ' if $tag =~ /\A(?:p|div|br|hr|li|tr|td|section|img)\z/;
    }, 'tagname, attr');
    $parser->handler(end => sub {
        my ($tag) = @_;
        if (@skip) {
            for (my $i = $#skip; $i >= 0; $i--) {
                if ($skip[$i] eq $tag) { splice @skip, $i; last; }
            }
            return;
        }
        $text .= ' ' if $tag =~ /\A(?:p|div|li|tr|td|section)\z/;
    }, 'tagname');
    $parser->handler(text => sub { $text .= $_[0] unless @skip }, 'dtext');
    # Chunking bounds text accumulation as well as the parser's input window.
    for (my $i = 0; $i < length($sample) && length($text) < 320; $i += 1024) {
        $parser->parse(substr($sample, $i, 1024));
        $text =~ s/\s+/ /g;
    }
    # Do not flush an incomplete tail: HTML::Parser can expose an unclosed
    # script as literal text at EOF, including when the input window cuts it.
    $text =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/ /g;
    $text =~ s/\s+/ /g;
    $text =~ s/\A\s+|\s+\z//g;
    return '' unless length($text) >= 40 && $text =~ /[[:alpha:]]/;
    return $text if length($text) <= 200;
    my $short = substr($text, 0, 197);
    $short =~ s/\s+\S*\z//;
    return $short . '...';
}

1;
