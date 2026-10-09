package Noosphere;
use strict;
use Encode ();
use HTML::Entities qw(encode_entities);
use URI::Escape qw(uri_escape_utf8);
use Template;
use Time::HiRes qw(time);
our ($dbh, $NoosphereTitle, $NoosphereCanonical, $RequestFormStatus);

sub normalizeNativeSearchRequest {
    my ($params) = @_;
    return if ref($params->{op});
    if ((!defined($params->{op}) || $params->{op} eq '' || $params->{op} eq 'frontpage')
        && defined($params->{q})) {
        $params->{op} = 'search';
    }
}

sub nativeSearchCollections {
    return [
        {value => 'objects', label => 'Encyclopedia', key => 'en_tbl'},
        {value => 'papers', label => 'Papers', key => 'papers_tbl'},
        {value => 'books', label => 'Books', key => 'books_tbl'},
        {value => 'lec', label => 'Lectures', key => 'exp_tbl'},
        {value => 'all', label => 'All library collections'},
    ];
}

sub nativeSearchInput {
    my ($value, $limit) = @_;
    return '' unless defined $value;
    die "Invalid search input\n" if ref($value) || length($value) > $limit * 4;
    $value = Encode::decode('UTF-8', $value, Encode::FB_CROAK()) unless utf8::is_utf8($value);
    die "Invalid search input\n" if length($value) > $limit || $value =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    $value =~ s/^\s+|\s+$//g;
    return $value;
}

sub nativeSearchQuery {
    my ($query) = @_;
    my @atoms;
    my $quoted = 0;
    my $phrase = '';
    while ($query =~ /("|[^"]+)/g) {
        if ($1 eq '"') {
            $quoted = !$quoted;
            if (!$quoted) {
                die "Empty search phrase\n" unless $phrase =~ /\S/;
                push @atoms, $phrase;
                $phrase = '';
            }
        } elsif ($quoted) { $phrase .= $1; }
        else { push @atoms, grep { length } split(/\s+/, $1); }
    }
    die "Unclosed search phrase\n" if $quoted;
    # Treat common title punctuation as word boundaries, without interpreting
    # user input as SQL, a regular expression, or ESSEX/boolean query syntax.
    my $normalize = sub {
        my $text = shift;
        $text =~ tr/-:;,()/      /;
        $text =~ s/\s+/ /g;
        $text =~ s/^ | $//g;
        return $text;
    };
    @atoms = grep { length } map { $normalize->($_) } @atoms;
    my %seen;
    @atoms = grep { !$seen{lc($_)}++ } @atoms;
    die "Too many search terms\n" if @atoms > 8;
    return {atoms => \@atoms, phrase => $normalize->(join(' ', @atoms))};
}

sub nativeSearchIdentifier {
    my ($key) = @_;
    my $table = getConfig($key);
    die "Invalid search configuration\n" unless defined($table) && $table =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $table;
}

sub nativeSearchSqlText {
    my ($column) = @_;
    my $sql = "COALESCE($column, '')";
    for my $punct ('-', ':', ';', ',', '(', ')') { $sql = "REPLACE($sql, '$punct', ' ')"; }
    for (1 .. 3) { $sql = "REPLACE($sql, '  ', ' ')"; }
    return "LOWER(TRIM($sql))";
}

sub nativeSearchLike {
    my ($term) = @_;
    $term =~ s/([!%_])/!$1/g;
    return $term;
}

sub nativeSearchMatch {
    my ($column, $atom, $bind) = @_;
    my $text = nativeSearchSqlText($column);
    my $escaped = nativeSearchLike(lc($atom));
    if (length($atom) <= 2 && $atom =~ /\A[\p{L}\p{N}]+\z/) {
        push @$bind, lc($atom), "$escaped %", "% $escaped", "% $escaped %";
        return "($text = ? OR $text LIKE ? ESCAPE '!' OR $text LIKE ? ESCAPE '!' OR $text LIKE ? ESCAPE '!')";
    }
    push @$bind, "%$escaped%";
    return "$text LIKE ? ESCAPE '!'";
}

# Public library search uses the sitemap's conservative anonymous ACL policy.
# Titles, counts, and metadata of private objects never enter a result set.
sub nativeSearchPublicSql {
    my ($table, $bind) = @_;
    return '1=1' unless getConfig('acl_tables')->{$table};
    my $acl = nativeSearchIdentifier('acl_tbl');
    my $members = nativeSearchIdentifier('gmember_tbl');
    my $groups = nativeSearchIdentifier('groups_tbl');
    push @$bind, $table, $table;
    return qq{EXISTS (SELECT 1 FROM $acl a WHERE a.tbl=? AND a.objectid=o.uid
        AND a.default_or_normal='d' AND a._read<>0)
        AND NOT EXISTS (SELECT 1 FROM $acl a WHERE a.tbl=? AND a.objectid=o.uid
        AND (a._read=0 OR a._read IS NULL) AND (a.default_or_normal='d'
        OR (a.default_or_normal='n' AND ((a.user_or_group='u' AND a.subjectid=-1)
        OR (a.user_or_group='g' AND (a.subjectid=-1 OR EXISTS (
            SELECT 1 FROM $members m JOIN $groups g ON g.groupid=m.groupid
            WHERE m.userid=-1 AND m.groupid=a.subjectid)))))))};
}

sub nativeSearchRows {
    my ($db, $sql, @bind) = @_;
    # The legacy mysql connection does not enable Unicode decoding. Do not
    # double-encode on connections which explicitly enable Unicode instead.
    if (($db->{Driver}{Name} || '') eq 'mysql' && !$db->{mysql_enable_utf8} && !$db->{mysql_enable_utf8mb4}) {
        @bind = map { defined($_) && utf8::is_utf8($_) ? Encode::encode('UTF-8', $_) : $_ } @bind;
    }
    my $sth = $db->prepare($sql) or die "Search prepare failed\n";
    die "Search execute failed\n" unless defined $sth->execute(@bind);
    my @rows;
    while (my $row = $sth->fetchrow_hashref()) { push @rows, $row; }
    die "Search fetch failed\n" if $sth->err;
    $sth->finish();
    return @rows;
}

sub nativeSearchSubject {
    my ($db, $code) = @_;
    return undef unless length $code;
    $code =~ s/^pacs://i;
    die "Invalid PACS code\n" unless $code =~ /\A[0-9]{2}[A-Za-z0-9.+-]{0,18}\z/;
    my $msc = nativeSearchIdentifier('msc_tbl');
    my $ns = nativeSearchIdentifier('ns_tbl');
    # PACS is displayed under that name but stored in the legacy msc namespace,
    # as in Classification::storageclassns('pacs').
    my @rows = nativeSearchRows($db, "SELECT m.uid, m.id, m.comment, n.id AS nsid FROM $msc m
        JOIN $ns n ON LOWER(n.name)='msc' WHERE LOWER(m.id)=LOWER(?) LIMIT 2", $code);
    die "Unknown PACS code\n" unless @rows == 1;
    return $rows[0];
}

sub nativeSearchSql {
    my ($options) = @_;
    my (@result_parts, @count_parts, @result_bind, @count_bind);
    my $index = nativeSearchIdentifier('index_tbl');
    for my $collection (@{nativeSearchCollections()}) {
        next if $collection->{value} eq 'all';
        next unless $options->{collection} eq 'all' || $options->{collection} eq $collection->{value};
        my $table = nativeSearchIdentifier($collection->{key});
        my $en = $collection->{value} eq 'objects';
        my @fields = $en ? qw(title synonyms defines keywords) : qw(title authors keywords);
        my (@where_bind, @rank_bind);
        my @where = ('o.uid>=0', nativeSearchPublicSql($table, \@where_bind));
        push @where, "o.name<>''" if $en;
        for my $atom (@{$options->{query}{atoms}}) {
            push @where, '(' . join(' OR ', map { nativeSearchMatch("o.$_", $atom, \@where_bind) } @fields) . ')';
        }
        if (my $subject = $options->{subject}) {
            my $class = nativeSearchIdentifier('class_tbl');
            my $links = nativeSearchIdentifier('clinks_tbl');
            push @where, "EXISTS (SELECT 1 FROM $class c WHERE c.tbl=? AND c.objectid=o.uid
                AND c.nsid=? AND (c.catid=? OR EXISTS (SELECT 1 FROM $links l
                    WHERE l.a=? AND l.b=c.catid AND l.nsa=? AND l.nsb=c.nsid)))";
            push @where_bind, $table, $subject->{nsid}, $subject->{uid}, $subject->{uid}, $subject->{nsid};
        }
        my @ranks;
        my $phrase = $options->{query}{phrase};
        if (length $phrase) {
            push @ranks, nativeSearchSqlText('o.title').' = ? THEN 1000';
            push @rank_bind, lc($phrase);
            if ($en) {
                for my $spec ([2, 900], [3, 850]) {
                    push @ranks, "EXISTS (SELECT 1 FROM $index i WHERE i.tbl=? AND i.objectid=o.uid
                        AND i.type=? AND ".nativeSearchSqlText('i.title')."=?) THEN $spec->[1]";
                    push @rank_bind, $table, $spec->[0], lc($phrase);
                }
            }
            push @ranks, nativeSearchMatch('o.title', $phrase, \@rank_bind).' THEN 800';
            my @title_terms = map { nativeSearchMatch('o.title', $_, \@rank_bind) } @{$options->{query}{atoms}};
            push @ranks, '('.join(' AND ', @title_terms).') THEN 600';
            for my $spec ($en ? (['defines', 500], ['synonyms', 450]) : (['authors', 450])) {
                push @ranks, nativeSearchMatch("o.$spec->[0]", $phrase, \@rank_bind)." THEN $spec->[1]";
            }
            push @ranks, nativeSearchMatch('o.keywords', $phrase, \@rank_bind).' THEN 300';
        }
        my $rank = @ranks ? 'CASE WHEN '.join(' WHEN ', @ranks).' ELSE 200 END' : '0';
        my $where = join(' AND ', map { "($_)" } @where);
        my $name = $en ? 'o.name' : "''";
        my $type = $en ? 'o.type' : '0';
        my $synonyms = $en ? "SUBSTR(o.synonyms,1,2048)" : "''";
        my $defines = $en ? "SUBSTR(o.defines,1,2048)" : "''";
        my $authors = $en ? "''" : 'SUBSTR(o.authors,1,512)';
        push @result_parts, "SELECT '$table' AS tbl, '$collection->{value}' AS collection,
            o.uid, SUBSTR(o.title,1,512) AS title, $name AS name, $type AS type,
            $synonyms AS synonyms, $defines AS defines, $authors AS authors,
            SUBSTR(o.keywords,1,1024) AS keywords, $rank AS score FROM $table o WHERE $where";
        push @count_parts, "SELECT o.uid FROM $table o WHERE $where";
        push @result_bind, @rank_bind, @where_bind;
        push @count_bind, @where_bind;
    }
    return (join(' UNION ALL ', @result_parts), \@result_bind,
        'SELECT COUNT(*) AS total FROM ('.join(' UNION ALL ', @count_parts).') matches', \@count_bind);
}

sub nativeSearchDisplayText {
    my ($value, $limit) = @_;
    $value = '' unless defined $value;
    $value = Encode::decode('UTF-8', $value, Encode::FB_DEFAULT()) unless utf8::is_utf8($value);
    $value =~ s/\s+/ /g;
    return length($value) > $limit ? substr($value, 0, $limit - 3).'...' : $value;
}

sub nativeSearchHighlight {
    my ($value, $atoms) = @_;
    my @terms = sort { length($b) <=> length($a) } grep { length } @$atoms;
    return encode_entities($value, '<>&"\'') unless @terms;
    my $pattern = join('|', map { quotemeta($_) } @terms);
    my ($html, $end) = ('', 0);
    while ($value =~ /($pattern)/ig) {
        my ($start, $stop, $match) = ($-[0], $+[0], $1);
        $html .= encode_entities(substr($value, $end, $start - $end), '<>&"\'');
        $html .= '<mark>'.encode_entities($match, '<>&"\'').'</mark>';
        $end = $stop;
    }
    return $html.encode_entities(substr($value, $end), '<>&"\'');
}

sub nativeSearchURL {
    my ($options, %change) = @_;
    my %params = (op => 'search', q => $options->{q}, collection => $options->{collection},
        subject => $options->{subject} ? $options->{subject}{id} : '', %change);
    return '/?'.join('&', map { uri_escape_utf8($_).'='.uri_escape_utf8($params{$_}) }
        sort grep { defined($params{$_}) && length($params{$_}) } keys %params);
}

sub nativeSearch {
    my ($params, $user) = @_;
    $NoosphereTitle = 'Search Physics Library';
    $NoosphereCanonical = '';
    my $started = time;
    my $options;
    my $error = '';
    my (@results, @subjects);
    my ($total, $offset) = (0, 0);
    eval {
        my $q = nativeSearchInput(defined($params->{q}) ? $params->{q} : $params->{term}, 256);
        my $collection = nativeSearchInput($params->{collection}, 16) || 'objects';
        die "Invalid collection\n" unless grep { $_->{value} eq $collection } @{nativeSearchCollections()};
        my $subject_code = nativeSearchInput($params->{subject}, 24);
        my $raw_offset = nativeSearchInput($params->{offset}, 5);
        die "Invalid offset\n" if length($raw_offset) && ($raw_offset !~ /\A[0-9]+\z/ || $raw_offset > 2000);
        $offset = int(($raw_offset || 0) / 20) * 20;
        $options = {q => $q, collection => $collection, query => nativeSearchQuery($q)};
        die "Empty search terms\n" if length($q) && !@{$options->{query}{atoms}};
        $options->{subject_code} = $subject_code;
        1;
    } or do { $error = 'Check your search: use up to 256 characters and 8 terms, close any quotation marks, and select a valid collection and PACS code.'; $RequestFormStatus = 400; };
    if (!$error && (length($options->{q}) || length($options->{subject_code}))) {
        eval {
            local $dbh->{RaiseError} = 1;
            local $dbh->{PrintError} = 0;
            $options->{subject} = nativeSearchSubject($dbh, $options->{subject_code});
            my ($sql, $bind, $count_sql, $count_bind) = nativeSearchSql($options);
            my @count = nativeSearchRows($dbh, $count_sql, @$count_bind);
            $total = $count[0]{total};
            $offset = $total ? int(($total - 1) / 20) * 20 : 0 if $offset >= $total;
            @results = nativeSearchRows($dbh, "SELECT * FROM ($sql) matches ORDER BY score DESC, LOWER(title), collection, uid LIMIT 20 OFFSET $offset", @$bind);
            my %labels = map { $_->{value} => $_->{label} } @{nativeSearchCollections()};
            for my $row (@results) {
                for my $field (qw(title name synonyms defines keywords authors)) {
                    $row->{$field} = nativeSearchDisplayText($row->{$field}, $field eq 'title' || $field eq 'name' ? 512 : 420);
                }
                $row->{href} = $row->{collection} eq 'objects' ? getEncyclopediaCanonicalURL($row->{tbl}, $row)
                    : '/?op=getobj&from='.uri_escape_utf8($row->{tbl}).'&id='.$row->{uid};
                $row->{label} = $row->{collection} eq 'objects' ? getTypeString($row->{type}) : $labels{$row->{collection}};
                $row->{title_html} = nativeSearchHighlight($row->{title}, $options->{query}{atoms});
                $row->{metadata} = [map { {label => $_->[1], html => nativeSearchHighlight($row->{$_->[0]}, $options->{query}{atoms})} }
                    grep { length($row->{$_->[0]}) } (['synonyms', 'Other names'], ['defines', 'Defines'], ['keywords', 'Keywords'], ['authors', 'Authors'])];
            }
            if (@results) {
                my $class = nativeSearchIdentifier('class_tbl');
                my $msc = nativeSearchIdentifier('msc_tbl');
                my $ns = nativeSearchIdentifier('ns_tbl');
                my @pairs;
                my $where = join(' OR ', map { push @pairs, $_->{tbl}, $_->{uid}; '(c.tbl=? AND c.objectid=?)' } @results);
                my @classes = nativeSearchRows($dbh, "SELECT c.tbl, c.objectid, m.id, m.comment FROM $class c
                    JOIN $ns n ON n.id=c.nsid AND LOWER(n.name)='msc' JOIN $msc m ON m.uid=c.catid
                    WHERE $where ORDER BY c.ord, m.id LIMIT 201", @pairs);
                my (%classmap, %seen_class);
                for my $c (@classes) {
                    next if $seen_class{"$c->{tbl}:$c->{objectid}:$c->{id}"}++;
                    push @{$classmap{"$c->{tbl}:$c->{objectid}"}}, {id => $c->{id}, comment => nativeSearchDisplayText($c->{comment}, 200),
                        href => nativeSearchURL($options, subject => $c->{id}, q => '')};
                }
                $_->{classes} = $classmap{"$_->{tbl}:$_->{uid}"} || [] for @results;
            }
            if (length($options->{q})) {
                my $msc = nativeSearchIdentifier('msc_tbl');
                my @bind;
                my $where = join(' AND ', map { '('.nativeSearchMatch('m.comment', $_, \@bind).' OR '.nativeSearchMatch('m.id', $_, \@bind).')' } @{$options->{query}{atoms}});
                @subjects = nativeSearchRows($dbh, "SELECT m.id, m.comment FROM $msc m WHERE $where ORDER BY m.id LIMIT 5", @bind);
                for my $subject (@subjects) {
                    $subject->{comment} = nativeSearchDisplayText($subject->{comment}, 200);
                    $subject->{href} = nativeSearchURL($options, subject => $subject->{id}, q => '');
                }
            }
            1;
        } or do {
            my $failure = $@;
            @results = (); @subjects = (); $total = 0;
            if ($failure =~ /(?:Invalid|Unknown) PACS code/) {
                $error = 'That PACS code was not found. Check the code or browse by subject.';
                $RequestFormStatus = 400;
            } else {
                warn "PL_SEARCH database failure\n";
                $error = 'Search is temporarily unavailable. Please try again shortly.';
                $RequestFormStatus = 503;
            }
        };
    }
    $options ||= {q => '', collection => 'objects', query => {atoms => []}};
    $params->{q} = $options->{q};
    my $pages = int(($total + 19) / 20);
    my $page = int($offset / 20) + 1;
    my @page_links = map { {number => $_, current => $_ == $page,
        href => nativeSearchURL($options, offset => ($_ - 1) * 20)} }
        grep { $_ >= 1 && $_ <= $pages && ($_ - 1) * 20 <= 2000 } ($page - 2 .. $page + 2);
    my $subject = $options->{subject};
    $subject->{comment} = nativeSearchDisplayText($subject->{comment}, 200) if $subject;
    my $html = '';
    Template->new({INCLUDE_PATH => getConfig('template_path')})->process('nativesearch.tt', {
        %$options, error => $error, results => \@results, subjects => \@subjects,
        total => $total, start => $total ? $offset + 1 : 0, end => $offset + scalar(@results),
        has_search => length($options->{q}) || length($options->{subject_code} || ''),
        collections => nativeSearchCollections(), page_links => \@page_links,
        previous => $offset ? nativeSearchURL($options, offset => $offset - 20) : '',
        next => $offset + 20 < $total && $offset < 2000 ? nativeSearchURL($options, offset => $offset + 20) : '',
        remove_subject => nativeSearchURL($options, subject => ''),
    }, \$html) || die "Search template failed\n";
    my $elapsed = time - $started;
    warn sprintf("PL_SEARCH slow seconds=%.3f collection=%s query_chars=%d results=%d\n", $elapsed, $options->{collection}, length($options->{q}), scalar(@results)) if $elapsed > .5;
    return $html;
}

1;
