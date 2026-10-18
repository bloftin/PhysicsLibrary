#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use JSON::PP;
use lib "$FindBin::Bin/../../lib";
use Noosphere::NativeSearch;
use Noosphere::SearchIndex;

my $dir = tempdir(CLEANUP => 1);
my %config = (base_dir=>$dir, file_root=>"$dir/files", en_tbl=>'objects', image_url=>'https://images.example.test');
{ package Noosphere; sub getConfig { $config{$_[0]} } }
make_path("$dir/etc", "$dir/files/objects/22");
sub writejson { open my $f,'>:raw',$_[0] or die $!; print $f JSON::PP->new->utf8->encode($_[1]); close $f; }
my $entry = {title=>'Gradient Lab',language=>'Julia',version=>'1.11.2',reproducibility=>'Scalar fields and directional derivatives.',
    explorer=>'index.html',source=>'gradient-lab.zip',provenance=>'provenance.toml',license=>'LICENSE.txt',datasets=>[{label=>'Julia field samples',file=>'reference.csv'}]};
writejson("$dir/etc/computational-resources.json", {schema_version=>1,resources=>{'gradient-lab'=>$entry}});
my $manifest = "$dir/files/objects/22/computational-resources.json";
my $record = {title=>'Vector calculus',keywords=>'gradient',synonyms=>'',defines=>''};
my $original = Noosphere::searchIndexDocumentText('objects',22,$record,'Original prose.');
unlike($original,qr/Computational resource/,'unattached article receives no labels');
writejson($manifest,{schema_version=>1,resources=>['gradient-lab','gradient-lab']});
my $text = Noosphere::searchIndexDocumentText('objects',22,$record,'Original prose.');
like($text,qr/Original prose\./,'article body preserved');
like($text,qr/Computational resources: Computational resource: gradient-lab Gradient Lab Julia 1\.11\.2/,'singular/plural discovery labels and reviewed identity included');
like($text,qr/Scalar fields and directional derivatives\. Julia field samples/,'reviewed descriptions and datasets searchable');
is(scalar(()=$text=~/Gradient Lab/g),1,'duplicate manifest IDs do not duplicate indexed metadata');
unlike(Noosphere::searchIndexDocumentText('papers',22,$record,'Original prose.'),qr/Computational resource/,'same numeric ID in another collection does not inherit article resources');
writejson($manifest,{schema_version=>1,resources=>['unknown']});
is(Noosphere::searchIndexDocumentText('objects',22,$record,'Original prose.'),$original,'unknown/unreviewed resource is not indexed');
writejson($manifest,{schema_version=>2,resources=>['gradient-lab']});
is(Noosphere::searchIndexDocumentText('objects',22,$record,'Original prose.'),$original,'malformed manifest rejected');
writejson($manifest,{schema_version=>1,resources=>['gradient-lab']});
writejson("$dir/etc/computational-resources.json", {schema_version=>1,resources=>{'gradient-lab'=>{%$entry,explorer=>'https://unreviewed.invalid'}}});
is(Noosphere::searchIndexDocumentText('objects',22,$record,'Original prose.'),$original,'invalid catalog publication rejected');
unlink $manifest or die $!;
is(Noosphere::searchIndexDocumentText('objects',22,$record,'Original prose.'),$original,'removed attachment loses its searchable labels');

done_testing;
