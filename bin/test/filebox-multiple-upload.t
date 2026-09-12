#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../../lib";

BEGIN {
    $INC{'Apache2/compat.pm'} = 1;
    $INC{'CGI/Util.pm'} = 1;
    package Apache2::compat;
    sub import { return; }
    package CGI::Util;
    sub unescape {
        my $value = shift;
        $value =~ tr/+/ /;
        $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        return $value;
    }
    package Noosphere;
    our $TempDir;
    our $TempFileCount = 0;
    sub basefilename {
        my $path = shift;
        return $1 if $path =~ /\\([^\\]+)$/;
        return $1 if $path =~ m{/([^/]+)$};
        return $path;
    }
    sub getTempFileName {
        return "$TempDir/upload-".++$TempFileCount;
    }
}

require Noosphere::Params;

my $dir = tempdir(CLEANUP => 1);
$Noosphere::TempDir = $dir;

subtest 'multipart parser keeps every uploaded file' => sub {
    my $boundary = 'AaB03x';
    my $body = join '',
        "--$boundary\r\n",
        "Content-Disposition: form-data; name=\"filebox\"\r\n\r\n",
        "upload\r\n",
        "--$boundary\r\n",
        "Content-Disposition: form-data; name=\"upload\"; filename=\"C:\\fakepath\\one.txt\"\r\n",
        "Content-Type: text/plain\r\n\r\n",
        "first file\r\n",
        "--$boundary\r\n",
        "Content-Disposition: form-data; name=\"upload\"; filename=\"two.txt\"\r\n",
        "Content-Type: text/plain\r\n\r\n",
        "second file\r\n",
        "--$boundary--\r\n";

    my ($params, $upload) = Noosphere::parseMime($boundary, $body);
    is($params->{filebox}, 'upload', 'ordinary fields are preserved');
    is($upload->{filename}, 'one.txt', 'legacy single-upload field uses first file');
    is(scalar @{$upload->{uploads}}, 2, 'all selected files are retained');
    is_deeply([map { $_->{filename} } @{$upload->{uploads}}], ['one.txt', 'two.txt'], 'base names retained');
    is_deeply([map { $_->{formname} } @{$upload->{uploads}}], ['upload', 'upload'], 'form field retained');
    is_deeply([map { $_->{type} } @{$upload->{uploads}}], ['text/plain', 'text/plain'], 'content types retained');

    open my $one, '<', $upload->{uploads}[0]{tempfile} or die $!;
    open my $two, '<', $upload->{uploads}[1]{tempfile} or die $!;
    is(do { local $/; <$one> }, 'first file', 'first temp file written');
    is(do { local $/; <$two> }, 'second file', 'second temp file written');
};

subtest 'Apache request parser keeps every uploaded file' => sub {
    my $req = bless {}, 'MultiUploadRequest';
    my ($params, $upload) = Noosphere::parseParamsNew($req);
    is_deeply($params, {filebox => 'upload'}, 'request params parsed');
    is($upload->{filename}, 'one.txt', 'legacy field uses first upload');
    is(scalar @{$upload->{uploads}}, 2, 'every Apache upload object is retained');
    is_deeply([map { $_->{filename} } @{$upload->{uploads}}], ['one.txt', 'two.txt'], 'Apache filenames normalized');
};

subtest 'filebox form shows selected filenames' => sub {
    my $template = "$FindBin::Bin/../../stemplates/filemanagerform.html";
    open my $fh, '<', $template or die "open $template: $!";
    my $html = do { local $/; <$fh> };
    like($html, qr/name="upload"[^>]*multiple="multiple"/, 'upload control accepts multiple files');
    like($html, qr/id="filebox-upload-list"/, 'selected-file list placeholder is present');
    like($html, qr/input\.onchange/, 'selected-file list updates when files are selected');
    like($html, qr/createTextNode\(files\[i\]\.name\)/, 'selected filenames are inserted as text');
};

{
    package MultiUploadRequest;
    sub args { return {filebox => 'upload'}; }
    sub uploads { return ('upload'); }
    sub upload {
        return (
            bless({name => 'upload', filename => 'C:\\fakepath\\one.txt', tempname => '/tmp/one'}, 'UploadObject'),
            bless({name => 'upload', filename => '/tmp/two.txt', tempname => '/tmp/two'}, 'UploadObject'),
        );
    }
    package UploadObject;
    sub name { return $_[0]->{name}; }
    sub filename { return $_[0]->{filename}; }
    sub tempname { return $_[0]->{tempname}; }
}

done_testing();
