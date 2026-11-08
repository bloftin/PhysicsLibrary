package Noosphere;
use strict;
use Noosphere::RequestForm;

our ($dbh, $stats, $RequestFormStatus);

sub discussionTables {
    return map { getConfig($_) } grep {
        my $table = getConfig($_);
        defined($table) && !ref($table) && $table =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
    } qw(en_tbl books_tbl papers_tbl exp_tbl forum_tbl news_tbl polls_tbl req_tbl cor_tbl collab_tbl);
}

sub discussionIdValid {
    return defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[0-9]{1,10}\z/ && $_[0] <= 2147483647;
}

sub discussionTableAllowed {
    my ($table) = @_;
    return 0 unless defined($table) && !ref($table);
    return scalar grep { $_ eq $table } discussionTables();
}

sub discussionParentReadable {
    my ($table, $id, $viewer) = @_;
    return 0 unless discussionTableAllowed($table) && discussionIdValid($id);
    return eval {
        my $row = dbSelectRowBound($dbh, "SELECT uid FROM $table WHERE uid = ?", $id);
        $row && hasPermissionTo($table, $id, $viewer || {uid => -1}, 'read') ? 1 : 0;
    } || 0;
}

sub discussionRawMessage {
    my ($id) = @_;
    return undef unless discussionIdValid($id);
    return dbSelectRowBound($dbh, 'SELECT * FROM messages WHERE uid = ?', $id);
}

sub discussionSameParent {
    my ($left, $right) = @_;
    return ref($left) eq 'HASH' && ref($right) eq 'HASH' &&
        defined($left->{tbl}) && defined($right->{tbl}) && $left->{tbl} eq $right->{tbl} &&
        discussionIdValid($left->{objectid}) && discussionIdValid($right->{objectid}) &&
        $left->{objectid} == $right->{objectid} &&
        discussionIdValid($left->{threadid}) && discussionIdValid($right->{threadid}) &&
        $left->{threadid} == $right->{threadid};
}

# Validate the full ancestor chain before exposing a message or accepting a reply.
sub discussionMessageReadable {
    my ($id, $viewer) = @_;
    return eval {
        my $row = discussionRawMessage($id);
        return undef unless $row && discussionParentReadable($row->{tbl}, $row->{objectid}, $viewer);
        return discussionMessageChainValid($row) ? $row : undef;
    };
}

# Scoped list queries can validate a freshly fetched row without rereading it.
sub discussionMessageChainValid {
    my ($row) = @_;
    return 0 unless ref($row) eq 'HASH';
    return eval {
        my ($current, %seen) = ($row);
        for (1 .. 128) {
            return 0 unless discussionIdValid($current->{uid}) && !$seen{$current->{uid}}++;
            return 0 if defined($current->{visible}) && !$current->{visible} &&
                $current->{tbl} ne (getConfig('collab_tbl') || '');
            if (defined($current->{replyto}) && $current->{replyto} eq '-1') {
                return discussionSameParent($row, $current) && $current->{threadid} == $current->{uid}
                    ? scalar(keys %seen) : 0;
            }
            $current = discussionRawMessage($current->{replyto});
            return 0 unless discussionSameParent($row, $current);
        }
        return 0;
    } || 0;
}

# SQL predicates use only allowlisted configuration identifiers, never request data.
sub discussionIdentityWhere {
    my ($alias) = @_;
    die "Invalid message alias\n" unless $alias =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return qq{EXISTS (SELECT 1 FROM messages ds_root WHERE ds_root.uid=$alias.threadid
        AND ds_root.threadid=ds_root.uid AND ds_root.replyto=-1
        AND ds_root.tbl=$alias.tbl AND ds_root.objectid=$alias.objectid)
        AND (($alias.replyto=-1 AND $alias.uid=$alias.threadid) OR EXISTS
        (SELECT 1 FROM messages ds_parent WHERE ds_parent.uid=$alias.replyto
        AND ds_parent.uid<>$alias.uid AND ds_parent.tbl=$alias.tbl
        AND ds_parent.objectid=$alias.objectid AND ds_parent.threadid=$alias.threadid))};
}

sub discussionPublicWhere {
    my ($alias) = @_;
    my @parents;
    for my $table (discussionTables()) {
        my $public = '1=1';
        if ((getConfig('acl_tables') || {})->{$table}) {
            my ($acl, $members, $groups) = map { getConfig($_) } qw(acl_tbl gmember_tbl groups_tbl);
            next if grep { !defined($_) || ref($_) || !/\A[A-Za-z_][A-Za-z0-9_]*\z/ } ($acl, $members, $groups);
            # Same conservative anonymous-read policy used by native search/sitemap.
            $public = qq{EXISTS (SELECT 1 FROM $acl a WHERE a.tbl='$table' AND a.objectid=p.uid
                AND a.default_or_normal='d' AND a._read<>0) AND NOT EXISTS
                (SELECT 1 FROM $acl a WHERE a.tbl='$table' AND a.objectid=p.uid
                AND (a._read=0 OR a._read IS NULL) AND (a.default_or_normal='d'
                OR (a.default_or_normal='n' AND ((a.user_or_group='u' AND a.subjectid=-1)
                OR (a.user_or_group='g' AND (a.subjectid=-1 OR EXISTS
                (SELECT 1 FROM $members m JOIN $groups g ON g.groupid=m.groupid
                WHERE m.userid=-1 AND m.groupid=a.subjectid)))))))};
        }
        $public .= ' AND p.published=1' if $table eq (getConfig('collab_tbl') || '');
        push @parents, "($alias.tbl='$table' AND EXISTS (SELECT 1 FROM $table p WHERE p.uid=$alias.objectid AND $public))";
    }
    return '0=1' unless @parents;
    return "$alias.visible=1 AND (".discussionIdentityWhere($alias).') AND ('.join(' OR ', @parents).')';
}

sub discussionWatchReadable {
    my ($table, $id, $viewer) = @_;
    return 0 unless defined($table) && !ref($table);
    return discussionMessageReadable($id, $viewer) ? 1 : 0 if $table eq 'messages';
    return discussionParentReadable($table, $id, $viewer) if discussionTableAllowed($table);
    return 0;
}

sub discussionPostDestination {
    my ($params, $viewer) = @_;
    return unless ($viewer->{uid} || 0) > 0;
    my %values = %$params;
    my $parent;
    if (defined($values{replyto}) && $values{replyto} ne '') {
        $parent = discussionMessageReadable($values{replyto}, $viewer);
        return unless $parent && discussionMessageChainValid($parent) < 128;
        @values{qw(from id)} = @{$parent}{qw(tbl objectid)};
    } else {
        return unless discussionParentReadable($values{from}, $values{id}, $viewer);
    }
    return (\%values, $parent);
}

sub discussionNoticeReadable {
    my ($id, $viewer) = @_;
    my $links = getConfig('olinks_tbl');
    return 0 unless discussionIdValid($id) && defined($links) && $links =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    my $sth = $dbh->prepare("SELECT destid FROM $links WHERE srctbl='notices' AND srcid=? AND desttbl='messages'");
    $sth->execute($id);
    my $rows = $sth->fetchall_arrayref();
    $sth->finish();
    for my $row (@$rows) { return 0 unless discussionMessageReadable($row->[0], $viewer); }
    return 1;
}

sub deleteDiscussionState {
    my ($table, $id) = @_;
    die "Invalid discussion target\n" unless discussionTableAllowed($table) && discussionIdValid($id);
    my ($watches, $seen) = map { getConfig($_) } qw(watch_tbl lseen_tbl);
    die "Invalid discussion state tables\n" if grep { !defined($_) || !/\A[A-Za-z_][A-Za-z0-9_]*\z/ } ($watches, $seen);
    my $sth = $dbh->prepare('SELECT uid FROM messages WHERE tbl=? AND objectid=?');
    $sth->execute($table, $id);
    my $rows = $sth->fetchall_arrayref();
    $sth->finish();
    for my $row (@$rows) {
        dbExecuteBound($dbh, "DELETE FROM $watches WHERE tbl='messages' AND objectid=?", $row->[0]);
        deleteNotices('messages', $row->[0]);
    }
    dbExecuteBound($dbh, "DELETE FROM $watches WHERE tbl=? AND objectid=?", $table, $id);
    dbExecuteBound($dbh, "DELETE FROM $seen WHERE tbl=? AND objid=?", $table, $id);
    dbExecuteBound($dbh, 'DELETE FROM messages WHERE tbl=? AND objectid=?', $table, $id);
    $stats->invalidate('latest_messages');
}

sub removeDiscussionMessage {
    my ($params, $viewer) = @_;
    my $admin = getConfig('access_admin');
    return errorMessage('Only administrators may remove message content.') unless
        defined($admin) && $admin =~ /\A[1-9][0-9]*\z/ &&
        ($viewer->{uid} || 0) > 0 && ($viewer->{data}{access} || 0) >= $admin;
    my $row = discussionMessageReadable($params->{id}, $viewer);
    return errorMessage('Message not available.') unless $row;
    my $req = Apache2::RequestUtil->request;
    my $blocked = requestFormGuard($req, {%$params, op => 'removemsg'}, $viewer);
    return $blocked if defined $blocked;
    return requestFormConfirmation({op => 'removemsg', id => $row->{uid}}, requestFormToken($viewer))
        if $req->method eq 'GET';
    return requestFormFailure(405, 'This action requires a submitted form.') unless $req->method eq 'POST';
    my $changed = dbExecuteBound($dbh,
        'UPDATE messages SET subject=?, body=? WHERE uid=? AND tbl=? AND objectid=?',
        '[Removed message]', '[Message content removed by an administrator.]', $row->{uid}, $row->{tbl}, $row->{objectid});
    return errorMessage('Message could not be updated.') unless defined $changed;
    deleteNotices('messages', $row->{uid});
    $stats->invalidate('latest_messages');
    $req->headers_out->set('Location' => '/?op=getmsg&id='.$row->{uid});
    $req->headers_out->set('Cache-Control' => 'no-store');
    $RequestFormStatus = 303;
    return '<p>Message content removed. Replies have been kept.</p>';
}

1;
