#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use DBI;
use Template;

my $root = "$FindBin::Bin/../..";
sub read_file {
    open my $fh, '<', $_[0] or die $!;
    local $/;
    return <$fh>;
}
my $source = read_file("$root/lib/Noosphere/GenericObject.pm");
my ($listing) = $source =~ /^(sub genericListTableIsAllowed \{.*?)(?=^sub renderGeneric)/ms;
die 'listing functions not found' unless $listing;
my ($browse) = $source =~ /^(sub browseGeneric \{.*?)(?=^sub |\z)/ms;
die 'browse function not found' unless $browse;

{
    package XSLTemplate;
    sub new { bless {}, shift }
    sub addText {}
    sub setKey {}
}
{
    package Noosphere;
    our $dbh;
    our %pager;
    sub getConfig {
        return { en_tbl=>'objects', user_tbl=>'users',
            generic_schema=>{books=>{}, papers=>{}, lec=>{}} }->{$_[0]};
    }
    sub dbGetRows {
        my $sth = shift;
        my $rows = $sth->fetchall_arrayref({});
        $sth->finish;
        return @$rows;
    }
    sub sq { my $s=shift; $s =~ s/'/''/g; return $s }
    sub dbRowCount {
        my ($table,$where)=@_;
        return $dbh->selectrow_array("SELECT COUNT(*) FROM $table".($where ? " WHERE $where" : ''));
    }
    sub dbSelect {
        my (undef,$q)=@_;
        my $sql="SELECT $q->{WHAT} FROM $q->{FROM}";
        $sql.=" WHERE $q->{WHERE}" if $q->{WHERE};
        $sql.=" ORDER BY $q->{'ORDER BY'} LIMIT $q->{LIMIT} OFFSET $q->{OFFSET}";
        my $sth=$dbh->prepare($sql); $sth->execute;
        return (1,$sth);
    }
    sub ymd { return substr($_[0],0,10) }
    sub lookupfield { return 'owner <one>' }
    sub classstring { return 'PACS 02.30' }
    sub getTypeString { return 'Example' }
    sub getIsA { return ucfirst($_[0]) }
    sub getPager { %pager=%{$_[0]}; return '<p>Result pages</p>' }
    sub errorMessage { return $_[0] }
}
eval 'package Noosphere; use strict; our $dbh; '.$listing.$browse;
die $@ if $@;

my $handler = read_file("$root/lib/Noosphere.pm");
my ($indexing) = $handler =~ /^(sub applyIndexingPolicy \{.*?)(?=^sub |\z)/ms;
die 'indexing policy not found' unless $indexing;
eval 'package Noosphere; '.$indexing;
die $@ if $@;
{
    package PapersIndexingRequest;
    sub new { bless {}, shift }
    sub headers_out { return $_[0] }
    sub set { $_[0]->{$_[1]} = $_[2] }
}

$Noosphere::dbh=DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError=>1,PrintError=>0});
my $db=$Noosphere::dbh;
$db->do('CREATE TABLE users (uid INTEGER, username TEXT)');
$db->do('INSERT INTO users VALUES (1, ?)', undef, 'owner <one>');
$db->do('CREATE TABLE objects (uid INTEGER, userid INTEGER, type INTEGER, title TEXT, synonyms TEXT, defines TEXT, keywords TEXT, data TEXT, created TEXT, modified TEXT)');
my @titles=('Newton\'s laws', 'Wave <motion>', '100% efficiency', 'under_score', 'UnderXscore', 'Empty fields');
for my $i (0..$#titles) {
    $db->do('INSERT INTO objects VALUES (?,1,1,?,?,?,?,?,?,?)', undef,
        $i+1, $titles[$i], $i==0 ? 'dynamics' : undef,
        $i==1 ? 'wave flux' : undef, $i==2 ? 'thermal' : undef,
        $i==0 ? 'force equals mass times acceleration' : '',
        sprintf('2026-01-%02d', $i+1), sprintf('2026-02-%02d', 10-$i));
}
$db->do('CREATE TABLE books (uid INTEGER, userid INTEGER, title TEXT, authors TEXT, keywords TEXT, data TEXT, comments TEXT, created TEXT, modified TEXT)');
$db->do("INSERT INTO books VALUES (1,1,'Mechanics','A. Author','','','', '2026-01-01', '2026-01-01')");
for my $id (2..7) {
    $db->do('INSERT INTO books VALUES (?,1,?,?,?,?,?,?,?)', undef,
        $id, $id == 7 ? 'Book <7>' : "Book $id", 'B. Author & Co.',
        $id == 7 ? 'quantum' : '', $id == 7 ? 'spin' : '',
        $id == 7 ? 'reviewnote' : '',
        sprintf('2026-01-%02d', $id), sprintf('2026-01-%02d', $id));
}
$db->do('CREATE TABLE papers AS SELECT * FROM books WHERE 0');
for my $id (1..7) {
    $db->do('INSERT INTO papers VALUES (?,1,?,?,?,?,?,?,?)', undef,
        $id, "Paper $id", 'A. Author', '', '', '',
        sprintf('2026-01-%02d', $id), sprintf('2026-01-%02d', $id));
}

for my $table (qw(objects books papers lec)) {
    ok(Noosphere::genericListTableIsAllowed($table), "$table can be listed");
}
ok(!Noosphere::genericListTableIsAllowed('users'), 'account table cannot be listed');
ok(!Noosphere::genericListTableIsAllowed('objects; DROP TABLE users'), 'table parameter is allowlisted');
for my $test (
    ["Newton's",1], ['DYNAMICS',1], ['wave flux',1], ['thermal',1],
    ['acceleration',1], ['owner <one>',6], ['%',1], ['_',1],
    ["' OR 1=1 --",0], ['not present',0], ['',6]
) {
    my ($count,@rows)=Noosphere::encyclopediaListRows($test->[0], 'title', 20, 0);
    is($count,$test->[1], "search matches expected count: $test->[0]");
    is(scalar @rows,$count,'count and result query agree');
}
my ($total,@page)=Noosphere::encyclopediaListRows('', 'created_desc', 2, 2);
is($total,6,'pagination retains total');
is_deeply([map {$_->{uid}} @page],[4,3],'pagination applies stable descending order and offset');
(undef,@page)=Noosphere::encyclopediaListRows('', 'modified_desc', 2, 0);
is_deeply([map {$_->{uid}} @page],[1,2],'latest edits sort');
(undef,@page)=Noosphere::encyclopediaListRows('', 'authors', 1, -10);
is($page[0]->{uid},6,'unsupported author sort falls back without querying an absent column');
(undef,@page)=Noosphere::encyclopediaListRows('', 'title; DROP TABLE objects', 1, 0);
is($page[0]->{uid},6,'invalid sort falls back safely');

require Template;
my $new=Template->can('new');
my $html;
{
    no warnings qw(redefine once);
    local *Template::new=sub {
        my ($class,$args)=@_;
        return $new->($class,{%$args, INCLUDE_PATH=>"$root/stemplates"});
    };
    my $user={prefs=>{pagelength=>20}};
    my $params={op=>'listobj',from=>'objects',q=>'  Wave <motion>  ',sort=>'title',offset=>0};
    $html=Noosphere::listGeneric($params,$user);
    like($html,qr/Search Encyclopedia/,'encyclopedia list heading');
    like($html,qr/Wave &lt;motion&gt;/,'article title and search input escaped');
    like($html,qr/owner &lt;one&gt;/,'owner escaped');
    unlike($html,qr/Authors:|Uploaded on:|op=addobj/,'no generic-only metadata or add route');
    like($html,qr/>Example</,'article type shown');
    like($html,qr/op=adden/,'correct article creation route');
    like($html,qr{href="/encyclopedia"},'alphabetical index remains accessible');
    like($html,qr/Browse by subject/,'subject browser remains accessible');
    like($html,qr/pl-encyclopedia-list-toolbar/,'encyclopedia search uses the modern result toolbar');
    is($Noosphere::pager{q},'Wave <motion>','pager retains trimmed search');
    is($Noosphere::pager{from},'objects','pager retains object domain');
    is($Noosphere::pager{total},1,'filtered total sent to pager');
    $params={op=>'listobj',from=>'objects',q=>'owner',sort=>'modified_desc',group=>'letter',offset=>2};
    Noosphere::listGeneric($params,$user);
    is($Noosphere::pager{sort},'title','letter grouping uses title order');
    is($Noosphere::pager{group},'letter','pager retains grouping');
    is($Noosphere::pager{offset},2,'pager retains offset');
    Noosphere::listGeneric({op=>'listobj',from=>'objects',q=>'0'},$user);
    is($Noosphere::pager{q},'0','zero is a valid search term');
    my $empty=Noosphere::listGeneric({op=>'listobj',from=>'objects',q=>'no-such-article'},$user);
    like($empty,qr/No articles match these filters/,'empty results keep the form and clear link');
    like($empty,qr/>Clear filters<\/a>/,'clear action for filtered results');
    my $book=Noosphere::listGeneric({op=>'listobj',from=>'books',q=>'Author',sort=>'authors'},$user);
    like($book,qr/Authors: A\. Author/,'book search still uses generic author metadata');
    like($book,qr/op=addobj&amp;to=books/,'books retain generic creation route');
    my $books_params={op=>'browse',from=>'books'};
    my $books=Noosphere::browseGeneric($books_params,$user);
    like($books,qr/<h1>Search Books<\/h1>/,'Books landing renders the modern search page');
    like($books,qr/aria-current="page">Browse and search/,'Books browse and search tab is selected');
    like($books,qr/value="created_desc"\s+selected[^>]*>latest additions first/,'Books defaults to newest additions');
    like($books,qr/Book &lt;7&gt;.*Book 6.*Book 5.*Book 4.*Book 3/s,'Books are newest first with escaped titles');
    unlike($books,qr/>Mechanics<|>Book 2</,'Books first page respects the page size');
    like($books,qr/Showing 1-5 of 7 matching books/,'Books count and range reflect the collection');
    like($books,qr/Authors: B\. Author &amp; Co\./,'Books authors are escaped');
    like($books,qr/owner &lt;one&gt;/,'Books owner is escaped');
    like($books,qr/op=getobj&amp;from=books&amp;id=7/,'Books rows link to book records');
    like($books,qr/op=addobj&amp;to=books">Add Book/,'Books keeps its creation action');
    like($books,qr/op=pacsbrowse&amp;from=books/,'Books retains subject browsing');
    like($books,qr/Uploaded 2026-01-07.*Classification: PACS 02\.30/,'Books keeps upload date and classification');
    like($books,qr/name="from" value="books"/,'Books search form stays in its collection');
    is($Noosphere::pager{op},'listobj','Books pager uses the canonical list route');
    is($Noosphere::pager{from},'books','Books pager retains its collection');
    is($Noosphere::pager{sort},'created_desc','Books pager retains newest-first order');
    my $books_request=PapersIndexingRequest->new();
    ok(Noosphere::applyIndexingPolicy($books_request,$books_params->{op}),'Books landing uses the listing noindex policy');
    is($books_request->{'X-Robots-Tag'},'noindex, follow','Books landing receives noindex header');
    my $book_page=Noosphere::browseGeneric({op=>'browse',from=>'books',q=>'Author',sort=>'created_asc',offset=>1},$user);
    like($book_page,qr/Book 2.*Book 3.*Book 4.*Book 5.*Book 6/s,'Books honors explicit ordering and offset');
    is($Noosphere::pager{q},'Author','Books pager preserves its search');
    is($Noosphere::pager{offset},1,'Books pager preserves its offset');
    Noosphere::browseGeneric({op=>'browse',from=>'books',group=>'letter'},$user);
    is($Noosphere::pager{group},'letter','Books retains letter grouping');
    is($Noosphere::pager{sort},'title','Books grouping sorts alphabetically');
    for my $term ('quantum', 'spin', 'reviewnote') {
        my $matches=Noosphere::listGeneric({op=>'listobj',from=>'books',q=>$term},$user);
        like($matches,qr/Showing 1-1 of 1 matching book\./,"Books searches topic metadata: $term");
    }
    my $empty_books=Noosphere::browseGeneric({op=>'browse',from=>'books',q=>'<absent>'},$user);
    like($empty_books,qr/No books match these filters/,'Books has an empty state');
    like($empty_books,qr/name="q" value="&lt;absent&gt;"/,'Books preserves and escapes unmatched query');
    like($empty_books,qr{href="/\?op=listobj&amp;from=books">Clear filters},'Books clear filters stays in the collection');
    if ($ENV{PL_BOOKS_PREVIEW}) {
        open my $out, '>', $ENV{PL_BOOKS_PREVIEW} or die $!;
        print $out '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>', $books, '</body></html>';
        close $out;
    }
    my $papers_params={op=>'browse',from=>'papers'};
    my $papers=Noosphere::browseGeneric($papers_params,$user);
    like($papers,qr/Search Papers/,'Papers landing renders the browse and search page');
    like($papers,qr/aria-current="page">Browse and search/,'browse and search navigation is selected');
    like($papers,qr/value="created_desc"\s+selected[^>]*>latest additions first/,'latest additions is the default selection');
    like($papers,qr/Paper 7.*Paper 6.*Paper 5.*Paper 4.*Paper 3/s,'newest papers appear first');
    unlike($papers,qr/Paper [12]</,'first page respects the listing page size');
    is($Noosphere::pager{op},'listobj','pagination uses the canonical listing operation');
    is($Noosphere::pager{from},'papers','pagination stays in the papers collection');
    is($Noosphere::pager{sort},'created_desc','pager retains latest-first ordering');
    my $request=PapersIndexingRequest->new();
    ok(Noosphere::applyIndexingPolicy($request,$papers_params->{op}),'Papers landing keeps listing noindex policy');
    is($request->{'X-Robots-Tag'},'noindex, follow','Papers landing receives the noindex header');
    my $filtered={op=>'browse',from=>'papers',q=>'Author',sort=>'created_asc',offset=>1};
    my $older=Noosphere::browseGeneric($filtered,$user);
    like($older,qr/Paper 2.*Paper 3.*Paper 4/s,'explicit oldest-first order and offset are honored');
    is($Noosphere::pager{q},'Author','landing alias preserves the search query');
    is($Noosphere::pager{offset},1,'landing alias preserves pagination offset');
    Noosphere::browseGeneric({op=>'browse',from=>'papers',group=>'letter'},$user);
    is($Noosphere::pager{group},'letter','landing alias preserves grouping');
    is($Noosphere::pager{sort},'title','letter grouping still uses alphabetical order');
    for my $table (qw(lec)) {
        my $other={op=>'browse',from=>$table};
        my $landing=Noosphere::browseGeneric($other,$user);
        is($other->{op},'browse',"$table landing keeps its original route");
        unlike($landing,qr/Search Papers/,"$table landing is not replaced by paper search");
    }
    is(Noosphere::listGeneric({from=>'users'},$user),'Unknown object type.','invalid table rejected by handler');
}
my $index=read_file("$root/lib/Noosphere/Encyclopedia.pm");
like($index,qr/encyclopediaindex\.tt/,'index uses the dedicated encyclopedia presentation template');
my $index_template=read_file("$root/stemplates/encyclopediaindex.tt");
like($index_template,qr/id="encyclopedia-search" type="search" name="q"/,'index exposes query field');
like($index_template,qr/name="op" value="listobj"/,'index search uses list route');
like($index_template,qr/Physics Library Encyclopedia/,'index template has an encyclopedia heading');
like($index_template,qr/Browse by subject/,'index template retains the subject browser');
like($index_template,qr/aria-label="Alphabetical index"/,'index template labels the alphabetical navigation');
like($index_template,qr/pl-encyclopedia-index/,'index template provides the modern index layout');
if ($ENV{PL_BROWSE_PREVIEW}) {
    open my $out, '>', $ENV{PL_BROWSE_PREVIEW} or die $!;
    print $out '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>', $html, '</body></html>';
    close $out;
}
done_testing();
