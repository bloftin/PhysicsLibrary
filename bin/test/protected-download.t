#!/usr/bin/perl
package Noosphere;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use Cwd qw(abs_path);

my $root = tempdir(CLEANUP => 1);
my %config = (
    base_dir => $root,
    main_url => 'https://physicslibrary.example.test',
    en_tbl => 'objects',
    books_tbl => 'books',
    papers_tbl => 'papers',
    exp_tbl => 'lec',
);
my %readable;
my @errors;

sub getConfig { return $config{$_[0]}; }
sub hasPermissionTo {
    my ($table, $objectid, $userinf) = @_;
    return $readable{"$table/$objectid/".($userinf->{uid} || 0)} || 0;
}
sub makeBox { return "<h2>$_[0]</h2>$_[1]"; }
sub errorMessage { return "<p class=\"error\">$_[0]</p>"; }
sub sendOutput { push @errors, [$_[1], $_[2]]; }
sub setStandardSecurityHeaders { $_[0]->{standard_headers}++; }

{
    package ProtectedDownloadHeaders;
    sub new { bless { values => {} }, shift; }
    sub set { $_[0]->{values}{$_[1]} = $_[2]; }
    sub add { $_[0]->{values}{$_[1]} = $_[2]; }
}
{
    package ProtectedDownloadRequest;
    sub new { bless { headers => ProtectedDownloadHeaders->new(), body => '' }, shift; }
    sub headers_out { $_[0]->{headers}; }
    sub content_type { $_[0]->{content_type} = $_[1] if @_ > 1; return $_[0]->{content_type}; }
    sub print { $_[0]->{body} .= $_[1]; }
    sub rflush { $_[0]->{flushed} = 1; }
}

sub read_file {
    open my $fh, '<', $_[0] or die $!;
    local $/;
    return <$fh>;
}
sub load_sub {
    my ($source, $name) = @_;
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name not found" unless defined $sub;
    eval $sub;
    die $@ if $@;
}

my $source = read_file("$FindBin::Bin/../../lib/Noosphere.pm");
load_sub($source, $_) for qw(
    serveProtectedDownload
    publicFileboxDownloadInfo
    downloadAttachmentFilename
    protectedDownloadContentType
);

make_path("$root/data/files/objects/1253", "$root/data/files/books/12");
open my $jl, '>', "$root/data/files/objects/1253/newton_modern_data_analysis.jl" or die $!;
print {$jl} "println(\"hello\")\n";
close $jl;
open my $csv, '>', "$root/data/files/books/12/orbit data.csv" or die $!;
print {$csv} "time,value\n0,1\n";
close $csv;

my $info = publicFileboxDownloadInfo('files/objects/1253/newton_modern_data_analysis.jl');
is_deeply($info, {table => 'objects', objectid => 1253, filename => 'newton_modern_data_analysis.jl'},
    'public object attachment resolves to its fixed parent table and id');
is(publicFileboxDownloadInfo('files/books/12/orbit data.csv')->{table}, 'books', 'book attachment maps to books table');
for my $bad (
    'files/objects/nope/file.txt',
    'files/objects/1253/nested/file.txt',
    'files/objects/1253/../secret.txt',
    "files/objects/1253/header\nvalue.txt",
    'snapshots/objects/1253/file.txt',
) {
    ok(!defined(publicFileboxDownloadInfo($bad)), "non-filebox public path rejected: $bad");
}

$readable{'objects/1253/0'} = 1;
my $req = ProtectedDownloadRequest->new();
serveProtectedDownload($req, {path => 'files/objects/1253/newton_modern_data_analysis.jl'}, {uid => 0});
is($req->{body}, "println(\"hello\")\n", 'anonymous reader receives a public object attachment');
is($req->{content_type}, 'text/plain; charset=UTF-8', 'Julia source is served as text');
is($req->{headers}{values}{'Content-Disposition'}, 'attachment; filename="newton_modern_data_analysis.jl"',
    'download preserves the filebox filename');
is($req->{headers}{values}{'content-length'}, length($req->{body}), 'download has content length');
ok($req->{standard_headers}, 'download applies standard security headers');

delete $readable{'objects/1253/0'};
@errors = ();
$req = ProtectedDownloadRequest->new();
serveProtectedDownload($req, {path => 'files/objects/1253/newton_modern_data_analysis.jl'}, {uid => 0});
is($errors[0][1], 403, 'unreadable object attachment remains forbidden anonymously');
like($errors[0][0], qr/Sign In Required/, 'anonymous denial retains sign-in guidance');

$readable{'objects/1253/7'} = 1;
@errors = ();
$req = ProtectedDownloadRequest->new();
serveProtectedDownload($req, {path => 'files/objects/1253/newton_modern_data_analysis.jl'}, {uid => 7});
is($req->{body}, "println(\"hello\")\n", 'authenticated reader with ACL access receives private attachment');
is(scalar @errors, 0, 'authorized request has no error response');

@errors = ();
$req = ProtectedDownloadRequest->new();
serveProtectedDownload($req, {path => 'files/objects/1253/newton_modern_data_analysis.jl'}, {uid => 8});
is($errors[0][1], 403, 'authenticated reader without ACL access is forbidden');
like($errors[0][0], qr/Access Denied/, 'authenticated denial does not imply a login would help');

$readable{'books/12/0'} = 1;
$req = ProtectedDownloadRequest->new();
serveProtectedDownload($req, {path => 'files/books/12/orbit data.csv'}, {uid => 0});
is($req->{content_type}, 'text/csv; charset=UTF-8', 'CSV attachment has a CSV media type');
is($req->{headers}{values}{'Content-Disposition'}, 'attachment; filename="orbit data.csv"', 'space-bearing filename is preserved');

@errors = ();
$req = ProtectedDownloadRequest->new();
serveProtectedDownload($req, {path => 'snapshots/objects/1253/archive.zip'}, {uid => 0});
is($errors[0][1], 403, 'snapshots remain protected from anonymous download');
is(downloadAttachmentFilename("bad\r\nname.txt"), 'bad__name.txt', 'header control characters are neutralized');

done_testing();
