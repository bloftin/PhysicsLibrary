package Noosphere;
use strict;
use Encode ();
use URI;
use XML::Writer;

sub getArticleSitemapURL {
    my $main = getConfig('main_url');
    die "Invalid sitemap origin\n" unless defined($main) && $main =~ /\A[\x21-\x7e]+\z/;
    my $uri = URI->new($main);
    die "Invalid sitemap origin\n" unless $uri->scheme && $uri->scheme =~ /\Ahttps?\z/
        && $uri->host && !defined($uri->userinfo)
        && !defined($uri->query) && !defined($uri->fragment);
    $main =~ s{/+$}{};
    return $main . '/sitemap.xml';
}

sub getArticleRobotsText {
    my $text = getConfig('robotstxt') || '';
    $text .= "\n" unless $text =~ /\n\z/;
    return $text . 'Sitemap: ' . getArticleSitemapURL() . "\n";
}

sub getArticleLastmod {
    my ($value, $now) = @_;
    return '' unless defined($value) && !ref($value)
        && $value =~ /\A(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](\d{2})(?::?(\d{2}))?)?)?\z/;
    my ($year, $month, $day, $hour, $minute, $second, $zone_hour, $zone_minute) = ($1, $2, $3, $4, $5, $6, $7, $8);
    return '' if $year < 1 || $month < 1 || $month > 12 || $day < 1;
    my @days = (31, 28 + ($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0)),
        31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    return '' if $day > $days[$month - 1]
        || (defined($hour) && ($hour > 23 || $minute > 59 || $second > 59))
        || (defined($zone_hour) && ($zone_hour > 14 || ($zone_minute || 0) > 59
            || ($zone_hour == 14 && ($zone_minute || 0) != 0)));
    my $date = sprintf('%04d-%02d-%02d', $year, $month, $day);
    my @today = gmtime(defined($now) ? $now : time);
    return '' if $date gt sprintf('%04d-%02d-%02d', $today[5] + 1900, $today[4] + 1, $today[3]);
    # The DB timestamp has no reliable timezone contract; publish only its date.
    return $date;
}

sub getArticleSitemap {
    my ($db) = @_;
    getArticleSitemapURL(); # Validate the configured origin, never the request Host.
    my $table = getConfig('en_tbl');
    my $where = "o.uid >= 0 AND o.name <> ''";
    my @tables = ($table);
    if (getConfig('acl_tables')->{$table}) {
        my $acl = getConfig('acl_tbl');
        my $members = getConfig('gmember_tbl');
        my $groups = getConfig('groups_tbl');
        push @tables, $acl, $members, $groups;
        # Require a world-readable default and conservatively exclude conflicting
        # defaults or a matching anonymous denial, irrespective of DB tie ordering.
        $where .= qq{
            AND EXISTS (SELECT 1 FROM $acl a
                WHERE a.tbl = ? AND a.objectid = o.uid
                AND a.default_or_normal = 'd' AND a._read <> 0)
            AND NOT EXISTS (SELECT 1 FROM $acl a
                WHERE a.tbl = ? AND a.objectid = o.uid
                AND (a._read = 0 OR a._read IS NULL)
                AND (
                    a.default_or_normal = 'd'
                    OR (a.default_or_normal = 'n' AND (
                        (a.user_or_group = 'u' AND a.subjectid = -1)
                        OR (a.user_or_group = 'g' AND (
                            a.subjectid = -1 OR EXISTS (
                                SELECT 1 FROM $members m JOIN $groups g
                                    ON g.groupid = m.groupid
                                WHERE m.userid = -1 AND m.groupid = a.subjectid
                            )
                        ))
                    ))
                )
            )
        };
    }
    die "Invalid sitemap table\n" if grep { !defined($_) || !/\A[A-Za-z_][A-Za-z0-9_]*\z/ } @tables;

    local $db->{PrintError} = 0;
    local $db->{RaiseError} = 1;
    my $sth = $db->prepare("SELECT DISTINCT o.uid, o.name, o.modified FROM $table o WHERE $where ORDER BY o.uid LIMIT 50001");
    die "Sitemap prepare failed\n" unless $sth;
    my @bind = getConfig('acl_tables')->{$table} ? ($table, $table) : ();
    die "Sitemap query failed\n" unless defined $sth->execute(@bind);

    my $xml = '';
    my $writer = XML::Writer->new(OUTPUT => \$xml, DATA_MODE => 1, DATA_INDENT => 2);
    $writer->xmlDecl('UTF-8');
    $writer->startTag('urlset', xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9');
    my (%seen, $count);
    while (my $rec = $sth->fetchrow_hashref()) {
        die "Sitemap requires splitting\n" if ++$count > 50000;
        my $url = getEncyclopediaCanonicalURL($table, $rec);
        next unless length $url;
        die "Sitemap URL too long\n" if length($url) >= 2048;
        next if $seen{$url}++;
        $writer->startTag('url');
        $writer->dataElement('loc', $url);
        my $lastmod = getArticleLastmod($rec->{modified});
        $writer->dataElement('lastmod', $lastmod) if length $lastmod;
        $writer->endTag('url');
        die "Sitemap requires splitting\n" if length($xml) > 50 * 1024 * 1024 - 1024;
    }
    die "Sitemap fetch failed\n" if $sth->err;
    $sth->finish();
    $writer->endTag('urlset');
    $writer->end();
    return Encode::encode('UTF-8', $xml);
}

sub serveArticleSitemap {
    my ($req) = @_;
    setStandardSecurityHeaders($req);
    $req->headers_out->set('Cache-Control' => 'no-store');
    my ($status, $type, $body) = (200, 'application/xml;charset=UTF-8', '');
    if ($req->method ne 'GET' && $req->method ne 'HEAD') {
        ($status, $type, $body) = (405, 'text/plain;charset=UTF-8', "Use GET or HEAD.\n");
        $req->headers_out->set('Allow' => 'GET, HEAD');
    } else {
        my $ok = eval {
            my $db = dbConnect();
            die "Sitemap database unavailable\n" unless $db;
            $body = getArticleSitemap($db);
            1;
        };
        unless ($ok) {
            warn "Article sitemap generation failed\n";
            ($status, $type, $body) = (503, 'text/plain;charset=UTF-8', "Sitemap temporarily unavailable.\n");
            $req->headers_out->set('Retry-After' => '300');
        }
    }
    $req->status($status);
    $req->content_type($type);
    $req->headers_out->set('Content-Length' => length($body));
    $req->print($body) unless $req->method eq 'HEAD';
}

1;
