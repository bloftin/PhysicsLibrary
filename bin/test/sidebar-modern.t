#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RequestForm;
my $root = "$FindBin::Bin/../..";
sub read_file {
    open my $in, '<', "$root/$_[0]" or die $!;
    return do {local $/; <$in>};
}
my $source = read_file('lib/Noosphere/Admin.pm');
my ($admin_handler) = $source =~ /(sub getAdminMenu \{.*?^\})/ms;
{
    package Noosphere;
    sub getConfig { return $_[0] eq 'access_admin' ? 100 : $_[0] eq 'main_url' ? 'https://example.invalid' : 'stemplates' }
}
{
    package SidebarTemplate;
    our ($name, $vars);
    sub process { my ($self,$name,$vars,$out)=@_; $SidebarTemplate::name=$name; $SidebarTemplate::vars=$vars; $$out='admin menu'; return 1 }
}
ok(eval("package Noosphere; $admin_handler\n1"), 'admin menu handler compiles') or diag($@);
{
    no warnings qw(redefine once);
    local *Template::new = sub {bless {}, 'SidebarTemplate'};
    is(Noosphere::getAdminMenu(undef), '', 'anonymous users have no admin menu');
    is(Noosphere::getAdminMenu(99), '', 'members below admin threshold have no admin menu');
    is(Noosphere::getAdminMenu(100), 'admin menu', 'administrator receives menu');
    is($SidebarTemplate::name, 'adminmenu.tt', 'admin menu uses scoped template');
}
for my $file (qw(sidebar loggedin login mainmenu adminmenu)) {
    unlike(read_file("stemplates/$file.tt"), qr/<table|<tr|<td|<font|<center/i, "$file removes legacy table and font wrappers");
}
my $tt = eval {
    require Template;
    require Template::Stash;
    Template->new({INCLUDE_PATH=>"$root/stemplates", STASH=>Template::Stash->new()});
};
subtest 'rendered sidebar' => sub {
    plan skip_all => 'Template Toolkit unavailable' unless $tt;
    my ($account, $menu, $admin, $sidebar, $anonymous);
    ok($tt->process('loggedin.tt', {username=>'<Ben>',mail=>2,notices=>3,corrections=>1}, \$account), 'account menu renders');
    like($account, qr/&lt;Ben&gt;/, 'username is escaped');
    for my $op (qw(logout settings collab edituserobjs editcors mailbox notices useractivity userlist sysstats adden)) {
        like($account, qr/op=$op(?:[";&])/, "account route $op is preserved");
    }
    for my $table (qw(papers books lec)) {
        like($account, qr/op=addobj;to=$table/, "$table creation route preserved");
    }
    unlike($account, qr/op=unpublished/, 'editor controls hidden by default');
    my $editor;
    $tt->process('loggedin.tt', {username=>'Editor',editor=>1}, \$editor);
    like($editor, qr/op=unpublished.*op=deleted/s, 'existing editor conditional retained');
    like($account, qr/Mailbox.*\(2\)/, 'unread mail count visible');
    like($account, qr/Notices.*\(3\)/, 'notice count visible');
    ok($tt->process('mainmenu.tt', {requests=>'(43)',orphans=>'(1)',corrections=>'(18)'}, \$menu), 'main menu renders');
    for my $op (qw(reqlist orphanage unclassified unproven globalcors viewpolls forums feedback license about snapshots)) {
        like($menu, qr/op=$op"/, "main menu route $op preserved");
    }
    like($menu, qr{/browse/categories/}, 'classification link retained');
    like($menu, qr{https://github.com/bloftin/PhysicsLibrary/issues}, 'bug report link retained');
    like($menu, qr{href="/\?op=snapshots"}, 'snapshot link stays in the site layout');
    like($menu, qr/Requests.*\(43\)/, 'main menu counts visible');
    ok($tt->process('adminmenu.tt', {main_url=>''}, \$admin), 'admin template renders');
    for my $op (qw(postnews newpoll adminstats dbadmin cachecont blacklist webstats)) {
        like($admin, qr/op=$op"/, "admin route $op preserved");
    }
    ok($tt->process('sidebar.tt', {login=>$account,features=>$menu,admin=>$admin}, \$sidebar), 'complete sidebar renders');
    like($sidebar, qr/<aside class="pl-sidebar"/, 'sidebar has navigation landmark');
    unlike($sidebar, qr/<tr|<td|<table/i, 'complete sidebar has no layout tables');
    ok($tt->process('login.tt', {Error=>'<Invalid>'}, \$anonymous), 'anonymous login renders');
    like($anonymous, qr/&lt;Invalid&gt;/, 'login error escaped');
    like($anonymous, qr/form method="post" action="\/"/, 'login retains local POST');
    like($anonymous, qr/name="user".*name="passwd".*name="url".*name="op" value="login"/s, 'login field names retained');
    like($anonymous, qr/op=newuser.*op=pwchangereq/s, 'signup and password recovery retained');
    my $user={uid=>1,ticket=>'test-session'};
    my $decorated=Noosphere::requestFormDecorate($sidebar, $user);
    like($decorated, qr/href="\/\?op=logout"/, 'form decoration preserves the existing logout route');
};
done_testing;
