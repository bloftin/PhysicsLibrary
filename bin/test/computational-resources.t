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
writefile($manifest_path, readfile("$repo/examples/newton-constant-acceleration/computational-resources.json"));
my $newton = resources();
is(scalar @$newton, 1, 'Newton manifest selects a second real publication');
is($newton->[0]{title}, "Constant Acceleration from Newton's Second Law", 'Newton title comes from catalog');
for my $url (render($newton) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'Newton publication asset exists: ' . $url);
}
reset_files();
writefile($manifest_path, readfile("$repo/examples/inclined-plane/computational-resources.json"));
my $incline = resources();
is(scalar @$incline, 1, 'inclined-plane manifest selects its reviewed publication');
is($incline->[0]{title}, 'Motion on an Inclined Plane', 'inclined-plane title comes from catalog');
for my $url (render($incline) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'inclined-plane publication asset exists: ' . $url);
}
reset_files();
writefile($manifest_path, readfile("$repo/examples/orbital-gravitation/computational-resources.json"));
my $orbit = resources();
is(scalar @$orbit, 1, 'orbital-gravitation manifest selects its reviewed publication');
is($orbit->[0]{title}, 'Orbital Motion from Universal Gravitation', 'orbital resource title comes from catalog');
is(scalar @{$orbit->[0]{datasets}}, 3, 'orbital resource exposes three reference datasets');
for my $url (render($orbit) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'orbital publication asset exists: ' . $url);
}
reset_files();
writefile($manifest_path, readfile("$repo/examples/minimum-effort-interception/computational-resources.json"));
my $intercept = resources();
is(scalar @$intercept, 1, 'interception manifest selects its reviewed publication');
is($intercept->[0]{title}, 'Minimum-Effort Interception of a Moving Target', 'interception title comes from catalog');
is(scalar @{$intercept->[0]{datasets}}, 1, 'interception resource exposes the Julia reference dataset');
for my $url (render($intercept) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'interception publication asset exists: ' . $url);
}
reset_files();
writefile($manifest_path, readfile("$repo/examples/gre-uniform-circular-motion/computational-resources.json"));
my $circular = resources();
is(scalar @$circular, 1, 'circular-motion manifest selects its reviewed publication');
is($circular->[0]{title}, 'GRE Uniform Circular Motion', 'circular-motion title comes from catalog');
is(scalar @{$circular->[0]{datasets}}, 1, 'circular-motion resource exposes Julia reference data');
for my $url (render($circular) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'circular-motion publication asset exists: ' . $url);
}
reset_files();
writefile($manifest_path, readfile("$repo/examples/pulley-atwood-machines/computational-resources.json"));
my $pulley = resources();
is(scalar @$pulley, 1, 'pulley manifest selects its reviewed publication');
is($pulley->[0]{title}, 'Pulleys and Atwood Machines', 'pulley title comes from catalog');
is(scalar @{$pulley->[0]{datasets}}, 1, 'pulley resource exposes reference trajectories');
for my $url (render($pulley) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'pulley publication asset exists: ' . $url);
}
reset_files();
writefile($manifest_path, readfile("$repo/examples/orbital-elements/computational-resources.json"));
my $elements = resources();
is(scalar @$elements, 1, 'orbital-elements manifest selects its reviewed publication');
is($elements->[0]{title}, 'Orbital Elements and Kepler Propagation', 'orbital-elements title comes from catalog');
is(scalar @{$elements->[0]{datasets}}, 1, 'orbital-elements resource exposes Julia reference data');
for my $url (render($elements) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'orbital-elements publication asset exists: ' . $url);
}
reset_files();
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
writefile($manifest_path, encode_json({schema_version => 1, resources => ['julia-oscillator', 'newton-constant-acceleration']}));
my $two_resources = resources();
is(scalar @$two_resources, 2, 'multiple reviewed publications share the section');
is_deeply([map { $_->{id} } @$two_resources], ['julia-oscillator', 'newton-constant-acceleration'], 'manifest order controls presentation order');
my $multi_html = render($two_resources);
like($multi_html, qr/2 reviewed static resources are attached to this article\./, 'multi-resource section explains the count');
like($multi_html, qr/julia-oscillator\/index\.html.*newton-constant-acceleration\/index\.html/s, 'both real resources render in order');
unlike($multi_html, qr/<(?:script|iframe|form|object)\b/i, 'multi-resource section still has no execution, embed or submission elements');
my @multi_urls = $multi_html =~ /href="([^"]+)"/g;
is(scalar @multi_urls, 14, 'both real resources expose their reviewed links');
for my $url (@multi_urls) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'multi-resource linked asset exists: ' . $url);
}
writefile($manifest_path, encode_json({schema_version => 1, resources => ['newton-constant-acceleration', 'julia-oscillator']}));
is_deeply([map { $_->{id} } @{resources()}], ['newton-constant-acceleration', 'julia-oscillator'], 'articles can choose a different multi-resource order');
reset_files();
writefile($manifest_path, readfile("$repo/examples/binary-star-observer/computational-resources.json"));
my $binary = resources();
is(scalar @$binary, 1, 'binary-star manifest selects its reviewed publication');
is($binary->[0]{title}, 'Binary Star Observer and Eclipse Probability', 'binary-star title comes from catalog');
is(scalar @{$binary->[0]{datasets}}, 1, 'binary-star resource exposes its Julia reference curves');
for my $url (render($binary) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'binary-star publication asset exists: ' . $url);
}
reset_files();
my $multi = decode_json(encode_json($catalog));
writefile($manifest_path, readfile("$repo/examples/spectroscopic-binary/computational-resources.json"));
my $spectroscopic = resources();
is(scalar @$spectroscopic, 1, 'spectroscopic manifest selects its reviewed publication');
is($spectroscopic->[0]{title}, 'Spectroscopic Binary Lab', 'spectroscopic title comes from catalog');
is(scalar @{$spectroscopic->[0]{datasets}}, 2, 'spectroscopic resource exposes orbital and spectral Julia references');
for my $url (render($spectroscopic) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'spectroscopic publication asset exists: ' . $url);
}
writefile($manifest_path, readfile("$repo/examples/spectroscopic-binary/binary-stars-computational-resources.json"));
is_deeply([map { $_->{id} } @{resources()}], ['binary-star-observer', 'spectroscopic-binary'], 'article attachment preserves the existing binary observer lab');
reset_files();
$multi->{resources}{'python-example'} = {%{$multi->{resources}{'julia-oscillator'}}, language => 'Python', version => '3.12'};
writefile($manifest_path, readfile("$repo/examples/em-field-lab/computational-resources.json"));
my $field_lab = resources();
is(scalar @$field_lab, 1, 'field-lab manifest selects its reviewed publication');
is($field_lab->[0]{title}, 'Wave and Field Explorer (EM01)', 'field-lab title comes from catalog');
is(scalar @{$field_lab->[0]{datasets}}, 1, 'field-lab exposes independent Julia field references');
for my $url (render($field_lab) =~ /href="([^"]+)"/g) {
    $url =~ s{\Ahttps://images\.example\.test/examples/}{};
    ok(-f "$repo/data/examples/$url", 'field-lab publication asset exists: ' . $url);
}
reset_files();
writefile($catalog_path, encode_json($multi));
writefile($manifest_path, encode_json({schema_version => 1, resources => ['python-example']}));
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
