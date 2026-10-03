#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
open my $in, '<', "$root/lib/Noosphere/Users.pm" or die $!;
my $source = do { local $/; <$in> };
my ($user_list) = $source =~ /(sub userList \{.*?^\})/ms;
ok($user_list, 'user list handler is available');

{
    package UserListStatement;
    sub new { return bless {}, shift }
    sub rows { return 3 }
    sub finish { return 1 }
}

{
    package Noosphere;
    our $dbh;
    our $dbms = 'MariaDB';
    our $query_ok = 1;
    our $count_ok = 1;
    our $query;
    our $pager_params;
    our @rows;
    sub getConfig {
        return $dbms if $_[0] eq 'dbms';
        return 'https://physicslibrary.org' if $_[0] eq 'main_url';
        return 20 if $_[0] eq 'listings_page';
        return 'stemplates';
    }
    sub dbSelect {
        $query = $_[1];
        return ($count_ok, UserListStatement->new) if $query->{WHAT} eq 'uid,username,joined,score';
        return ($query_ok, UserListStatement->new);
    }
    sub dbGetRows { return @rows }
    sub urlunescape { return $_[0] }
    sub ymd { return $_[0] }
    sub qhtmlescape {
        my $text = shift;
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        return $text;
    }
    sub getPager {
        $pager_params = { %{$_[0]} };
        return '3 items';
    }
    sub paddingTable { return $_[0] }
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
        $$output = 'rendered user list';
        return 1;
    }
}

my $loaded = eval "package Noosphere; our \$dbh; $user_list; 1";
ok($loaded, 'user list handler compiles with site globals') or diag($@);

@Noosphere::rows = ({ uid => 7, username => '<Alice>&', score => 3,
    entries => 2, productivity => 1.25, consistency => 1.5, joined => '2026-01-02' });
my $prefs = { prefs => { pagelength => 20 } };
is(Noosphere::userList({ offset => 0 }, $prefs), 'rendered user list', 'list renders through the template');
is($Template::name, 'userlist.tt', 'user list uses its dedicated template');
is($Noosphere::query->{LIMIT}, 20, 'page length is preserved');
is($Noosphere::query->{'ORDER BY'}, 'uid ASC', 'default user order is preserved');
is($Template::vars->{members}[0]{username}, '&lt;Alice&gt;&amp;', 'username is escaped');
is($Template::vars->{members}[0]{profile_url}, 'https://physicslibrary.org/?op=getuser&amp;id=7', 'profile link is preserved');
is($Template::vars->{members}[0]{productivity}, '1.25', 'productivity is formatted');
is($Template::vars->{total}, 3, 'total is counted');
is($Template::vars->{pager}, '3 people', 'pager names people');
is(scalar @{$Template::vars->{columns}}, 7, 'all sortable columns are present');

Noosphere::userList({ total => 3, sortby => 'score', sortidx => 1 }, $prefs);
is($Noosphere::query->{'ORDER BY'}, 'score ASC', 'score sort can be reversed');
is($Template::vars->{columns}[2]{direction}, 'ascending', 'active direction is available to the template');
like($Template::vars->{columns}[2]{url}, qr/sortidx=0$/, 'active heading toggles the direction');

Noosphere::userList({ total => 3, sortby => 'not-a-column', sortidx => 'oops', offset => '1;DROP' }, $prefs);
is($Noosphere::query->{'ORDER BY'}, 'uid ASC', 'unknown sort key falls back to user id');
is($Noosphere::query->{OFFSET}, 0, 'invalid offset cannot enter SQL');
is($Noosphere::pager_params->{sortby}, 'uid', 'pager receives the validated sort key');
is($Noosphere::pager_params->{offset}, 0, 'pager receives the validated offset');

@Noosphere::rows = ();
Noosphere::userList({ total => 0 }, $prefs);
is(scalar @{$Template::vars->{members}}, 0, 'empty member list reaches the template');

$Noosphere::query_ok = 0;
is(Noosphere::userList({ total => 3 }, $prefs), 'Could not load user list.', 'query failure has a readable error');
$Noosphere::count_ok = 0;
is(Noosphere::userList({}, $prefs), 'Could not load user list.', 'count failure has a readable error');

open my $template_in, '<', "$root/stemplates/userlist.tt" or die $!;
my $template = do { local $/; <$template_in> };
like($template, qr/INCLUDE modernboxheader\.tt/, 'list uses the shared box heading');
like($template, qr/aria-sort=/, 'table exposes sort direction');
like($template, qr/About the scores/, 'score definitions remain available');

done_testing();
