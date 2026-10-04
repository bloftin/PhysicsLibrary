#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Test::More;
use Template;

my $root = "$FindBin::Bin/../..";
my $tt = Template->new({ INCLUDE_PATH => "$root/stemplates" });

sub read_file {
    my ($path) = @_;
    open my $fh, '<', "$root/$path" or die "$path: $!";
    return do { local $/; <$fh> };
}

my %pages = (
    about => 'The Physics Library Story',
    license => 'Creative Commons Attribution-ShareAlike CC BY-SA 4.0 License',
    reqlist => 'Requests', orphanage => 'Orphanage',
    userarticlesbeta => 'My Articles', unclassified => 'Unclassified Articles',
    unproven => 'Unproven Theorems', globalcors => 'Pending Corrections',
    encyclopediaindex => 'Physics Library Encyclopedia',
    encyclopedialist => 'Search Encyclopedia', paperslobby => 'Physics Library Papers',
    paperslist => 'Search Papers', bookslist => 'Search Books',
    lectureslist => 'Search Lectures', pacsbrowse => 'Browse by Subject',
    pacssearch => 'Search Subjects', collabmain => 'Collaborations',
    pollslist => 'Polls', forumslist => 'Forums', feedback => 'Feedback',
    useractivity => 'User Activity', userlist => 'Physics Library Users',
    systemstats => 'Physics Library Stats', notices => 'Your Notices',
    mailbox => 'Your Mailbox', editcors => 'Corrections to Your Objects',
);

for my $page (sort keys %pages) {
    my $source = read_file("stemplates/$page.tt");
    like($source, qr/INCLUDE modernboxheader\.tt/, "$page uses the shared heading");
    unlike($source, qr/\.pl-[\w-]+(?:-header)? h1\s*\{/,
        "$page has no competing title style");
    for my $total (0, 2) {
        my $html = '';
        ok($tt->process("$page.tt", {
            title => $pages{$page}, total => $total, showing_from => 1, showing_to => 2,
            sort => 'created_desc', objects => [], groups => [],
            orphaned => [], adoptable => [], open_requests => [], fulfilled_requests => [],
        }, \$html), "$page renders with total=$total") or diag($tt->error());
        like($html, qr/<header class="pl-modern-box-header"><h1>\Q$pages{$page}\E<\/h1><\/header>/,
            "$page retains its title in the blue bar");
        is(scalar(() = $html =~ /<h1\b/g), 1, "$page has exactly one page heading");
        unlike($html, qr/<header\b[^>]*>\s*(?:<style\b.*?<\/style>\s*)?<header\b/s,
            "$page does not nest header elements");
    }
}

my $shared = read_file('stemplates/modernboxheader.tt');
like($shared, qr/background: #003399; border-bottom: 1px solid #002266/,
    'shared heading matches the established sidebar blue and border');
like($shared, qr/padding: \.15rem \.5rem/, 'shared heading uses compact spacing');
like($shared, qr/font: bold 1rem.*line-height: 1\.2/s, 'shared title matches sidebar sizing');
like($shared, qr/overflow-wrap: anywhere/, 'long titles can wrap at narrow widths');
my $escaped = '';
ok($tt->process('modernboxheader.tt', { title => 'Inbox <script> & "notes"' }, \$escaped),
    'dynamic heading renders');
like($escaped, qr/<h1>Inbox &lt;script&gt; &amp; &quot;notes&quot;<\/h1>/,
    'dynamic titles remain HTML-escaped');

for my $case (
    ['Encyclopedia', 'getEncyclopedia'],
    ['Requests', 'reqList'], ['Orphan', 'orphanage'], ['UserData', 'userObjectListPage'],
    ['Stats', 'unprovenTheorems'], ['Stats', 'unclassifiedObjects'], ['Stats', 'getSystemStats'],
    ['Corrections', 'globalViewCorrections'], ['Collab', 'collabMain'], ['Msc', 'pacsSearch'],
    ['Polls', 'viewPolls'], ['Forums', 'getForumsTop'], ['Docs', 'getFeedback'],
    ['Docs', 'getLicense'],
    ['Users', 'showUserActivity'], ['Users', 'userList'],
) {
    my ($module, $handler) = @$case;
    my $source = read_file("lib/Noosphere/$module.pm");
    my ($body) = $source =~ /^sub \Q$handler\E\b(.*?)(?=^sub |\z)/ms;
    ok(defined($body), "$handler exists");
    like($body, qr/return \$html(?: if \$view->\{modern\})?;/,
        "$handler returns the modern view without the legacy spacing table");
    unlike($body, qr/paddingTable\(\$html\)/,
        "$handler does not offset the title bar from the sidebar");
}
like(read_file('lib/Noosphere/UserData.pm'), qr/return paddingTable\(clearBox\(/,
    'legacy object views keep their existing wrapper');

done_testing();
