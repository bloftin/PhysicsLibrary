use strict;
use warnings;
use Test::More;
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);

my $root="$FindBin::Bin/../..";
# Replace only the connection and worker operations; execute the real CLI without
# loading deployment configuration or requiring a live database/Pandoc.
my $boot=<<'PERL';
BEGIN { $INC{'Noosphere/DB.pm'}=1; }
use Noosphere::NativeSearch;
use Noosphere::SearchIndex;
package Noosphere;
no warnings 'redefine';
sub dbConnect { bless {Driver=>{Name=>$ENV{SEARCH_DRIVER_TEST}}},'DriverTestDatabase' }
sub getConfig { $_[0] eq 'search_documents_tbl' ? 'search_documents' : undef }
sub nativeSearchRows {
    my ($db,$sql)=@_;
    return ({acquired=>1}) if $sql =~ /GET_LOCK/;
    return ({minimum=>3,maximum=>84}) if $sql =~ /innodb_ft_min_token_size/;
    return ({tbl=>'objects',status=>'ready',total=>1,oldest=>'2026-10-09',newest=>'2026-10-09'}) if $sql =~ /COUNT/;
    die 'Unexpected query';
}
sub searchIndexCandidates { ({collection=>'objects',uid=>209}) }
sub searchIndexText { 'Fixture plain text' }
sub searchIndexRecord { {source_bytes=>7,source=>'Fixture'} }
sub searchIndexSave { 1 }
sub searchIndexPrune { 0 }
package DriverTestDatabase;
sub do {
    my ($db,$sql)=@_;
    die 'MariaDB charset should remain driver-managed' if $db->{Driver}{Name} eq 'MariaDB';
    die 'Unexpected command' unless $sql eq 'SET NAMES utf8mb4';
    print "mysql charset set\n";
    return 1;
}
sub disconnect { 1 }
package main;
my $file=shift @ARGV;
do $file;
die $@ || $!;
PERL

sub cli {
    my ($driver,@args)=@_;
    local $ENV{SEARCH_DRIVER_TEST}=$driver;
    my ($in,$out);
    my $err=gensym;
    my $pid=open3($in,$out,$err,$^X,"-I$root/lib",'-e',$boot,"$root/bin/update-search-index",@args);
    close $in;
    local $/;
    my $stdout=<$out> || '';
    my $stderr=<$err> || '';
    waitpid($pid,0);
    return ($? >> 8,$stdout,$stderr);
}

for my $driver ('mysql','MariaDB') {
    for my $case (['status','--status'], ['dry run','--limit','5'], ['apply','--apply','--limit','5']) {
        my ($name,@args)=@$case;
        my ($code,$out,$err)=cli($driver,@args);
        is($code,0,"$driver $name succeeds") or diag $err;
        is($err,'',"$driver $name has no driver rejection/warnings");
        if ($name eq 'status') { like($out,qr/objects\s+ready\s+1/,"$driver status reports progress"); }
        elsif ($name eq 'dry run') { like($out,qr/selected 1 document\(s\); no changes made/,"$driver dry run remains read-only"); }
        else { like($out,qr/ready objects:209.*updated 1 document\(s\); pruned 0; failed 0/s,"$driver apply reaches indexing"); }
        if ($driver eq 'mysql') { like($out,qr/mysql charset set/,"$name retains mysql UTF-8 setup"); }
        else { unlike($out,qr/mysql charset set/,"$name preserves MariaDB-managed Unicode"); }
    }
}
for my $driver ('Pg','SQLite','') {
    for my $args (['--status'], ['--limit','5'], ['--apply']) {
        my ($code,$out,$err)=cli($driver,@$args);
        isnt($code,0,"unsupported driver '$driver' rejected for @$args");
        like($err,qr/Full-text index requires MySQL\/MariaDB/,"unsupported driver '$driver' gets clear diagnostic");
        is($out,'','unsupported driver performs no charset/index operations');
    }
}

done_testing();
