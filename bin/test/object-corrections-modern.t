#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
my $root = "$FindBin::Bin/../..";
open my $fh, '<', "$root/lib/Noosphere/Corrections.pm" or die $!;
my $source = do { local $/; <$fh> };
my ($handler) = $source =~ /(sub editCorrections \{.*?^\})/ms;
my $tt = eval {
    require Template;
    require Template::Stash;
    Template->new({ INCLUDE_PATH => "$root/stemplates", STASH => Template::Stash->new() });
};
{
    package Noosphere;
    our ($dbh, @queries, @rows, $pager);
    our $success = 1;
    sub getConfig { {en_tbl=>'objects', cor_tbl=>'corrections', main_url=>'', template_path=>'stemplates'}->{$_[0]} }
    sub errorMessage { $_[0] }
    sub dbSelect { push @queries, $_[1]; return ($success, bless {}, 'CorrectionStatement') }
    sub dbGetRows { @rows }
    sub ymd { substr($_[0],0,10) }
    sub getPager { $pager = $_[0]; return '<a href="/?op=editcors&amp;offset=10">Next</a>' }
}
{
    package CorrectionStatement;
    sub fetchrow_hashref { {cnt => 4} }
    sub finish { 1 }
}
{
    package CorrectionTemplate;
    our ($vars, $name);
    sub process { my ($self,$name,$vars,$out) = @_; $CorrectionTemplate::name=$name; $CorrectionTemplate::vars=$vars; $$out='rendered corrections'; return 1 }
}
ok(eval("package Noosphere; our \$dbh; $handler\n1"), 'handler compiles') or diag($@);
my $user = {uid=>1, prefs=>{pagelength=>20}};
my $vars;
{
    no warnings qw(redefine once);
    local *Template::new = sub { bless {}, 'CorrectionTemplate' };
    is(Noosphere::editCorrections({}, {uid=>0}), 'Must be logged in to view corrections to your objects', 'anonymous request rejected');
    is(scalar @Noosphere::queries, 0, 'anonymous request does not query corrections');
    @Noosphere::rows = map { {uid=>7+$_, objectid=>116, userid=>2, title=>'<Correction>', objtitle=>'<Object>', username=>'<Ben>', filed=>'2026-10-03 12:30:00', closed=>($_ ? '2026-10-03' : undef), accepted=>($_ == 1 ? 1 : $_ == 2 ? 0 : 2)} } 0..3;
    is(Noosphere::editCorrections({op=>'editcors'}, $user), 'rendered corrections', 'dedicated template renders');
    is($CorrectionTemplate::name, 'editcors.tt', 'template selected');
    is($CorrectionTemplate::vars->{total}, 4, 'count query supplies total');
    like($Noosphere::queries[0]{WHERE}, qr/objects.userid=1$/, 'count remains owner-scoped');
    like($Noosphere::queries[1]{WHERE}, qr/objects.userid=1$/, 'list remains owner-scoped');
    is($Noosphere::queries[1]{LIMIT}, 10, 'page size stays half user preference');
    ok(exists $Noosphere::queries[1]{DESC}, 'newest-first default retained');
    is_deeply([map $_->{status}, @{$CorrectionTemplate::vars->{rows}}], [qw(Pending Accepted Rejected Retracted)], 'status labels match stored meanings');
    is($CorrectionTemplate::vars->{rows}[0]{date}, '2026-10-03', 'date normalized');
    $vars = $CorrectionTemplate::vars;
    Noosphere::editCorrections({total=>4, offset=>10, asc=>1}, $user);
    ok(exists $Noosphere::queries[-1]{ASC}, 'oldest-first option retained');
    is($Noosphere::queries[-1]{OFFSET}, 10, 'page offset retained');
    is($Noosphere::pager->{asc}, 1, 'pager preserves oldest-first option');
    @Noosphere::rows=();
    Noosphere::editCorrections({total=>4}, $user);
    is(scalar @{$CorrectionTemplate::vars->{rows}}, 0, 'empty result does not rely on driver rows()');
    $Noosphere::success=0;
    like(Noosphere::editCorrections({}, $user), qr/Error with query/, 'count failure has a readable error');
    like(Noosphere::editCorrections({total=>4}, $user), qr/Error with query/, 'list failure has a readable error');
}
SKIP: {
    skip 'Template Toolkit unavailable', 9 unless $tt;
    my $html;
    ok($tt->process('editcors.tt', $vars, \$html), 'real template renders') or diag($tt->error);
    like($html, qr/&lt;Correction&gt;.*&lt;Object&gt;.*&lt;Ben&gt;/s, 'titles and reporter are escaped');
    like($html, qr/op=edit&amp;from=objects&amp;id=116&amp;correct=7/, 'resolve link preserves correction context');
    like($html, qr/op=rejectcor&amp;id=116&amp;correct=7/, 'reject link preserves correction context');
    is(scalar(()=$html =~ /op=rejectcor/g), 1, 'closed corrections have no reject controls');
    like($html, qr/op=editfiledcors/, 'filed corrections navigation retained');
    like($html, qr/background: #003399/, 'compact original-blue header');
    ok($tt->process('editcors.tt', {title=>'Corrections to Your Objects', total=>0, rows=>[]}, \$html), 'empty template renders');
    like($html, qr/No corrections\./, 'empty state visible');
}
done_testing;
