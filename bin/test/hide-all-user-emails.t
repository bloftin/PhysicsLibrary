#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/../convert/hide_all_user_emails.pl";

for my $case (
    [undef, 'hideemail=on'],
    ['', 'hideemail=on'],
    ['hideemail=off', 'hideemail=on'],
    ['hideemail=on', 'hideemail=on'],
    ['style=pdf;hideemail=off;unknown=a=b;', 'style=pdf;hideemail=on;unknown=a=b;'],
    ['style=pdf', 'style=pdf;hideemail=on'],
    ['style=pdf;', 'style=pdf;hideemail=on'],
    ['hideemail=off;hideemail=unexpected', 'hideemail=on;hideemail=on'],
) {
    my ($old, $expected) = @$case;
    is(hidden_email_prefs($old), $expected, 'reset preserves unrelated preferences');
    is(hidden_email_prefs($expected), $expected, 'reset is idempotent');
}

open my $config, '<', "$FindBin::Bin/../../lib/Noosphere/Config.pm" or die $!;
my $source = do { local $/; <$config> };
like($source, qr/hideemail\s*=>\s*\[[^\n]*'check'\s*,\s*'on'\s*\]/,
    'production default hides email');
done_testing;
