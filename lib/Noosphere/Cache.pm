package Noosphere;

use strict;
	
require Noosphere::Filebox;
require Noosphere::Encyclopedia;
require Noosphere::Crossref;
require Noosphere::Layout;
require Noosphere::Latex;
require Noosphere::TemplateNS;

# entry point for getting an image which is a single TeX math object.
#
sub getRenderedContentImage	{
	my $math = shift;
	my $variant = shift;
	my $make = shift;

	my ($url, $align) = getRenderedContentImageURL($math, $variant, $make);

	# return the HTML for the image URL to the image 
	return "<img title=\"\$".qhtmlescape($math)."\$\" alt=\"\$".qhtmlescape($math)."\$\" align=\"$align\" border=\"0\" src=\"$url\" />";
}

# get the URL (and align) for an image of a single TeX math environment object
#
sub getRenderedContentImageURL	{
	my $math = shift;
	my $variant = shift;
	my $make = shift || getConfig('single_render_variants');

	# render the math if it isn't in the db
	# 
	if (!variant_exists($math, $variant)) {
		singleRenderLaTeX($math, $make);
	} 

	# get unique id of the image variant
	my $id = lookupfield(getConfig('rendered_tbl'), "uid", "imagekey='".sq($math)."' and variant='".sq($variant)."'");

	# get the align mode
	my $align = lookupfield(getConfig('rendered_tbl'), "align", "imagekey='".sq($math)."' and variant='".sq($variant)."'") || 'bottom';

	# return the URL and alignment
	#
	return (getConfig("main_url")."/?op=getimage&amp;id=$id", $align);
}

# get image data from database based on its id
# 
sub getImage {
	my $id = shift;

	my $image = lookupfield(getConfig('rendered_tbl'), "image", "uid=$id");

	return $image;
}

# main entry point for full rendering of a document. returns some HTML which
# can be output to display the rendered docuemnt.
#
sub getRenderedContentHtml {
	my $table = shift;
	my $rec = shift;
	my $method = shift || 'l2h';	 # default default

	my $html = '';
	
	my ($valid,$build) = getcacheflags($table, $rec->{'uid'}, $method);
	
	if ($valid == 0) {
		if (!getConfig('on_demand_rendering_enabled')) {
			return "<br />This entry needs to be rendered, but on-demand rendering is temporarily disabled while Physics Library is under heavy load. Please try again later.<br />";
		}

		#dwarn "object not valid, rerender/build";
		if (! cacheObject($table, $rec, $method)) {
			$html .= "<br />Timed out waiting for render.	Please wait a few seconds and try again (for longer documents, give more time.)<br />";
			return $html;
		}
	}

	# read in the planetmath.html file for the method
	#
	return getRenderedObjectHtml($table, $rec->{'uid'}, $method);
}

# build an object and place it in the cache
#
sub cacheObject {	
	my $table = shift;
	my $rec = shift;
	my $method = shift;
	
	my $id = $rec->{'uid'};
	my $count = 0;
	my $max = getConfig('build_timeout');
	my $latex = '';
	
	my ($valid,$build) = getcacheflags($table,$id,$method);

	#dwarn "cacheObject started";
	# not valid, but building, so wait
	#
	if ($build == 1)	{
		do { 
		sleep 1;
			print "Not valid, but bulding\n";
			if ($count >= $max) { return 0; }
				($valid,$build) = getcacheflags($table,$id,$method);
			$count++;
		} while ($valid == 0 && $build == 1);
	}
	# not valid, and not building, so build it
	#
	else { 
		print "not valid and not building, so build it\n";
		setbuildflag_on($table, $id, $method);
		cleanCache($table, $id, $method);
		cacheFileBox($table, $id, $method);

		if ($table eq getConfig('en_tbl')) {
			print "prepareEntryForRendering start\n";
			my ($output, $links) = prepareEntryForRendering(
				0,
				$rec->{'preamble'},
				$rec->{'data'},
				$method,
				$rec->{'title'},
				[@{getSynonymsList($rec->{'uid'})},@{getDefinesList($rec->{'uid'})}],
				$table,
				$rec->{'uid'},
				classstring($table,$rec->{'uid'}));
			print "prepareEntryForRendering end\n";
			print "renderLaTeX start\n";
			renderLaTeX($table, $rec->{'uid'}, $output, $method, $rec->{'name'});
			print "renderLaTeX end\n";
			print "writeLinksToFile start\n";
			writeLinksToFile($table, $id, $method, $links);
			print "writeLinksToFile end\n";
		}

		elsif ($table eq getConfig('collab_tbl')) {
			print "renderLaTeX coolab_tbl start\n";
			my $name = normalize($rec->{'title'});
			renderLaTeX($table, $rec->{'uid'}, $rec->{'data'}, $method, $name);
			print "renderLaTeX coolab_tbl end\n";
		}
		print "setbuildflag_off start\n";
		setbuildflag_off($table, $id, $method);
		print "setbuildflag_off end\n";
		print "setbuildflag_on start\n";
		setvalidflag_on($table, $id, $method);
		print "setbuildflag_on end\n";
	}

	return 1;
}

# Read one brace-delimited LaTeX argument, preserving nested groups.  This is
# used when native renderers transform Noosphere's HTML-only link commands.
#
sub readBracedLaTeXArgument {
	my $text = shift;
	my $start = shift;

	return (undef, undef)
		if (!defined($start) || substr($text, $start, 1) ne '{');

	my $depth = 1;
	my $content_start = $start + 1;
	my $i = $content_start;
	my $length = length($text);

	while ($i < $length) {
		my $char = substr($text, $i, 1);

		# Skip an escaped character so \{ and \} do not affect brace depth.
		if ($char eq '\\') {
			$i += 2;
			next;
		}

		if ($char eq '{') {
			$depth++;
		} elsif ($char eq '}') {
			$depth--;
			if ($depth == 0) {
				return (
					substr($text, $content_start, $i - $content_start),
					$i + 1
				);
			}
		}

		$i++;
	}

	return (undef, undef);
}

# Page-image PNGs cannot preserve hyperlinks, so flatten Noosphere's
# \htmladdnormallink commands to their visible anchor text.
#
sub stripNativeRenderLinks {
	my $latex = shift;
	my $command = '\\htmladdnormallink';
	my $offset = 0;

	while ((my $start = index($latex, $command, $offset)) >= 0) {
		my $pos = $start + length($command);
		$pos++ while ($pos < length($latex) && substr($latex, $pos, 1) =~ /\s/);

		my ($anchor, $after_anchor) = readBracedLaTeXArgument($latex, $pos);
		if (!defined($after_anchor)) {
			$offset = $pos;
			next;
		}

		$pos = $after_anchor;
		$pos++ while ($pos < length($latex) && substr($latex, $pos, 1) =~ /\s/);

		my (undef, $after_url) = readBracedLaTeXArgument($latex, $pos);
		if (!defined($after_url)) {
			$offset = $pos;
			next;
		}

		substr($latex, $start, $after_url - $start, $anchor);
		$offset = $start + length($anchor);
	}

	return $latex;
}

# PDF output can preserve links natively.  Convert Noosphere's intermediate
# HTML link representation into hyperref's \href command.  protectURL() and
# protectAnchor() HTML-escape ampersands for non-l2h methods, so translate them
# back to the appropriate LaTeX/PDF forms here.
#
sub convertPdfRenderLinks {
	my $latex = shift;
	my $command = '\\htmladdnormallink';
	my $offset = 0;

	while ((my $start = index($latex, $command, $offset)) >= 0) {
		my $pos = $start + length($command);
		$pos++ while ($pos < length($latex) && substr($latex, $pos, 1) =~ /\s/);

		my ($anchor, $after_anchor) = readBracedLaTeXArgument($latex, $pos);
		if (!defined($after_anchor)) {
			$offset = $pos;
			next;
		}

		$pos = $after_anchor;
		$pos++ while ($pos < length($latex) && substr($latex, $pos, 1) =~ /\s/);

		my ($url, $after_url) = readBracedLaTeXArgument($latex, $pos);
		if (!defined($after_url)) {
			$offset = $pos;
			next;
		}

		$anchor =~ s/&amp;/\\&/g;
		$url =~ s/&amp;/&/g;

		my $replacement = "\\href{$url}{$anchor}";
		substr($latex, $start, $after_url - $start, $replacement);
		$offset = $start + length($replacement);
	}

	return $latex;
}

# prepares an entry for rendering :
#	- combine with template
#	- get supplementary packages
#	- do cross-referencing
#
sub prepareEntryForRendering {
	my $newent = shift;	 # new entry flag
	my $preamble = shift;
	my $latex = shift;
	my $method = shift;
	my $title = shift;
	my $syns = shift;
	my $table = shift;
	my $id = shift;
	my $class = shift;
	
	#dwarn "prepareEntryForRendering start cwd: $CWD";
	my $file = getConfig('entry_template');
	my $template = new TemplateNS($file);	
 
	# handle cross-referencing 
	#
	my ($linked,$links) = crossReferenceLaTeX($newent,$latex,$title,$method,$syns,$id,$class);
	$linked = dolinktofile($linked,$table,$id);	# handle \PMlinktofile
	
	# png uses the pre-processed output; hyperlink directives are flattened to
	# their visible text because page images do not preserve clickable links.
	#
	if ($method eq "png") {
		$latex = stripNativeRenderLinks($linked);
	}
	
	# l2h uses the cross-referenced text as primary output
	#
	if ($method eq "l2h") {
		$latex = $linked;
	}

	# PDF uses native hyperref links rather than the old MAP/image-map path.
	#
	if ($method eq "pdf") {
		$latex = convertPdfRenderLinks($linked);
		if ($latex =~ /\\href\s*\{/ &&
			(!defined($preamble) || $preamble !~ /\\usepackage(?:\[[^\]]*\])?\{hyperref\}/)) {
			$preamble = '' if (!defined($preamble));
			$preamble .= "\n\\usepackage[colorlinks=true,linkcolor=blue,citecolor=blue,urlcolor=blue]{hyperref}\n";
		}
	}

	# make4ht uses the cross-referenced text as primary output so links remain.
	#
	if ($method eq "make4ht") {
		$latex = $linked;
	}

	# calculate supplementary packages to add (this now only includes
	# the html package, for linking)
	#
	my $packages = supplementaryPackages($latex,getConfig('latex_packages'),getConfig('latex_params'));
	
	# combine with template
	#
	$template->setKeys('preamble' => $preamble, 'math' => $latex);
	if (nb($packages)) { $template->setKey('packages', $packages) if (nb($packages)); }

	#dwarn "prepareEntryForRendering end cwd: $CWD";

	if ( $method eq "src" ) {
		return ($latex,$links);
	} else {
		my $returnTemplate = $template->expand();
		#dwarn "links:\n $links";
		#dwarn "prepareEntryForRendering template:\n$returnTemplate";
		return ($returnTemplate,$links);
	}
}

# cache flag util functions
#
sub setbuildflag_on {
	my $table = shift;
	my $id = shift;
	my @methods = @_;

	my $ctbl = getConfig('cache_tbl');

	my $methodq = '';
	$methodq = " and (".join(' or ',map("method='$_'",@methods)).")" if (@methods);

	(my $rv, my $sth) = dbUpdate($dbh,{WHAT => $ctbl, SET => 'build=1, touched=CURRENT_TIMESTAMP',
		 WHERE => "tbl='$table' and objectid=$id $methodq"});	
	$sth->finish();
}

sub setbuildflag_off {
	my $table = shift;
	my $id = shift;
	my @methods = @_;
	
	my $ctbl = getConfig('cache_tbl');

	my $methodq = '';
	$methodq = " and (".join(' or ',map("method='$_'",@methods)).")" if (@methods);

	(my $rv, my $sth) = dbUpdate($dbh,{WHAT => $ctbl, SET => 'build=0, touched=CURRENT_TIMESTAMP',
		 WHERE => "tbl='$table' and objectid=$id $methodq"}); 
	$sth->finish();
}
									 
sub setvalidflag_on {
	my $table = shift;
	my $id = shift;
	my @methods = @_;
 
	my $ctbl = getConfig('cache_tbl');

	my $methodq = '';
	$methodq = " and (".join(' or ',map("method='$_'",@methods)).")" if (@methods);

	(my $rv, my $sth) = dbUpdate($dbh,{WHAT => $ctbl, SET => 'valid=1, touched=CURRENT_TIMESTAMP',
		WHERE => "tbl='$table' and objectid=$id $methodq"}); 
	$sth->finish();
}

sub setvalidflag_off {
	my $table = shift;
	my $id = shift;
	my @methods = @_;

	my $ctbl = getConfig('cache_tbl');
 
	my $methodq = '';
	$methodq = " and (".join(' or ',map("method='$_'",@methods)).")" if (@methods);
	
	(my $rv, my $sth) = dbUpdate($dbh,{WHAT => $ctbl, SET => 'valid=0, touched=CURRENT_TIMESTAMP',
		 WHERE => "tbl='$table' and objectid=$id $methodq"}	); 
	$sth->finish();
}
 
# deletecacheflags - useful for removing cache flags for removed entries.
#
sub deletecacheflags {
	my $table = shift;
	my $id = shift;
	my @methods = @_;
 
	my $ctbl = getConfig('cache_tbl');

	my $methodq = '';
	$methodq = " and (".join(' or ',map("method='$_'",@methods)).")" if (@methods);
	
	my ($rv,$sth) = dbDelete($dbh,{FROM=>$ctbl,WHERE=>"objectid=$id and tbl='$table' $methodq"});
	$sth->finish();
}

# getcacheflags - also makes new entry if there isn't one
#
sub getcacheflags {
	my $table = shift;
	my $id = shift;
	my $method = shift;
	
	my $row;

	my $ctbl = getConfig('cache_tbl');

	my ($rv,$sth) = dbSelect($dbh,{WHAT=>'valid,build',FROM=>$ctbl,
					 WHERE=>"tbl='$table' and objectid=$id and method='$method'"});
	$row = $sth->fetchrow_hashref();
	$sth->finish();
	
	# if we got back nothing, create a new cache entry for the method and object
	#
	if (not defined $row->{valid}) {
		($rv,$sth) = dbInsert($dbh,{INTO=>$ctbl,COLS=>'tbl,objectid,method,touched',
						VALUES=>"'$table',$id,'$method',CURRENT_TIMESTAMP"});
	$sth->finish();
		return (0,0);
	}
	
	# otherwise return cache values for existing entry
	#
	return ($row->{valid},$row->{build});
}
 
1;
