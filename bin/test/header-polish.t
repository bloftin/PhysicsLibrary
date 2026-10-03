#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::TemplateNS;
{
    package Noosphere;
    sub getConfig {
        return {
            stemplate_path=>"$FindBin::Bin/../../stemplates", template_cmd_prefix=>'NS',
            siteaddrs=>{main=>'physicslibrary.org',images=>'images.physicslibrary.org'},
            main_url=>'https://physicslibrary.org',projname=>'Physics Library',
            slogan=>'An open source physics library',
        }->{$_[0]};
    }
    sub readFile {open my $in,'<',$_[0] or die $!; return do {local $/; <$in>}}
    sub htmlescape {my $s=$_[0]; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s}
    sub urlescape {$_[0]}
}
my $header=TemplateNS->new('header.html');
$header->setKey('q','polar "waves" & <rays>');
my $html=$header->expand();
like($html,qr/physicslibrarylogotransparent\.png/,'distinctive logo retained');
like($html,qr/An open source physics library/,'slogan retained');
like($html,qr/\.pl-header-quick-links \{ font: \.8rem/,'quick links use readable fixed-size type');
like($html,qr/<span class="pl-header-quick-links">.*<\/span>/s,'quick links use scoped styling instead of tiny font tag');
for my $route ('/encyclopedia','/?op=forums','/?op=sitedoc','/?op=randomentry') {
    like($html,qr/\Qhref="https:\/\/physicslibrary.org$route"\E/,'quick link retained: '.$route);
}
like($html,qr/#cse-search-box input\[type=submit\] \{ background: #003399/,'Search button matches original-blue controls');
like($html,qr/<form action="https:\/\/physicslibrary.org" id="cse-search-box">/,'existing search destination preserved');
for my $field (['cx','d7c37e2bb0d444808'],['cof','FORID:10'],['ie','UTF-8'],['sa','Search']) {
    like($html,qr/name="$field->[0]" value="$field->[1]"/,'search field retained: '.$field->[0]);
}
like($html,qr/aria-label="Search Physics Library"/,'query field has accessible label');
like($html,qr/value="polar &quot;waves&quot; &amp; &lt;rays&gt;"/,'query safely repopulates field');
like($html,qr/restoreHeaderSearchQuery/,'existing query-restoration script retained');
done_testing;
