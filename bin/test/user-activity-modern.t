#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
open my $in, '<', "$root/lib/Noosphere/Users.pm" or die $!;
my $source = do { local $/; <$in> };
my ($show_activity) = $source =~ /(sub showUserActivity \{.*?^\})/ms;
ok($show_activity, 'user activity handler is available');

{
    package Noosphere;
    our $dbh;
    our $dbms = 'MariaDB';
    our $query_ok = 1;
    our $query;
    our @rows;
    sub getConfig {
        return $dbms if $_[0] eq 'dbms';
        return 50 if $_[0] eq 'useractivity_max';
        return 'https://physicslibrary.org' if $_[0] eq 'main_url';
        return 'stemplates';
    }
    sub dbSelect { $query = $_[1]; return ($query_ok, 'activity rows') }
    sub dbGetRows { return @rows }
    sub qhtmlescape {
        my $text = shift;
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        return $text;
    }
    sub paddingTable { return $_[0] }
    sub loginExpired { return 'login expired' }
    sub errorMessage { return $_[0] }
}

{
    package Template;
    our $name;
    our $vars;
    sub new { return bless {}, shift }
    sub process {
        my ($self, $template, $data, $output) = @_;
        $name = $template;
        $vars = $data;
        $$output = 'rendered activity';
        return 1;
    }
}

my $loaded = eval "package Noosphere; our \$dbh; $show_activity; 1";
ok($loaded, 'activity handler compiles with the site globals') or diag($@);
is(Noosphere::showUserActivity({}, { uid => -1 }), 'login expired', 'anonymous visitors still need to log in');

@Noosphere::rows = ({ uid => 7, username => '<Alice>&', last => '2026-10-02 04:05:00', idle => 3661.9 });
is(Noosphere::showUserActivity({}, { uid => 5 }), 'rendered activity', 'member activity renders through the template');
is($Template::name, 'useractivity.tt', 'activity uses its dedicated template');
is($Noosphere::query->{LIMIT}, 50, 'existing activity limit is preserved');
like($Noosphere::query->{WHERE}, qr/uid != 5/, 'current user is excluded');
is($Template::vars->{members}[0]{username}, '&lt;Alice&gt;&amp;', 'username is escaped');
is($Template::vars->{members}[0]{profile_url}, 'https://physicslibrary.org/?op=getuser&amp;id=7', 'member profile is linked');
is($Template::vars->{members}[0]{idle}, '1h 1m 1s', 'idle seconds are formatted for display');
is($Template::vars->{members}[0]{last}, '2026-10-02 04:05:00', 'last request timestamp is preserved');

$Noosphere::dbms = 'pg';
Noosphere::showUserActivity({}, { uid => 5 });
like($Noosphere::query->{WHAT}, qr/EXTRACT\(EPOCH FROM/, 'PostgreSQL returns numeric idle seconds');

@Noosphere::rows = ();
Noosphere::showUserActivity({}, { uid => 5 });
is(scalar @{$Template::vars->{members}}, 0, 'empty activity list reaches the template');

$Noosphere::query_ok = 0;
is(Noosphere::showUserActivity({}, { uid => 5 }), 'Could not load user activity.', 'query failure has a readable error');

open my $template_in, '<', "$root/stemplates/useractivity.tt" or die $!;
my $template = do { local $/; <$template_in> };
like($template, qr/INCLUDE modernboxheader\.tt/, 'activity page uses the shared box heading');
like($template, qr/<th scope="col">Member<\/th>/, 'table has column headings');

done_testing();
