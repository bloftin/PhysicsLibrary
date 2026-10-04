#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
my $root = "$FindBin::Bin/../..";
open my $fh, '<', "$root/lib/Noosphere/Notices.pm" or die $!;
my $source = do { local $/; <$fh> };
my ($view) = $source =~ /(sub viewNotices \{.*?^\})/ms;
my ($format) = $source =~ /(sub formatNotice \{.*?^\})/ms;
my $tt = eval {
    require Template;
    require Template::Stash;
    Template->new({ INCLUDE_PATH => "$root/stemplates", STASH => Template::Stash->new() });
};
{
    package Noosphere;
    our ($dbh, @rows, @deleted, @defaults, @queries);
    sub getConfig { $_[0] eq 'main_url' ? '' : 'stemplates' }
    sub nb { defined $_[0] && length $_[0] }
    sub blank { !nb($_[0]) }
    sub tohtmlascii { my $s = $_[0] // ''; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; return $s }
    sub urlescape { $_[0] }
    sub lookupfield { 'Ben <test>' }
    sub dbSelect { push @queries, $_[1]; return (1, $_[1]{FROM}) }
    sub dbGetRows { $_[0] eq 'notices' ? @rows : ({ desttbl => 'objects', destid => 116, note => 'Context' }) }
    sub dbDelete { push @deleted, $_[1]{WHERE}; return (1, undef) }
    sub noticeActivateDefault { push @defaults, $_[1] }
    sub noticeActivateDefaults { push @defaults, 'all' }
    sub getNoticeIDHash { (7 => 1, 8 => 1) }
    sub getop { ('getobj', 'objects') }
    sub contextLink { '<a href="/?op=getobj&amp;id=116">Context</a>' }
}
{
    package NoticeTemplate;
    our $vars;
    sub process { my ($self, $name, $data, $out) = @_; $vars = $data; $$out = $name; return 1 }
}
ok(eval("package Noosphere; our \$dbh; $view\n$format\n1"), 'notice handlers compile') or diag($@);
my $row = { uid => 7, title => '<Notice>', created => '2026-10-03', userfrom => 1,
    data => '<message>', choice_title => 'Accept;Decline', choice_action => 'accept;decline', choice_default => 1 };
my $html = Noosphere::formatNotice($row);
like($html, qr/<article class="pl-notice">/, 'notice uses an unframed row');
like($html, qr/&lt;Notice&gt;/, 'title is escaped');
like($html, qr/Ben &lt;test&gt;/, 'sender is escaped');
like($html, qr/&lt;message&gt;/, 'body is escaped');
like($html, qr/name="sel_7"/, 'selection name is preserved');
like($html, qr/op=exercise_option.*delsel=1&sel_7=on&params=accept/, 'prompt action and deletion parameters are preserved');
like($html, qr/default choice.*'Decline'/, 'default-on-deletion remains visible');
like($html, qr/op=getobj/, 'context link is retained');
unlike($html, qr/<table|<tr|<td/, 'nested layout tables are removed');
my $vars;
{
    no warnings qw(redefine once);
    local *Template::new = sub { bless {}, 'NoticeTemplate' };
    @Noosphere::queries = ();
    @Noosphere::rows = ($row);
    is(Noosphere::viewNotices({}, {uid => 1}), 'notices.tt', 'dedicated template is used');
    is($NoticeTemplate::vars->{count}, 1, 'unread total is provided');
    like($Noosphere::queries[0]{WHERE}, qr/userid=1 and viewed=0/, 'inbox remains restricted to unread notices for this user');
    $vars = $NoticeTemplate::vars;
    Noosphere::viewNotices({delsel => 1, sel_7 => 'on'}, {uid => 1});
    is($Noosphere::deleted[-1], 'uid=7 and userid=1', 'selected deletion remains user-scoped');
    is($Noosphere::defaults[-1], 7, 'selected deletion activates its default');
    Noosphere::viewNotices({delunsel => 1, sel_7 => 'on'}, {uid => 1});
    is($Noosphere::deleted[-1], 'uid=8 and userid=1', 'unselected deletion preserves selected notices');
    Noosphere::viewNotices({delall => 1}, {uid => 1});
    is($Noosphere::defaults[-1], 'all', 'delete all still activates defaults');
    is($Noosphere::deleted[-1], 'userid=1', 'delete all remains user-scoped');
    @Noosphere::rows = ();
    Noosphere::viewNotices({return_title => '<Result>', return_message => '<a>Done</a>'}, {uid => 1});
    like($NoticeTemplate::vars->{message}, qr/&lt;Result&gt;.*<a>Done<\/a>/, 'result title is escaped and handler HTML is preserved');
    is($NoticeTemplate::vars->{count}, 0, 'empty inbox is passed to template');
}
SKIP: {
    skip 'Template Toolkit unavailable', 5 unless $tt;
    my $rendered = '';
    ok($tt->process('notices.tt', $vars, \$rendered), 'real template renders') or diag($tt->error);
    like($rendered, qr/background: #003399/, 'notices retain the original title-box blue');
    like($rendered, qr/name="delunsel"/, 'bulk deletion controls render');
    like($rendered, qr/&lt;Notice&gt;/, 'representative notice renders');
    $tt->process('notices.tt', {title => 'Your Notices', count => 0}, \$rendered);
    like($rendered, qr/No notices\./, 'empty state renders');
}
done_testing;
