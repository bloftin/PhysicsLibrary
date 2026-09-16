#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
my $template_path = "$root/stemplates/collabmain.xsl";

open my $template, '<', $template_path or die $!;
my $source = do { local $/; <$template> };
close $template;

like(
	$source,
	qr{src="\{//globals/image_url\}/object\.png"},
	'site-document collaborations use the existing object icon',
);
unlike($source, qr/site_icon\.png/, 'template does not reference the missing legacy icon');
ok(-f "$root/data/images/object.png", 'referenced collaboration icon exists');

done_testing();
