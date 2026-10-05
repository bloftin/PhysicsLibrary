#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Noosphere::RequestForm;

{
    package Noosphere;
    sub getConfig { return 'https://example.invalid' if $_[0] eq 'main_url'; }
}
my $token = 'a' x 64;
my $page = Noosphere::requestFormConfirmation({op => 'updatereq', request => 90}, $token);
like($page, qr/<header class="pl-confirm-action__header"><h1 id="pl-confirm-action-title">Confirm Action<\/h1><\/header>/,
    'confirmation has a single blue-box page heading');
like($page, qr/<\/header><section class="pl-confirm-action" aria-labelledby="pl-confirm-action-title">/,
    'header precedes the existing review panel and labels it');
like($page, qr/\.pl-confirm-action__header\{background:#003399;border-bottom:1px solid #002266;/,
    'header matches the sidebar and modern page-header blue');
like($page, qr/box-sizing:border-box;color:#fff;margin:0;padding:\.15rem \.5rem/,
    'header uses compact padding with no top margin');
like($page, qr/font:bold 1rem Arial,Helvetica,sans-serif;letter-spacing:0;line-height:1\.2/,
    'header matches modern page typography');
unlike($page, qr/<h2>Confirm Action|font-size:1\.45em/, 'oversized panel heading removed');
like($page, qr/No change has been made yet\./, 'pending-state wording unchanged');
like($page, qr/<dt>Action<\/dt><dd>Update request<\/dd>/, 'action detail unchanged');
like($page, qr/<dt>Request<\/dt><dd>90<\/dd>/, 'request detail unchanged');
like($page, qr/method="post" action="https:\/\/example\.invalid\/"/, 'confirmation still posts to configured origin');
like($page, qr/name="_form_token" value="$token"/, 'confirmation token unchanged');
like($page, qr/name="request" value="90"/, 'request identifier submitted unchanged');
like($page, qr/>Confirm action<\/button>.*href="\/">Cancel<\/a>/, 'confirm and cancel controls unchanged');
for my $op (qw(rerender delobj deluser deactivate reactivate abandon rollback deletereq confirmreq denyreq)) {
    my $other = Noosphere::requestFormConfirmation({op => $op, id => 209, from => 'objects'}, $token);
    like($other, qr/<header class="pl-confirm-action__header">/, "$op uses the same compact page header");
}
my $warning = Noosphere::requestFormConfirmation({op => 'delobj', id => 209}, $token);
like($warning, qr/This object will be permanently deleted\. Continue\?/, 'destructive warning preserved');
my $escaped = Noosphere::requestFormConfirmation({op => 'rerender', id => '<script>alert(1)</script>'}, $token);
unlike($escaped, qr/<script>/, 'detail escaping preserved');
like($escaped, qr/&lt;script&gt;/, 'escaped detail remains visible');

if (my $dir = $ENV{CONFIRM_HEADER_TEST_DIR}) {
    require Template;
    my $tt = Template->new({INCLUDE_PATH => "$FindBin::Bin/../../stemplates"});
    my ($sidebar, $html) = ('', '');
    $tt->process('sidebar.tt', {login => '<section class="pl-sidebar-section"><h2 class="pl-sidebar-title">Demo user</h2><div class="pl-sidebar-body"><a href="#">My Articles</a></div></section>'}, \$sidebar) or die $tt->error;
    $tt->process('view.tt', {title => 'Confirm Action preview', content => $page, sidebar => $sidebar,
        header => '<div style="padding-bottom:12px;font:2rem Georgia;color:#990000">PhysicsLibrary.org</div>'}, \$html) or die $tt->error;
    open my $out, '>', "$dir/confirm-action.html" or die $!;
    print {$out} $html; close $out;
}
done_testing();
