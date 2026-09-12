package Noosphere;

use strict;
use Digest::SHA qw(hmac_sha256_hex);
use HTML::Entities qw(encode_entities);
use HTML::Parser;
use URI;

our ($RequestFormUser, $RequestFormStatus, $RequestFormValidated);

sub requestFormToken {
    my ($user) = @_;
    return undef unless ref($user) eq 'HASH' &&
        defined($user->{uid}) && !ref($user->{uid}) && $user->{uid} =~ /\A[1-9][0-9]*\z/ &&
        defined($user->{ticket}) && !ref($user->{ticket}) && $user->{ticket} =~ /\A[0-9a-f]{64}\z/ &&
        ref($user->{data}) eq 'HASH' && ($user->{data}{active} || '') eq '1';
    return hmac_sha256_hex("request-form-v1\0".$user->{uid}, $user->{ticket});
}

sub requestFormTokenMatches {
    my ($supplied, $expected) = @_;
    return 0 unless defined($supplied) && !ref($supplied) &&
        $supplied =~ /\A[0-9a-f]{64}\z/ && defined($expected);
    my $difference = 0;
    for my $i (0 .. 63) {
        $difference |= ord(substr($supplied, $i, 1)) ^ ord(substr($expected, $i, 1));
    }
    return $difference == 0;
}

sub requestFormOrigin {
    my ($value) = @_;
    return '' unless defined($value) && !ref($value) && $value !~ /[\s\\]/;
    my $uri = eval { URI->new($value) };
    return '' unless $uri && $uri->scheme && $uri->scheme =~ /\Ahttps?\z/i &&
        $uri->host && !defined($uri->userinfo);
    return lc($uri->scheme).'://'.lc($uri->host).':'.$uri->port;
}

sub requestFormSameOrigin {
    my ($req, $required) = @_;
    my $expected = requestFormOrigin(getConfig('main_url'));
    return 0 unless length $expected;
    my $site = $req->header_in('Sec-Fetch-Site') || '';
    return 0 if $site eq 'cross-site' || $site eq 'same-site';
    my $origin = $req->header_in('Origin');
    if (defined $origin) {
        return requestFormOrigin($origin) eq $expected;
    }
    my $referer = $req->header_in('Referer');
    return requestFormOrigin($referer) eq $expected if defined $referer;
    return !$required;
}

# Account entry points run before dispatch and have their own token checks.
sub requestAccountOriginError {
    my ($req, $params) = @_;
    my $op = $params->{op} || '';
    return '' unless $op =~ /\A(?:login|logout|newuser|activate|pwchangereq|pwchange)\z/;
    my $method = $req->method;
    return 'Use the sign-in form to sign in.' if $op eq 'login' && $method ne 'POST';
    return '' if $method eq 'GET' || $method eq 'HEAD';
    return 'Please return to the site and reload the form before submitting.'
        unless $method eq 'POST' && requestFormSameOrigin($req, 1);
    return '';
}

sub requestFormReadRoutes {
    return qw(frontpage adminstats webstats showise oldnews pacssearch pacsbrowse
        settings getuser edituserobjs userobjs usermsgs usercorsf usercorsr
        orphanage ownerhistory collab enchrono preamble getrefs en vbrowser
        viewver viewdiff messageschrono showwatchers getmsg forums viewpoll
        viewpolls getpoll mailbox oldmail sentmail getmail globalcors unproven
        useractivity sysstats userlist unclassified hitinfo reqlist oldreqs
        getcors editcors editfiledcors getobj listobj browse authorlist search
        oldsearch adv_search latexguidelines assocguidelines license about
        feedback sitedoc checkword help viewobj explain_err);
}

sub requestFormNeedsProtection {
    my ($params, $method) = @_;
    my $op = $params->{op} || '';
    return 1 if ref($op);
    # Watches can be changed from several otherwise read-only views.
    return 1 if exists $params->{watch};
    return 0 if $op =~ /\A(?:login|logout|newuser|activate|pwchangereq|pwchange|edituser)\z/;
    my %read = map { $_ => 1 } requestFormReadRoutes();
    return 0 if $read{$op};
    if ($op eq 'notices' || $op eq 'watches') {
        return scalar grep { exists $params->{$_} } qw(delsel delunsel delall);
    }
    return 1 unless $method eq 'GET' || $method eq 'HEAD';

    # Only initial editor navigation is allowed without a submitted form.
    my %landing = (
        editprefs => '', edit => 'id from new type',
        adden => 'class parent request title type',
        addobj => 'to type', acledit => 'id from', groupedit => '',
        memberedit => 'gid', linkpolicy => 'id from',
        collab_edit_comment => 'id', postmsg => 'id from replyto subject',
        sendmail => 'sendto', replymail => 'id rsubject', postnews => '',
        newpoll => '', correct => 'id from', rejectcor => 'id correct',
        retractcor => 'id correct continue', addreq => '', updatereq => 'id',
        adminedit => 'id from', adminclassify => 'id from', editscore => '',
        blacklist => '', cachecont => 'group offset total method', dbadmin => '',
        rollback => 'id from ver', transfer => 'id from',
        httpupload => '',
    );
    if (exists $landing{$op}) {
        my %allowed = map { $_ => 1 } ('op', split / /, $landing{$op});
        return scalar grep { !$allowed{$_} } keys %$params;
    }
    return 1;
}

sub requestFormEscape {
    return encode_entities(defined($_[0]) ? $_[0] : '', q{<>&"'});
}

sub requestFormFailure {
    my ($status, $message) = @_;
    $RequestFormStatus = $status;
    return '<p>'.requestFormEscape($message).'</p><p><a href="/">Return to Physics Library</a></p>';
}

sub requestFormConfirmation {
    my ($params, $token) = @_;
    my $fields = '';
    my $details = '';
    for my $key (sort keys %$params) {
        next if $key eq '_form_token';
        return requestFormFailure(400, 'Invalid action parameters.')
            if $key !~ /\A[a-z0-9_]+\z/ || ref($params->{$key}) ||
                length($params->{$key} || '') > 65536;
        my $value = requestFormEscape($params->{$key});
        $fields .= '<input type="hidden" name="'.$key.'" value="'.$value.'" />';
        $details .= '<dt>'.$key.'</dt><dd style="overflow-wrap:anywhere">'.
            requestFormEscape(substr($params->{$key} || '', 0, 500)).'</dd>';
    }
    return '<h2>Confirm Action</h2><p>Review this action before continuing.</p><dl>'.
        $details.'</dl><form method="post" action="'.requestFormEscape(getConfig('main_url')).'/">'.
        $fields.'<input type="hidden" name="_form_token" value="'.$token.'" />'.
        '<button type="submit">Confirm</button> <a href="/">Cancel</a></form>';
}

sub requestFormGuard {
    my ($req, $params, $user) = @_;
    my $method = $req ? $req->method : '';
    return requestFormFailure(405, 'Use GET to view a page or POST to submit a form.')
        unless $method =~ /\A(?:GET|HEAD|POST)\z/;
    return undef unless requestFormNeedsProtection($params, $method);
    my $token = requestFormToken($user);
    return requestFormFailure(403, 'Please sign in before using this action.') unless defined $token;
    return undef if $RequestFormValidated && $method eq 'POST';
    if ($method eq 'GET') {
        return requestFormConfirmation($params, $token);
    }
    return requestFormFailure(405, 'This action requires a submitted form.') unless $method eq 'POST';
    return requestFormFailure(403, 'The form has expired. Please reload it and try again.')
        unless requestFormSameOrigin($req, 0) &&
            requestFormTokenMatches($params->{_form_token}, $token);
    return undef;
}

# Apply only at response time, after caches and template expansion. Offsets
# preserve TeX-generated markup, scripts and textarea contents byte for byte.
sub requestFormDecorate {
    my ($html, $user, $current_uri) = @_;
    my $token = requestFormToken($user);
    return $html unless defined($token) && defined($html) && length($html);
    my $base = getConfig('main_url');
    my $current = URI->new_abs($current_uri || '/', $base.'/');
    my (@forms, @stack, %overrides);
    my $parser = HTML::Parser->new(api_version => 3);
    $parser->handler(start => sub {
        my ($tag, $attr, $offset, $length) = @_;
        if ($tag eq 'form') {
            $_->{unsafe} = 1 for @stack;
            my $form = {attr => {%$attr}, offset => $offset, length => $length,
                unsafe => scalar(@stack), params => {}, token_fields => []};
            push @forms, $form;
            push @stack, $form;
        } elsif ($tag =~ /\A(?:input|button|select|textarea)\z/) {
            if (exists($attr->{formaction}) || exists($attr->{formmethod})) {
                $overrides{$attr->{form}} = 1 if defined $attr->{form};
                $_->{unsafe} = 1 for @stack;
            }
            return unless @stack;
            my $form = $stack[-1];
            my $name = lc($attr->{name} || '');
            $form->{unsafe} = 1 if $name eq '_form_token' && $tag ne 'input';
            $form->{params}{$name} = $attr->{value} || '' if length $name;
            push @{$form->{token_fields}}, [$offset, $length]
                if $tag eq 'input' && $name eq '_form_token';
        }
    }, 'tagname, attr, offset, length');
    $parser->handler(end => sub {
        my ($tag) = @_;
        pop @stack if $tag eq 'form';
    }, 'tagname');
    $parser->parse($html);
    $parser->eof;
    my @edits;
    for my $form (@forms) {
        my $attr = $form->{attr};
        next if $form->{unsafe} || $overrides{$attr->{id} || ''};
        my $action = defined($attr->{action}) && length($attr->{action}) ? $attr->{action} : "$current";
        next if $action =~ /[\x00-\x20\\]/;
        my $uri = URI->new_abs($action, $current);
        next unless requestFormOrigin("$uri") eq requestFormOrigin($base);
        next unless ($uri->path || '/') eq '/';
        my %params = ($uri->query_form, %{$form->{params}});
        my $method = lc($attr->{method} || 'get');
        next unless $method eq 'post' || requestFormNeedsProtection(\%params, 'GET');
        next unless defined($params{op}) && $params{op} =~ /\A[a-z_]+\z/;
        # Always POST tokens, even for legacy GET action forms.
        $attr->{method} = 'post';
        $uri->fragment(undef);
        my @query = $uri->query_form;
        my @kept;
        while (@query) {
            my ($key, $value) = splice(@query, 0, 2);
            push @kept, $key, $value unless lc($key) eq '_form_token';
        }
        $uri->query(undef);
        $uri->query_form(@kept) if @kept;
        $attr->{action} = "$uri";
        my $start = '<form'.join('', map {
            ' '.$_.'="'.requestFormEscape($attr->{$_}).'"'
        } sort keys %$attr).'>';
        $start .= '<input type="hidden" name="_form_token" value="'.$token.'" />';
        push @edits, [$form->{offset}, $form->{length}, $start];
        push @edits, map { [@$_, ''] } @{$form->{token_fields}};
    }
    for my $edit (sort { $b->[0] <=> $a->[0] } @edits) {
        substr($html, $edit->[0], $edit->[1], $edit->[2]);
    }
    return $html;
}

1;
