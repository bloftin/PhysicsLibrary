#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RequestForm;
my $root = "$FindBin::Bin/../..";
sub read_file {
    open my $in, '<', "$root/$_[0]" or die $!;
    return do {local $/; <$in>};
}
my @handlers;
for my $spec (['Stats.pm', 'getTopUsers'], ['Stats.pm','getLatest'], ['Polls.pm','getCurrentPoll'], ['Messages.pm','getLatestMessages']) {
    my $source=read_file('lib/Noosphere/'.$spec->[0]);
    my ($handler)=$source =~ /(sub $spec->[1] \{.*?^\})/ms;
    push @handlers, $handler;
}
{
    package Noosphere;
    our ($dbh,$stats,@queries,@polls,@messages);
    our $success=1;
    sub getConfig {
        return {template_path=>'stemplates',main_url=>'https://example.invalid',latest_additions=>20,latest_revisions=>20,latest_messages=>20,message_tbl=>'messages',user_tbl=>'users'}->{$_[0]};
    }
    sub dbSelect {push @queries,$_[1]; return ($success,bless {pos=>0},'HomeStatement')}
    sub dbGetRows {@polls}
    sub mdhm {$_[0]}
    sub qhtmlescape {my $s=$_[0]; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/"/&quot;/g; $s}
    sub mathTitle {$_[0]}
    sub dwarn {die 'unexpected diagnostic'}
}
{
    package HomeCache;
    our %values;
    our @keys;
    sub get {push @keys,$_[1]; $values{$_[1]}}
}
{
    package HomeStatement;
    our $finished=0;
    sub fetchrow_hashref {$Noosphere::messages[$_[0]{pos}++]}
    sub finish {$finished++;1}
}
{
    package HomeTemplate;
    our ($name,$vars);
    sub process {my ($self,$name,$vars,$out)=@_; $HomeTemplate::name=$name; $HomeTemplate::vars=$vars; $$out=$name;1}
}
my $tt=eval {
    require Template;
    require Template::Stash;
    Template->new({INCLUDE_PATH=>"$root/stemplates",STASH=>Template::Stash->new()});
};
ok(eval('package Noosphere; our ($dbh,$stats); '.join("\n",@handlers).' 1'), 'modern presentation branches compile') or diag($@);
$Noosphere::stats=bless {},'HomeCache';
my %fixtures;
{
    no warnings qw(redefine once);
    local *Template::new=sub {bless {},'HomeTemplate'};
    $HomeCache::values{topusers}={toparows=>[{uid=>1,username=>'<Ben>',score=>12345},{uid=>0,username=>'nobody'}],topwrows=>[{uid=>1,username=>'<Ben>',sum=>30},{uid=>2,sum=>0}]};
    is(Noosphere::getTopUsers(1),'hometopusers.tt','modern top users uses dedicated template');
    is(scalar @{$HomeTemplate::vars->{alltime}},1,'non-user entries excluded from rankings');
    is(scalar @{$HomeTemplate::vars->{recent}},1,'only positive recent activity shown');
    $fixtures{top_users}=$HomeTemplate::vars;
    $HomeCache::values{latestadds}=[{'Saturday, 2026-10-03'=>[{'<Work & Energy>'=>'/encyclopedia/Work.html'}]}];
    is(Noosphere::getLatest('additions',1),'homelatest.tt','additions render through modern template');
    is($HomeCache::keys[-1],'latestadds','additions use existing cached statistics');
    is($HomeTemplate::vars->{days}[0]{items}[0]{title_html},'&lt;Work &amp; Energy&gt;','title is escaped before established math presentation');
    $fixtures{latestadditions}=$HomeTemplate::vars;
    $HomeCache::values{latestmods}=$HomeCache::values{latestadds};
    Noosphere::getLatest('modifications',1);
    is($HomeCache::keys[-1],'latestmods','revisions use existing cache');
    like($HomeTemplate::vars->{more_url},qr/mode=modified$/,'revision history route retained');
    $fixtures{latestrevisions}=$HomeTemplate::vars;
    @Noosphere::polls=({uid=>90,title=>'<Poll>',options=>'Yes,No & maybe'});
    is(Noosphere::getCurrentPoll(1),'homepoll.tt','current poll uses modern template');
    is_deeply($HomeTemplate::vars->{options},['Yes','No & maybe'],'poll option values are preserved');
    like($Noosphere::queries[-1]{WHERE},qr/start<CURRENT_TIMESTAMP and finish>CURRENT_TIMESTAMP/,'open-poll filter retained');
    is($Noosphere::queries[-1]{LIMIT},1,'poll query stays bounded');
    $fixtures{poll}=$HomeTemplate::vars;
    @Noosphere::polls=();
    Noosphere::getCurrentPoll(1);
    ok(!$HomeTemplate::vars->{poll},'no open poll represented explicitly');
    @Noosphere::messages=({uid=>8,threadid=>7,userid=>1,tbl=>'objects',objectid=>116,subject=>'<Message>',username=>'<Ben>',created=>'2026-10-03'});
    is(Noosphere::getLatestMessages(1),'homemessages.tt','messages use modern template');
    like($Noosphere::queries[-1]{WHERE},qr/messages.visible = 1/,'hidden messages remain excluded');
    is($Noosphere::queries[-1]{LIMIT},20,'message query retains configured limit');
    ok($HomeStatement::finished,'message statement is finished');
    $fixtures{latestmessages}=$HomeTemplate::vars;
    $Noosphere::success=0;
    Noosphere::getLatestMessages(1);
    ok($HomeTemplate::vars->{failed},'message query failure gets an unavailable state');
    Noosphere::getCurrentPoll(1);
    ok($HomeTemplate::vars->{failed},'poll failure gets an unavailable state');
    $HomeCache::values{topusers}=[];
    Noosphere::getTopUsers(1);
    is(scalar @{$HomeTemplate::vars->{alltime}},0,'unavailable ranking cache handled');
    $HomeCache::values{latestadds}='query error';
    Noosphere::getLatest('additions',1);
    is(scalar @{$HomeTemplate::vars->{days}},0,'unavailable latest cache handled');
}
subtest 'real front-page templates' => sub {
    plan skip_all=>'Template Toolkit unavailable' unless $tt;
    my %rendered;
    my %templates=(top_users=>'hometopusers.tt',latestadditions=>'homelatest.tt',latestrevisions=>'homelatest.tt',poll=>'homepoll.tt',latestmessages=>'homemessages.tt');
    for my $key (sort keys %templates) {
        ok($tt->process($templates{$key},$fixtures{$key},\$rendered{$key}),"$key renders") or diag($tt->error);
    }
    like($rendered{top_users},qr/&lt;Ben&gt;/,'ranking usernames escaped');
    like($rendered{latestmessages},qr/&lt;Message&gt;/,'message subjects escaped');
    like($rendered{latestmessages},qr/op=getobj&amp;from=objects&amp;id=116/,'message context preserved');
    like($rendered{latestmessages},qr/op=getmsg&amp;id=7/,'thread navigation preserved');
    like($rendered{latestadditions},qr/&lt;Work &amp; Energy&gt;/,'entry titles escaped');
    like($rendered{poll},qr/&lt;Poll&gt;/,'poll title escaped');
    like($rendered{poll},qr/value="No &amp; maybe"/,'poll options escaped without changing values');
    like($rendered{poll},qr/method="post" action="\/"/,'poll retains POST submission');
    like($rendered{poll},qr/name="op" value="vote".*name="id" value="90"/s,'vote route and poll identifier retained');
    my $decorated=Noosphere::requestFormDecorate($rendered{poll},{uid=>1,ticket=>('a' x 64),data=>{active=>1}});
    like($decorated,qr/name="_form_token"/,'existing CSRF decorator protects voting form');
    my $html;
    ok($tt->process('mainpage.tt',{%rendered,sidebar=>'<aside>Sidebar</aside>',no_index=>0},\$html),'homepage renders');
    like($html,qr/pl-home-layout/,'homepage uses responsive layout');
    unlike($html,qr/<table|<center|<font/i,'homepage removes legacy wrappers');
    unlike($html,qr/name="robots"/,'normal homepage remains indexable');
    $html='';
    ok($tt->process('mainpage.tt',{%rendered,search_results=>1,no_index=>1},\$html),'search-results branch renders');
    like($html,qr/gcse-searchresults-only/,'Google results widget retained');
    like($html,qr/name="robots" content="noindex,follow"/,'search-results noindex retained');
    unlike($html,qr/Welcome!/,'welcome does not appear in search results');
    for my $template (qw(hometopusers homelatest homepoll homemessages)) {
        ok($tt->process("$template.tt",{},\$html),"$template empty state renders");
    }
};
done_testing;
