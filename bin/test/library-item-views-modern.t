#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use URI;
use URI::Escape qw(uri_escape_utf8);
use HTML::Parser;
use Noosphere::EntryInteractions;
use Noosphere::RequestForm;
use Noosphere::TemplateNS;

our ($dbh, $NoosphereCanonical, $NoosphereTitle);
my $root = "$FindBin::Bin/../..";
my %config = (
    template_path => "$root/stemplates", stemplate_path => "$root/stemplates",
    main_url => 'https://physicslibrary.org', siteaddrs => {}, template_cmd_prefix => 'NS',
    en_tbl => 'objects', cor_tbl => 'corrections', user_tbl => 'users',
    papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec',
    news_tbl => 'news', collab_tbl => 'collab', forum_tbl => 'forums',
    polls_tbl => 'polls', req_tbl => 'requests', access_admin => 100,
);
my $record;
our $read_allowed = 1;
my (@queries, @files, @classes, @watches, @hits);
our ($file_html, $class_html);
sub getConfig { $config{$_[0]} }
sub readFile { open my $in, '<', $_[0] or die $!; return do {local $/; <$in>}; }
sub getAddr { 'feedback@example.invalid' }
sub hasPermissionTo {
    my ($table, $id, $user, $mode) = @_;
    return $read_allowed if $mode eq 'read';
    return $user->{uid} == 5 || $user->{uid} == 6 if $mode eq 'write';
    return $user->{uid} == 6 if $mode eq 'acl';
    return 0;
}
sub dbSelect { push @queries, $_[1]; return (1, bless {}, 'LibraryItemRows'); }
sub lookupfield { 'Uploader <Editor> & Team' }
sub nb { defined($_[0]) && $_[0] =~ /\S/ }
sub TeXtoUTF8 { $_[0] }
sub errorMessage { $_[0] }
sub changeWatch { push @watches, [@_] }
sub hitObject { push @hits, [@_] }
sub getWatchWidget { '' }
sub get_lastseen { die 'Library views must not start loading discussion'; }
sub getfilelist { push @files, [@_]; return $file_html; }
sub printclass { push @classes, [@_]; return $class_html; }
sub adminBox { '<div class="legacy-admin">'.$_[1].'</div>' }
{
    package LibraryItemRows;
    sub rows { 1 }
    sub fetchrow_hashref { return {%$record}; }
}
for my $spec (
    ['GetObj', qw(getEncyclopediaCanonicalURL getObjTableIsAllowed getObjIdIsValid getObj getOwnerControls getAuthorControls)],
    ['GenericObject', qw(renderGeneric getGenericAdmin getIsA)],
) {
    my ($module, @names) = @$spec;
    my $source = readFile("$root/lib/Noosphere/$module.pm");
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body;
        die $@ if $@;
    }
}
my $new = Template->can('new');
{
    no warnings qw(redefine once);
    *Template::new = sub { $new->($_[0], {INCLUDE_PATH => "$root/stemplates"}) };
}
sub user {
    my ($uid, $access) = @_;
    return {uid => $uid, data => {access => $access || 0}};
}
sub page {
    my ($table, $user, $params) = @_;
    @queries = (); @files = (); @classes = (); @watches = (); @hits = ();
    return getObj({op => 'getobj', from => $table, id => $record->{uid}, %{$params || {}}}, $user);
}
sub links {
    my @links;
    HTML::Parser->new(start_h => [sub {
        my ($tag, $attrs) = @_;
        push @links, URI->new($attrs->{href}) if $tag eq 'a' && defined $attrs->{href};
    }, 'tagname, attr'])->parse($_[0]);
    return @links;
}
sub query { return {$_[0]->query_form}; }
my @fixtures;
for my $case (['books', 406, 'Book'], ['papers', 142, 'Paper'], ['lec', 258, 'Lecture']) {
    my ($table, $id, $type) = @$case;
    $record = {
        uid => $id, userid => 2, title => 'A <Quantum> & Classical Resource',
        authors => 'Author <One> & Author Two', comments => "Original comments\nSecond line",
        data => "An abstract with <script>alert(1)</script> & physics.\nA second paragraph.",
        rights => 'Creative Commons <Attribution> & original wording',
        isbn => $table eq 'books' ? '978-1-23456-789-0' : '',
        urls => " https://example.invalid/paper?q=a&lang=en \r\n\nhttp://example.invalid/notes\nftp://example.invalid/source\njavascript:alert(1)\n<script>bad</script>",
    };
    $file_html = '<table><tr><td><a href="https://aux.physicslibrary.org/files/'.$table.'/'.$id.'/Calculus%20of%20variations%20and%20its%20applications%20Graves%20-%20NoRenewelPublicDomain.pdf">Calculus of variations and its applications Graves - NoRenewelPublicDomain.pdf</a></td><td>&nbsp;&nbsp;</td><td>Full text</td></tr></table>';
    $class_html = '<table><tr><td>Physics Classification:</td><td><a href="/?op=pacsbrowse&amp;from='.$table.'&amp;id=02.30.Xx">02.30.Xx</a> (Calculus of variations)</td></tr></table>';
    my $guest = page($table, user(-1));
    like($guest, qr/<header class="pl-modern-box-header"><h1>\Q$type\E: A &lt;Quantum&gt; &amp; Classical Resource<\/h1>/, "$table uses the compact escaped title header");
    is(() = $guest =~ /<h1>/g, 1, "$table does not repeat the title");
    for my $label ('Authors:', 'Uploaded by:', 'Comments:', 'Abstract:', 'Rights:', 'Download:', 'Links:', 'Classification:') {
        like($guest, qr/<dt>\Q$label\E<\/dt>/, "$table retains $label");
    }
    like($guest, qr/Author &lt;One&gt; &amp; Author Two/, "$table escapes author text");
    like($guest, qr/&lt;script&gt;alert\(1\)&lt;\/script&gt; &amp; physics/, "$table escapes abstract text");
    like($guest, qr/Original comments\nSecond line/, "$table retains comments and newlines");
    like($guest, qr/Creative Commons &lt;Attribution&gt; &amp; original wording/, "$table retains and escapes rights");
    like($guest, qr/Uploader &lt;Editor&gt; &amp; Team/, "$table escapes uploader names");
    like($guest, qr/class="pl-library-item-downloads">\Q$file_html\E/, "$table keeps downloads and descriptions in a shaded area");
    like($guest, qr/\Q$class_html\E/, "$table keeps classification content intact");
    is(scalar @queries, 1, "$table adds no extra object or discussion queries");
    is_deeply(\@files, [[$table, $id]], "$table fetches the resolved object's filebox once");
    is_deeply(\@classes, [[$table, $id, '-1']], "$table fetches classification once");
    is($NoosphereCanonical, '', "$table does not inherit an encyclopedia canonical URL");
    is_deeply($hits[0], [$id, $table, 'hits'], "$table still records a visit");
    is($watches[0][2], $table, "$table preserves watch handling context");
    my @links = links($guest);
    my ($profile) = grep { (query($_)->{op} || '') eq 'getuser' } @links;
    is(query($profile)->{id}, 2, "$table keeps the uploader's profile link");
    my ($browse) = grep { (query($_)->{op} || '') eq 'browse' } @links;
    is(query($browse)->{from}, $table, "$table links back to its own browse section");
    my @external = grep { $_->can('host') && ($_->host || '') eq 'example.invalid' } @links;
    is(scalar @external, 3, "$table links each supported URL on its own line");
    is("$external[0]", 'https://example.invalid/paper?q=a&lang=en', "$table preserves external query parameters");
    unlike($guest, qr/href="javascript:|<script>|<center>|<\/xsl:if>/, "$table has no executable links or malformed legacy markup");
    like($guest, qr/javascript:alert\(1\).*&lt;script&gt;bad&lt;\/script&gt;/s, "$table retains unsupported URL text safely");
    unlike($guest, qr/<h2>(?:Admin|Owner|Author) Controls/, "$table readers do not see privileged controls");
    if ($table eq 'books') {
        like($guest, qr/<dt>ISBN #:<\/dt><dd>978-1-23456-789-0<\/dd>/, 'book ISBN is now actually displayed');
    } else {
        unlike($guest, qr/<dt>ISBN/, "$table does not show an empty ISBN row");
    }
    my $admin = page($table, user(1, 100));
    like($admin, qr/pl-entry-section-admin.*<h2>Admin Controls/s, "$table admin controls keep the red header");
    for my $op (qw(adminedit adminclassify delobj)) {
        my ($action) = grep { (query($_)->{op} || '') eq $op } links($admin);
        ok($action, "$table retains admin $op action");
        is_deeply(query($action), {op => $op, from => $table, id => $id, ($op eq 'delobj' ? (ask => 'yes') : ())}, "$table admin $op keeps its target and confirmation");
    }
    unlike(page($table, user(1,99)), qr/<h2>Admin Controls/, "$table respects the admin threshold");
    my $owner = page($table, user(2));
    like($owner, qr/<h2>Owner Controls/, "$table uses modern owner controls");
    for my $op (qw(edit rerender linkpolicy acledit creategroup transfer delobj abandon)) {
        my ($action) = grep { (query($_)->{op} || '') eq $op } links($owner);
        ok($action, "$table keeps owner $op action");
        is(query($action)->{from}, $table, "$table owner $op retains its table");
        is(query($action)->{id}, $id, "$table owner $op retains its identifier");
    }
    like(page($table, user(2,100)), qr/<h2>Admin Controls.*<h2>Owner Controls/s, "$table administrators who own an item keep both controls");
    for my $uid (5, 6) {
        my $writer = page($table, user($uid));
        like($writer, qr/<h2>Author Controls/, "$table permitted writer $uid receives author controls");
        my @acl = grep { (query($_)->{op} || '') eq 'acledit' } links($writer);
        is(scalar @acl, $uid == 6 ? 1 : 0, "$table writer ACL visibility respects its separate permission");
    }
    like(getGenericAdmin({from => $table}, user(1,100), $record), qr/legacy-admin/, "$table legacy admin callers remain compatible");
    push @fixtures, [$table, $guest], ["$table-owner", $owner];
    {
        local $record->{urls} = '  ';
        local $record->{authors} = '';
        local $record->{comments} = '';
        local $record->{rights} = '';
        local $record->{isbn} = '';
        local $record->{userid} = -1;
        local $file_html = '';
        local $class_html = '';
        my $empty = page($table, user(3));
        unlike($empty, qr/<dt>(?:Authors|Comments|Download|Links|Classification|ISBN)/, "$table hides absent optional metadata");
        like($empty, qr/\[none given\] \(proceed with caution!\)/, "$table keeps the missing-rights warning");
        unlike($empty, qr/op=getuser/, "$table does not link an unowned item's uploader");
        push @fixtures, ["$table-empty", $empty];
    }
    {
        local $read_allowed = 0;
        like(page($table, user(-1)), qr/don't have permission/, "$table still enforces read permission");
        is(scalar @files, 0, "$table denied readers cannot enumerate downloads");
    }
    {
        local $SIG{__WARN__} = sub { die $_[0] unless $_[0] =~ /isn't numeric/ };
        like(page($table, user(-1), {id => '1 OR 1=1'}), qr/Invalid object id/, "$table rejects invalid identifiers before loading files");
        is(scalar @files, 0, "$table invalid identifiers cannot enumerate downloads");
    }
}
if (my $dir = $ENV{LIBRARY_ITEM_TEST_DIR}) {
    my $tt = Template->new;
    my ($sidebar, $menu) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>',
        features => $menu,
    }, \$sidebar) or die $tt->error;
    for my $case (@fixtures) {
        my $html = '';
        $tt->process('view.tt', {
            title => 'Library detail preview', site_name => 'Physics Library', sidebar => $sidebar,
            content => $case->[1],
            header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>',
        }, \$html) or die $tt->error;
        open my $out, '>', "$dir/$case->[0].html" or die $!;
        print {$out} $html;
        close $out;
    }
}
done_testing();
