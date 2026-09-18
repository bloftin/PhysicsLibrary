#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

our $dbh;
my $update_result = 1;
my @updates;
my @flags;
my $render_result = 1;
my $render_exception = '';
my $render_calls = 0;
my $build_off_calls = 0;
my $valid_on_calls = 0;
my $valid_off_calls = 0;
my @finalization;

sub getConfig {
    return {cache_tbl => 'cache', en_tbl => 'objects', collab_tbl => 'collab'}->{$_[0]};
}
sub dbUpdate {
    push @updates, $_[1];
    return ($update_result, bless({}, 'ClaimStatement'));
}
{ package ClaimStatement; sub finish { return 1; } }
sub getcacheflags { return @{shift @flags}; }
sub setbuildflag_off { $build_off_calls++; push @finalization, 'build-off'; }
sub setvalidflag_on { $valid_on_calls++; push @finalization, 'valid-on'; }
sub setvalidflag_off { $valid_off_calls++; push @finalization, 'valid-off'; }
sub cleanCache {}
sub cacheFileBox {}
sub getSynonymsList { return []; }
sub getDefinesList { return []; }
sub classstring { return ''; }
sub prepareEntryForRendering { return ('document', 'links'); }
sub writeLinksToFile {}
sub renderLaTeX {
    $render_calls++;
    die $render_exception if $render_exception ne '';
    return $render_result;
}
sub dwarn {}

open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/Cache.pm" or die $!;
my $source = do { local $/; <$in> };
close $in;
for my $name (qw(cacheObject setbuildflag_on)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name not found" unless defined $sub;
    eval $sub;
    die $@ if $@;
}

$update_result = 1;
@updates = ();
ok(setbuildflag_on('objects', 1224, 'make4ht'), 'conditional update claims an available build');
is($updates[0]->{WHERE},
    "tbl='objects' and objectid=1224 and valid=0 and build=0  and (method='make4ht')",
    'claim only updates an invalid idle cache row');

$update_result = '0E0';
ok(!setbuildflag_on('objects', 1224, 'make4ht'), 'zero affected rows loses the build claim');

my $rec = {uid => 1224, preamble => '', data => '', title => 'Article', name => 'Article'};
@flags = ([0, 0], [0, 1]);
$render_calls = 0;
$build_off_calls = 0;
my $lost_debug = '';
my $lost;
{
    open my $capture, '>', \$lost_debug or die $!;
    local *STDOUT = $capture;
    $lost = cacheObject('objects', $rec, 'make4ht');
}
is($lost, 0, 'a competing request returns without rendering');
is($render_calls, 0, 'a competing request does not invoke the renderer');
is($build_off_calls, 0, 'a competing request does not release another renderer claim');

$update_result = 1;
@flags = ([0, 0]);
$render_result = 1;
$render_exception = '';
$render_calls = 0;
$build_off_calls = 0;
$valid_on_calls = 0;
@finalization = ();
my $success_debug = '';
my $success;
{
    open my $capture, '>', \$success_debug or die $!;
    local *STDOUT = $capture;
    $success = cacheObject('objects', $rec, 'make4ht');
}
is($success, 1, 'claim winner returns successful render');
is($render_calls, 1, 'claim winner invokes the renderer once');
is($build_off_calls, 1, 'successful render releases its claim');
is($valid_on_calls, 1, 'successful render marks the cache valid');
is_deeply(\@finalization, ['valid-on', 'build-off'],
    'successful cache becomes valid before its build claim is released');

@flags = ([0, 0]);
$render_result = 0;
$build_off_calls = 0;
$valid_off_calls = 0;
@finalization = ();
my $failure_debug = '';
my $failure;
{
    open my $capture, '>', \$failure_debug or die $!;
    local *STDOUT = $capture;
    $failure = cacheObject('objects', $rec, 'make4ht');
}
is($failure, 0, 'renderer failure is returned');
is($build_off_calls, 1, 'renderer failure releases its claim');
is($valid_off_calls, 1, 'renderer failure leaves the cache invalid');
is_deeply(\@finalization, ['valid-off', 'build-off'],
    'failed cache remains claimed until invalid state is recorded');

@flags = ([0, 0]);
$render_result = 1;
$render_exception = 'converter died';
$build_off_calls = 0;
$valid_off_calls = 0;
@finalization = ();
my $exception_debug = '';
my $exception;
{
    open my $capture, '>', \$exception_debug or die $!;
    local *STDOUT = $capture;
    $exception = cacheObject('objects', $rec, 'make4ht');
}
is($exception, 0, 'renderer exception is contained');
is($build_off_calls, 1, 'renderer exception releases its claim');
is($valid_off_calls, 1, 'renderer exception leaves the cache invalid');
is_deeply(\@finalization, ['valid-off', 'build-off'],
    'exception cache remains claimed until invalid state is recorded');

done_testing();
