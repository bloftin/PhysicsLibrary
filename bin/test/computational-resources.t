#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use JSON::PP;
use Template;
use lib "$FindBin::Bin/../../lib";
use Noosphere::ComputationalResources;

my $repo = "$FindBin::Bin/../..";
my $dir = tempdir(CLEANUP => 1);
my %config = (base_dir => $dir, file_root => "$dir/files", en_tbl => 'objects',
    image_url => 'https://images.example.test/images');
{
    no warnings 'redefine';
    *Noosphere::getConfig = sub { $config{$_[0]} };
}
make_path("$dir/etc", "$dir/files/objects/22", "$dir/files/objects/23");
my $manifest_path = "$dir/files/objects/22/computational-resources.json";
my $catalog_path = "$dir/etc/computational-resources.json";
sub readfile { open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>; }
sub writefile { open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1]; close $fh or die $!; }
my $catalog = decode_json(readfile("$repo/etc/computational-resources.json"));
my $manifest = decode_json(readfile("$repo/examples/julia-oscillator/computational-resources.json"));
sub reset_files {
    writefile($catalog_path, encode_json($catalog));
    writefile($manifest_path, encode_json($manifest));
}
sub resources { Noosphere::getComputationalResources({uid => 22}) }
my $tt = Template->new(INCLUDE_PATH => "$repo/stemplates");
sub render {
    my ($data, $template) = @_;
    my $html = '';
    $tt->process($template || 'computationalresources.tt',
        {computational_resources => $data, mathobj => '<p>Article</p>', viewstyle => 'HTML', metadata => '<p>Metadata</p>'},
        \$html) or die $tt->error;
    return $html;
}

is_deeply(resources(), [], 'ordinary articles need no manifest or catalog');
reset_files();
my $result = resources();
is(scalar @$result, 1, 'oscillator filebox manifest selects the reviewed publication');
is($result->[0]{title}, 'Damped Harmonic Motion', 'title comes from catalog');
is($result->[0]{explorer}, 'https://images.example.test/examples/julia-oscillator/index.html', 'uses configured image host and fixed publication path');
is(scalar @{$result->[0]{datasets}}, 3, 'three reference CSVs');
is_deeply(Noosphere::getComputationalResources({uid => 23}), [], 'does not attach to unrelated objects');
for my $id (undef, '', '../22', '22/../23', '22?x', '0', -1, "22\n") {
    is_deeply(Noosphere::getComputationalResources({uid => $id}), [], 'invalid object id is rejected');
}
my $html = render($result, 'encyclopediaobject.tt');
like($html, qr/Article.*HTML.*Computational Resources.*Metadata/s, 'real article template places resources below renderer and before metadata');
like($html, qr/Julia 1\.10\.12/, 'runtime is displayed');
like($html, qr/Precomputed results/, 'publication mode is explicit');
unlike($html, qr/<(?:script|iframe|form|object)\b/i, 'section has no execution, embed or submission elements');
unlike(render([], 'encyclopediaobject.tt'), qr/pl-computational-resources|Computational Resources/, 'unrelated articles have no empty heading or styles');
my @urls = $html =~ /href="([^"]+)"/g;
is(scalar @urls, 7, 'explorer, source, provenance, license and datasets are linked');
for my $url (@urls) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'linked publication asset exists: ' . $url);
}
my $license = readfile("$repo/data/examples/julia-oscillator/LICENSE.txt");
like($license, qr/GNU General Public License, version 3/, 'software license is GPLv3');
like($license, qr/Creative\s+Commons\s+Attribution-ShareAlike/, 'article and math materials retain Physics Library CC BY-SA terms');

for my $bad ('{', '[]', '{"schema_version":2,"resources":["julia-oscillator"]}',
    '{"schema_version":1,"resources":"julia-oscillator"}', 'x' x 8193,
    '{"schema_version":1,"resources":["a","b","c","d","e"]}') {
    writefile($manifest_path, $bad);
    is_deeply(resources(), [], 'invalid/oversized manifest leaves article unaffected');
}
reset_files();
writefile($manifest_path, encode_json({schema_version => 1, resources => ["../julia-oscillator", 'unknown', {}, 'julia-oscillator']}));
is(scalar @{resources()}, 1, 'unknown and malformed selections ignored, valid selection retained');
writefile($manifest_path, encode_json({schema_version => 1, resources => ['julia-oscillator', 'julia-oscillator']}));
is(scalar @{resources()}, 1, 'duplicate resource IDs collapse');
writefile($manifest_path, encode_json({%$manifest, explorer => 'https://unreviewed.test', title => '<script>alert(1)</script>'}));
is_deeply(resources(), $result, 'uploaded metadata cannot override catalog URLs or display fields');
reset_files();
my $multi = decode_json(encode_json($catalog));
$multi->{resources}{'python-example'} = {%{$multi->{resources}{'julia-oscillator'}}, language => 'Python', version => '3.12'};
writefile($catalog_path, encode_json($multi));
writefile($manifest_path, encode_json({schema_version => 1, resources => ['julia-oscillator', 'python-example']}));
is(scalar @{resources()}, 2, 'multiple reviewed publications share the section');
like(render(resources()), qr/Python 3\.12/, 'presentation is not Julia-specific');
reset_files();
my $invalid_dataset = decode_json(encode_json($catalog));
$invalid_dataset->{resources}{'julia-oscillator'}{datasets}[0]{file} = '../private.csv';
writefile($catalog_path, encode_json($invalid_dataset));
is_deeply(resources(), [], 'invalid dataset suppresses its resource');
reset_files();
for my $bad ('{', 'x' x 65537, '{"schema_version":2,"resources":{}}') {
    writefile($catalog_path, $bad);
    is_deeply(resources(), [], 'invalid catalog cannot break article view');
}
reset_files();
for my $bad ('../index.html', 'https://unreviewed.test/index.html', 'index.html?run=1', 'index.php', '//unreviewed.test', "index.html\n") {
    my $changed = decode_json(encode_json($catalog));
    $changed->{resources}{'julia-oscillator'}{explorer} = $bad;
    writefile($catalog_path, encode_json($changed));
    is_deeply(resources(), [], 'only plain static publication filenames accepted');
}
reset_files();
my $changed = decode_json(encode_json($catalog));
$changed->{resources}{'julia-oscillator'}{title} = '<b>Untrusted & "title"</b>';
$changed->{resources}{'julia-oscillator'}{datasets}[0]{label} = '<img src=x>';
writefile($catalog_path, encode_json($changed));
my $escaped = render(resources());
like($escaped, qr/&lt;b&gt;Untrusted &amp; &quot;title&quot;&lt;\/b&gt;/, 'catalog title escaped in text and attributes');
unlike($escaped, qr/<b>|<img\b/, 'labels cannot inject markup');
reset_files();
for my $origin ('http://images.example.test/images', 'javascript:alert(1)', 'https://user:pass@images.example.test/images') {
    local $config{image_url} = $origin;
    is_deeply(resources(), [], 'unexpected origin configuration fails closed');
}
SKIP: {
    unlink $manifest_path or die $!;
    writefile("$dir/outside.json", encode_json($manifest));
    skip 'symlinks unavailable', 1 unless symlink("$dir/outside.json", $manifest_path);
    is_deeply(resources(), [], 'symlink manifest not followed');
    unlink $manifest_path or die $!;
}
reset_files();
writefile("$dir/outside.json", encode_json($manifest));
is(Noosphere::computationalResourceJSON("$dir/files", "$dir/outside.json", 8192), undef, 'file must remain under expected root');
like(readfile("$repo/lib/Noosphere/Encyclopedia.pm"), qr/computational_resources\s*=>\s*getComputationalResources\(\$rec\)/, 'integration uses retrieved article record, not request-selected metadata');

done_testing();
