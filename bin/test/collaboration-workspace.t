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

my $source = read_file("$repo/lib/Noosphere/Collab.pm");
like($source, qr/sub collabMain\s*\{.*?collabmain\.tt/s,
    'existing collaboration route uses the modern workspace template');
like($source, qr/\$sort\s*=\s*\$params->\{'sort'\}\s*\|\|\s*'activity'/,
    'recent activity is the default collaboration ordering');
like($source, qr/\$filter\s*=\s*\$params->\{'filter'\}\s*\|\|\s*'all'/,
    'collaboration filters default to all visible workspaces');
like($source, qr/\Q(?:all|locked|mine|shared|published)\E/,
    'collaboration filter values are allowlisted');
like($source, qr/locked_by_current_user/, 'workspace data distinguishes a lock held by the current user');
like($source, qr/Revision history.*Manage access.*Edit comment/s,
    'existing management actions remain available to the modern template');

my $template = read_file("$repo/stemplates/collabmain.tt");
like($template, qr/name="op" value="collab"/, 'workspace filter form targets the existing collaboration route');
like($template, qr/name="q"/, 'workspace provides search');
like($template, qr/name="filter"/, 'workspace provides state filtering');
like($template, qr/name="sort"/, 'workspace provides sorting');
like($template, qr/Create Collaboration/, 'workspace provides direct collaboration creation');
like($template, qr/Locked by you.*Release lock/s, 'workspace provides a lock recovery action');
like($template, qr/Available to edit/, 'workspace surfaces edit availability');
like($template, qr/collab\.manage/, 'workspace retains conditional management actions');

SKIP: {
    eval { require Template; 1 } or skip 'Template Toolkit is not installed', 5;
    my $tt = Template->new(INCLUDE_PATH => "$repo/stemplates");
    my $rendered = '';
    ok($tt->process('collabmain.tt', {
        total => 1, owned => 1, shared => 0, locked => 1,
        sort => 'activity', filter => 'all', search => '',
        collabs => [{
            title => 'Active &amp; Safe', abstract => 'A working document.',
            is_owner => 1, ownername => '', locked => 1,
            locked_by_current_user => 1, lockuser => 'Ada', locktime => 'today',
            lastwhen => 'today', lastuser => 'Ada', published => 0, sitedoc => 0,
            viewhref => '/?op=getobj&amp;id=7', edithref => '/?op=edit&amp;id=7',
            lockhref => '/?op=edit&amp;id=7&amp;lock=1',
            releasehref => '/?op=collab_release_lock&amp;id=7',
            manage => [{url => '/?op=vbrowser&amp;id=7', anchor => 'Revision history'}],
        }],
    }, \$rendered), 'workspace template renders a locked collaboration');
    like($rendered, qr/Active &amp; Safe/, 'rendered title remains escaped');
    like($rendered, qr/Locked by you.*Release lock/s, 'rendered workspace exposes the lock recovery path');
    like($rendered, qr/Recent activity/, 'rendered workspace includes sort control');
    like($rendered, qr/Create Collaboration/, 'rendered workspace includes creation action');
}

done_testing();
