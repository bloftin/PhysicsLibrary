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
			my $output = prepareCollabForRendering($rec->{'data'}, $method);
			renderLaTeX($table, $rec->{'uid'}, $output, $method, $name);
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

# Replace a two-argument LaTeX command while respecting nested braces in each
# argument.  The replacer receives the visible anchor and URL arguments.
#
sub replaceTwoArgRenderCommand {
	my $latex = shift;
	my $command = shift;
	my $replacer = shift;
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

		my $replacement = $replacer->($anchor, $url);
		substr($latex, $start, $after_url - $start, $replacement);
		$offset = $start + length($replacement);
	}

	return $latex;
}

# Page-image PNGs cannot preserve hyperlinks, so flatten Noosphere's link
# commands to their visible anchor text.
#
sub stripNativeRenderLinks {
	my $latex = shift;

	foreach my $command ('\\htmladdnormallink', '\\PMlinkexternal') {
		$latex = replaceTwoArgRenderCommand($latex, $command, sub {
			my ($anchor, $url) = @_;
			return $anchor;
		});
	}

	return $latex;
}

# LaTeX2HTML understands \htmladdnormallink but not PhysicsLibrary's
# \PMlinkexternal command unless an entry preamble happens to define it.
#
sub convertL2HRenderLinks {
	my $latex = shift;

	$latex = replaceTwoArgRenderCommand($latex, '\\PMlinkexternal', sub {
		my ($anchor, $url) = @_;
		return "\\htmladdnormallink{$anchor}{$url}";
	});

	return $latex;
}

# PDF and make4ht output can preserve links natively.  Convert Noosphere's
# link commands into hyperref's \href command.
# protectURL() and protectAnchor() HTML-escape ampersands for non-l2h methods,
# so translate them back to the appropriate LaTeX forms here.
#
sub convertHyperrefRenderLinks {
	my $latex = shift;

	foreach my $command ('\\htmladdnormallink', '\\PMlinkexternal') {
		$latex = replaceTwoArgRenderCommand($latex, $command, sub {
			my ($anchor, $url) = @_;
			$anchor =~ s/&amp;/\\&/g;
			$url =~ s/&amp;/&/g;

			return "\\href{$url}{$anchor}";
		});
	}

	return $latex;
}

sub addHyperrefPackage {
	my $preamble = shift;

	if (!defined($preamble) || $preamble !~ /\\usepackage(?:\[[^\]]*\])?\{hyperref\}/) {
		$preamble = '' if (!defined($preamble));
		$preamble .= "\n\\usepackage[colorlinks=true,linkcolor=blue,citecolor=blue,urlcolor=blue]{hyperref}\n";
	}

	return $preamble;
}

sub addPDFLinkSupport {
	my $preamble = shift;

	$preamble = addHyperrefPackage($preamble);
	if ($preamble !~ /\\(?:providecommand|newcommand|renewcommand)\s*\{\\PMlinkexternal\}/) {
		$preamble .= "\n\\providecommand{\\PMlinkexternal}[2]{%\n";
		$preamble .= "  \\href{#2}{#1}%\n";
		$preamble .= "}\n";
	}

	return $preamble;
}

sub addHyperrefToLaTeXDocument {
	my $latex = shift;

	return $latex if ($latex =~ /\\usepackage(?:\[[^\]]*\])?\{hyperref\}/);

	my $package = "\\usepackage[colorlinks=true,linkcolor=blue,citecolor=blue,urlcolor=blue]{hyperref}\n";
	if ($latex =~ s/(\\begin\{document\})/$package$1/) {
		return $latex;
	}

	return $package.$latex;
}

sub addLatexPackageToDocument {
	my $latex = shift;
	my $package = shift;

	return $latex if ($latex =~ /\\usepackage(?:\[[^\]]*\])?\{$package\}/);

	my $include = "\\usepackage{$package}\n";
	if ($latex =~ s/(\\begin\{document\})/$include$1/) {
		return $latex;
	}

	return $include.$latex;
}

sub escapeRawHTML {
	my $text = shift;

	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;

	return $text;
}

sub convertL2HVerbatimBlocks {
	my $latex = shift;

	$latex =~ s{\\begin\{(verbatim\*?|Verbatim|lstlisting)\}(.*?)\\end\{\1\}}{
		my $body = escapeRawHTML($2);
		"\\begin{rawhtml}<pre>$body</pre>\\end{rawhtml}";
	}egs;

	return $latex;
}

sub hasLiveL2HTikzContent {
	my $latex = shift || '';

	$latex = remove_literal_latex_blocks($latex);
	$latex =~ s/^.*?\\begin\{document\}//s;
	$latex =~ s/\\end\{document\}.*$//s;

	return 1 if ($latex =~ /\\begin\{tikzpicture\}/);
	return 1 if ($latex =~ /\\begin\{axis\}/);
	return 1 if ($latex =~ /\\begin\{pgfpicture\}/);
	return 1 if ($latex =~ /\\tikz\b/);

	return 0;
}

sub stripL2HTikzPreambleOnly {
	my $latex = shift;

	return $latex if (hasLiveL2HTikzContent($latex));

	$latex =~ s/^[ \t]*\\usepackage(?:\[[^\]]*\])?\{[^}]*\b(?:tikz|pgfplots)\b[^}]*\}[ \t]*(?:\r?\n)?//mg;
	$latex =~ s/^[ \t]*\\usetikzlibrary\b[ \t]*(?:\[[^\]]*\])?\{[^}]*\}[ \t]*(?:\r?\n)?//mg;
	$latex =~ s/^[ \t]*\\pgfplotsset\b[ \t]*\{[^}]*\}[ \t]*(?:\r?\n)?//mg;

	return $latex;
}

sub prepareCollabForRendering {
	my $latex = shift;
	my $method = shift;

	if ($method eq "png") {
		return stripNativeRenderLinks($latex);
	}

	if ($method eq "l2h") {
		$latex = stripL2HTikzPreambleOnly($latex);
		$latex = convertL2HVerbatimBlocks($latex);
		$latex = convertL2HRenderLinks($latex);
		$latex = addLatexPackageToDocument($latex, 'html') if ($latex =~ /\\(?:htmladdnormallink|begin\{rawhtml\})/);
		return $latex;
	}

	if ($method eq "pdf" || $method eq "make4ht") {
		$latex = convertHyperrefRenderLinks($latex);
		$latex = addHyperrefToLaTeXDocument($latex) if ($latex =~ /\\href\s*\{/);
		return $latex;
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
		$preamble = addPDFLinkSupport($preamble) if ($latex =~ /\\(?:href|PMlinkexternal)\s*\{/);
	}
	
	# l2h uses the cross-referenced text as primary output
	#
	if ($method eq "l2h") {
		$latex = convertL2HRenderLinks($linked);
	}

	# PDF uses native hyperref links rather than the old MAP/image-map path.
	#
	if ($method eq "pdf") {
		$latex = convertHyperrefRenderLinks($linked);
		$preamble = addPDFLinkSupport($preamble) if ($latex =~ /\\(?:href|PMlinkexternal)\s*\{/);
	}

	# make4ht handles hyperref links cleanly; the old html package command is
	# latex2html-specific and can render as plain text.
	#
	if ($method eq "make4ht") {
		$latex = convertHyperrefRenderLinks($linked);
		$preamble = addPDFLinkSupport($preamble) if ($latex =~ /\\(?:href|PMlinkexternal)\s*\{/);
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
