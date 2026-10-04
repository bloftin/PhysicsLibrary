#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use URI;
use HTML::Parser;
use Noosphere::RequestForm;

our $dbh;
my $root = "$FindBin::Bin/../..";
my %config = (template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    projname => 'Physics Library', message_maxcols => 72);
our $record = {uid => 1153, userfrom => 2, userto => 1, fromname => 'Demo <Sender>',
    toname => 'Demo <Recipient>', sent => '2026-10-04 12:30:00', subject => 'Private <subject> & "question"',
    body => "First line\n<script>not executable</script>\n  Indented line", _read => undef};
our @rows = ({%$record, username => 'Demo <Sender>'},
    {%$record, uid => 1154, subject => '', _read => 1, username => 'Demo <Recipient>'});
our ($success, $missing) = (1, 0);
my (@queries, @counts, @updates, @deletes, @inserts, @spelling, @pagers);
sub getConfig { $config{$_[0]} }
sub errorMessage { $_[0] }
sub needAccount { 'Sign in required' }
sub nb { defined($_[0]) && length($_[0]) }
sub blank { !defined($_[0]) || $_[0] =~ /^\s*$/ }
sub ymd { substr($_[0], 0, 10) }
sub dbRowCount { push @counts, [@_]; return scalar @rows; }
sub dbSelect {
    my ($db, $query) = @_;
    push @queries, $query;
    return (0, undef) unless $success;
    my @result = $query->{FROM} eq 'mail,users' ? @rows : $missing ? () : ({%$record});
    return (1, bless {rows => \@result}, 'ModernMailRows');
}
sub dbGetRows { @{$_[0]->{rows}} }
sub dbUpdate { push @updates, $_[1]; return (1, bless {}, 'ModernMailRows'); }
sub dbDelete { push @deletes, $_[1]; return (1, bless {}, 'ModernMailRows'); }
sub getPager {
    push @pagers, [@_];
    return '<a href="/?op='.$_[0]->{op}.'&amp;offset=10">Next messages</a>';
}
sub user_registered { defined($_[0]) && ($_[0] eq 'Demo <Sender>' || $_[0] eq 'Demo <Recipient>') }
sub insertMail { push @inserts, {%{$_[0]}}; }
sub checkdoc { push @spelling, $_[0]; return '<span style="color:red">Misspelling</span>'; }
{
    package ModernMailRows;
    sub fetchrow_hashref { $_[0]->{rows}[0] }
    sub finish { }
}

# Exercise the real handlers and templates without a production database or mail transport.
for my $spec (
    ['Mail', qw(renderMailPage getMailRecord replyMail unsendMail getMail markMailRead mailBox sentMail oldMail mailFolder sendMailForm checkSendMail)],
    ['Messages', qw(getquoted wordsplit)],
) {
    my ($module, @names) = @$spec;
    open my $in, '<', "$root/lib/Noosphere/$module.pm" or die $!;
    my $source = do {local $/; <$in>};
    for my $name (@names) {
        my ($body) = $source =~ /(^sub \Q$name\E\b.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $body;
        eval $body;
        die $@ if $@;
    }
}
sub user {
    return {uid => $_[0], ticket => 'a' x 64, data => {active => 1}, prefs => {pagelength => 20}};
}
sub links {
    my @result;
    HTML::Parser->new(start_h => [sub {
        push @result, URI->new($_[1]->{href}) if $_[0] eq 'a' && defined $_[1]->{href};
    }, 'tagname, attr'])->parse($_[0]);
    return @result;
}
sub query { return {$_[0]->query_form}; }
sub action { return grep { (query($_)->{op} || '') eq $_[1] } links($_[0]); }
sub form_values {
    my %values;
    HTML::Parser->new(start_h => [sub {
        my ($tag, $attrs) = @_;
        $values{$attrs->{name}} = $attrs->{value} if $tag eq 'input' && defined $attrs->{name};
    }, 'tagname, attr'])->parse($_[0]);
    return \%values;
}

for my $handler (\&oldMail, \&sentMail, \&sendMailForm, \&replyMail, \&getMail, \&unsendMail) {
    like($handler->({id => 1153}, user(0)), qr/logged in|Sign in required/, 'mail route rejects anonymous users');
}
is(scalar @queries, 0, 'anonymous requests do not query private mail');
is(scalar @inserts, 0, 'anonymous requests do not send mail');

my %fixtures;
for my $spec (['oldmail', \&oldMail, 'userfrom', 'mail.userto=1 and _read=1', 'old'],
              ['sentmail', \&sentMail, 'userto', 'mail.userfrom=1', 'sent']) {
    my ($op, $handler, $party, $scope, $label) = @$spec;
    my $html = $fixtures{$op} = $handler->({op => $op, offset => 10}, user(1));
    is_deeply($counts[-1], ['mail', $scope], 'folder total stays scoped to current user');
    is($queries[-1]->{WHERE}, "users.uid=mail.$party and $scope", 'folder rows keep the correct participant join');
    is($queries[-1]->{LIMIT}, 10, 'folder page size stays half the preference');
    is($queries[-1]->{OFFSET}, 10, 'folder offset retained');
    is($queries[-1]->{'ORDER BY'}, 'sent', 'folder sort remains sent date');
    ok(exists $queries[-1]->{DESC}, 'folder remains newest first');
    is_deeply($pagers[-1]->[0], {op => $op, offset => 10, total => 2}, 'pager retains route, offset and total');
    is($pagers[-1]->[2], 2, 'pager scale retained');
    like($html, qr/2 $label messages/, 'folder count displayed');
    like($html, qr/Private &lt;subject&gt; &amp; &quot;question&quot;/, 'subject safely escaped');
    like($html, qr/Demo &lt;Sender&gt;/, 'username safely escaped');
    like($html, qr/2026-10-04/, 'filed date normalized');
    like($html, qr/\(No subject\)/, 'blank subjects retain a message link');
    like($html, qr/op=getmail&amp;id=1153/, 'message link preserved');
    is(scalar(() = $html =~ /Next messages/g), 2, 'pager appears above and below messages');
    like($html, qr/background: #003399/, 'shared compact blue header used');
    my $name = $op eq 'oldmail' ? 'Old mail' : 'Sent mail';
    like($html, qr/<strong aria-current="page">$name<\/strong>/, 'current folder distinguished from links');
    local @rows = ();
    my $empty = $handler->({}, user(1));
    $fixtures{"empty-$op"} = $empty;
    like($empty, qr/No $label mail\./, 'folder empty state preserved');
    local $success = 0;
    like($handler->({}, user(1)), qr/Query error/, 'folder query failure remains readable');
}
like($fixtures{sentmail}, qr/>Unread<\/span>.*>Read<\/span>/s, 'sent folder uses explicit read labels');
like($fixtures{sentmail}, qr/To <a.*op=getuser&amp;id=1/, 'sent folder links to recipients');
like($fixtures{oldmail}, qr/From <a.*op=getuser&amp;id=2/, 'old folder links to senders');

my $recipient = $fixtures{recipient} = getMail({id => 1153}, user(1));
like($queries[-1]->{WHERE}, qr/mail.uid=1153 and \(mail.userfrom=1 or mail.userto=1\)$/, 'message query restricts access to participants');
is_deeply($updates[-1], {WHAT => 'mail', SET => '_read=1', WHERE => 'uid=1153'}, 'recipient marks unread message read');
like($recipient, qr/Viewing Mail Message/, 'message uses modern view template');
like($recipient, qr/Demo &lt;Sender&gt;.*Demo &lt;Recipient&gt;/s, 'message participant metadata escaped');
like($recipient, qr/&lt;script&gt;not executable&lt;\/script&gt;/, 'message body remains plain escaped text');
unlike($recipient, qr/<script>|<table/, 'mail view does not interpret body HTML or use a legacy wrapper');
like($recipient, qr/First line\n.*\n  Indented line/, 'line breaks and indentation retained');
my ($reply_link) = action($recipient, 'replymail');
is_deeply(query($reply_link), {op => 'replymail', id => 1153, rsubject => $record->{subject}}, 'reply link safely encodes the full subject');
is(scalar(action($recipient, 'unsend')), 0, 'recipient cannot unsend mail');
my $read_count = scalar @updates;
my $sender = $fixtures{sender} = getMail({id => 1153}, user(2));
is(scalar @updates, $read_count, 'sender view does not mark mail read');
is(scalar(action($sender, 'replymail')), 0, 'sender does not get reply action');
my ($unsend_link) = action($sender, 'unsend');
is_deeply(query($unsend_link), {op => 'unsend', id => 1153}, 'unread outgoing mail retains unsend');
ok(requestFormNeedsProtection(query($unsend_link), 'GET'), 'unsend still goes through the existing protected confirmation flow');
{
    local $record->{_read} = 1;
    is(scalar(action(getMail({id => 1153}, user(2)), 'unsend')), 0, 'read outgoing mail cannot be unsent');
    getMail({id => 1153}, user(1));
    is(scalar @updates, $read_count, 'already-read recipient message is not updated again');
}
{
    local $record->{userfrom} = 1;
    my $self = getMail({id => 1153}, user(1));
    is(scalar(action($self, 'unsend')), 0, 'self-addressed mail does not show unsend');
    is(scalar(action($self, 'replymail')), 0, 'self-addressed mail does not show reply');
}
my $updates_before_denied = scalar @updates;
like(getMail({id => 1153}, user(3)), qr/cannot view mail/, 'unrelated signed-in viewer denied');
is(scalar @updates, $updates_before_denied, 'denied viewer cannot mark mail read');
for my $handler (\&getMail, \&replyMail, \&unsendMail) {
    for my $id (undef, '1153 OR 1=1', 'x', ['1153']) {
        my $before = scalar @queries;
        like($handler->({id => $id}, user(1)), qr/Missing id|Invalid message id/, 'mail routes reject missing or invalid identifiers');
        is(scalar @queries, $before, 'invalid identifier never reaches database');
    }
    local $missing = 1;
    like($handler->({id => 9999}, user(1)), qr/Message could not be found/, 'missing message is handled without dereferencing an empty row');
    local $success = 0;
    like($handler->({id => 1153}, user(1)), qr/Query error/, 'message lookup failure remains readable');
}

my $compose = $fixtures{compose} = sendMailForm({sendto => 'Demo <Recipient>'}, user(2));
my $values = form_values($compose);
is($values->{sendto}, 'Demo <Recipient>', 'compose landing preserves recipient prefill');
is($values->{subject}, '', 'compose landing starts with empty subject');
like($compose, qr/<form class="pl-mailbox-form" method="post" action="\/">/, 'compose submits to the existing POST endpoint');
is($values->{op}, 'sendmail', 'compose operation retained');
like($compose, qr/name="post" value="send"/, 'send button contract retained');
like($compose, qr/name="spell" value="spell"/, 'spell button contract retained');
for my $field (['To:', 'pl-mail-to'], ['Subject:', 'pl-mail-subject'], ['Message:', 'pl-mail-body']) {
    like($compose, qr/<label for="$field->[1]">$field->[0]<\/label>/, 'compose field has an accessible label');
}
my $invalid = $fixtures{invalid} = sendMailForm({post => 'send', sendto => 'Unknown <user>', subject => 'Draft & "subject"', body => "</textarea><script>bad</script>\nDraft"}, user(2));
like($invalid, qr/Need a registered Physics Library user/, 'invalid recipient reports existing validation error');
is(form_values($invalid)->{sendto}, 'Unknown <user>', 'validation retains recipient');
is(form_values($invalid)->{subject}, 'Draft & "subject"', 'validation retains subject');
like($invalid, qr/&lt;\/textarea&gt;&lt;script&gt;bad&lt;\/script&gt;\nDraft/, 'draft is retained without textarea injection');
is(scalar @inserts, 0, 'validation failure does not send');
my $blank = sendMailForm({post => 'send'}, user(2));
like($blank, qr/Need a user to send to!.*Need a subject!.*Need a message!/s, 'required-field errors retained');
my $spell = $fixtures{spell} = sendMailForm({spell => 'spell', sendto => 'Demo <Recipient>', subject => 'Draft', body => " > Quoted text\n  New text"}, user(2));
is($spelling[-1], 'New text', 'spell check retains stripping of quoted lines and leading space');
like($spell, qr/Spell check \(broken words in red, clickable\):.*<span style="color:red">Misspelling/s, 'spell output and explanation retained');
is(form_values($spell)->{subject}, 'Draft', 'spell action retains draft fields');
is(scalar @inserts, 0, 'spell check does not send');
my %submitted = (post => 'send', sendto => 'Demo <Recipient>', subject => 'Ready', body => 'Ready body');
my $sent = $fixtures{sent} = sendMailForm(\%submitted, user(2));
like($sent, qr/Mail Sent.*Your message was sent/s, 'successful send has modern confirmation and original wording');
is_deeply($inserts[-1], \%submitted, 'send passes unchanged values to existing delivery pipeline');
is(scalar @inserts, 1, 'send delivered exactly once');

my $reply = $fixtures{reply} = replyMail({id => 1153, rsubject => 'Forged subject'}, user(1));
is(form_values($reply)->{subject}, 'Re: '.$record->{subject}, 'reply prefix is derived from stored subject');
is(form_values($reply)->{sendto}, 'Demo <Sender>', 'reply recipient is derived from stored sender');
is(form_values($reply)->{original}, $record->{body}, 'reply original is safely encoded for form round-trip');
like($reply, qr/name="quote" value="quote"/, 'quote button contract retained');
like($reply, qr/Original Message:.*&lt;script&gt;not executable/s, 'original message display stays escaped');
{
    local $record->{subject} = 'rE: Already a reply';
    is(form_values(replyMail({id => 1153}, user(1)))->{subject}, $record->{subject}, 'reply prefix is not duplicated');
}
my $quoted = $fixtures{quoted} = replyMail({id => 1153, quote => 'quote', subject => 'Draft', body => 'My reply', original => 'Forged original'}, user(1));
like($quoted, qr/&gt; First line/, 'quote uses original stored message');
like($quoted, qr/My reply<\/textarea>/, 'quote retains the current reply draft');
unlike($quoted, qr/Forged original/, 'forged hidden original is not trusted');
my $reply_spell = replyMail({id => 1153, spell => 'spell', subject => 'Draft', body => 'Reply draft'}, user(1));
is($spelling[-1], 'Reply draft', 'reply supports spell check');
like($reply_spell, qr/Misspelling/, 'reply displays spell output');
my $reply_invalid = replyMail({id => 1153, post => 'send', subject => '', body => 'My draft'}, user(1));
like($reply_invalid, qr/Need a subject!/, 'reply validation error retained');
like($reply_invalid, qr/My draft<\/textarea>/, 'reply validation retains message');
my $replied = $fixtures{replied} = replyMail({id => 1153, post => 'send', subject => 'Reply', body => 'My reply', sendto => 'Unknown'}, user(1));
like($replied, qr/Reply Sent/, 'reply sends and displays modern confirmation');
is($inserts[-1]->{sendto}, 'Demo <Sender>', 'reply cannot be redirected through hidden sendto field');
my $insert_count = scalar @inserts;
like(replyMail({id => 1153, post => 'send', subject => 'Bad', body => 'Bad'}, user(3)), qr/cannot view mail/, 'nonparticipant cannot reply to private mail');
like(replyMail({id => 1153}, user(2)), qr/cannot reply to mail you sent/, 'sender cannot reply to own sent message');
is(scalar @inserts, $insert_count, 'denied replies never send');

like(unsendMail({id => 1153}, user(1)), qr/cannot unsend mail you did not send/, 'recipient cannot unsend');
{
    local $record->{_read} = 1;
    like(unsendMail({id => 1153}, user(2)), qr/cannot unsend mail that has been read/, 'read mail cannot be unsent');
}
is(scalar @deletes, 0, 'failed unsend attempts do not delete');
my $unsent = $fixtures{unsent} = unsendMail({id => 1153}, user(2));
like($unsent, qr/Mail Unsent.*Your message has been unsent/s, 'unsend completion uses modern header and original wording');
is_deeply($deletes[0], {FROM => 'mail', WHERE => 'uid=1153'}, 'authorized unsend retains deletion scope');

for my $html ($compose, $invalid, $spell, $reply, $quoted) {
    my $decorated = requestFormDecorate($html, user(1));
    my ($depth, $nested, $tokens) = (0, 0, 0);
    HTML::Parser->new(start_h => [sub {
        my ($tag, $attrs) = @_;
        $nested++ if $tag eq 'form' && $depth++;
        $tokens++ if $tag eq 'input' && ($attrs->{name} || '') eq '_form_token' && $depth;
    }, 'tagname, attr'], end_h => [sub {$depth-- if $_[0] eq 'form'}, 'tagname'])->parse($decorated);
    is($depth, 0, 'mail forms have closing tags');
    is($nested, 0, 'mail forms do not nest');
    is($tokens, 1, 'compose/reply form retains response-time CSRF protection');
}

if (my $dir = $ENV{MAIL_PAGES_TEST_DIR}) {
    my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
    my ($menu, $sidebar) = ('', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('sidebar.tt', {login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo editor</h2><div class="pl-sidebar-body">Mailbox</div></section>', features => $menu}, \$sidebar) or die $tt->error;
    {
        local $record = {%$record, subject => 'LongSubjectWord' x 18, body => ('LongMessageWord' x 35)."\nSecond line"};
        $fixtures{long} = getMail({id => 1153}, user(1));
        local @rows = ({%{$rows[0]}, subject => 'LongSubjectWord' x 18, username => 'LongSenderName' x 15});
        $fixtures{'long-folder'} = sentMail({}, user(1));
    }
    for my $name (sort keys %fixtures) {
        my $html = '';
        $tt->process('view.tt', {title => 'Mail preview', site_name => 'Physics Library', sidebar => $sidebar,
            content => $fixtures{$name}, header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$html) or die $tt->error;
        open my $out, '>', "$dir/$name.html" or die $!;
        print {$out} $html;
        close $out;
    }
}
done_testing();
