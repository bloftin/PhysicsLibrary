#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Noosphere::RequestForm;
use Noosphere::Dispatch;
use Noosphere::SecurityHeaders;
use HTML::Parser;
use URI;
use Encode ();
use bytes ();

our ($request, @writes, $exists, $owner, $account_ok);
{
    package Noosphere;
    sub getConfig { return {main_url=>'https://example.invalid', access_admin=>50, user_tbl=>'users'}->{$_[0]}; }
    sub errorMessage { return 'Error: '.$_[0]; }
    sub loginExpired { return 'Sign in'; }
    sub objectOwnerByUid { return $main::owner; }
    sub lookupfield { return $main::owner; }
    sub objectExistsByUid { return $main::exists; }
    sub _delObject { push @main::writes, 'delete'; return 1; }
    sub _abandonObject { push @main::writes, 'abandon'; }
    sub setvalidflag_off { push @main::writes, 'invalidate'; }
    sub setbuildflag_off { push @main::writes, 'build'; }
    sub setAccountActive { push @main::writes, 'account'; return $main::account_ok; }
    sub userCreatedObjects { return 0; }
    sub delrows { push @main::writes, 'delete user'; }
    sub delUserWatches { }
    sub deleteUserDefaultACL { }
    sub deleteTitle { }
    sub irUnindex { }
    package Apache2::RequestUtil;
    sub request { return $main::request; }
    package ReturnRequest;
    sub method { return $_[0]{method}; }
    sub header_in { return $_[0]{headers}{$_[1]}; }
    sub headers_out { return $_[0]; }
    sub set { $_[0]{out}{$_[1]} = $_[2]; }
    sub add { $_[0]->set($_[1],$_[2]); }
    sub unparsed_uri { return '/'; }
    sub status { $_[0]{status} = $_[1]; }
    sub content_type { return 'text/html'; }
    sub print { $_[0]{output} = $_[1]; }
    sub rflush { }
}

# Exercise real handlers with synthetic persistence and HTTP services.
for my $spec (['DelObj.pm',qw(delObject)], ['Orphan.pm',qw(abandonObject)],
        ['Admin.pm',qw(reRenderObj deactivate reactivate delUser)], ['../Noosphere.pm',qw(sendOutput)]) {
    my ($file,@names) = @$spec;
    open my $fh, '<', "$FindBin::Bin/../../lib/Noosphere/$file" or die $!;
    my $source = do { local $/; <$fh> };
    for my $name (@names) {
        my ($sub) = $source =~ /^(sub \Q$name\E \{.*?)(?=^sub |\z)/ms;
        die "Missing $name" unless $sub;
        eval "package Noosphere; our (\$RequestFormStatus, \$RequestFormUser); $sub";
        die $@ if $@;
    }
}
my %handlers = (delobj=>\&Noosphere::delObject, abandon=>\&Noosphere::abandonObject,
    rerender=>\&Noosphere::reRenderObj, deactivate=>\&Noosphere::deactivate,
    reactivate=>\&Noosphere::reactivate, deluser=>\&Noosphere::delUser,
    getobj=>sub {'Object view'}, getuser=>sub {'User view'}, frontpage=>sub {'Home'});
my $user = {uid=>42, ticket=>'a' x 64, data=>{active=>1,access=>100}};
sub reset_request {
    my ($method) = @_;
    $request = bless {method=>$method,headers=>{Origin=>'https://example.invalid'},out=>{}}, 'ReturnRequest';
    $Noosphere::RequestFormStatus = undef;
}
sub fields {
    my ($html) = @_;
    my %fields;
    my $parser = HTML::Parser->new(api_version=>3);
    $parser->handler(start=>sub {
        my ($tag,$attr) = @_;
        $fields{$attr->{name}} = $attr->{value} if $tag eq 'input';
    }, 'tagname, attr');
    $parser->parse($html); $parser->eof;
    return \%fields;
}

for my $op (qw(delobj abandon rerender deactivate reactivate deluser)) {
    subtest "$op confirmation to final GET" => sub {
        @writes=(); $exists=1; $owner=42; $account_ok=1;
        reset_request('GET');
        my %params=(op=>$op,id=>87,from=>'objects',method=>'pdf');
        $params{ask}='yes' unless $op eq 'rerender';
        my $page=Noosphere::dispatch(\%handlers,\%params,$user);
        like($page,qr/Confirm Action/,'navigation shows confirmation');
        is(scalar @writes,0,'navigation does not change data');
        like($page,qr/permanently deleted/,'deletion warning retained') if $op =~ /\Adel/;
        my $body=fields($page);
        ok(!exists $body->{ask},'confirmation does not reopen old ask step');
        reset_request('POST');
        my %bad=%$body; delete $bad{_form_token};
        Noosphere::dispatch(\%handlers,\%bad,$user);
        is(scalar @writes,0,'invalid submission does not run action');
        ok(!exists $request->{out}{Location},'rejection does not redirect');
        reset_request('POST');
        my $result=Noosphere::dispatch(\%handlers,$body,$user);
        ok(@writes,'confirmed action runs');
        unlike($result,qr/Confirm Action|YES!/,'no further confirmation');
        my $destination=$request->{out}{Location};
        my $expected=$op =~ /\Adel/ ? 'https://example.invalid/' :
            $op =~ /activate\z/ ? 'https://example.invalid/?op=getuser&id=87' :
            'https://example.invalid/?op=getobj&from=objects&id=87&method=pdf';
        is($destination,$expected,'appropriate canonical destination');
        local $Noosphere::RequestFormUser=$user;
        Noosphere::sendOutput($request,$result);
        is($request->{status},303,'HTTP response instructs browser to GET');
        is($request->{out}{'Cache-Control'},'no-store','completion is not cached');
        my %query=URI->new($destination)->query_form;
        $query{op} ||= 'frontpage';
        my $count=@writes;
        for (1..2) {
            reset_request('GET');
            like(Noosphere::dispatch(\%handlers,\%query,$user),qr/view|Home/,'destination and refresh show ordinary page');
        }
        is(scalar @writes,$count,'refresh does not repeat action');
    };
}

subtest 'errors and older submitted ask forms' => sub {
    for my $op (qw(delobj abandon deactivate reactivate deluser)) {
        @writes=();$exists=1;$owner=42;$account_ok=1;
        reset_request('POST');
        my $page=Noosphere::dispatch(\%handlers,{op=>$op,id=>87,from=>'objects',ask=>'yes',
            _form_token=>Noosphere::requestFormToken($user)},$user);
        like($page,qr/method="post"/,'older ask submission gets direct final form');
        ok(!exists fields($page)->{ask},'final form omits ask');
        is(scalar @writes,0,'ask remains non-mutating');
        ok(!exists $request->{out}{Location},'ask does not claim completion');
    }
    $exists=0;reset_request('POST');
    like(Noosphere::dispatch(\%handlers,{op=>'delobj',id=>87,from=>'objects',
        _form_token=>Noosphere::requestFormToken($user)},$user),qr/doesn't exist/,'missing object error retained');
    ok(!exists $request->{out}{Location},'missing object not redirected');
    $exists=1;$owner=99;reset_request('POST');
    my $member={%$user,data=>{active=>1,access=>1}};
    like(Noosphere::dispatch(\%handlers,{op=>'delobj',id=>87,from=>'objects',
        _form_token=>Noosphere::requestFormToken($member)},$member),qr/can't delete/,'ownership rejection retained');
    ok(!exists $request->{out}{Location},'denied deletion not redirected');
    $account_ok=0;reset_request('POST');
    like(Noosphere::dispatch(\%handlers,{op=>'deactivate',id=>87,
        _form_token=>Noosphere::requestFormToken($user)},$user),qr/Could not update/,'update error retained');
    ok(!exists $request->{out}{Location},'failed update not redirected');
};

subtest 'return destination excludes action parameters' => sub {
    reset_request('POST');
    Noosphere::requestFormComplete('rerender',{id=>87,from=>'objects',method=>'pdf&op=delobj',
        return=>'https://other.invalid',ask=>'yes',watch=>'add',_form_token=>'synthetic'});
    is($request->{out}{Location},'https://example.invalid/?op=getobj&from=objects&id=87','only view identity is carried forward');
    for my $bad ({id=>[],from=>'objects'},{id=>87,from=>"objects\r\nX-Test: bad"}) {
        Noosphere::requestFormComplete('rerender',$bad);
        is($request->{out}{Location},'https://example.invalid/','invalid view identity falls back home');
    }
};
done_testing();
