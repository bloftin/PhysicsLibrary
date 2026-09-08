#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
require Noosphere::PDF;

our $dbh;
my $owner = {active => 1, username => 'maintainer', forename => 'Public', surname => 'Name'};
my @queries;
my @author_requests;
my $rendered;
my $finished = 0;
my $document = "\\documentclass{article}\n\\begin{document}\nBody.\n\\end{document}\n";
sub getConfig {
    return {en_tbl => 'objects', collab_tbl => 'collab', user_tbl => 'users',
        base_dir => '/missing', main_url => 'https://physicslibrary.org', build_timeout => 1}->{$_[0]};
}
sub dbSelect { push @queries, $_[1]; return (1, bless({}, 'OwnerStatement')); }
{ package OwnerStatement;
  sub fetchrow_hashref { return $owner; }
  sub finish { $finished++; }
}
sub pdfDocumentPresentation { return Noosphere::pdfDocumentPresentation(@_); }
sub getcacheflags { return (0, 0); }
sub setbuildflag_on {}
sub setbuildflag_off {}
sub setvalidflag_on {}
sub setvalidflag_off {}
sub cleanCache {}
sub cacheFileBox {}
sub writeLinksToFile {}
sub getSynonymsList { return []; }
sub getDefinesList { return []; }
sub classstring { return ''; }
sub normalize { return 'Title'; }
sub prepareEntryForRendering { return ($document, ''); }
sub prepareCollabForRendering { return ($document, ''); }
sub renderLaTeX { $rendered = $_[2]; return 1; }
sub getAuthorList {
    push @author_requests, [@_];
    return ({userid => 2, username => 'contributor'});
}

# Exercise both real cache branches; only the database and converter are stubbed.
open my $in, '<', "$FindBin::Bin/../../lib/Noosphere/Cache.pm" or die $!;
my $source = do { local $/; <$in> };
close $in;
for my $name (qw(cacheObject prepareCachedPDF)) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
    die "$name not found" unless defined $sub;
    eval $sub;
    die $@ if $@;
}
my $rec = {uid => 1142, userid => 1, title => 'Article', name => 'Article', version => 1};
for my $table (qw(objects collab)) {
    for my $method (qw(pdf png make4ht l2h src)) {
        @queries = ();
        @author_requests = ();
        my $debug = '';
        my $ok;
        {
            open my $capture, '>', \$debug or die $!;
            local *STDOUT = $capture;
            $ok = cacheObject($table, $rec, $method);
        }
        is($ok, 1, "$table/$method cache build succeeds");
        if ($method eq 'pdf') {
            like($rendered, qr/Maintained by Public Name/, "$table PDF receives public attribution");
            like($rendered, qr/\Qfrom=$table&id=1142\E/, "$table PDF links to the correct object type");
            is_deeply(\@queries, [{WHAT => 'username, forename, surname, active', FROM => 'users', WHERE => 'uid=1'}],
                'fetches only attribution fields for the recorded owner');
            is_deeply(\@author_requests, [[$table, 1142]], 'uses the existing object author history');
            like($rendered, qr/Article authors.*contributor \(user 2\)/s, 'records contributors separately from the maintainer');
            like($rendered, qr/License notice:.*physicslibrary\.org\/\?op=license/, 'links the site license notice');
        } else {
            is($rendered, $document, "$table/$method source is unchanged");
            is(scalar(@queries), 0, "$table/$method does not query profile data");
            is(scalar(@author_requests), 0, "$table/$method does not query contributor history");
        }
    }
}
is($finished, 2, 'owner queries are finished');
$owner = undef;
my $missing = prepareCachedPDF($document, 'objects', $rec);
like($missing, qr/Maintained by \(user 1\)/, 'missing profile falls back to the known user id');
@queries = ();
my $unowned = prepareCachedPDF($document, 'objects', {%$rec, userid => 0});
is(scalar(@queries), 0, 'unowned articles do not query user zero');
unlike($unowned, qr/Maintained by/, 'unowned articles do not acquire a fictitious author');
done_testing();
