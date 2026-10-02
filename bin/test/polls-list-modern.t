#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
open my $in, '<', "$root/lib/Noosphere/Polls.pm" or die $!;
my $source = do { local $/; <$in> };
my ($view_polls) = $source =~ /(sub viewPolls \{.*?^\})/ms;
ok($view_polls, 'poll list handler is available');

{
    package Noosphere;
    our $dbh;
    our @rows;
    sub dbSelect { return (1, 'poll rows') }
    sub dbGetRows { return @rows }
    sub getConfig { return $_[0] eq 'main_url' ? 'https://physicslibrary.org' : "$root/stemplates" }
    sub ymd { return substr($_[0], 0, 10) }
    sub qhtmlescape {
        my $text = shift;
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        return $text;
    }
    sub paddingTable { return $_[0] }
    sub errorMessage { return $_[0] }
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
        $$output = 'rendered poll list';
        return 1;
    }
}

my $loaded = eval "package Noosphere; our \$dbh; $view_polls; 1";
ok($loaded, 'poll list handler compiles with the site globals') or diag($@);

@Noosphere::rows = (
    { uid => 7, title => 'Open <poll> & friends', start => '2026-09-01 00:00:00', finish => '2026-10-01 00:00:00', opened => 1 },
    { uid => 6, title => 'Past poll', start => '2026-08-01 00:00:00', finish => '2026-08-08 00:00:00', opened => 0 },
);
is(Noosphere::viewPolls(), 'rendered poll list', 'poll list renders through the template');
is($Template::name, 'pollslist.tt', 'poll list uses its dedicated template');
is(scalar @{$Template::vars->{open_polls}}, 1, 'open poll is available to the template');
is(scalar @{$Template::vars->{closed_polls}}, 1, 'closed poll is available to the template');
is($Template::vars->{open_polls}[0]{title}, 'Open &lt;poll&gt; &amp; friends', 'poll title is escaped');
is($Template::vars->{open_polls}[0]{vote_url}, 'https://physicslibrary.org/?op=getpoll&amp;id=7', 'open poll keeps the vote route');
is($Template::vars->{closed_polls}[0]{results_url}, 'https://physicslibrary.org/?op=getobj&amp;from=polls&amp;id=6', 'past poll keeps the results route');

@Noosphere::rows = ();
Noosphere::viewPolls();
is(scalar @{$Template::vars->{open_polls}}, 0, 'empty poll list has no open rows');
is(scalar @{$Template::vars->{closed_polls}}, 0, 'empty poll list has no past rows');

open my $template_in, '<', "$root/stemplates/pollslist.tt" or die $!;
my $template = do { local $/; <$template_in> };
like($template, qr/INCLUDE modernboxheader\.tt/, 'poll list uses the reusable box heading');
like($template, qr/No polls are open right now\./, 'poll list has an open poll empty state');
like($template, qr/No polls have been posted yet\./, 'poll list has a site empty state');
like($template, qr/IF closed_polls\.size/, 'past polls are omitted when there are none');

done_testing();
