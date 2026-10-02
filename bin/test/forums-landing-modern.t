#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
open my $in, '<', "$root/lib/Noosphere/Forums.pm" or die $!;
my $source = do { local $/; <$in> };
my ($get_forums_top) = $source =~ /(sub getForumsTop \{.*?^\})/ms;
ok($get_forums_top, 'forums landing handler is available');

{
    package Noosphere;
    our $dbh;
    our @rows;
    our $query_ok = 1;
    sub dbSelect { return ($query_ok, 'forum rows') }
    sub dbGetRows { return @rows }
    sub getConfig {
        return 'forums' if $_[0] eq 'forum_tbl';
        return 'https://physicslibrary.org' if $_[0] eq 'main_url';
        return 'stemplates';
    }
    sub qhtmlescape {
        my $text = shift;
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        return $text;
    }
    sub getmsgcount { return $_[1] == 7 ? 6 : 0 }
    sub count_unseen { return $_[1] == 7 && $_[2] == 42 ? 2 : 0 }
    sub paddingTable { return $_[0] }
    sub dwarn {}
}

{
    package Template;
    our $vars;
    our $name;
    sub new { return bless {}, shift }
    sub process {
        my ($self, $template, $data, $output) = @_;
        $name = $template;
        $vars = $data;
        $$output = 'rendered forums landing';
        return 1;
    }
}

my $loaded = eval "package Noosphere; our \$dbh; $get_forums_top; 1";
ok($loaded, 'forums handler compiles with the site globals') or diag($@);

@Noosphere::rows = (
    { uid => 7, title => 'Physics <questions>', data => 'Ask & discuss.' },
    { uid => 8, title => 'Books', data => 'Reviews' },
);
is(Noosphere::getForumsTop({}, { uid => 42 }), 'rendered forums landing', 'forum listing renders through the template');
is($Template::name, 'forumslist.tt', 'forum listing uses its dedicated template');
is(scalar @{$Template::vars->{forums}}, 2, 'both forums reach the template');
is($Template::vars->{forums}[0]{title}, 'Physics &lt;questions&gt;', 'forum title is escaped');
is($Template::vars->{forums}[0]{description}, 'Ask &amp; discuss.', 'forum description is escaped');
is($Template::vars->{forums}[0]{url}, 'https://physicslibrary.org/?op=getobj&amp;from=forums&amp;id=7', 'forum link keeps its existing route');
is($Template::vars->{forums}[0]{messages}, 6, 'message count is passed as a number');
is($Template::vars->{forums}[0]{unread}, 2, 'unread count is passed as a number');
is($Template::vars->{forums}[1]{messages}, 0, 'forum without messages keeps a zero count');

@Noosphere::rows = ();
Noosphere::getForumsTop({}, { uid => 42 });
is(scalar @{$Template::vars->{forums}}, 0, 'empty forum list reaches the template');

open my $template_in, '<', "$root/stemplates/forumslist.tt" or die $!;
my $template = do { local $/; <$template_in> };
like($template, qr/INCLUDE modernboxheader\.tt/, 'landing page uses the shared box heading');
like($template, qr/No forums are available yet\./, 'landing page has an empty state');
like($template, qr/IF forum\.unread > 0/, 'unread count is shown only when positive');

done_testing();
