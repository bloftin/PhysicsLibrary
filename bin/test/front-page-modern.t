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
for my $spec (['Stats.pm', 'getTopUsers'], ['Stats.pm','getLatest'], ['Polls.pm','getCurrentPoll'], ['Messages.pm','getLatestMessages'], ['News.pm','getHomeNews']) {
    my $source=read_file('lib/Noosphere/'.$spec->[0]);
    my ($handler)=$source =~ /(sub $spec->[1] \{.*?^\})/ms;
    push @handlers, $handler;
}
{
    package Noosphere;
    our ($dbh,$stats,@queries,@polls,@messages);
    our $success=1;
    sub getConfig {
        return {template_path=>'stemplates',main_url=>'https://example.invalid',latest_additions=>20,latest_revisions=>20,latest_messages=>20,message_tbl=>'messages',user_tbl=>'users',news_tbl=>'news',news_frontpage_count=>1}->{$_[0]};
    }
    sub dbSelect {push @queries,$_[1]; return ($success,bless {pos=>0},'HomeStatement')}
    sub dbGetRows {@polls}
    sub mdhm {$_[0]}
    sub md {$_[0]}
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
    @Noosphere::polls=({uid=>12,title=>'<News & Updates>',created=>'2026-10-03'});
    is(Noosphere::getHomeNews(),'homenews.tt','homepage news uses dedicated template');
    is($Noosphere::queries[-1]{LIMIT},1,'news honors configured front-page limit');
    is($Noosphere::queries[-1]{FROM},'news','news headlines need no user join');
    is($Noosphere::queries[-1]{WHAT},'uid,title,created','sidebar does not load full news bodies');
    is($Noosphere::queries[-1]{'ORDER BY'},'created DESC, uid DESC','newest news appears first with stable ordering');
    is($HomeTemplate::vars->{items}[0]{date},'2026-10-03','news dates formatted for display');
    $fixtures{news}=$HomeTemplate::vars;
    @Noosphere::polls=();
    Noosphere::getHomeNews();
    is(scalar @{$HomeTemplate::vars->{items}},0,'empty news represented explicitly');
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
    Noosphere::getHomeNews();
    ok($HomeTemplate::vars->{failed},'news query failure gets an unavailable state');
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
    my %templates=(top_users=>'hometopusers.tt',latestadditions=>'homelatest.tt',latestrevisions=>'homelatest.tt',poll=>'homepoll.tt',latestmessages=>'homemessages.tt',news=>'homenews.tt');
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
    like($rendered{news},qr/&lt;News &amp; Updates&gt;/,'news headlines are escaped');
    like($rendered{news},qr/op=getobj&amp;from=news&amp;id=12/,'news links to the existing full article');
    like($rendered{news},qr/op=oldnews/,'news archive remains accessible');
    my $decorated=Noosphere::requestFormDecorate($rendered{poll},{uid=>1,ticket=>('a' x 64),data=>{active=>1}});
    like($decorated,qr/name="_form_token"/,'existing CSRF decorator protects voting form');
    my $html;
    ok($tt->process('mainpage.tt',{%rendered,sidebar=>'<aside>Sidebar</aside>',no_index=>0},\$html),'homepage renders');
    like($html,qr/pl-home-layout/,'homepage uses responsive layout');
    unlike($html,qr/<table|<center|<font/i,'homepage removes legacy wrappers');
    unlike($html,qr/name="robots"/,'normal homepage remains indexable');
    like($html,qr/Current Poll.*aria-label="News".*Latest Additions/s,'news appears below poll and above additions');
    my @welcome_paragraphs = (
        q{<p> Physics Library is a virtual community which aims to help make physics knowledge more accessible. Physics Library's content is created collaboratively: the main feature is the <a href="/encyclopedia">physics encyclopedia</a> with entries written and reviewed by members. The entries are contributed under the terms of the <a href="https://creativecommons.org/licenses/by-sa/4.0/"> Creative Commons Attribution-ShareAlike CC BY-SA 4.0 License </a>.</p>},
        q{<p> Physics Library entries are written in <a href="https://www.latex-project.org/">LaTeX</a>, the <i>lingua franca</i> of the worldwide mathematics community. All of the entries are automatically cross-referenced with each other, and the entire corpus is kept updated in real-time. </p>},
        q{<p> In addition to the physics encyclopedia, there are <a href="https://physicslibrary.org/?op=browse;from=books">books</a>, <a href="https://physicslibrary.org/?op=browse;from=lec">lectures</a>, <a href="https://physicslibrary.org/?op=browse;from=papers">papers</a> and <a href="https://physicslibrary.org/?op=forums">forums</a>. You also might want to check out encyclopedia <a href="https://physicslibrary.org/?op=reqlist">requests</a> if you would like to see something we don't have or want to get started contributing. </p>},
        q{<p> Accounts are free and required to do anything other than browse, so <a href="https://physicslibrary.org/?op=newuser">sign up!</a> It only takes a minute. </p>},
        q{<p>Browse Encyclopedia By: <a href="https://physicslibrary.org/encyclopedia">Encyclopedia</a> </p>},
    );
    my $normalized_html = $html;
    $normalized_html =~ s/\s+/ /g;
    for my $index (0 .. $#welcome_paragraphs) {
        like($normalized_html, qr/\Q$welcome_paragraphs[$index]\E/,
            'original Welcome paragraph '.($index + 1).' retains all wording, emphasis, and links');
    }
    $html='';
    ok($tt->process('mainpage.tt',{%rendered,search_results=>1,no_index=>1},\$html),'front page tolerates old search-results flag');
    unlike($html,qr/gcse-searchresults-only/,'retired Google results widget is not rendered');
    like($html,qr/name="robots" content="noindex,follow"/,'supplied noindex retained');
    like($html,qr/Welcome!/,'front-page template remains the home page; native results use their own view');
    for my $template (qw(hometopusers homelatest homepoll homemessages homenews)) {
        ok($tt->process("$template.tt",{},\$html),"$template empty state renders");
    }
    my $empty_news='';
    ok($tt->process('homenews.tt',{items=>[]},\$empty_news),'empty news renders');
    like($empty_news,qr/No news yet\./,'empty news is clearly distinguished from failure');
    my $failed_news='';
    ok($tt->process('homenews.tt',{failed=>1},\$failed_news),'news failure renders');
    like($failed_news,qr/temporarily unavailable/,'failed news does not claim there are no items');
};
done_testing;
