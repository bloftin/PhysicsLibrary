package Noosphere;
use strict;
use Encode ();
use File::Temp ();
use IPC::Open3;

sub searchIndexParserVersion { 1 }
sub searchIndexSourceLimit { 262144 }

sub searchIndexCollection {
    my ($value) = @_;
    my ($collection) = grep { $_->{value} eq $value && $value ne 'all' } @{nativeSearchCollections()};
    die "Invalid index collection\n" unless $collection;
    return $collection;
}

sub searchIndexCandidates {
    my ($db, $options) = @_;
    my $documents = nativeSearchIdentifier('search_documents_tbl');
    my (@parts, @bind);
    for my $collection (@{nativeSearchCollections()}) {
        next if $collection->{value} eq 'all';
        next if $options->{collection} ne 'all' && $options->{collection} ne $collection->{value};
        my $table = nativeSearchIdentifier($collection->{key});
        my @where_bind;
        my $public = nativeSearchPublicSql($table, \@where_bind);
        my $en = $collection->{value} eq 'objects';
        my $version = $en ? 'COALESCE(o.version,0)' : '0';
        my @where = ('o.uid>=0', $public);
        push @where, "o.name<>''" if $en;
        if (defined $options->{object}) {
            push @where, 'o.uid=?';
            push @where_bind, $options->{object};
        } else {
            push @where, "(s.objectid IS NULL OR NOT (".nativeSearchFreshSql('s', $en).")
                OR s.parser_version<>".searchIndexParserVersion()."
                OR (s.status='failed' AND s.indexed_at < NOW()-INTERVAL 1 HOUR)
                OR s.indexed_at < NOW()-INTERVAL 1 DAY)";
        }
        push @parts, "SELECT '$collection->{value}' AS collection, o.uid, s.indexed_at
            FROM $table o LEFT JOIN $documents s ON s.tbl='$table' AND s.objectid=o.uid
            WHERE ".join(' AND ', map { "($_)" } @where);
        push @bind, @where_bind;
    }
    return nativeSearchRows($db, 'SELECT * FROM ('.join(' UNION ALL ', @parts).
        ') pending ORDER BY indexed_at, collection, uid LIMIT '.int($options->{limit}), @bind);
}

sub searchIndexRecord {
    my ($db, $collection, $uid) = @_;
    my $spec = searchIndexCollection($collection);
    my $table = nativeSearchIdentifier($spec->{key});
    my (@bind, @fields);
    my $en = $collection eq 'objects';
    @fields = $en ? qw(title synonyms defines keywords) : qw(title authors keywords);
    my $public = nativeSearchPublicSql($table, \@bind);
    push @bind, $uid;
    my @rows = nativeSearchRows($db, 'SELECT o.uid, COALESCE(o.modified,\'\') AS source_modified, '.
        ($en ? 'COALESCE(o.version,0)' : '0').' AS source_version,
        OCTET_LENGTH(COALESCE(o.data,\'\')) AS source_bytes,
        CASE WHEN OCTET_LENGTH(COALESCE(o.data,\'\'))<='.searchIndexSourceLimit().' THEN COALESCE(o.data,\'\') ELSE \'\' END AS source,
        '.join(',', map { "SUBSTR(o.$_,1,2048) AS $_" } @fields)."
        FROM $table o WHERE ($public) AND o.uid=?".($en ? " AND o.name<>''" : '').' LIMIT 1', @bind);
    return $rows[0];
}

# Pandoc reads markup, not a TeX compiler. Explicit sandboxing prevents \input
# and similar commands from loading files outside the one supplied document.
sub searchIndexText {
    my ($source, $collection) = @_;
    my $pandoc = getConfig('search_pandoc');
    die "Invalid Pandoc path\n" unless $pandoc && $pandoc =~ m{\A/[^\x00-\x1f]+\z} && -x $pandoc;
    die "Index source exceeds limit\n" if length(Encode::encode('UTF-8', $source)) > searchIndexSourceLimit();
    my $dir = File::Temp->newdir('pl-search-XXXXXXXX', TMPDIR => 1);
    my ($input, $output, $errors) = map { "$dir/$_" } qw(input.txt output.txt errors.txt);
    open my $in, '>:encoding(UTF-8)', $input or die "Cannot create index input\n";
    if ($collection eq 'objects') {
        print $in <<'MACROS';
\newcommand{\PMlinkname}[2]{#1}
\newcommand{\PMlinkid}[2]{#1}
\newcommand{\PMlinkexternal}[2]{#1}
\newcommand{\PMlinkescapetext}[1]{#1}
\newcommand{\PMlinkescapephrase}[1]{}
\newcommand{\PMlinkescapeword}[1]{}
MACROS
    }
    print $in $source;
    close $in or die "Cannot write index input\n";
    open my $err, '>', $errors or die "Cannot create index diagnostics\n";
    my ($stdin, $stdout);
    my $pid = IPC::Open3::open3($stdin, $stdout, '>&'.fileno($err), '/usr/bin/timeout',
        '--kill-after=2s', '15s', $pandoc, '--sandbox',
        '--from='.($collection eq 'objects' ? 'latex' : 'html'), '--to=plain', '--wrap=none',
        '--output='.$output, $input);
    close $stdin;
    # stdout is unused with --output; still drain it without accumulating it.
    while (sysread($stdout, my $unused, 4096)) { }
    close $stdout;
    waitpid($pid, 0);
    my $status = $?;
    close $err;
    die "Index parser failed\n" if $status != 0 || !-f $output || -s $output > searchIndexSourceLimit();
    open my $out, '<:raw', $output or die "Cannot read index output\n";
    local $/;
    my $text = Encode::decode('UTF-8', <$out>, Encode::FB_CROAK());
    close $out;
    $text =~ s/[\x00-\x1f\x7f]/ /g;
    $text =~ s/\s+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub searchIndexSave {
    my ($db, $collection, $uid, $record, $body, $status) = @_;
    my $table = nativeSearchIdentifier(searchIndexCollection($collection)->{key});
    my $documents = nativeSearchIdentifier('search_documents_tbl');
    # Re-read after conversion. A changed/deleted/private object is never saved
    # as a current public document; requests also check live ACL and revision.
    my $current = searchIndexRecord($db, $collection, $uid);
    return 0 unless $current && $current->{source_modified} eq $record->{source_modified}
        && $current->{source_version} == $record->{source_version} && $current->{source} eq $record->{source};
    my @fields = $collection eq 'objects' ? qw(title synonyms defines keywords) : qw(title authors keywords);
    my $text = join(' ', map { nativeSearchDisplayText($current->{$_}, 2048) } @fields).' '.$body;
    my $sth = $db->prepare("INSERT INTO $documents
        (tbl,objectid,source_modified,source_version,parser_version,status,indexed_at,body_text,search_text)
        VALUES (?,?,?,?,?,?,NOW(),?,?) ON DUPLICATE KEY UPDATE
        source_modified=VALUES(source_modified),source_version=VALUES(source_version),
        parser_version=VALUES(parser_version),status=VALUES(status),indexed_at=VALUES(indexed_at),
        body_text=VALUES(body_text),search_text=VALUES(search_text)");
    my @bind = ($table, $uid, $record->{source_modified}, $record->{source_version}, searchIndexParserVersion(),
        $status, $body, $text);
    if (($db->{Driver}{Name} || '') eq 'mysql' && !$db->{mysql_enable_utf8} && !$db->{mysql_enable_utf8mb4}) {
        @bind = map { utf8::is_utf8($_) ? Encode::encode('UTF-8', $_) : $_ } @bind;
    }
    $sth->execute(@bind);
    $sth->finish;
    return 1;
}

sub searchIndexPrune {
    my ($db, $limit) = @_;
    my $documents = nativeSearchIdentifier('search_documents_tbl');
    my (@live, @bind);
    for my $collection (@{nativeSearchCollections()}) {
        next if $collection->{value} eq 'all';
        my $table = nativeSearchIdentifier($collection->{key});
        my $public = nativeSearchPublicSql($table, \@bind);
        push @live, "(s.tbl='$table' AND EXISTS (SELECT 1 FROM $table o WHERE o.uid=s.objectid
            AND o.uid>=0 AND ($public)".($collection->{value} eq 'objects' ? " AND o.name<>''" : '').'))';
    }
    my @gone = nativeSearchRows($db, "SELECT s.tbl,s.objectid FROM $documents s WHERE NOT (".
        join(' OR ', @live).') ORDER BY s.tbl,s.objectid LIMIT '.int($limit), @bind);
    for my $row (@gone) {
        my $sth = $db->prepare("DELETE FROM $documents WHERE tbl=? AND objectid=?");
        $sth->execute($row->{tbl}, $row->{objectid});
        $sth->finish;
    }
    return scalar @gone;
}

1;
