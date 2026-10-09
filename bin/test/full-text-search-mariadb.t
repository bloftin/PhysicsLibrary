#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use DBI;
use Encode ();
use IPC::Open3;
use Symbol qw(gensym);
use Time::HiRes qw(time);
use lib "$FindBin::Bin/../../lib";
use Noosphere::NativeSearch;
use Noosphere::SearchIndex;

# This test creates/drops fixture tables in an explicitly supplied disposable
# database. Never point it at the production database.
plan skip_all=>'Set FULLTEXT_TEST_DSN to a disposable MariaDB database ending in _test'
    unless ($ENV{FULLTEXT_TEST_DSN} || '') =~ /\Adbi:(?:mysql|MariaDB):database=[a-z0-9_]+_test;/;
my $mysql_driver = $ENV{FULLTEXT_TEST_DSN} =~ /\Adbi:mysql:/;
my %connect_options = (RaiseError=>1,PrintError=>0);
$connect_options{mysql_enable_utf8mb4}=1 if $mysql_driver;
my $db=$Noosphere::dbh=DBI->connect($ENV{FULLTEXT_TEST_DSN}, undef, undef,
    \%connect_options);
$db->do('SET NAMES utf8mb4') if $mysql_driver;
my $root="$FindBin::Bin/../..";
my %config=(template_path=>"$root/stemplates",en_tbl=>'objects',books_tbl=>'books',papers_tbl=>'papers',exp_tbl=>'lec',
    index_tbl=>'objindex',acl_tbl=>'acl',acl_tables=>{map{$_=>1}qw(objects books papers lec)},
    gmember_tbl=>'group_members',groups_tbl=>'groups',class_tbl=>'classification',clinks_tbl=>'catlinks',msc_tbl=>'msc',ns_tbl=>'ns',
    search_documents_tbl=>'search_documents',native_fulltext_enabled=>1,search_pandoc=>$ENV{SEARCH_TEST_PANDOC} || '/usr/bin/pandoc');
{
    package Noosphere;
    sub getConfig { $config{$_[0]} }
    sub getTypeString { 'Definition' }
    sub readFile { open my $fh,'<',$_[0] or die $!; local $/; <$fh> }
    sub htmlescape { HTML::Entities::encode_entities($_[0], '<>&') }
    sub urlescape { URI::Escape::uri_escape_utf8($_[0]) }
    sub getEncyclopediaCanonicalURL { '/encyclopedia/'.$_[1]{name}.'.html' }
    sub renderLaTeX { die 'Search invoked rendering' }
}
my @tables=qw(search_documents objects books papers lec objindex acl group_members groups classification catlinks msc ns);
$db->do("DROP TABLE IF EXISTS $_") for @tables;
$db->do('CREATE TABLE objects (uid BIGINT PRIMARY KEY,title TEXT,name TEXT,type INT,synonyms TEXT,defines TEXT,keywords TEXT,data MEDIUMTEXT,modified DATETIME,version INT) ENGINE=InnoDB CHARACTER SET utf8mb4');
for(qw(books papers lec)) { $db->do("CREATE TABLE $_ (uid BIGINT PRIMARY KEY,title TEXT,authors TEXT,keywords TEXT,data TEXT,modified DATETIME) ENGINE=InnoDB CHARACTER SET utf8mb4"); }
$db->do('CREATE TABLE objindex (tbl VARCHAR(64),objectid BIGINT,type INT,title TEXT)');
$db->do('CREATE TABLE acl (tbl VARCHAR(64),objectid BIGINT,subjectid INT,user_or_group CHAR(1),default_or_normal CHAR(1),_read INT,KEY(tbl,objectid))');
$db->do('CREATE TABLE group_members (groupid INT,userid INT)');
$db->do('CREATE TABLE groups (groupid INT)');
$db->do('CREATE TABLE classification (tbl VARCHAR(64),objectid BIGINT,nsid INT,catid INT,ord INT)');
$db->do('CREATE TABLE catlinks (a INT,b INT,nsa INT,nsb INT)');
$db->do('CREATE TABLE msc (uid INT,id VARCHAR(24),comment TEXT)');
$db->do('CREATE TABLE ns (id INT,name VARCHAR(24))');
$db->do("INSERT INTO ns VALUES(1,'msc')");
$db->do("INSERT INTO msc VALUES(1,'02-XX','Mechanics'),(2,'02.30.Xx','Calculus of variations')");
$db->do('INSERT INTO catlinks VALUES(1,2,1,1)');
open my $migration,'<',"$root/db/search-documents.mysql.sql" or die $!;
my $ddl=do {local $/;<$migration>};
$ddl =~ s/^--[^\n]*\n//mg;
$db->do($_) for grep{ /\S/ } split /;/,$ddl;
pass('real additive InnoDB FULLTEXT migration applied');
$db->do($_) for grep{ /\S/ } split /;/,$ddl;
pass('migration is rerunnable');
sub article {
    my ($id,$title,$body,%extra)=@_;
    $db->do('INSERT INTO objects VALUES(?,?,?,5,?,?,?, ?, NOW(),1)',undef,$id,$title,"Article$id",
        $extra{synonyms} || '',$extra{defines} || '',$extra{keywords} || '',$body);
    $db->do("INSERT INTO acl VALUES('objects',?,-1,'u','d',?)",undef,$id,$extra{private}?0:1);
}
sub index_object {
    my ($collection,$id,$body,$status)=@_;
    my $record=Noosphere::searchIndexRecord($db,$collection,$id);
    return Noosphere::searchIndexSave($db,$collection,$id,$record,$body,$status || 'ready');
}
sub result {
    my ($query,$collection,$subject)=@_;
    my $options={collection=>$collection || 'objects',query=>Noosphere::nativeSearchQuery($query),subject=>$subject};
    my ($sql,$bind,$count_sql,$count_bind)=Noosphere::nativeSearchSql($options);
    my ($count)=Noosphere::nativeSearchRows($db,$count_sql,@$count_bind);
    my @rows=Noosphere::nativeSearchRows($db,"SELECT * FROM ($sql) matches ORDER BY score DESC,relevance DESC,LOWER(title),collection,uid LIMIT 20",@$bind);
    Noosphere::nativeSearchSnippets($db,\@rows,$options->{query});
    return($count->{total},\@rows);
}
article(1,'Calculus of Variations','The stationary action principle is introduced.');
article(2,'Mechanics primer','A calculus of variations treatment of the stationary action principle.');
article(3,'Separated words','Calculus describes models of advanced variations.');
article(4,'Hidden mechanics','A calculus of variations secret.',private=>1);
article(5,'Celestial applications','Keplerian dynamics and orbital navigation.');
article(6,'Aliases','No equations here.',synonyms=>'Calculus of Variations');
$db->do("INSERT INTO objindex VALUES('objects',6,2,'Calculus of Variations')");
article(7,'Short words','An EM field and the orbital acceleration.');
article(8,'Unicode prose','Über stellar atmospheres and naïve models.');
article(9,'Markup safety','The orbital <script>alert(1)</script> & dynamics.');
article(10,'Late phrase',('context 'x200).'calculus of variations explains this model.');
article(11,'Large source','x'x(Noosphere::searchIndexSourceLimit()+1));
$db->do("INSERT INTO classification VALUES('objects',2,1,2,0)");
for my $id (1..10) {
    next if $id==4;
    my $r=Noosphere::searchIndexRecord($db,'objects',$id);
    ok(index_object('objects',$id,$r->{source}),"index article $id");
}
index_object('objects',11,'','oversize');
my $oversize=Noosphere::searchIndexRecord($db,'objects',11);
is($oversize->{source},'','oversized body is not loaded into worker memory');
cmp_ok($oversize->{source_bytes},'>',Noosphere::searchIndexSourceLimit(),'oversize reported from database byte length');
$db->do("INSERT INTO papers VALUES(2,'A physics paper','A. Author','', '<p>orbital acceleration</p>',NOW())");
$db->do("INSERT INTO acl VALUES('papers',2,-1,'u','d',1)");
ok(index_object('papers',2,'orbital acceleration'),'resource abstract indexed');
{
    my ($sql,$bind)=Noosphere::nativeSearchSql({collection=>'objects',query=>Noosphere::nativeSearchQuery('orbital')});
    my @plan=Noosphere::nativeSearchRows($db,"EXPLAIN $sql",@$bind);
    ok(grep(($_->{type} || '') eq 'fulltext',@plan),'actual native query plan uses the FULLTEXT index');
}
my ($total,$rows)=result('calculus of variations');
is($total,5,'metadata plus prose matches; short word verified and private result excluded');
is_deeply([map{$_->{uid}}@$rows[0,1]],[1,6],'exact title and concept outrank prose');
ok(grep($_->{uid}==2,@$rows),'body-only result present');
unlike(join('',map{$_->{snippet_html}}@$rows),qr/<script>/,'snippet markup escaped');
($total,$rows)=result('"calculus of variations"');
is($total,4,'quoted phrase finds contiguous prose only');
is((grep{$_->{uid}==10}@$rows)[0]{snippet_html} =~ /<mark>calculus of variations<\/mark>/ ? 1:0,1,'snippet centered on late match');
($total,$rows)=result('orbital EM');
is($total,1,'short body term verified alongside indexed token');
is($rows->[0]{uid},7,'short body term never silently omitted');
($total)=result('orbital missing');is($total,0,'all indexed terms required');
($total)=result('-orbital');is($total,3,'minus is punctuation, not a Boolean exclusion');
($total,$rows)=result('Über');is($total,1,'Unicode prose searchable');
like($rows->[0]{snippet_html},qr/<mark>Über<\/mark>/,'UTF-8 snippet highlighted');
($total,$rows)=result('orbital');
like((grep{$_->{uid}==9}@$rows)[0]{snippet_html},qr/&lt;script&gt;.*&amp;/,'HTML-looking source escaped');
($total)=result('the');is($total,4,'stopwords disabled for new index without changing server global setting');
SKIP: {
    # Mirror the legacy undecoded mysql connection, including latin1 client
    # negotiation, without changing the new index's UTF-8 text/collation.
    skip 'DBD::MariaDB always negotiates Unicode; no legacy byte/latin1 mode',2 unless $mysql_driver;
    local $db->{mysql_enable_utf8mb4}=0;
    $db->do('SET NAMES latin1');
    my ($count,$unicode_rows)=result('Über');
    is($count,1,'UTF-8 full-text bind survives legacy mysql client charset');
    like($unicode_rows->[0]{snippet_html},qr/<mark>Über<\/mark>/,'snippet bytes not converted through client latin1');
    $db->do('SET NAMES utf8mb4');
}
($total,$rows)=result('orbital','all');is($total,4,'all collections include prose and abstract');
is(scalar(grep{$_->{collection} eq 'papers'}@$rows),1,'equal IDs in different collections remain distinct');
my $subject=Noosphere::nativeSearchSubject($db,'02-XX');
($total,$rows)=result('calculus','objects',$subject);is($total,1,'PACS descendant filtering applies before count');
is($rows->[0]{uid},2,'correct classified prose result');
$db->do("UPDATE acl SET _read=0 WHERE tbl='objects' AND objectid=2");
($total)=result('"calculus of variations"');is($total,3,'privacy change immediate even with stale index');
$db->do("UPDATE acl SET _read=1 WHERE tbl='objects' AND objectid=2");
$db->do('INSERT INTO groups VALUES(10)');$db->do('INSERT INTO group_members VALUES(10,-1)');
$db->do("INSERT INTO acl VALUES('objects',2,10,'g','n',0)");
($total)=result('"calculus of variations"');is($total,3,'live anonymous group deny respected');
$db->do("DELETE FROM acl WHERE tbl='objects' AND objectid=2 AND default_or_normal='n'");
$db->do("UPDATE objects SET data='revised acceleration',version=version+1 WHERE uid=2");
($total)=result('"calculus of variations"');is($total,3,'stale body revision excluded');
ok(index_object('objects',2,'revised acceleration'),'edited body reindexed');
($total)=result('revised');is($total,1,'new body appears after refresh');
my $stale=Noosphere::searchIndexRecord($db,'objects',2);
$db->do("UPDATE objects SET data='newer text',version=version+1 WHERE uid=2");
is(Noosphere::searchIndexSave($db,'objects',2,$stale,'outdated text','ready'),0,'edit during conversion deferred');
my $private=Noosphere::searchIndexRecord($db,'objects',5);
$db->do("UPDATE acl SET _read=0 WHERE objectid=5 AND tbl='objects'");
is(Noosphere::searchIndexSave($db,'objects',5,$private,'private text','ready'),0,'privacy change during conversion not saved');
$db->do('DELETE FROM objects WHERE uid=9');
($total)=result('orbital');is($total,1,'deleted and newly private bodies disappear immediately');
is(Noosphere::searchIndexPrune($db,1),1,'prune obeys batch size');
is(Noosphere::searchIndexPrune($db,5),1,'remaining private/deleted index copy pruned');
my @pending=Noosphere::searchIndexCandidates($db,{limit=>2,collection=>'all'});
ok(@pending<=2,'worker candidates bounded');
ok(!grep($_->{uid}==11,@pending),'oversize source does not stall pending queue');
@pending=Noosphere::searchIndexCandidates($db,{limit=>5,collection=>'objects',object=>11});
is(scalar(@pending),1,'explicit object allows retry after parser/limit changes');
article(14,'Failed parsing','A source requiring a later repair.');
ok(index_object('objects',14,'','failed'),'failure stored without a raw-source fallback');
@pending=Noosphere::searchIndexCandidates($db,{limit=>50,collection=>'all'});
ok(!grep($_->{uid}==14,@pending),'fresh failure held out during retry cooldown');
$db->do("UPDATE search_documents SET indexed_at=NOW()-INTERVAL 2 HOUR WHERE tbl='objects' AND objectid=14");
@pending=Noosphere::searchIndexCandidates($db,{limit=>50,collection=>'all'});
ok(grep($_->{uid}==14,@pending),'failed parsing retried after cooldown');
$db->do("UPDATE search_documents SET indexed_at=NOW()-INTERVAL 2 DAY WHERE tbl='objects' AND objectid=1");
@pending=Noosphere::searchIndexCandidates($db,{limit=>50,collection=>'all'});
ok(grep($_->{uid}==1,@pending),'daily repair sweep checks old unchanged documents');
Noosphere::nativeSearchForgetDocument($db,'papers',2);
($total)=result('orbital','papers');is($total,0,'resource edit invalidation removes old abstract even in same second');
ok(index_object('papers',2,'new spectroscopy abstract'),'resource ready after refresh');
($total)=result('spectroscopy','papers');is($total,1,'refreshed resource abstract searchable');
{
    local $config{search_documents_tbl}='missing_index_table';
    my @warnings;local $SIG{__WARN__}=sub{push @warnings,@_};
    Noosphere::nativeSearchForgetDocument($db,'papers',2);
    like(join('',@warnings),qr/PL_SEARCH index invalidation failed/,'index problem does not abort a successful content edit');
    unlike(join('',@warnings),qr/missing_index_table|DELETE|driver/,'edit diagnostic sanitized');
}
{
    my $boot = q{BEGIN { $INC{'Noosphere/DB.pm'}=1; }
        use DBI; package Noosphere;
        sub dbConnect {
            my %options=(RaiseError=>1,PrintError=>0);
            $options{mysql_enable_utf8mb4}=1 if $ENV{FULLTEXT_TEST_DSN} =~ /\Adbi:mysql:/;
            DBI->connect($ENV{FULLTEXT_TEST_DSN},undef,undef,\%options);
        }
        sub getConfig { my %c=(en_tbl=>'objects',books_tbl=>'books',papers_tbl=>'papers',exp_tbl=>'lec',
            acl_tbl=>'acl',acl_tables=>{map{$_=>1}qw(objects books papers lec)},gmember_tbl=>'group_members',groups_tbl=>'groups',
            search_documents_tbl=>'search_documents',search_pandoc=>$ENV{SEARCH_TEST_PANDOC} || '/usr/bin/pandoc'); return $c{$_[0]}; }
        package main; my $file=shift @ARGV; do $file; die $@ || $!;
    };
    my $cli=sub {
        my @args=@_;
        my ($in,$out); my $err=gensym;
        my $pid=IPC::Open3::open3($in,$out,$err,$^X,"-I$root/lib",'-e',$boot,"$root/bin/update-search-index",@args);
        close $in; local $/; my $stdout=<$out> || ''; my $stderr=<$err> || '';
        waitpid($pid,0); return($? >> 8,$stdout,$stderr);
    };
    my ($code,$out,$err)=$cli->('--status');
    is($code,0,'real CLI status exits successfully');
    like($out,qr/objects\s+ready\s+\d+/,'status reports progress');
    ($code,$out,$err)=$cli->('--collection','objects','--object','11');
    is($code,0,'dry-run exits successfully');
    like($out,qr/no changes made/,'dry-run does not parse/write');
    ($code,$out,$err)=$cli->('--limit','51');
    isnt($code,0,'CLI rejects excessive batch');
    $db->selectrow_array("SELECT GET_LOCK('pl-search-index',0)");
    ($code,$out,$err)=$cli->('--apply');
    isnt($code,0,'CLI refuses concurrent worker');
    like($err,qr/already running/,'clear concurrency diagnostic');
    $db->selectrow_array("SELECT RELEASE_LOCK('pl-search-index')");
    SKIP: {
        skip 'Pandoc --sandbox unavailable',4 unless -x $config{search_pandoc};
        article(12,'Actual parsed document',"% commented text\nA \\emph{stellar} laboratory with \\PMlinkname{spectroscopic binaries}{Binaries}.");
        ($code,$out,$err)=$cli->('--apply','--collection','objects','--object','12');
        is($code,0,"CLI indexes actual TeX with Pandoc: $err");
        like($out,qr/ready objects:12/,'document state reported');
        ($total,$rows)=result('spectroscopic binaries');is($total,1,'parsed link label searchable end to end');
        like($rows->[0]{snippet_html},qr/<mark>spectroscopic<\/mark> <mark>binaries<\/mark>/,'parsed snippet highlighted');
    }
}
if ($ENV{FULLTEXT_SEARCH_QA_DIR}) {
    require File::Path;
    require Template;
    require Noosphere::TemplateNS;
    $config{stemplate_path}="$root/stemplates"; $config{template_cmd_prefix}='NS';
    $config{main_url}='https://physicslibrary.org'; $config{projname}='Physics Library';
    $config{slogan}='An open source physics library';
    $config{siteaddrs}={main=>'physicslibrary.org',image=>'images.physicslibrary.org'};
    File::Path::make_path($ENV{FULLTEXT_SEARCH_QA_DIR});
    my $content=Noosphere::nativeSearch({q=>'calculus of variations'},{uid=>-1});
    my $header=TemplateNS->new('header.html'); $header->setKey('q','calculus of variations');
    my $page='';
    Template->new({INCLUDE_PATH=>$config{template_path}})->process('view.tt',{
        native_search=>1,no_index=>1,title=>'Search Physics Library',site_name=>'Physics Library',header=>$header->expand(),
        sidebar=>'<nav class="qa-sidebar"><h2>Main Menu</h2><a href="/encyclopedia">Encyclopedia</a></nav><style>.qa-sidebar{font:.88rem Arial;background:#eff4f8;border:1px solid #c9d7e3}.qa-sidebar h2{background:#003399;color:white;font-size:1rem;line-height:1.2;margin:0;padding:.15rem .5rem}.qa-sidebar a{display:block;padding:.4rem .5rem}</style>',content=>$content},\$page) or die Template->error;
    open my $qa,'>:encoding(UTF-8)',"$ENV{FULLTEXT_SEARCH_QA_DIR}/fulltext.html" or die $!;
    print $qa $page; close $qa;
}
if ($ENV{FULLTEXT_BENCH}) {
    $db->begin_work;
    for my $id (1000..2499) {
        article($id,"Synthetic mechanics $id",'The stationary action principle describes orbital dynamics.');
        $db->do("INSERT INTO search_documents VALUES('objects',?,COALESCE((SELECT modified FROM objects WHERE uid=?),''),1,1,'ready',NOW(),?,?)",
            undef,$id,$id,'The stationary action principle describes orbital dynamics.',"Synthetic mechanics $id stationary action principle orbital dynamics");
    }
    $db->commit;
    my @times;
    for(1..20) { my $start=time; ($total,$rows)=result('stationary action'); push @times,time-$start; }
    is($total,1501,'full-sized corpus count without loading corpus into Perl');
    is(scalar(@$rows),20,'result page remains bounded for large match set');
    @times=sort{$a<=>$b}@times;
    diag(sprintf('MariaDB 10.6 synthetic 1500-document benchmark, count/page/snippets: median %.3fs, p95 %.3fs (not production timing)', $times[10],$times[18]));
}
local $config{native_fulltext_enabled}=0;
($total)=result('stellar');is($total,0,'feature off restores metadata-only path');
($total)=result('Calculus of Variations');is($total,2,'metadata works with feature off');
$db->do("DROP TABLE $_") for @tables;
$db->disconnect;
done_testing;
