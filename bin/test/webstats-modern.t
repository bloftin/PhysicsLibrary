#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Template;
use HTML::Parser;
use Noosphere::RequestForm;

my $root = "$FindBin::Bin/../..";
my %config = (template_path => "$root/stemplates", access_admin => 50);
my $denied = 0;
sub getConfig { $config{$_[0]} }
sub noAccess { $denied++; return 'Access denied'; }
sub read_file {
    open my $fh, '<', "$root/$_[0]" or die $!;
    return do { local $/; <$fh> };
}
my $source = read_file('lib/Noosphere/Admin.pm');
my ($handler) = $source =~ /(^sub webStats\b.*?)(?=^sub |\z)/ms;
ok($handler, 'web stats handler exists');
ok(eval("$handler\n1"), 'real handler compiles') or diag($@);
like($source, qr/^use Template;/m, 'Template Toolkit is explicitly loaded');

{
    no warnings qw(redefine once);
    local *Template::new = sub { die 'Denied requests must not render a report'; };
    for my $access (0, 10, 49) {
        is(webStats({}, {uid => 1, data => {access => $access}}), 'Access denied',
            "access $access is denied before template processing");
    }
}
is($denied, 3, 'existing admin access threshold is enforced');
my $url = 'https://aux.physicslibrary.org/stats/awstats.physicslibrary.org.html';
my $html = webStats({}, {uid => 1, data => {access => 50}});
like($html, qr/<header class="pl-modern-box-header"><h1>Web Statistics<\/h1>/,
    'admin receives the shared compact blue header');
like($html, qr/background: #003399/, 'header matches the sidebar blue');
unlike($handler, qr/paddingTable|clearBox/, 'legacy title wrapper and inset removed');
unlike($html, qr/height="900"|<table/, 'wrapper has no fixed-height legacy layout');
like($html, qr/height: clamp\(/, 'desktop report height adapts to available viewport');
like($html, qr/\@media \(max-width: 640px\)/, 'report has a small-screen layout');
like($html, qr/box-sizing: border-box.*width: 100%/,
    'frame border stays inside the content width');
my (@frames, @links);
HTML::Parser->new(start_h => [sub {
    push @frames, $_[1] if $_[0] eq 'iframe';
    push @links, $_[1] if $_[0] eq 'a';
}, 'tagname, attr'])->parse($html);
is(scalar @frames, 1, 'one complete AWStats report is embedded');
is($frames[0]{src}, $url, 'existing report URL preserved');
is($frames[0]{title}, 'PhysicsLibrary web stats', 'frame has an accessible title');
ok(!exists $frames[0]{sandbox}, 'existing report navigation is not restricted');
is($links[0]{href}, $url, 'external fallback opens the same complete report');
is($links[0]{target}, '_blank', 'separate-page link opens a new tab');
is($links[0]{rel}, 'noopener', 'new tab cannot control the admin page');
like($html, qr/Open web stats in a separate page/, 'existing fallback wording retained');
is(webStats({url => 'https://example.invalid/'}, {data => {access => 99}}), $html,
    'higher-access admin allowed and request cannot replace report URL');
unlike($handler, qr/dbSelect|spawn_proc_prog|HTTP::|system\s*\(/,
    'viewing stats introduces no database, report-generation, or network jobs');

my $tt = Template->new({INCLUDE_PATH => "$root/stemplates"});
my $escaped = '';
ok($tt->process('webstats.tt', {stats_url => 'https://example.invalid/?a="<&b=1'}, \$escaped),
    'dedicated template renders') or diag($tt->error);
like($escaped, qr/a=&quot;&lt;&amp;b=1/, 'report URL is escaped in both attributes');
my $dispatch = read_file('lib/Noosphere/Dispatch.pm');
like($dispatch, qr/'webstats'\s*=>\s*\\&webStats/, 'existing handler route retained');
my ($non_template) = $dispatch =~ /%NONTEMPLATE\s*=\s*\((.*?)\);/s;
unlike($non_template, qr/'webstats'/, 'web stats keeps the main site shell and sidebar');
ok(grep($_ eq 'webstats', requestFormReadRoutes()), 'stats navigation remains read-only');
like(read_file('stemplates/adminmenu.tt'), qr/op=webstats/, 'admin menu entry retained');

if (my $dir = $ENV{WEBSTATS_TEST_DIR}) {
    my ($sidebar, $menu, $admin) = ('', '', '');
    $tt->process('mainmenu.tt', {}, \$menu) or die $tt->error;
    $tt->process('adminmenu.tt', {}, \$admin) or die $tt->error;
    $tt->process('sidebar.tt', {features => $menu, adminmenu => $admin,
        login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo admin</h2><div class="pl-sidebar-body"><a href="#">My Settings</a></div></section>'}, \$sidebar) or die $tt->error;
    my $page = '';
    $tt->process('view.tt', {title => 'Web Statistics', site_name => 'Physics Library',
        content => $html, sidebar => $sidebar,
        header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$page) or die $tt->error;
    open my $out, '>', "$dir/webstats.html" or die $!;
    print {$out} $page; close $out;
}

done_testing();
