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
eval 'package Noosphere; use strict; our $dbh; '.$listing;
die $@ if $@;

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
    like($book,qr/op=addobj;to=books/,'books retain generic creation route');
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
