#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;

my $root = "$FindBin::Bin/../..";
sub read_file {
    open my $fh, '<', "$root/$_[0]" or die $!;
    local $/;
    return <$fh>;
}
for my $file (qw(db/schema.mysql.sql db/schema.new.mysql.sql db/schema.pg.sql)) {
    my ($block) = read_file($file) =~ /create table objindex\s*\((.*?)^\)/ism;
    ok(defined $block, "$file has the title index");
    like($block, qr/\btitle\s+varchar\(255\)/i, "$file title matches article width");
    like($block, qr/\bcname\s+varchar\(255\)/i, "$file canonical name matches article width");
    if ($file =~ /mysql/) {
        like($block, qr/objindex_title_idx\s*\(title\(128\)\)/i, "$file preserves title index budget");
        like($block, qr/objindex_cnameidx\s*\(cname\(128\)\)/i, "$file preserves name index budget");
    }
}
my $migration = read_file('db/migrations/objindex-title-width.mysql.sql');
$migration =~ s/^--[^\n]*\n//mg;
like($migration, qr/MODIFY COLUMN title VARCHAR\(255\)/, 'upgrade widens titles');
like($migration, qr/MODIFY COLUMN cname VARCHAR\(255\)/, 'upgrade widens canonical names');
unlike($migration, qr/\b(?:DELETE|TRUNCATE|DROP TABLE)\b/i, 'migration does not discard rows');
my ($repair) = read_file('etc/title-index-recovery.md') =~ /```sql\n(INSERT INTO objindex.*?)```/s;
ok(defined $repair, 'recovery SQL is present and executable');
like($repair, qr/o\.uid=1454 AND NOT EXISTS/, 'repair targets one reviewed missing entry');
like($repair, qr/i\.type=1/, 'repair does not replace aliases');

SKIP: {
    my $dsn = $ENV{TITLE_INDEX_TEST_DSN} || '';
    skip 'Set TITLE_INDEX_TEST_DSN to a disposable MySQL/MariaDB database ending in _test', 1
        unless $dsn =~ /\Adbi:(?:mysql|MariaDB):database=[a-z0-9_]+_test;/;
    require DBI;
    my %options = (RaiseError=>1, PrintError=>0);
    $options{mysql_enable_utf8mb4}=1 if $dsn =~ /\Adbi:mysql:/;
    my $db = DBI->connect($dsn, undef, undef, \%options);
    $db->do('SET NAMES utf8mb4');
    $db->do("SET SESSION sql_mode='STRICT_ALL_TABLES'");
    # Require an empty test schema, rather than deleting another suite's tables.
    my ($existing) = $db->selectrow_array("SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('objects','objindex','storage')");
    die 'Fixture table names already exist; use an empty disposable test database' if $existing;
    my $title = 'Electromagnetic Waves, Antennas, and RF: Antenna Directivity, Radiation Efficiency, Gain, EIRP, and Effective Aperture - Exercises and Complete Worked Solutions';
    my $name = 'ElectromagneticWavesAntennasAndRFAntennaDirectivityRadiationEfficiencyGainEIRPAndEffectiveApertureExercisesAndCompleteWorkedSolutions';
    for my $engine (qw(InnoDB MyISAM)) {
        subtest "$engine strict UTF-8 migration and recovery" => sub {
            $db->do('CREATE TABLE objects (uid BIGINT,title VARCHAR(255),name VARCHAR(255),
                userid INT,parentid INT,data TEXT) ENGINE=InnoDB CHARACTER SET utf8mb4');
            $db->do("CREATE TABLE objindex (objectid BIGINT,tbl VARCHAR(16),userid INT,
                title VARCHAR(128) NOT NULL DEFAULT '',cname VARCHAR(128) NOT NULL DEFAULT '',
                type INT NOT NULL DEFAULT 1,source VARCHAR(16),ichar CHAR(1),
                KEY objindex_title_idx(title),KEY objindex_cnameidx(cname))
                ENGINE=$engine CHARACTER SET utf8mb4");
            $db->do('CREATE TABLE storage (_key VARCHAR(64),valid INT) ENGINE=InnoDB');
            $db->do("INSERT INTO objects VALUES(1454,?,?,1,1451,'UNCHANGED SOURCE')", undef, $title, $name);
            $db->do("INSERT INTO storage VALUES('latestadds',1),('latestmods',1),('unclassified_objects',1),('topusers',1)");
            my $insert = "INSERT INTO objindex (objectid,tbl,userid,title,cname,type,source,ichar)
                VALUES(?,'objects',1,?,?,1,'PP','E')";
            eval { $db->do($insert, undef, 1454, $title, $name); };
            like($@, qr/Data too long.*title/, 'reproduces logged failure after article save');
            eval { $db->do($insert, undef, 1, 'Short title', $name); };
            like($@, qr/Data too long.*cname/, 'long canonical names independently fail');
            $db->do("INSERT INTO objindex VALUES(1454,'objects',1,'EM 24 E12','EM24E12',2,'PP','E')");
            my ($before) = $db->selectrow_array("SELECT COUNT(*) FROM objects o JOIN objindex i
                ON i.tbl='objects' AND i.objectid=o.uid AND i.type=1");
            is($before, 0, 'stored article is invisible to primary-index listings');
            $db->do($migration);
            for my $column (qw(title cname)) {
                my ($width) = $db->selectrow_array("SELECT CHARACTER_MAXIMUM_LENGTH
                    FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
                    AND TABLE_NAME='objindex' AND COLUMN_NAME=?", undef, $column);
                is($width, 255, "$column widened without truncation");
            }
            for my $index (qw(objindex_title_idx objindex_cnameidx)) {
                my ($prefix) = $db->selectrow_array("SELECT SUB_PART FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='objindex' AND INDEX_NAME=?", undef, $index);
                is($prefix, 128, "$index retains legacy prefix length");
            }
            for my $attempt (1,2) {
                $db->do($_) for grep { /\S/ } split /;/, $repair;
                my ($count) = $db->selectrow_array("SELECT COUNT(*) FROM objindex WHERE objectid=1454 AND type=1");
                is($count, 1, "repair attempt $attempt leaves exactly one primary row");
            }
            my $row = $db->selectrow_hashref("SELECT * FROM objindex WHERE objectid=1454 AND type=1");
            is($row->{title}, $title, 'complete title retained');
            is($row->{cname}, $name, 'complete canonical name retained');
            my ($alias) = $db->selectrow_array("SELECT COUNT(*) FROM objindex WHERE cname='EM24E12' AND type=2");
            is($alias, 1, 'shortcut alias preserved');
            my ($after) = $db->selectrow_array("SELECT COUNT(*) FROM objects o JOIN objindex i
                ON i.tbl='objects' AND i.objectid=o.uid AND i.type=1");
            is($after, 1, 'article visible to primary-index listings');
            my ($parent, $data) = $db->selectrow_array('SELECT parentid,data FROM objects WHERE uid=1454');
            is($parent, 1451, 'attachment parent is untouched');
            is($data, 'UNCHANGED SOURCE', 'article body is untouched');
            my ($valid) = $db->selectrow_array("SELECT SUM(valid) FROM storage WHERE _key<>'topusers'");
            is($valid, 0, 'affected listing statistics invalidated');
            my ($other) = $db->selectrow_array("SELECT valid FROM storage WHERE _key='topusers'");
            is($other, 1, 'unrelated cached statistics preserved');
            my $unicode = chr(0x1D400) x 255;
            $db->do($insert, undef, 2, $unicode, $unicode);
            my ($got) = $db->selectrow_array('SELECT title FROM objindex WHERE objectid=2');
            is($got, $unicode, '255 four-byte UTF-8 characters supported in full');
            eval { $db->do($insert, undef, 3, 'x' x 256, 'too-long'); };
            like($@, qr/Data too long/, 'article-equivalent 255-character limit still enforced');
            my $prefix = 'A' x 128;
            for my $suffix (qw(One Two)) { $db->do($insert, undef, 4, $prefix.$suffix, $prefix.$suffix); }
            my ($matched) = $db->selectrow_array('SELECT COUNT(*) FROM objindex WHERE cname=?', undef, $prefix.'One');
            is($matched, 1, 'prefix index does not conflate different full canonical names');
            $db->do($migration);
            my ($preserved) = $db->selectrow_array('SELECT COUNT(*) FROM objindex');
            is($preserved, 5, 'migration can be rerun without losing primary or alias rows');
            $db->do("DROP TABLE $_") for qw(objindex objects storage);
        };
    }
    $db->disconnect;
}
done_testing;
