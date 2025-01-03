#!/usr/bin/perl
package Noosphere;

use strict;
use Noosphere::Util;
use Noosphere::XSLTemplate;
use HTML::Tidy;
use XML::Writer;
use File::chdir;
use vars qw{%HANDLERS %NONTEMPLATE %CACHEDFILES};
use vars qw{$dbh $DEBUG $NoosphereTitle $AllowCache $MAINTENANCE $stats};

# 0 to turn off debug warnings.	1 turns on level 1 display, 2 for level 2 
#	(shows all database and file operations), and so on.
$DEBUG = 2;

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
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
	if ($MAINTENANCE == 1) {
		return getMaintenance();
	}

	if ($params->{'op'} eq 'robotstxt') {
		return getConfig('robotstxt');
	}
	dwarn "getNoTemplateContent params->op: $params->{'op'}";
	my $content = dispatch(\%NONTEMPLATE, $params, $user_info, $upload); 
	
	return $content;
}

# call functions that have output meant to go in the view template
#
sub getViewTemplateContent {
	my ($params, $user_info, $upload) = @_;
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
	# find function call in handler table and execute it with standard params
	#
	dwarn "getViewTemplateContent params: $params\n";
	my $content = dispatch(\%HANDLERS,$params, $user_info, $upload); 
	
	return $content;
}

# for main window, with both sidebars
#
sub getMainTemplateContent {
	my $userinf = shift;
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
	my $content = '';
	
	# op=news or op=main
	#$content = paddingTable(getTopNews($userinf));
	$content = paddingTable(getFrontPage({}, $userinf));
	dwarn "getFrontPage Finished"; 
	return $content;
}

# get the data for front page (latest news, messages) and combine with template
#
# sub getFrontPage { 
# 	my $params = shift;
# 	my $userinf = shift;
# 	my $template = XSLTemplate->new('frontpage.xsl');
# 	$template->addText("<frontpage>");

# 	# get the data and add it to be transformed by the stylesheet
# 	#
# 	my $newsxml = $stats->get('top_news');
# 	my $messagexml = $stats->get('latest_messages');

# 	#my $messages = getLatestMessagesXML($params, $userinf);
# 	$template->addText($newsxml);
# 	$template->addText($messagexml);
# 	$template->addText("</frontpage>");
# 	return $template->expand();
# }

# get the data for front page (latest news, messages) and combine with template
#
sub getFrontPage {
	my $params = shift;
	my $userinf = shift;
	dwarn "getFrontPage started";
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
#	my $template = new XSLTemplate('frontpage.xsl');

	
	my $xmlstring = '';
	my $w = new XML::Writer( OUTPUT=>\$xmlstring, UNSAFE=>1 );
	$w->startTag('frontpage');
	#latest additions
	my $la = getLatestAdditions();
	$w->startTag("latest_additions");
	$w->raw($la);
	$w->endTag("latest_additions");
	#top authors
	my $ta = getTopUsers();
	$w->startTag("top_users");
	$w->raw($ta);
	$w->endTag("top_users");
	$w->endTag('frontpage');

	
	my $xslt = getConfig("stemplate_path") . "/frontpage.xsl";
	dwarn "Before buildStringUsingXSLT";
	my $page = buildStringUsingXSLT( $xmlstring, $xslt );
	return $page;
}
# get main menu box
# 
sub getMainMenu {
	
		#my $content_type = $req->content_type;
		#dwarn "headerAndCSS started req content type: $content_type";
		#my $mail = getNewMailCount($user_info);
		#my $corrections = countPendingCorrections($user_info);
		#my $notices = getNoticeCount($user_info);
		my $xml = '';
		#my $username = $data->{'username'};
		my $writer = new XML::Writer(OUTPUT=>\$xml);
		$writer->startTag("mainmenu");
		# BEN: Roles have not been upgraded to yet
		#if ( is_editor( $user_info->{'uid'} ) ) {
		#	$writer->startTag("editor");
		#	$writer->endTag("editor");	
		#}
		##$writer->startTag("username");
		##$writer->characters($username);
		##$writer->endTag("username");
		##$writer->startTag('mail');
		##$writer->characters($mail);
		##$writer->endTag('mail');
		##$writer->startTag('notices');
		##$writer->characters($notices);
		##$writer->endTag('notices');
		##$writer->startTag('corrections');
		##$writer->characters($corrections);
		##$writer->endTag('corrections');
	    $writer->endTag("mainmenu");

		my $xslt = getConfig("stemplate_path") . "/mainmenu.xsl";
		my $mainmenubox = buildStringUsingXSLT( $xml, $xslt );

		return $mainmenubox;
}

sub getMainMenuOld {
	my $template = new XSLTemplate("mainmenu.xsl");
	dwarn("MainMenu Started");
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
	dwarn("MainMenu Before Expand");
	return makeBox("Main Menu",$template->expand());
}

# fill sidebars into a template
#
sub fillInSideBars {
	my $html = shift;
	my $params = shift;
	my $userinf = shift;
	dwarn("fillInSideBars Started");
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
	my $sidebar = new Template("sidebar.html");
	my $rightbar = new Template("rightbar.html");
	my $login = getLoginBox($userinf);
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
	dwarn("fillInSideBars Ended");
}

# fill left bar (sidebar) into a template
#
sub fillInLeftBar {
	my $html = shift;
	my $params = shift;
	my $userinf = shift;
	dwarn("fillInLeftBar Started");
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
	my $sidebar = new Template("sidebar.html");
	
	my $login = getLoginBox($userinf);
	dwarn("Before getMainMenu Started");
	my $features = getMainMenu();
	dwarn("After getMainMenu Started");
	dwarn("Before getAdminMenu Started");
	my $admin = getAdminMenu($userinf->{data}->{access});
	dwarn("After getAdminMenu Started");
	$sidebar->setKeys('login' => $login, 'admin' => $admin, 'features' => $features);
	#$sidebar->setKeys('login' => $login, 'features' => $features);
	$html->setKey('sidebar', $sidebar->expand());
	dwarn("fillInLeftBar End");
	return $html;
}

# get "top" stuff: header and CSS
#
sub headerAndCSS {
	my $template = shift;
	my $params = shift;
	
	dwarn "headerAndCSS started";
	#my $content_type = $req->content_type;
	#dwarn "headerAndCSS started req content type: $content_type";
	#my $search = getSearchBox($params);
	my $header = new Template('header.html');
	#my $style = new Template('style.css');

	#$header->setKey('search', $search);

	dwarn "headerAndCSS ended";
	$template->setKey('header', $header->expand());
	#$template->setKey('style', $style->expand());
}

# final sending of response to web request
#
sub sendOutput {
	my $req = shift;
	my $html = shift;
	my $status = shift || 200;
	my $len = bytes::length($html);

	$req->status($status);
	$req->content_type('text/html;charset=UTF-8');
#    $req->content_language('en');
	$req->headers_out->add('content-length' => $len);
#	$req->send_http_header;
	my $content_type = $req->content_type;
	dwarn "sendOutput req content type: $content_type";
	open( OUT, ">/tmp/sendOutput.html");
	print OUT $html;
	close(OUT);
	$req->print($html);
	$req->rflush(); 
}

sub sendOutputOld {
	my $req = shift;
	my $html = shift;
	my $status = shift || 200;
	dwarn "sendOutput started";
	my $len = length($html);

	#$req->status($status);
	$req->content_type('text/html;charset=UTF-8');
#    $req->content_language('en');
	#$req->headers_out->add('content-length' => $len);
	my $content_type = $req->content_type;
	dwarn "sendOutput req content type: $content_type";
#	$req->send_http_header;
	$req->print($html);
	dwarn "sendOutput ended";
	$req->rflush();  
}

sub serveImage {
	my ($req, $id) = @_;
	my $image = getImage($id);
	my $len = bytes::length($image);

	$req->content_type('image/png');
	$req->headers_out->add('content-length' => $len);
#	$req->send_http_header;
	$req->print($image);
	$req->rflush();
}

# BB: cached files stored in %CACHEDFILES
#     key exists -- file should be cached
#     key defined -- file has been cached
sub serveFile {
	my ($req, $name) = @_;
	my $html = '';
	unless (%CACHEDFILES) {
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

sub serveFileNew {
	my ($req, $name) = @_;
	my $html = '';
	unless (%CACHEDFILES) {
		my $cachelist = getConfig('cachedfiles');
		%CACHEDFILES = %$cachelist;
		foreach my $key (keys %CACHEDFILES) {
			undef $CACHEDFILES{$key};
		}
	}
	unless (defined $CACHEDFILES{$name}) {
		my $filenames = getConfig('cachedfiles');
		$CACHEDFILES{$name} = [readFile($filenames->{$name}->[0]), $filenames->{$name}->[1] ];
	}
	$html = $CACHEDFILES{$name}->[0];

	warn "reading in $name";
	my $file = readFile($name);
	my $len = bytes::length($file);
#	$req->content_type($CACHEDFILES{$name}->[1]);
	$req->headers_out->add("content-length" => "$len");
#	$req->send_http_header;
	warn "returning size = $len";
	#warn "$file";
	$req->print($file);
	$req->rflush(); 

	return;	

	unless (exists $CACHEDFILES{$name}) {
		return 404;	
	}
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
		#my $req = shift;
	#Ben, latest noosphere getting request this way
	#my $req = Apache2::Request->new(shift);
	my $req = Apache2::RequestUtil->request;
	# $req->content_type('text/plain');
	# my $dir = '/var/www/pp/data/cache/temp/95/l2h';
	# my $renderProgram = getConfig('latex2htmlcmd');
	# local $CWD = "$dir"; 
	# #my $retval = system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." $fname >error.out 2>&1");
	# my $fname = "Test.tex";
	# my $command = getConfig('base_dir'). $renderProgram .getConfig('l2h_opts')." $fname >error.out 2>&1";
	# my $output = `$command`;
	# $req->print("Command: $command\nCommand Output:\n$output");
	# return Apache2::Const::OK;

	#my $req = Apache->request();
        #my $PPreq = Apache2::RequestUtil->request();
	#dwarn $PPreq->param();
	my $content_type = $req->content_type;
	dwarn "Before parseParams started req content type: $content_type";
	my ($params,$upload) = parseParams($req);
        #dwarn "Params";
        #dwarn $params;
        #dwarn "Upload";
        #dwarn $upload;
	dwarn "After parseParams";
	$content_type = $req->content_type;
	dwarn "After parseParams started req content type: $content_type";
	my %cookies = parseCookies($req);
	dwarn "After parseCookies";
	dwarn "cookies:\n @{[%cookies]}\n";
	my $html = '';

	$AllowCache = 0;	# default to allow client caching

	# uri remapping
	# we use this instead of a mod_rewrite-ish thing
	#
	my $uri = $req->uri();
	dwarn "req->uri:\n$uri";
	# deny IIS virii requests
	#
	if ($uri =~ /[aA]dmin\.dll/o || 
		$uri =~ /root\.exe/o ||
		$uri =~ /winnt/o ||
		$uri =~ /cmd\.exe/o ) {
		dwarn "URI: IIS Virii request";		
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

		dwarn "*** BANNED REQUEST *** host $ENV{REMOTE_ADDR} with client $ENV{HTTP_USER_AGENT} was rejected!";

		exit;	
	} 
	# BB: cached files serving
	if ($uri =~ /\/files\/(.+)$/o) { 
		dwarn "URI: Cached files serving";
		return serveFile($req,$1);
	}
	# remapping
	#
	if ($uri =~ /\/[Ee]ncyclopedia\/(.+)\.htm[l]{0,1}(#.+)?$/o ||
			$uri =~ /^\/([^\/]+)\.htm[l]{0,1}(#.+)?$/) {
		dwarn "URI: remapping";
		$params->{'op'} = 'getobj';
		$params->{'from'} = getConfig('en_tbl');
		my $basename = $1;
		if ($basename =~ /^\d+$/) {
			$params->{'id'} = $basename;
		} else {
			$params->{'name'} = $basename;
		}
	} elsif ($uri =~ /\/[Ee]ncyclopedia\/([0-9A-Z])[\/]{0,1}$/o) {
		dwarn "URI: remapping idx";
		my $ord = ord($1);
		$params->{'op'} = 'en';
		$params->{'idx'} = "$ord";
	
	} elsif ($uri =~ /\/[Ee]ncyclopedia[\/]{0,1}$/o) {
		dwarn "URI: remapping En";
		$params->{'op'} = 'en';
	}
	elsif ($uri =~ /\/browse\/([^\/]+)\/([^\/]+)\/$/o) {

		my $from = $1;
		my $id = $2;
		dwarn "URI: remapping op from id";
		$params->{'op'} = 'mscbrowse';
		$params->{'from'} = $from;
		$params->{'id'} = $id;
	}

	elsif ($uri =~ /\/browse\/([^\/]+)\/$/o) {

		my $from = $1;
		dwarn "URI: remapping op from";
		$params->{'op'} = 'mscbrowse';
		$params->{'from'} = $from;
	}

	# remap to display robots.txt directives
	#
	if ($uri =~ /\/robots\.txt$/o) {
		dwarn "URI: robotstxt";
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
	dwarn "Request URI: \n $uri";

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
		dwarn "servImage before";
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
	$content_type = $req->content_type;
	dwarn "getNoTemplateContent started req content type: $content_type";
	$html = getNoTemplateContent($params, \%user_info, $upload);
	# if none, process template stuff
	#
	if ($html eq '') {
		dwarn "No params process template stuff";
		$content_type = $req->content_type;
		dwarn "No params process template stuff started req content type: $content_type";
		my $content;
		my $template;
		$NoosphereTitle = '';
		dwarn "Process Template inputs, params:\n$params";
		dwarn "hash params:\n @{[$params]}\n";
		$content = getViewTemplateContent($params,\%user_info,$upload);
		#dwarn "getViewTemplateContent: content:\n$content";
		if ($content ne '' ) {
			
			
			dwarn "view.html template"; 
			$content_type = $req->content_type;
			dwarn "view.html started req content type: $content_type";
			$template = new Template('view.html');
			fillInLeftBar($template,$params,\%user_info);
			$template->setKeys('content' => $content, 'NoosphereTitle' => $NoosphereTitle);
			headerAndCSS($template, $params);
			#
			my $nocache = '
			<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
			<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
			<META HTTP-EQUIV="Expires" CONTENT="-1">';

			$template->setKey('metacache', ($AllowCache ? '' : $nocache));

			$html = $template->expand();
			#warn "building with:\n\n\n\n\n\n\n\n$mainpage\n\n\n\n\n\n\n";
			open( OUT, ">/tmp/view.xml");
			print OUT $html;
			close(OUT);
			# handle caching
		
		
			sendOutput( $req, $html );
			
			return;
			#dwarn "view.html template"; 
			#$template = new Template('view.html');
			#fillInLeftBar($template,$params,\%user_info);
			#dwarn "After fillInLeftBar";
			#dwarn "NoosphereTitle: NoosphereTitle, content fill:\n$content";
			#$template->setKeys('content' => $content, 'NoosphereTitle' => $NoosphereTitle);
		}
		# front page
		else {

			$content_type = $req->content_type;
			dwarn "frontpage started req content type: $content_type";
			$content = buildMainPage(\%user_info);
			#warn "content = $content";
			sendOutput($req, $content);
			warn "got past opening main.html template content\n";
			return;	

		}

		#headerAndCSS($template, $params);
	
		# handle caching
		#
		#my $nocache = '
		#<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
		#<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
		#<META HTTP-EQUIV="Expires" CONTENT="-1">';

		#$template->setKey('metacache', ($AllowCache ? '' : $nocache));
		#$html = $template->expand();

		#open( OUT, ">/tmp/viewpage.xml");
		#print OUT $html;
		#close(OUT);
		
	} 
	return;
	
	# finish and send output
	#
	#dwarn "Before sending output";
	#sendOutput($req, $html);
	#dwarn "After sending output";
#	$dbh->disconnect();
}

sub buildMainPage {
	my $userinf = shift;
	
	#get login from template
	# if the login succeeds we need to display the menu otherwise a login
	# TODO - prompt with a possible error message.
	my $headt = new Template( 'head.html' );
	my $head = $headt->expand();

	my $headert = new Template( 'header.html' );
	my $header = $headert->expand();

	
	my $loginbox = getLoginBox($userinf);

	#my $xslt = getConfig("stemplate_path") . "/logos.xsl";
	#my $logosbox = buildStringUsingXSLT( '<temp></temp>', $xslt );

	my $mainMenubox = getMainMenu();
	
	my $xmlstring = '';
	my $writer = new XML::Writer( OUTPUT=>\$xmlstring, UNSAFE=>1 );
	$writer->startTag("mainpage");
	my $la = getLatestAdditions();
	$writer->startTag("latestadditions");
	$writer->raw($la);
	$writer->endTag("latestadditions");
	#top authors
	my $ta = getTopUsers();
	$writer->startTag("topusers");
	#$writer->raw($ta);
	$writer->endTag("topusers");
	$writer->raw($head);
	$writer->startTag("header");
	$writer->raw($header);
	$writer->endTag("header");
	$writer->startTag("login");
	$writer->raw($loginbox);
	$writer->endTag("login");
	#$writer->raw($logosbox);
	$writer->startTag("mainmenu");
	$writer->raw($mainMenubox);
	$writer->endTag("mainmenu");
	
	$writer->endTag("mainpage");


	my $xslt = getConfig("stemplate_path") . "/mainpage.xsl";

	#warn "building with:\n\n\n\n\n\n\n\n$xmlstring\n\n\n\n\n\n\n";
	open( OUT, ">/tmp/xmlstring.xml");
	print OUT $xmlstring;
	close(OUT);
	
	my $mainpage = buildStringUsingXSLT( $xmlstring, $xslt );

	#warn "building with:\n\n\n\n\n\n\n\n$mainpage\n\n\n\n\n\n\n";
	open( OUT, ">/tmp/mainpage.xml");
	print OUT $mainpage;
	close(OUT);

	

	return $mainpage;

}

sub buildViewPage {
	my $content = shift;
	my $userinf = shift;
	my $params  = shift;

	#tidy up the content so that we know we have valid xhtml
	##my $tidy = HTML::Tidy->new( {
    ##                       output_xhtml => 1,
    ##                });
	#my $allclean = $tidy->clean($content);
	#extract out only the body
	#$allclean =~ /<body.*?>(.*?)<\/body>/sio;
	#my $clean = $1;
	#$content = $clean;

#	warn "buildViewPage [$content]\n";
	
	#get login from template
	# if the login succeeds we need to display the menu otherwise a login
	# TODO - prompt with a possible error message.
	##my $headt = new Template( 'head.html' );

	#set jsmathcode
	##my $head = $headt->expand();

	##my $headert = new Template( 'header.html' );
	##my $header = $headert->expand();

	
	##my $loginbox = getLoginBox($userinf);

	#my $xslt = getConfig("stemplate_path") . "/logos.xsl";
	#my $logosbox = buildStringUsingXSLT( '<temp></temp>', $xslt );


	##my $xmlstring = '';
	##my $writer = new XML::Writer( OUTPUT=>\$xmlstring, UNSAFE=>1 );
	##$writer->startTag("viewpage");
	##$writer->raw($head);
	##$writer->startTag("header");
	##$writer->raw($header);
	##$writer->endTag("header");
	##$writer->startTag("login");
	##$writer->raw($loginbox);
	##$writer->endTag("login");
	#$writer->raw($logosbox);
	##$writer->startTag("content");
	##$writer->raw($content);
	##$writer->endTag("content");
	##$writer->endTag("viewpage");

	#my $xslt = getConfig("stemplate_path") . "/view.xsl";
	#my $page = buildStringUsingXSLT( $xmlstring, $xslt );
	#return $page;
	my $template = new Template('view.html');

	fillInLeftBar($template,$params,$userinf);
	##$template->addText($xmlstring);
	
	$template->setKeys('content' => $content, 'NoosphereTitle' => $NoosphereTitle);
	headerAndCSS($template, $params);
	my $nocache = '
		<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
		<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
		<META HTTP-EQUIV="Expires" CONTENT="-1">';

	$template->setKey('metacache', ($AllowCache ? '' : $nocache));
	my $html = '';
	dwarn "buildViewPage before expand";
	$html = $template->expand();
	#dwarn "buildViewPage after  expand, html: \n$html";
	
	return $html;

}

1;
