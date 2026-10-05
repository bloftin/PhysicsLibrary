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
        settings getuser edituserobjs edituserobjsbeta userobjs usermsgs usercorsf usercorsr
        orphanage ownerhistory collab enchrono preamble getrefs en vbrowser
        viewver viewdiff messageschrono showwatchers getmsg forums viewpoll
        viewpolls getpoll mailbox oldmail sentmail getmail globalcors unproven
        useractivity sysstats userlist unclassified hitinfo reqlist oldreqs
        getcors editcors editfiledcors getobj listobj browse authorlist search
        oldsearch adv_search latexguidelines assocguidelines license about
        feedback snapshots sitedoc checkword help viewobj explain_err);
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
    my %warnings = (
        delobj => 'This object will be permanently deleted. Continue?',
        deluser => 'This user will be permanently deleted. Continue?',
        deactivate => 'This user will no longer be able to sign in. Continue?',
        reactivate => 'This user will be able to sign in again. Continue?',
        abandon => 'You will give up ownership of this object. Continue?',
    );
    my %actions = (
        updatereq => 'Update request',
        deletereq => 'Delete request',
        confirmreq => 'Confirm request fulfillment',
        confirmallreq => 'Confirm request fulfillments',
        denyreq => 'Deny request fulfillment',
        rerender => 'Rerender article',
        delobj => 'Delete article',
        deluser => 'Delete user',
        deactivate => 'Deactivate user',
        reactivate => 'Reactivate user',
        abandon => 'Give up ownership',
        rollback => 'Restore article version',
    );
    my %labels = (
        op => 'Action', request => 'Request', identifier => 'Filling article',
        id => 'Article ID', from => 'Collection', method => 'Format',
    );
    my $warning = $warnings{$params->{op} || ''};
    my $fields = '';
    my $details = '';
    for my $key (sort keys %$params) {
        next if $key eq '_form_token';
        return requestFormFailure(400, 'Invalid action parameters.')
            if $key !~ /\A[a-z0-9_]+\z/ || ref($params->{$key}) ||
                length($params->{$key} || '') > 65536;
        # This form supplies the warning formerly shown by the handler's ask step.
        next if defined($warning) && $key eq 'ask';
        my $value = requestFormEscape($params->{$key});
        $fields .= '<input type="hidden" name="'.$key.'" value="'.$value.'" />';
        my $label = requestFormEscape($labels{$key} || $key);
        my $display = $key eq 'op' ? ($actions{$params->{$key}} || $params->{$key}) :
            substr($params->{$key} || '', 0, 500);
        $details .= '<div class="pl-confirm-action__detail"><dt>'.$label.'</dt><dd>'.
            requestFormEscape($display).'</dd></div>';
    }
    my $message = requestFormEscape($warning || 'Review the details before continuing.');
    return '<style>'.
        '.pl-confirm-action__header{background:#003399;border-bottom:1px solid #002266;'.
        'box-sizing:border-box;color:#fff;margin:0;padding:.15rem .5rem}'.
        '.pl-confirm-action__header h1{color:#fff;font:bold 1rem Arial,Helvetica,sans-serif;'.
        'letter-spacing:0;line-height:1.2;margin:0;min-width:0;overflow-wrap:anywhere}'.
        '.pl-confirm-action{max-width:46rem;margin:.65rem auto 0;padding:1.25rem 1.35rem;'.
        'border:1px solid #b8c9d8;background:#fff;color:#182633}'.
        '.pl-confirm-action__intro{margin:.4rem 0 1rem;color:#455d73}'.
        '.pl-confirm-action__warning{margin:0 0 1rem;padding:.65rem .75rem;'.
        'border-left:4px solid #b24a23;background:#fff4e8;color:#652c18}'.
        '.pl-confirm-action__details{margin:0 0 1.1rem;border-top:1px solid #d5e0e9}'.
        '.pl-confirm-action__detail{display:grid;grid-template-columns:10rem minmax(0,1fr);'.
        'gap:.75rem;padding:.55rem .15rem;border-bottom:1px solid #d5e0e9}'.
        '.pl-confirm-action__detail dt{font-weight:bold;color:#314e68}'.
        '.pl-confirm-action__detail dd{margin:0;overflow-wrap:anywhere}'.
        '.pl-confirm-action__actions{display:flex;align-items:center;gap:.9rem;margin:0}'.
        '.pl-confirm-action__confirm{padding:.45rem .85rem;border:1px solid #173f67;'.
        'background:#1d5b8f;color:#fff;font:inherit;font-weight:bold;cursor:pointer}'.
        '.pl-confirm-action__cancel{color:#174f83}'.
        '@media(max-width:34rem){.pl-confirm-action{margin:.75rem 0;padding:1rem}'.
        '.pl-confirm-action__detail{grid-template-columns:1fr;gap:.15rem}}</style>'.
        '<header class="pl-confirm-action__header"><h1 id="pl-confirm-action-title">Confirm Action</h1></header>'.
        '<section class="pl-confirm-action" aria-labelledby="pl-confirm-action-title">'.
        '<p class="pl-confirm-action__intro">No change has been made yet.</p>'.
        (defined($warning) ? '<p class="pl-confirm-action__warning">'.$message.'</p>' : '').
        '<dl class="pl-confirm-action__details">'.$details.'</dl>'.
        '<form class="pl-confirm-action__actions" method="post" action="'.
        requestFormEscape(getConfig('main_url')).'/">'.$fields.
        '<input type="hidden" name="_form_token" value="'.$token.'" />'.
        '<button class="pl-confirm-action__confirm" type="submit">Confirm action</button>'.
        '<a class="pl-confirm-action__cancel" href="/">Cancel</a></form></section>';
}

sub requestFormComplete {
    my ($op, $params) = @_;
    my $main = getConfig('main_url');
    $main =~ s{/+$}{};
    my $url = URI->new($main.'/');
    my $id = $params->{id};
    if (defined($id) && !ref($id) && $id =~ /\A[1-9][0-9]*\z/) {
        if (($op eq 'rerender' || $op eq 'abandon') &&
                defined($params->{from}) && !ref($params->{from}) &&
                $params->{from} =~ /\A[a-z][a-z0-9_]*\z/) {
            my @query = (op => 'getobj', from => $params->{from}, id => $id);
            push @query, method => $params->{method} if defined($params->{method}) &&
                !ref($params->{method}) && $params->{method} =~ /\A(?:make4ht|l2h|pdf|png|src)\z/;
            $url->query_form(@query);
        } elsif ($op eq 'deactivate' || $op eq 'reactivate') {
            $url->query_form(op => 'getuser', id => $id);
        }
    }
    # A GET destination prevents refresh from submitting the completed action again.
    my $req = Apache2::RequestUtil->request;
    $req->headers_out->set('Location' => "$url");
    $req->headers_out->set('Cache-Control' => 'no-store');
    $RequestFormStatus = 303;
    my %messages = (delobj => 'Object deleted.', deluser => 'User deleted.',
        deactivate => 'User deactivated.', reactivate => 'User reactivated.',
        abandon => 'Object abandoned.', rerender => 'Rendering requested.');
    return '<p>'.($messages{$op} || 'Action completed.').' <a href="'.
        requestFormEscape("$url").'">Continue</a></p>';
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
