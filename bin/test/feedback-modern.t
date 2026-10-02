#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
open my $in, '<', "$root/lib/Noosphere/Docs.pm" or die $!;
my $source = do { local $/; <$in> };
my ($get_feedback) = $source =~ /(sub getFeedback \{.*?^\})/ms;
ok($get_feedback, 'feedback handler is available');

{
    package Noosphere;
    sub getConfig { return 'stemplates' }
    sub getAddr { return 'team+feedback@example.org' }
    sub qhtmlescape { return $_[0] }
    sub paddingTable { return $_[0] }
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
        $$output = 'rendered feedback page';
        return 1;
    }
}

my $loaded = eval "package Noosphere; $get_feedback; 1";
ok($loaded, 'feedback handler compiles') or diag($@);
is(Noosphere::getFeedback(), 'rendered feedback page', 'feedback page renders through the template');
is($Template::name, 'feedback.tt', 'feedback uses the modern template');
is($Template::vars->{email}, 'team+feedback@example.org', 'template receives the configured feedback address');

open my $template_in, '<', "$root/stemplates/feedback.tt" or die $!;
my $template = do { local $/; <$template_in> };
like($template, qr/INCLUDE modernboxheader\.tt title = 'Feedback'/, 'page uses the shared box heading');
like($template, qr/href="\/\?op=getobj&amp;from=forums&amp;id=6"/, 'comments forum is directly linked');
like($template, qr/href="mailto:\[% email %\]"/, 'email address is a mail link');
like($template, qr/href="\/\?op=newuser"/, 'correction guidance links to account creation');

done_testing();
