#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $repo = "$FindBin::Bin/../..";

sub read_file {
    my ($path) = @_;
    open my $in, '<', $path or die "$path: $!";
    my $text = do { local $/; <$in> };
    close $in;
    return $text;
}

my $requests = read_file("$repo/lib/Noosphere/Requests.pm");
my ($req_list) = $requests =~ /^(sub reqList \{.*?)(?=^# Retained|\z)/ms;
die 'reqList not found' unless defined $req_list;

like($req_list, qr/Template->new\(\{ INCLUDE_PATH => '\/var\/www\/pp\/stemplates' \}\)/,
    'request listing uses the Template Toolkit presentation');
like($req_list, qr/process\('reqlist\.tt'/,
    'request listing renders the modern request template');
like($req_list, qr/open_requests.*fulfilled_requests/s,
    'request listing separates open requests from reported fulfillments');
like($req_list, qr/qhtmlescape\(\$row->\{title\}\).*qhtmlescape\(\$row->\{username\}\)/s,
    'request titles and requester names are escaped before template output');
like($req_list, qr/message_total.*message_unseen/s,
    'request listing retains discussion and unread-message state');

my $template = read_file("$repo/stemplates/reqlist.tt");
like($template, qr/<h1>Requests<\/h1>/, 'modern request view has a clear title');
like($template, qr/Create Request/, 'modern request view provides a creation action');
like($template, qr/Open Requests.*Awaiting Confirmation/s,
    'modern request view separates open and reported fulfillment work');
like($template, qr/Fill request.*Update fulfillment/s,
    'open requests preserve the established fulfillment actions');
like($template, qr/Browse completed requests/, 'modern request view retains access to old requests');
like($template, qr/Confirm filled requests/, 'modern request view retains the administrator confirmation action');

SKIP: {
    eval { require Template; 1 } or skip 'Template Toolkit is not installed', 4;
    my $tt = Template->new(INCLUDE_PATH => "$repo/stemplates");
    my $rendered = '';
    ok($tt->process('reqlist.tt', {
        open_total => 1,
        fulfilled_total => 1,
        admin => 1,
        open_requests => [{
            title => 'Vector &amp; Flux', titlehref => '/?op=getobj&amp;id=4',
            requester => 'Ada', requesterhref => '/?op=getuser&amp;id=2', date => '2026-09-26',
            message_total => 2, message_unseen => 1, fillhref => '/?op=adden&amp;request=4',
            updatehref => '/?op=updatereq&amp;request=4',
        }],
        fulfilled_requests => [{
            title => 'A completed request', titlehref => '/?op=getobj&amp;id=5',
            requester => 'Grace', requesterhref => '/?op=getuser&amp;id=3', date => '2026-09-25',
            filler => 'Lin', fillerhref => '/?op=getuser&amp;id=4',
            message_total => 0, message_unseen => 0,
        }],
    }, \$rendered), 'template renders representative request data');
    like($rendered, qr/Vector &amp; Flux/, 'escaped title remains escaped in the rendered list');
    like($rendered, qr/Reported filled by/, 'rendered list includes fulfillment status');
    like($rendered, qr/Confirm filled requests/, 'rendered administrator action is present');
}

done_testing();
