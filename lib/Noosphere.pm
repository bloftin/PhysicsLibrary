#!/usr/bin/perl
package Noosphere;

use strict;
use Noosphere::Util;
use Noosphere::XSLTemplate;
use vars qw{%HANDLERS %NONTEMPLATE %CACHEDFILES};
use vars qw{$dbh $DEBUG $NoosphereTitle $AllowCache $MAINTENANCE $stats};

# 0 to turn off debug warnings.	1 turns on level 1 display, 2 for level 2 
#	(shows all database and file operations), and so on.
$DEBUG = 0;

# are we in maintenance mode?
#
sub inMaintenance {
	my $ip = shift;	# client IP for whitelist check

	my $root = getConfig('base_dir');
	if (-e "$root/maintenance") {

		# if IP list is present, build and check whitelist
		#
		if (-e "$root/maintenance_ips") {
			open FILE, "$root/maintenance_ips";
			my @list = <FILE>;
			chomp @list;
			my %whitelist = map { $_ => 1 } @list;
			
			# if IP is in whitelist, pretend like we're not in maintenance mode
			#
			if ($whitelist{$ip}) {
				return 0;
			}

			# otherwise, block the request
			#
			else {
				return 1;
			}
		} 
		
		# no IP list-- reject everyone
		# 
		else {
			return 1;
		}
	}

	return 0;
}

# call functions that have raw output (not embedded in any templates) 
#
sub getNoTemplateContent {
	my ($params, $user_info, $upload) = @_;
	
	if ($MAINTENANCE == 1) {
		return getMaintenance();
	}

	if ($params->{'op'} eq 'robotstxt') {
		return getConfig('robotstxt');
	}

	my $content = dispatch(\%NONTEMPLATE, $params, $user_info, $upload); 
	
	return $content;
}

# call functions that have output meant to go in the view template
#
sub getViewTemplateContent {
	my ($params, $user_info, $upload) = @_;
	
	# find function call in handler table and execute it with standard params
	#
	my $content = dispatch(\%HANDLERS,$params, $user_info, $upload); 
	
	return $content;
}

# for main window, with both sidebars
#
sub getMainTemplateContent {
	my $userinf = shift;
	my $content = '';
	
	# op=news or op=main
	#$content = paddingTable(getTopNews($userinf));
	$content = paddingTable(getFrontPage({}, $userinf));
	 
	return $content;
}

# get the data for front page (latest news, messages) and combine with template
#
sub getFrontPage { 
	my $params = shift;
	my $userinf = shift;
	my $template = XSLTemplate->new('frontpage.xsl');
	$template->addText("<frontpage>");

	# get the data and add it to be transformed by the stylesheet
	#
	my $newsxml = $stats->get('top_news');
	my $messagexml = $stats->get('latest_messages');

	#my $messages = getLatestMessagesXML($params, $userinf);
	$template->addText($newsxml);
	$template->addText($messagexml);
	$template->addText("</frontpage>");
	return $template->expand();
}

# get main menu box
# 
sub getMainMenu {
	my $template = new XSLTemplate("mainmenu.xsl");
	
	$template->addText('<mainmenu>');

	my $count = getUnfilledReqCount();
	my $request_count = '';
	$request_count = "($count)" if ($count);
	
	$count = orphanCount();
	my $orphan_count = '';
	$orphan_count = "($count)" if ($count);

	$count = countGlobalPendingCorrections();
	my $cor_count = '';
	$cor_count = "($count)" if ($count);
	
	my $uc_count = '';
	if (getConfig('classification_supported')) {
		$count = $stats->get('unclassified_objects');
		$uc_count = "($count)" if ($count);
	}

	$count = $stats->get('unproven_theorems');
	my $up_count = '';
	$up_count = "($count)" if ($count);
	
	my $bullet = getBullet();
	
	$template->setKeys('unproven' => $up_count, 'unclassified' => $uc_count, 'orphans' => $orphan_count, 'corrections' => $cor_count, 'requests' => $request_count, 'bullet' => $bullet);
	
	$template->addText('</mainmenu>');

	return makeBox("Main Menu",$template->expand());
}

# fill sidebars into a template
#
sub fillInSideBars {
	my $html = shift;
	my $params = shift;
	my $userinf = shift;
	
	my $sidebar = new Template("sidebar.html");
	my $rightbar = new Template("rightbar.html");
	my $login = getLoginBox($params, $userinf);
	$sidebar->setKey('login', $login);
	my $search = getSearchBox($params);
	my $admin = getAdminMenu($userinf->{data}->{access});
	my $topusers = getTopUsers();
	my $features = getMainMenu();
	my $latesta = getLatestAdditions();
	my $latestm = getLatestModifications();
	my $poll = getCurrentPoll();
	$sidebar->setKeys('search' => $search, 'admin' => $admin, 'features' => $features);
	$rightbar->setKeys('topusers' => $topusers, 'latesta' => $latesta, 'latestm' => $latestm, 'poll' => $poll);
	$html->setKeys('sidebar' => $sidebar->expand(), 'rightbar' => $rightbar->expand());
}

# fill left bar (sidebar) into a template
#
sub fillInLeftBar {
	my $html = shift;
	my $params = shift;
	my $userinf = shift;
	
	my $sidebar = new Template("sidebar.html");
	my $login = getLoginBox($params, $userinf);
	my $features = getMainMenu();
	my $admin = getAdminMenu($userinf->{data}->{access});
	$sidebar->setKeys('login' => $login, 'admin' => $admin, 'features' => $features);
	$html->setKey('sidebar', $sidebar->expand());
	return $html;
}

# get "top" stuff: header and CSS
#
sub headerAndCSS {
	my $template = shift;
	my $params = shift;

	my $search = getSearchBox($params);
	my $header = new Template('header.html');
	my $style = new Template('style.css');

	$header->setKey('search', $search);

	$template->setKey('header', $header->expand());
	$template->setKey('style', $style->expand());
}

# final sending of response to web request
#
sub sendOutput {
	my $req = shift;
	my $html = shift;
	my $status = shift || 200;

	my $len = length($html);
	$req->status($status);
	$req->content_type('text/html;charset=UTF-8');
#	$req->content_language('en');
	$req->header_out('Content-Length'=>$len);
	$req->send_http_header;
	$req->print($html);
	#dwarn $html;
	$req->rflush(); 
}

sub serveImage {
	my ($req, $id) = @_;

	my $image = getImage($id);
	my $len = length($image);

	$req->content_type('image/png');
	$req->header_out('Content-Length'=>$len);
	$req->send_http_header;
	$req->print($image);
	$req->rflush();
}

# BB: cached files stored in %CACHEDFILES
#     key exists -- file should be cached
#     key defined -- file has been cached
sub serveFile {
	my ($req, $name) = @_;
	my $html = '';
	unless (defined %CACHEDFILES) {
		my $cachelist = getConfig('cachedfiles');
		%CACHEDFILES = %$cachelist;
		foreach my $key (keys %CACHEDFILES) {
			undef $CACHEDFILES{$key};
		}
	}
	unless (exists $CACHEDFILES{$name}) {
		return 404;	
	}
	unless (defined $CACHEDFILES{$name}) {
		my $filenames = getConfig('cachedfiles');
		$CACHEDFILES{$name} = [readFile($filenames->{$name}->[0]), $filenames->{$name}->[1] ];
	}

	$html = $CACHEDFILES{$name}->[0];
	my $len = length($html);
	$req->content_type($CACHEDFILES{$name}->[1]);
	$req->header_out("Content-Length"=>"$len");
	$req->send_http_header;
	$req->print($html);
	$req->rflush(); 
	return;	
}

sub initNoosphere {
	initStats();
}

sub initStats {

	require Noosphere::StatCache;
	$stats = new StatCache;

	# add in the statcache statistics
	#
	$stats->add('unproven_theorems',{callback=>'unprovenCount'});
	$stats->add('unclassified_objects',{callback=>'unclassifiedCount'});
	$stats->add('topusers',{timeout=>30*60, callback=>'getTopUsers_callback'});
	$stats->add('latestadds',{callback=>'getLatestAdditions_data'});
	$stats->add('latestmods',{callback=>'getLatestModifications_data'});
	$stats->add('latest_messages',{callback=>'getLatestMessages_data'});
	$stats->add('top_news',{callback=>'getTopNews_data'});
}

# main noosphere CGI entry point (incomplete)
#
sub cgi_handler {
	my $params = shift;
	my $cookies = shift;
	
}

# main noosphere mod_perl entry point
#
sub handler {
        dwarn "Noosphere Entry Point";
	my $req = shift;
	#my $req = Apache->request();
        #my $PPreq = Apache2::RequestUtil->request();
	#dwarn $PPreq->param();
	my ($params,$upload) = parseParams($req);
        #dwarn "Params";
        #dwarn $params;
        #dwarn "Upload";
        #dwarn $upload;
	#dwarn "After parseParams";
	my %cookies = parseCookies($req);
	#dwarn "After parseCookies";

	my $html = '';

	$AllowCache = 1;	# default to allow client caching

	# uri remapping
	# we use this instead of a mod_rewrite-ish thing
	#
	my $uri = $req->uri();
	
	# deny IIS virii requests
	#
	if ($uri =~ /[aA]dmin\.dll/o || 
		$uri =~ /root\.exe/o ||
		$uri =~ /winnt/o ||
		$uri =~ /cmd\.exe/o ) {
		
		$html .= "No IIS here, sorry.";
		my $len = length($html);
		$req->header_out("Content-Length"=>"$len");
		$req->send_http_header;
		$req->print($html);
		$req->rflush(); 
		exit;	
	}

	# banned hosts or clients
	#
	my $banned = 0;
	my $bannedips = getConfig('bannedips');
	if (exists $bannedips->{$ENV{'REMOTE_ADDR'}}) {
		$banned = 1;
	}

	foreach my $str (@{getConfig('screen_scrapers')}) {
		if ($ENV{'HTTP_USER_AGENT'} =~ /$str/i ) {
			$banned = 1;
			last;
		}
	}

	if ($banned) {
		$html .= "You or your client is banned.  This is probably for trying to mirror us impolitely.  Please download snapshots instead, this is what they are for.";
		my $len = length($html);
		$req->header_out("Content-Length"=>"$len");
		$req->send_http_header;
		$req->print($html);
		$req->rflush(); 

		dwarn "*** host $ENV{REMOTE_ADDR} with client $ENV{HTTP_USER_AGENT} was rejected!";

		exit;	
	} 
	# BB: cached files serving
	if ($uri =~ /\/files\/(.+)$/o) { 
		return serveFile($req,$1);
	}
	# remapping
	#
	if ($uri =~ /\/[Ee]ncyclopedia\/(.+)\.htm[l]{0,1}(#.+)?$/o ||
			$uri =~ /^\/(.+)\.htm[l]{0,1}(#.+)?$/) {
		
		$params->{'op'} = 'getobj';
		$params->{'from'} = getConfig('en_tbl');
		my $basename = $1;
		if ($basename =~ /^\d+$/) {
			$params->{'id'} = $basename;
		} else {
			$params->{'name'} = $basename;
		}
	} elsif ($uri =~ /\/[Ee]ncyclopedia\/([0-9A-Z])[\/]{0,1}$/o) {
	
		my $ord = ord($1);
		$params->{'op'} = 'en';
		$params->{'idx'} = "$ord";
	
	} elsif ($uri =~ /\/[Ee]ncyclopedia[\/]{0,1}$/o) {
	
		$params->{'op'} = 'en';
	}
	elsif ($uri =~ /\/browse\/([^\/]+)\/([^\/]+)\/$/o) {

		my $from = $1;
		my $id = $2;

		$params->{'op'} = 'mscbrowse';
		$params->{'from'} = $from;
		$params->{'id'} = $id;
	}

	elsif ($uri =~ /\/browse\/([^\/]+)\/$/o) {

		my $from = $1;

		$params->{'op'} = 'mscbrowse';
		$params->{'from'} = $from;
	}

	# remap to display robots.txt directives
	#
	if ($uri =~ /\/robots\.txt$/o) {
		$params->{'op'} = 'robotstxt';
	}

	#BEN Added to test PASSWORD RESET PROBLEM
	# generic remapping of /param=val/... style paths
        # NOTE: do we really want to rewrite all of the CGI strings
  	# in this site to use this style? hmm..
  	#
	#if ($uri =~ /\/((?:\w+=[^\/]+\/)+)/o) {
	#    my $path = $1;

	#    foreach my $keyval (split(/\//,$path)) {
	#      my ($key, $val) = split(/=/,$keyval);
	#      $params->{key} = $val;
	#    }
       	#}
#	dwarn "Request URI is $uri";

	# debug print request headers
	# 
	#my %headers_in=$req->headers_in;
	#dwarn "HEADERIN: ----------------------\n";
	#foreach my $key (keys %headers_in) {
	#	dwarn "HEADERIN: $key=>$headers_in{$key}\n";
	#}
	
	# return maintenance mode message.  also checks to see if in whitelisted
	# maintenance mode.
	#
	if (inMaintenance($ENV{'REMOTE_ADDR'})) {
		sendOutput($req, getMaintenance(), 502); # server overloaded status
		return;
	}

	# connect to db
	#
	#BEGIN {
	#unless ($dbh ||= dbConnect()) {
	#	die "Couldn't open database: ",$DBI::errstr; 
	#dwarn "Before database connect";
	$dbh = dbConnect();
	#dwarn "After database connect";
	#}
	#}
	#END {}
	# handle serving of images
	#
	if ($params->{op} eq 'getimage') {
		serveImage($req, $params->{id});
		return;	
	}
	#dwarn "After serving images";
	# initialize stat cache
	#
	if (not defined $stats) {
		initStats();
	}
	#dwarn "After init stat cache";
	# user info and cookies
	#
	my %user_info = handleLogin($req, $params, \%cookies);

	# check for any content that isn't meant for any template
	#
	$html = getNoTemplateContent($params, \%user_info, $upload);
	# if none, process template stuff
	#
	if ($html eq '') {
		my $content;
		my $template;
		$NoosphereTitle = '';
		$content = getViewTemplateContent($params,\%user_info,$upload);
		if ($content ne '' ) { 
			$template = new Template('view.html');
			fillInLeftBar($template,$params,\%user_info);
			$template->setKeys('content' => $content, 'NoosphereTitle' => $NoosphereTitle);
		} else {
			$content = getMainTemplateContent(\%user_info); 
			$template = new Template('main.html');
			fillInSideBars($template,$params,\%user_info);
			$template->setKey('content', $content);
		}
		headerAndCSS($template, $params);
	
		# handle caching
		#
		my $nocache = '
		<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
		<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
		<META HTTP-EQUIV="Expires" CONTENT="-1">';

		$template->setKey('metacache', ($AllowCache ? '' : $nocache));
		$html = $template->expand();
	} 
	# finish and send output
	#
	#dwarn "Before sending output";
	sendOutput($req, $html);
#	$dbh->disconnect();
}

1;
