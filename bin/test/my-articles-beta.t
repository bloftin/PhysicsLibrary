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

my $dispatch = read_file("$repo/lib/Noosphere/Dispatch.pm");
like($dispatch, qr/'edituserobjsbeta'\s*=>\s*\\&userArticleBetaList/,
    'dispatch retains the legacy beta My Articles route');

my $routes = read_file("$repo/lib/Noosphere/RequestForm.pm");
like($routes, qr/\bedituserobjsbeta\b/,
    'beta list is a read-only request route');

my $sidebar = read_file("$repo/stemplates/loggedin.tt");
like($sidebar, qr{op=edituserobjs">My Articles</a>},
    'sidebar links to the canonical modern My Articles route');
unlike($sidebar, qr/edituserobjsbeta|My Articles \(Beta\)/,
    'sidebar no longer exposes a separate beta My Articles route');

my $template = read_file("$repo/stemplates/userarticlesbeta.tt");
like($template, qr/name="op" value="edituserobjs"/,
    'modern filter form targets the canonical My Articles route');
like($template, qr/name="q"/, 'beta view provides title and name search');
like($template, qr/name="type"/, 'beta view provides collection filtering');
like($template, qr/name="sort"/, 'beta view provides sorting');
unlike($template, qr/Open classic My Articles|>BETA</, 'modern view has no beta or classic escape hatch');
like($template, qr/Create Article/, 'beta view provides a direct article creation action');
like($template, qr/Showing \[% showing_from %\]-\[% showing_to %\] of \[% total %\]/,
    'beta view reports the currently visible article range');
like($template, qr/<nav class="pl-articles-beta-pager" aria-label="Article pages">/,
    'beta pager has navigation semantics');
like($template, qr/object\.safe_title/, 'beta output uses the escaped article title');
like($template, qr/Needs classification.*Corrections.*New messages/s,
    'beta view surfaces existing article status flags');
like($template, qr/object\.abandonhref.*object\.deletehref/s,
    'beta view keeps established confirmation-backed destructive actions');

my $userdata = read_file("$repo/lib/Noosphere/UserData.pm");
like($userdata, qr/sub userEditObjectList.*?template\s*=>\s*'userarticlesbeta\.tt'.*?modern\s*=>\s*1/s,
    'canonical route uses the modern presentation template');
like($userdata, qr/sub userArticleBetaList.*?return userEditObjectList\(\@_\)/s,
    'legacy beta route delegates to the canonical route');
like($userdata, qr/sub userObjectListPage/s,
    'classic and beta views share the established list data path');
like($userdata, qr/safe_title\s*=>\s*qhtmlescape\(\$row->\{'title'\}\)/,
    'article titles are escaped before beta template rendering');
like($userdata, qr/showing_from\s*=>\s*\$showing_from.*?showing_to\s*=>\s*\$showing_to/s,
    'beta view receives the visible article range');

SKIP: {
    eval { require Template; 1 } or skip 'Template Toolkit is not installed', 5;
    my $tt = Template->new(INCLUDE_PATH => "$repo/stemplates");
    my $rendered = '';
    ok($tt->process('userarticlesbeta.tt', {
        total => 1,
		showing_from => 1,
		showing_to => 1,
        search => 'field',
        sort => 'modified_desc',
        object_type => 'objects',
        group => '',
        qtype => '',
        pager => '<p>Page 1</p>',
        objects => [{
            safe_title => 'Field &amp; Flux', obj_url => '/?op=getobj&amp;id=5',
            type_label => 'Encyclopedia', created => '2026-09-20',
            modified => '2026-09-20', table => 'objects', unclassified => 1,
            has_messages => 1, has_corrections => 1, edithref => '/?op=edit&amp;id=5',
            aclhref => '/?op=acledit&amp;id=5', historyhref => '/?op=vbrowser&amp;id=5',
            linkhref => '/?op=linkpolicy&amp;id=5', transferhref => '/?op=transfer&amp;id=5',
            abandonhref => '/?op=abandon&amp;id=5&amp;ask=yes',
            deletehref => '/?op=delobj&amp;id=5&amp;ask=yes',
        }],
    }, \$rendered), 'beta template renders with a representative article');
    like($rendered, qr/Field &amp; Flux/, 'rendered title retains escaped markup');
    like($rendered, qr/Needs classification.*Corrections.*New messages/s,
        'rendered article includes status flags');
	unlike($rendered, qr/Open classic My Articles|>BETA</, 'rendered view has no beta or classic escape hatch');
	like($rendered, qr/Showing 1-1 of 1 article/, 'rendered view describes the visible range');
}

done_testing();
