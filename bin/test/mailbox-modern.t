#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
my $root = "$FindBin::Bin/../..";
open my $fh, '<', "$root/lib/Noosphere/Mail.pm" or die $!;
my $source = do { local $/; <$fh> };
my ($handler) = $source =~ /(sub mailBox \{.*?^\})/ms;
my $tt = eval {
    require Template;
    require Template::Stash;
    Template->new({ INCLUDE_PATH => "$root/stemplates", STASH => Template::Stash->new() });
};
{
    package Noosphere;
    our ($dbh, @queries, @rows);
    our $success = 1;
    sub getConfig { $_[0] eq 'main_url' ? '' : $_[0] eq 'projname' ? 'Physics Library' : 'stemplates' }
    sub errorMessage { $_[0] }
    sub dbSelect { push @queries, $_[1]; return ($success, undef) }
    sub dbGetRows { @rows }
    sub ymd { substr($_[0], 0, 10) }
}
{
    package MailboxTemplate;
    our ($vars, $name);
    sub process { my ($self, $template, $data, $out) = @_; $vars = $data; $name = $template; $$out = 'rendered mailbox'; return 1 }
}
ok(eval("package Noosphere; our \$dbh; $handler\n1"), 'mailbox handler compiles') or diag($@);
my $vars;
{
    no warnings qw(redefine once);
    local *Template::new = sub { bless {}, 'MailboxTemplate' };
    is(Noosphere::mailBox({}, {uid => 0}), 'Must be logged in to use mail', 'anonymous users are rejected');
    is(scalar @Noosphere::queries, 0, 'anonymous requests do not query mail');
    @Noosphere::rows = ({uid => 7, userfrom => 2, subject => '<Private & subject>', username => '<Ben>', sent => '2026-10-03 12:30:00'},
        {uid => 8, userfrom => 2, subject => '', username => 'Ben', sent => '2026-10-02 12:00:00'});
    is(Noosphere::mailBox({}, {uid => 1}), 'rendered mailbox', 'mailbox renders');
    is($MailboxTemplate::name, 'mailbox.tt', 'dedicated template is used');
    is($Noosphere::queries[-1]{WHERE}, 'users.uid=mail.userfrom and mail.userto=1 and _read is null', 'unread mail stays scoped to the recipient');
    is($Noosphere::queries[-1]{'ORDER BY'}, 'sent', 'sent-date ordering is retained');
    ok(exists $Noosphere::queries[-1]{DESC}, 'newest messages stay first');
    is($MailboxTemplate::vars->{count}, 2, 'unread count is accurate');
    is($MailboxTemplate::vars->{rows}[0]{date}, '2026-10-03', 'display date is normalized');
    $vars = $MailboxTemplate::vars;
    @Noosphere::rows = ();
    Noosphere::mailBox({}, {uid => 1});
    is($MailboxTemplate::vars->{count}, 0, 'empty inbox is supported');
    $Noosphere::success = 0;
    is(Noosphere::mailBox({}, {uid => 1}), 'Query error, contact admin.', 'query failures retain the error response');
}
SKIP: {
    skip 'Template Toolkit unavailable', 10 unless $tt;
    my $html = '';
    ok($tt->process('mailbox.tt', $vars, \$html), 'real template renders') or diag($tt->error);
    like($html, qr/&lt;Private &amp; subject&gt;/, 'subject is escaped');
    like($html, qr/&lt;Ben&gt;/, 'sender is escaped');
    like($html, qr/op=getmail&amp;id=7/, 'message link is retained');
    like($html, qr/op=getuser&amp;id=2/, 'sender profile link is retained');
    like($html, qr/\(No subject\)/, 'blank subjects remain clickable');
    like($html, qr/background: #003399/, 'header uses original blue');
    like($html, qr/op=oldmail.*op=sentmail.*op=sendmail/s, 'all mailbox navigation is retained');
    ok($tt->process('mailbox.tt', {title => 'Mail Box', count => 0}, \$html), 'empty template renders');
    like($html, qr/No new mail\./, 'empty state is visible');
}
done_testing;
