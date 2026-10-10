#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use DBI;
use XML::LibXML;
use URI::Escape qw(uri_escape_utf8);
use Encode ();
use Time::HiRes qw(time);
use lib "$FindBin::Bin/../../lib";
use Noosphere::NativeSearch;

my $root = "$FindBin::Bin/../..";
my %config = (template_path => "$root/stemplates", main_url => 'https://physicslibrary.org',
    stemplate_path => "$root/stemplates", template_cmd_prefix => 'NS',
    siteaddrs => {main=>'physicslibrary.org',image=>'images.physicslibrary.org'},
    projname => 'Physics Library', slogan => 'An open source physics library',
    en_tbl => 'objects', papers_tbl => 'papers', books_tbl => 'books', exp_tbl => 'lec',
    index_tbl => 'objindex', acl_tbl => 'acl', acl_tables => {map {$_=>1} qw(objects papers books lec)},
    gmember_tbl => 'group_members', groups_tbl => 'groups', class_tbl => 'classification',
    clinks_tbl => 'catlinks', msc_tbl => 'msc', ns_tbl => 'ns');
my @queries;
{
    package Noosphere;
    sub getConfig { $config{$_[0]} }
    sub readFile {open my $fh,'<',$_[0] or die $!; local $/; <$fh>}
    sub htmlescape { HTML::Entities::encode_entities($_[0], '<>&') }
    sub urlescape { URI::Escape::uri_escape_utf8($_[0]) }
    sub getTypeString { 'Definition' }
    sub getObj { die 'Search invoked article rendering' }
    sub wordIndexEntry { die 'Search rebuilt a cross-reference index' }
    sub irSearch { die 'Search contacted ESSEX' }
    sub getGoogleSearch { die 'Search contacted Google' }
    sub getEncyclopediaCanonicalURL { 'https://physicslibrary.org/encyclopedia/'.URI::Escape::uri_escape_utf8($_[1]{name}).'.html' }
}
my $db = $Noosphere::dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError=>1, PrintError=>0, sqlite_unicode=>1});
# SQLite's built-in LOWER is ASCII-only; mirror the Unicode lowercase supplied
# by the production UTF-8 MariaDB collation for these portable fixtures.
$db->sqlite_create_function('LOWER', 1, sub { defined($_[0]) ? lc($_[0]) : undef });
$db->do('CREATE TABLE objects (uid INTEGER PRIMARY KEY, userid INTEGER, title TEXT, name TEXT, type INTEGER, synonyms TEXT, defines TEXT, keywords TEXT, data TEXT)');
for my $table (qw(books papers lec)) {
    $db->do("CREATE TABLE $table (uid INTEGER PRIMARY KEY, userid INTEGER, title TEXT, authors TEXT, keywords TEXT, data TEXT)");
}
$db->do('CREATE TABLE objindex (tbl TEXT, objectid INTEGER, type INTEGER, title TEXT)');
$db->do('CREATE TABLE acl (tbl TEXT, objectid INTEGER, subjectid INTEGER, user_or_group TEXT, default_or_normal TEXT, _read INTEGER)');
$db->do('CREATE INDEX acl_object ON acl(objectid)');
$db->do('CREATE INDEX concept_object ON objindex(objectid)');
$db->do('CREATE TABLE ns (id INTEGER, name TEXT)');
$db->do("INSERT INTO ns VALUES (1,'msc'),(2,'foreign')");
$db->do('CREATE TABLE msc (uid INTEGER, id TEXT, comment TEXT)');
$db->do('CREATE TABLE classification (tbl TEXT, objectid INTEGER, catid INTEGER, nsid INTEGER, ord INTEGER)');
$db->do('CREATE TABLE catlinks (a INTEGER, b INTEGER, nsa INTEGER, nsb INTEGER)');
$db->do('CREATE TABLE groups (groupid INTEGER)');
$db->do('CREATE TABLE group_members (groupid INTEGER, userid INTEGER)');
sub public {
    my ($table,$uid)=@_;
    $db->do("INSERT INTO acl VALUES (?,?,-1,'u','d',1)",undef,$table,$uid);
}
sub article {
    my ($uid, $title, %extra) = @_;
    my $name = $extra{name} || "Article$uid";
    $db->do('INSERT INTO objects VALUES (?,1,?,?,5,?,?,?,?)',undef,$uid,$title,$name,
        $extra{synonyms},$extra{defines},$extra{keywords},$extra{data} || 'BODY MUST NOT BE SEARCHED');
    public('objects',$uid) unless $extra{private};
    for my $field (['title',1],['synonyms',2],['defines',3]) {
        for my $label (split(/,/, $field->[0] eq 'title' ? $title : ($extra{$field->[0]} || ''))) {
            $label =~ s/^\s+|\s+$//g;
            $db->do('INSERT INTO objindex VALUES (?,?,?,?)',undef,'objects',$uid,$field->[1],$label);
        }
    }
}
article(209,'Vector Triple Product',name=>'VectorTripleProduct',synonyms=>'BACK CAB, vector identity');
article(210,'Scalar Triple Product',name=>'ScalarTripleProduct');
article(211,'Vector Triple Product Exercises');
article(212,'Triple products in mechanics',keywords=>'vector triple product');
article(213,'Calculus of Variations');
article(214,'Calculus of Variations: Functional Evaluation');
article(215,'Calculus of Variations: Euler-Lagrange Equations');
article(216,'Pulleys and Atwood Machines',synonyms=>'Atwood machine');
article(217,'Binary stars',defines=>'center of mass relation');
article(218,'Electromagnetic fields',keywords=>'EM, GPS');
article(219,'Theorem of mechanics',data=>'calculus of variations');
article(220,'100% efficiency');
article(221,'under_score');
article(222,'underXscore');
article(223,'A <script>alert("XSS")</script> & title',keywords=>'safe');
article(224,'Über waves',name=>'ÜberWaves',keywords=>'wave');
article(225,'Euler Lagrange principles');
article(230,'Secret vector triple product',private=>1);
$db->do("INSERT INTO acl VALUES ('objects',230,-1,'u','d',0)");
article(231,'Hidden vector triple product');
$db->do("INSERT INTO acl VALUES ('objects',231,-1,'u','n',0)");
article(232,'Conflicting vector triple product');
$db->do("INSERT INTO acl VALUES ('objects',232,77,'u','d',0)");
article(233,'Group private vector triple product');
$db->do("INSERT INTO groups VALUES (10)");
$db->do("INSERT INTO group_members VALUES (10,-1)");
$db->do("INSERT INTO acl VALUES ('objects',233,10,'g','n',0)");
article(234,'Nameless vector triple product');
$db->do("UPDATE objects SET name='' WHERE uid=234");
for my $spec (['books','Vector Analysis','A. Author'],['papers','Vector Triple Product','B. Researcher'],['lec','Vector Triple Product Lecture','C. Teacher']) {
    $db->do("INSERT INTO $spec->[0] VALUES (209,1,?,?,?,'BODY MUST NOT BE SEARCHED')",undef,$spec->[1],$spec->[2],'vector triple product');
    public($spec->[0],209);
}
$db->do("INSERT INTO papers VALUES (230,1,'Private Vector Triple Product','Secret Author','vector triple product','secret')");
$db->do("INSERT INTO acl VALUES ('papers',230,-1,'u','d',0)");
$db->do("INSERT INTO msc VALUES (1,'02-XX','Mathematical methods in physics'),(2,'02.30.Xx','Calculus of variations'),(3,'02.30.Sa','Functional analysis'),(4,'51.60.+a','Magnetic properties')");
$db->do('INSERT INTO catlinks VALUES (1,2,1,1),(1,3,1,1),(1,4,2,2)');
for my $id (213,214,215) { $db->do("INSERT INTO classification VALUES ('objects',?,2,1,0)",undef,$id); }
$db->do("INSERT INTO classification VALUES ('objects',209,3,1,0),('objects',209,3,1,1),('objects',210,4,2,0),('objects',230,2,1,0)");
$db->do("INSERT INTO classification VALUES ('papers',209,2,1,0),('objects',218,4,1,0)");
$db->{Callbacks} = {prepare=>sub {push @queries,$_[1]; return;}};
sub search {
    my (%params)=@_;
    @queries=();
    local $Noosphere::RequestFormStatus;
    my $html=Noosphere::nativeSearch(\%params,{uid=>-1});
    return ($html,$Noosphere::RequestFormStatus);
}
sub titles {
    my ($html)=@_;
    my $doc=XML::LibXML->load_html(string=>Encode::encode('UTF-8',$html),encoding=>'UTF-8',recover=>2,suppress_errors=>1,suppress_warnings=>1);
    return map {$_->textContent} $doc->findnodes('//ul[@class="pl-native-search-results"]/li/h2/a');
}
sub pager {
    my ($html)=@_;
    my $doc=XML::LibXML->load_html(string=>Encode::encode('UTF-8',$html),encoding=>'UTF-8',recover=>2,suppress_errors=>1,suppress_warnings=>1);
    my @nodes=$doc->findnodes('//nav[@class="pl-native-search-pages"]/*');
    return @nodes;
}
sub page_numbers { return map {0+$_->textContent} grep {$_->textContent =~ /^\d+$/} pager($_[0]); }
my ($html,$status)=search(q=>'vector triple product');
is_deeply([titles($html)],['Vector Triple Product','Vector Triple Product Exercises','Triple products in mechanics'],'exact title first, then title phrase, then keyword');
like($html,qr{href="https://physicslibrary.org/encyclopedia/VectorTripleProduct.html"},'article uses canonical URL');
like($html,qr/Other names:.*BACK CAB/,'alternate labels are visible');
like($html,qr/<mark>vector<\/mark>/i,'terms safely highlighted');
like($html,qr/Showing 1-3 of 3/,'private entries do not enter counts');
like($html,qr/>02\.30\.Sa<\/a>/,'PACS attached to result');
unlike($html,qr/Secret|Hidden|Conflicting|Group private|Nameless|BODY MUST/,'no private metadata or source leaked');
is(scalar(@queries),4,'count, results, batched classification, and bounded related-subject query');
unlike(join(' ',@queries),qr/\bo\.data\b|searchresults|wordidx|\bINSERT\b|\bUPDATE\b/i,'queries never fetch bodies or write search/index state');
for my $q ('Vector Triple Product','VECTOR TRIPLE PRODUCT','"Vector Triple Product"','product vector triple') {
    my ($page)=search(q=>$q);
    is((titles($page))[0],'Vector Triple Product',"title recovered for $q");
}
is((titles((search(q=>'BACK CAB'))[0]))[0],'Vector Triple Product','exact synonym resolves owning article');
is((titles((search(q=>'center of mass relation'))[0]))[0],'Binary stars','defines finds a non-titular concept');
is((titles((search(q=>'Atwood machine'))[0]))[0],'Pulleys and Atwood Machines','singular synonym resolves plural article title');
is_deeply([titles((search(q=>'EM'))[0])],['Electromagnetic fields'],'short keyword does not match inside theorem');
is_deeply([titles((search(q=>'GPS'))[0])],['Electromagnetic fields'],'physics acronym searchable');
is_deeply([titles((search(q=>'100%'))[0])],['100% efficiency'],'percent is literal');
is_deeply([titles((search(q=>'under_score'))[0])],['under_score'],'underscore is literal');
is((titles((search(q=>'Euler-Lagrange'))[0]))[0],'Calculus of Variations: Euler-Lagrange Equations','hyphenated query finds title');
is(scalar(titles((search(q=>'Euler Lagrange'))[0])),2,'punctuation does not block word matching');
my ($quoted)=search(q=>'"Euler Lagrange"');
is(scalar(titles($quoted)),2,'phrase recognizes normalized title hyphen');
my ($calculus)=search(q=>'calculus of variations');
is((titles($calculus))[0],'Calculus of Variations','known subject title appears first');
like($calculus,qr/Related subjects.*02\.30\.Xx.*Calculus of variations/s,'PACS labels suggest a subject independently of document ranking');
like($calculus,qr/subject=02\.30\.Xx/,'subject suggestion can steer to classified entries');
my ($scope)=search(subject=>'02-XX');
is(scalar(titles($scope)),4,'parent subject includes exact descendants and deduplicates repeated classifications');
unlike($scope,qr/>Scalar Triple Product<\/a>/,'foreign namespace closure does not match PACS');
my ($leaf)=search(subject=>'51.60.+a');
is_deeply([titles($leaf)],['Electromagnetic fields'],'leaf subject works without reflexive closure link');
like($leaf,qr/subject=51\.60\.%2Ba/,'PACS plus safely percent encoded');
is_deeply([titles((search(subject=>'pacs:51.60.+a'))[0])],['Electromagnetic fields'],'display PACS alias resolves legacy msc namespace');
my ($combined)=search(q=>'vector',subject=>'02-XX');
is_deeply([titles($combined)],['Vector Triple Product'],'query and subject intersect');
my ($all)=search(q=>'vector triple product',collection=>'all');
is(scalar(titles($all)),6,'unified search keeps distinct table/id resources without duplicate concept results');
like($all,qr/href="\/\?op=getobj&amp;from=papers&amp;id=209"/,'generic result uses valid object route');
unlike($all,qr/Secret Author|Private Vector/,'generic ACL also enforced');
is_deeply([titles((search(q=>'Researcher',collection=>'papers'))[0])],['Vector Triple Product'],'author finds a paper');
is_deeply([titles((search(q=>'vector',collection=>'papers',subject=>'02-XX'))[0])],['Vector Triple Product'],'PACS works across collections');
my ($xss)=search(q=>'safe');
like($xss,qr/&lt;script&gt;/,'result title HTML escaped');
unlike($xss,qr/<script>/,'metadata is not executable markup');
my ($q_xss)=search(q=>'<script>');
like($q_xss,qr/value="&lt;script&gt;"/,'query input escaped');
unlike($q_xss,qr/<script>/,'highlighting cannot inject markup');
my ($unicode)=search(q=>Encode::encode('UTF-8','Über'));
is_deeply([titles($unicode)],['Über waves'],'UTF-8 byte query and Unicode metadata display');
like($unicode,qr/%C3%9CberWaves\.html/,'Unicode canonical name encoded once');
my ($empty)=search();
like($empty,qr/Enter a search term/,'empty state');
is(scalar(@queries),0,'empty search does no corpus queries');
my ($none)=search(q=>'definitelymissing');
like($none,qr/No matching entries/,'zero results state');
is(scalar(@queries),3,'no per-result lookups for empty result set');
for my $params (
    {q=>'x'x257}, {q=>'a b c d e f g h i'}, {q=>'"unclosed'}, {q=>'""'},
    {q=>['vector']}, {q=>"bad\0input"}, {q=>"\xff"}, {q=>'---'},
    {q=>'vector',collection=>'mail'}, {q=>'vector',collection=>'objects;DROP'},
    {q=>'vector',offset=>'-1'}, {q=>'vector',offset=>'2001'}, {q=>'vector',offset=>'1 OR 1=1'}) {
    my ($page,$code)=search(%$params);
    is($code,400,'invalid input has 400 status');
    like($page,qr/Check your search/,'invalid input has actionable error');
    is(scalar(@queries),0,'invalid input never reaches SQL');
}
for my $subject ('not-a-code','99.99.Zz',"02-XX' OR 1=1") {
    my ($page,$code)=search(q=>'vector',subject=>$subject);
    is($code,400,'invalid/unknown subject rejected instead of broadening search');
    is(scalar(titles($page)),0,'no unfiltered results on bad subject');
}
my ($injection)=search(q=>"x' OR 1=1 --");
is(scalar(titles($injection)),0,'query cannot change SQL structure');
for my $i (300..344) {article($i,sprintf('Batch entry %03d',$i));}
my ($first)=search(q=>'Batch');
is(scalar(titles($first)),20,'page size fixed at twenty');
like($first,qr/Showing 1-20 of 45/,'first page count');
like($first,qr/offset=20/,'next page preserves filters');
my ($second)=search(q=>'Batch',offset=>20);
is((titles($second))[0],'Batch entry 320','stable second page');
my ($last)=search(q=>'Batch',offset=>2000);
is(scalar(titles($last)),5,'out-of-range offset clamps to last page');
like($last,qr/Showing 41-45 of 45/,'clamped page counts correct');
for my $spec ([$first,1],[$second,2],[$last,3]) {
    is_deeply([page_numbers($spec->[0])],[1,2,3],'small result sets show every real page without phantom links');
    is_deeply([map {0+$_->textContent} grep {($_->getAttribute('aria-current') || '') eq 'page'} pager($spec->[0])],
        [$spec->[1]],'exactly the current page is marked');
}
is(scalar(pager($html)),0,'single-page results do not show pagination');
is(scalar(pager($none)),0,'empty results do not show pagination');
$db->begin_work;
for my $i (500..734) {
    article($i,sprintf('Pagerwindow entry %03d',$i));
    $db->do("INSERT INTO classification VALUES ('objects',?,3,1,0)",undef,$i);
}
$db->commit;
my %pager_options=(q=>'Pagerwindow',collection=>'objects',subject=>'02.30.Sa');
my ($pager_first)=search(%pager_options);
my ($pager_second)=search(%pager_options,offset=>20);
my ($pager_middle)=search(%pager_options,offset=>100);
my ($pager_last)=search(%pager_options,offset=>220);
is_deeply([page_numbers($pager_first)],[1..10],'first page shows ten page numbers');
is_deeply([page_numbers($pager_second)],[1..10],'early pages retain the same ten numbers');
is_deeply([page_numbers($pager_middle)],[2..11],'middle window follows the current page');
is_deeply([page_numbers($pager_last)],[3..12],'last window retains ten numbers');
is(scalar(titles($pager_last)),15,'partial last page retains the existing page size');
for my $spec ([$pager_first,1],[$pager_middle,6],[$pager_last,12]) {
    is_deeply([map {0+$_->textContent} grep {($_->getAttribute('aria-current') || '') eq 'page'} pager($spec->[0])],
        [$spec->[1]],'ten-number pager marks only the current page');
}
for my $link (grep {$_->nodeName eq 'a'} pager($pager_middle)) {
    like($link->getAttribute('href'),qr/collection=objects&offset=\d+&op=search&q=Pagerwindow&subject=02\.30\.Sa/,
        'numbered and previous/next links preserve query, collection, and subject');
}
ok(!grep({($_->getAttribute('rel') || '') eq 'prev'} pager($pager_first)),'first page has no previous link');
ok(!grep({($_->getAttribute('rel') || '') eq 'next'} pager($pager_last)),'last page has no next link');
$db->begin_work;
for my $i (5000..7020) {article($i,sprintf('Capwindow entry %04d',$i));}
$db->commit;
my ($pager_cap)=search(q=>'Capwindow',offset=>2000);
is_deeply([page_numbers($pager_cap)],[92..101],'ten-number window respects the maximum offset');
ok(!grep({($_->getAttribute('rel') || '') eq 'next'} pager($pager_cap)),'offset cap has no unreachable next page');
for my $table (qw(objects objindex acl classification)) {
    my $id=$table eq 'objects' ? 'uid' : 'objectid';
    $db->do("DELETE FROM $table WHERE $id BETWEEN 500 AND 734 OR $id BETWEEN 5000 AND 7020");
}
article(250,'Fresh metadata title',keywords=>'instant-update');
is((titles((search(q=>'instant-update'))[0]))[0],'Fresh metadata title','new article immediately searchable without index rebuild');
$db->do("UPDATE objects SET keywords='revisedword' WHERE uid=250");
is(scalar(titles((search(q=>'instant-update'))[0])),0,'edits remove stale keyword matches immediately');
is((titles((search(q=>'revisedword'))[0]))[0],'Fresh metadata title','updated keyword searchable immediately');
$db->do("UPDATE acl SET _read=0 WHERE tbl='objects' AND objectid=250");
is(scalar(titles((search(q=>'revisedword'))[0])),0,'newly private article disappears immediately');
{
    local $Noosphere::dbh=bless {},'BrokenNativeSearchDB';
    my @warnings;
    local $SIG{__WARN__}=sub {push @warnings,@_};
    my ($page,$code)=search(q=>'vector');
    is($code,503,'database failure has service-unavailable status');
    like($page,qr/Search is temporarily unavailable/,'database error friendly');
    unlike($page,qr/password|internal SQL|driver secret/,'database internals not leaked');
    like(join('',@warnings),qr/PL_SEARCH database failure/,'sanitized diagnostic');
}
{
    package BrokenNativeSearchDB;
    sub prepare { die 'driver secret / internal SQL / password' }
}
for my $params ({q=>'vector',cx=>'old'}, {q=>'vector',sa=>'Search'}, {q=>'vector'}, {op=>'frontpage',q=>'vector'}) {
    Noosphere::normalizeNativeSearchRequest($params);
    is($params->{op},'search','legacy root query routes natively');
}
for my $op (qw(listobj getobj pacssearch edit search)) {
    my $p={op=>$op,q=>'vector'};
    Noosphere::normalizeNativeSearchRequest($p);
    is($p->{op},$op,'explicit operation not hijacked');
}
my $homepage={}; Noosphere::normalizeNativeSearchRequest($homepage);
ok(!exists($homepage->{op}),'homepage without query remains homepage');
my ($legacy)=search(term=>'Vector Triple Product');
is((titles($legacy))[0],'Vector Triple Product','old op=search term parameter still works');
my $route_source=do {open my $fh,'<',"$root/lib/Noosphere/Dispatch.pm" or die $!;local $/;<$fh>};
like($route_source,qr/'search'\s*=>\s*\\&nativeSearch/,'actual dispatch routes to native handler');
my $handler_source=do {open my $fh,'<',"$root/lib/Noosphere.pm" or die $!;local $/;<$fh>};
like($handler_source,qr/sub getViewTemplateContent.*?normalizeNativeSearchRequest\(\$params\).*?dispatch/s,'real view dispatch normalizes old Google links');
my ($dispatch)=$route_source =~ /^(sub dispatch \{.*?)(?=^# the registry)/ms;
my ($view)=$handler_source =~ /^(sub getViewTemplateContent \{.*?)(?=^sub |\z)/ms;
eval "package Noosphere; our (%HANDLERS, \$RequestFormValidated); $dispatch $view";
die $@ if $@;
{
    package Noosphere;
    sub requestFormGuard { undef }
    package Apache2::RequestUtil;
    sub request { bless {}, 'NativeSearchRequest' }
    package NativeSearchRequest;
    sub method { 'GET' }
}
{
    no warnings 'once';
    local %Noosphere::HANDLERS=(search=>\&Noosphere::nativeSearch);
    my $old={cx=>'old-google-id',cof=>'FORID:10',ie=>'UTF-8',q=>'vector triple product',sa=>'Search'};
    my $page=Noosphere::getViewTemplateContent($old,{uid=>-1},{});
    is((titles($page))[0],'Vector Triple Product','legacy URL passes through real view dispatcher to native results');
    is($old->{op},'search','normalization updates operation before header indexing policy');
}
my ($policy)=$handler_source =~ /^(sub applyIndexingPolicy \{.*?)(?=^sub |\z)/ms;
eval "package Noosphere; $policy";die $@ if $@;
my $request=bless {},'NativeSearchHeaders';
ok(Noosphere::applyIndexingPolicy($request,'search'),'native results remain noindex');
is($request->{'X-Robots-Tag'},'noindex, follow','native search header policy');
{
    package NativeSearchHeaders;
    sub headers_out {$_[0]}
    sub set {$_[0]{$_[1]}=$_[2]}
}
if ($ENV{NATIVE_SEARCH_QA_DIR}) {
    require File::Path;
    require Noosphere::TemplateNS;
    File::Path::make_path($ENV{NATIVE_SEARCH_QA_DIR});
    for my $spec (['results', $html], ['subject',$scope], ['all',$all], ['empty',$empty], ['none',$none], ['calculus',$calculus], ['pages',$first],
        ['pager-first',$pager_first],['pager-middle',$pager_middle],['pager-last',$pager_last],['pager-cap',$pager_cap]) {
        my $header=TemplateNS->new('header.html');
        $header->setKey('q', $spec->[0] eq 'calculus' ? 'Calculus of Variations' : '');
        my $page='';
        my $sidebar='<style>.qa-sidebar { background:#eff4f8; border:1px solid #c9d7e3; font:.88rem Arial; }.qa-sidebar h2 { background:#003399; color:white; font-size:1rem; line-height:1.2; margin:0; padding:.15rem .5rem; }.qa-sidebar a { display:block; color:#174e80; padding:.4rem .5rem; }</style><nav class="qa-sidebar"><h2>Main Menu</h2><a href="/encyclopedia">Encyclopedia</a><a href="/?op=browse&amp;from=papers">Papers</a><a href="/?op=browse&amp;from=books">Books</a><a href="/?op=browse&amp;from=lec">Lectures</a></nav>';
        Template->new({INCLUDE_PATH=>$config{template_path}})->process('view.tt',{
            native_search=>1,no_index=>1,title=>'Search Physics Library',site_name=>'Physics Library',
            header=>$header->expand(),sidebar=>$sidebar,content=>$spec->[1]},\$page) or die Template->error();
        open my $out,'>:encoding(UTF-8)',"$ENV{NATIVE_SEARCH_QA_DIR}/$spec->[0].html" or die $!;
        print $out $page;
        close $out;
    }
}
if ($ENV{NATIVE_SEARCH_BENCH}) {
    $db->begin_work;
    for my $i (1000..2499) {article($i,"Mechanics example $i",keywords=>'vector mechanics orbit');}
    $db->commit;
    my @elapsed;
    for (1..50) {
        my $start=time;
        search(q=>'mechanics',collection=>'all');
        push @elapsed,time-$start;
    }
    @elapsed=sort {$a<=>$b} @elapsed;
    diag(sprintf('SQLite metadata benchmark: 1500 synthetic articles, 50 searches, median=%.3fs p95=%.3fs (not a production MariaDB benchmark)', $elapsed[25],$elapsed[47]));
}
done_testing;
