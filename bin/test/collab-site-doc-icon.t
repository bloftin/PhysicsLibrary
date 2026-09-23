#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
my $template_path = "$root/stemplates/collabmain.tt";

open my $template, '<', $template_path or die $!;
my $source = do { local $/; <$template> };
close $template;

like($source, qr/pl-collab-badge-site/, 'site-document collaborations have a dedicated state badge');
like($source, qr/Site documentation/, 'site-document collaborations have a visible label');
unlike($source, qr/site_icon\.png/, 'workspace does not reference the missing legacy icon');

done_testing();
