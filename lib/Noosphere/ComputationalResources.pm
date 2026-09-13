package Noosphere;
use strict;
use warnings;
use Cwd qw(abs_path);
use JSON::PP ();
use URI ();

sub computationalResourceJSON {
    my ($root, $path, $limit) = @_;
    return if !defined($root) || !-f $path || -l $path;
    my $realroot = abs_path($root);
    my $realpath = abs_path($path);
    return unless defined($realroot) && defined($realpath)
        && index($realpath, "$realroot/") == 0;
    open my $fh, '<:raw', $path or return;
    return if !-f $fh || -s $fh > $limit;
    my $length = read($fh, my $bytes, $limit + 1);
    close $fh;
    return unless defined($length) && $length <= $limit;
    my $data = eval { JSON::PP->new->utf8->max_depth(8)->decode($bytes) };
    return ref($data) eq 'HASH' ? $data : undef;
}

sub computationalResourceText {
    my ($value, $limit) = @_;
    return defined($value) && !ref($value) && length($value) > 0
        && length($value) <= $limit && $value !~ /[\x00-\x1f\x7f]/;
}

sub computationalResourceFile {
    my ($value, $extension) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[A-Za-z0-9][A-Za-z0-9_.-]{0,100}\.$extension\z/
        && $value !~ /\.\./;
}

# Filebox metadata selects reviewed static publications; it cannot supply URLs or code.
sub getComputationalResources {
    my ($rec) = @_;
    return [] unless ref($rec) eq 'HASH' && defined($rec->{uid})
        && $rec->{uid} =~ /\A[1-9][0-9]{0,18}\z/;
    my $table = getConfig('en_tbl');
    return [] unless defined($table) && $table =~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
    my $root = getConfig('file_root');
    return [] unless defined($root) && length($root);
    my $manifest = computationalResourceJSON($root,
        "$root/$table/$rec->{uid}/computational-resources.json", 8192);
    return [] unless $manifest && !ref($manifest->{schema_version})
        && ($manifest->{schema_version} || '') eq '1'
        && ref($manifest->{resources}) eq 'ARRAY' && @{$manifest->{resources}} <= 4;
    my $base = getConfig('base_dir');
    return [] unless defined($base) && length($base);
    my $catalog = computationalResourceJSON("$base/etc", "$base/etc/computational-resources.json", 65536);
    return [] unless $catalog && !ref($catalog->{schema_version})
        && ($catalog->{schema_version} || '') eq '1' && ref($catalog->{resources}) eq 'HASH';
    my $origin = eval { URI->new(getConfig('image_url')) };
    return [] unless $origin && $origin->scheme && $origin->scheme eq 'https'
        && $origin->can('host') && $origin->host && !defined($origin->userinfo);
    my (@resources, %seen);
    for my $id (@{$manifest->{resources}}) {
        next unless defined($id) && !ref($id) && $id =~ /\A[a-z0-9][a-z0-9-]{0,63}\z/;
        next if $seen{$id}++;
        my $entry = $catalog->{resources}{$id};
        next unless ref($entry) eq 'HASH';
        next unless computationalResourceText($entry->{title}, 120)
            && computationalResourceText($entry->{language}, 40)
            && computationalResourceText($entry->{version}, 40)
            && computationalResourceText($entry->{reproducibility}, 320);
        next unless computationalResourceFile($entry->{explorer}, 'html')
            && computationalResourceFile($entry->{source}, 'zip')
            && computationalResourceFile($entry->{provenance}, 'toml')
            && computationalResourceFile($entry->{license}, 'txt');
        next unless ref($entry->{datasets}) eq 'ARRAY' && @{$entry->{datasets}} <= 8;
        my @datasets;
        my $invalid = 0;
        my $url = sub { URI->new_abs("/examples/$id/$_[0]", $origin)->as_string };
        for my $dataset (@{$entry->{datasets}}) {
            if (ref($dataset) ne 'HASH' || !computationalResourceText($dataset->{label}, 80)
                || !computationalResourceFile($dataset->{file}, 'csv')) { $invalid = 1; last; }
            push @datasets, {label => $dataset->{label}, url => $url->($dataset->{file})};
        }
        next if $invalid;
        push @resources, {
            id => $id, title => $entry->{title}, language => $entry->{language},
            version => $entry->{version}, reproducibility => $entry->{reproducibility},
            explorer => $url->($entry->{explorer}), source => $url->($entry->{source}),
            provenance => $url->($entry->{provenance}), license => $url->($entry->{license}),
            datasets => \@datasets,
        };
    }
    return \@resources;
}

1;
