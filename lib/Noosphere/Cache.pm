package Noosphere;

use strict;
	
require Noosphere::Filebox;
require Noosphere::Encyclopedia;
require Noosphere::Crossref;
require Noosphere::Layout;
require Noosphere::Latex;
require Noosphere::Template;

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
	
	my $file = getConfig('entry_template');
	my $template = new Template($file);	
 
	# handle cross-referencing 
	#
	my ($linked,$links) = crossReferenceLaTeX($newent,$latex,$title,$method,$syns,$id,$class);
	$linked = dolinktofile($linked,$table,$id);	# handle \PMlinktofile
	
	# png uses the pre-processed output; that is, link directives are removed.
	#
	if ($method eq "png") {
		$latex = $linked;
	}
	
	# l2h uses the cross-referenced text as primary output
	#
	if ($method eq "l2h") {
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

	if ( $method eq "src" ) {
		return ($latex,$links);
	} else {
		return ($template->expand(),$links);
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
