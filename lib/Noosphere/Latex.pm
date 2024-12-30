package Noosphere;

use strict;
use Noosphere::Util;
use Noosphere::Charset;
use HTML::Entities;
use Cwd;

# needed for when we require images.pl
#
use vars qw{%cached_env_img $reruns};

# a regexp string which will match any command that indicates we need to run
# LaTeX twice.
$reruns = "ref|eqref|cite";

# mangle a given title into a index-form title 
# ("proof of blah" => "blah, proof of")
#
sub mangleTitle {
	my $title = shift;

	($title, my $math) = escapeMathSimple($title);

	my $modified = 0;
	while ($title =~ /^\s*(proof|derivation|example[s]?|of|that|the|an|any|a)\s+(.+)/) {
		my $end = $1;	 # piece to move to end
		my $beg = $2;	 # new beginning 

		my $com = $modified ? '' : ',';
		$title = $beg . $com . ' ' . $end;
		$modified = 1;
	}

	return unescapeMathSimple($title, $math);
}

# simple "escape" of math.. take $.?$ sections and replace them with 
# unambiguous, single-word tags that are relatively inert to other processing.
#
sub escapeMathSimple {
	my $text = shift;

	my $copy = $text;
	my @math = ();
	my $idx = 0;

	while ($copy =~ /(\$.+?\$)/g) {
		my $chunk = $1;
		push @math, $chunk;
		$text =~ s/\Q$chunk\E/##$idx##/;
		$idx++;
	}

	return ($text, [@math]);
}

# reverse the above -- replace unique identifiers with the original math
#
sub unescapeMathSimple {
	my $text = shift;
	my $math = shift;

	# reversing is much simpler....
	#
	$text =~ s/##(\d+)##/$math->[$1]/g;
	
	return $text;
}

# supplementaryPackages - determine what additional packages must be included
# based on a command=>package hash and some text. 
# returns a bunch of \usepackage{}'s as one chunk
# of text
#
sub supplementaryPackages {
	my $latex = shift;
	my $lookup = shift;
	my $params = shift;

	my %includehash;

	# loop through the commands in the lookup table looking for them in the latex
	#
	foreach my $command (keys %$lookup) {
		$includehash{$lookup->{$command}}=1 if ($latex=~/\\$command([\{\[\s])/s);
	}

	my @includes;
	foreach (keys %includehash) {
		push @includes,"\\usepackage[$params->{$_}]{$_}" if (defined $params->{$_});
		push @includes,"\\usepackage{$_}";
	}
	my $include = join("\n",@includes);

	return $include;
}

# same as above but detect "environment-style" commands
#
sub supplementaryEnvPackages {
	my $latex = shift;
	my $lookup = shift;
	my $params = shift;

	my %includehash;

	# loop through the commands in the lookup table looking for them in the latex
	#
	foreach my $command (keys %$lookup) {
		$includehash{$lookup->{$command}}=1 if ($latex=~/\\begin\{$command\}/s);
	}

	my @includes;
	foreach (keys %includehash) {
		push @includes,"\\usepackage[$params->{$_}]{$_}" if (defined $params->{$_});
	push @includes,"\\usepackage{$_}";
	}
	my $include=join("\n",@includes);

	return $include;
}

# check to see if a singly rendered math chunk exists in the database
#
sub variant_exists {
	my $math = shift;
	my $variant = shift;

	my ($rv, $sth) = dbSelect($dbh, {WHAT=>'uid', FROM=>getConfig('rendered_tbl'), WHERE=>"imagekey = '".sq($math)."' and variant = '".sq($variant)."'"});
	my $rowcount = $sth->rows();
	$sth->finish();

	return $rowcount;
}

# the low-level interface to rendering a single math environment to a png image
#
sub singleRenderLaTeX {
	my $math = shift;
	my $variants = shift || getConfig('single_render_variants');
	dwarn "singleRenderLaTeX started";
	# make a rendering directory in /tmp
	# 
	my $suffix = 0;
	my $root = getConfig('single_render_root');
	while (-e "$root$suffix") {
		$suffix++;
	}
	my $dir = $root . $suffix;
	dwarn "singleRenderLaTeX dir to make: $dir";
	mkdir $dir;
	dwarn "after mkdir $dir;";

	# copy over templates we need
	#
	my $template_root = getConfig('stemplate_path');
	`cp "$template_root/.latex2html-singlerender-init" $dir/.latex2html-init`;

	my $prefix = getConfig('single_render_template_prefix');

	# loop through each variant, render the math and load the image into the 
	# database (if its not there already, this is a last line of defens failsafe)
	# 
	foreach my $variant (@$variants) {
	next if (variant_exists($math, $variant));

	# do the rendering
	#
	require Noosphere::Template;
	my $template = new Template($prefix . "_$variant.tex");
	$template->setKey('math', $math);
	writeFile("$dir/single_render.tex", $template->expand());
	chdir $dir;
        #Ben - error.out is filling the harddrive, remove for now
        my $retval = system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." single_render.tex > /dev/null 2>&1");
        #my $retval = system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." single_render.tex > /dev/null 2>&1");

	# abort if a render failed
	#
	if ($retval > 0) {
                        `rm -rf $dir`;
			return $retval;
	}

	# read in the resulting image, convert binary data to octal 
	#
	my $image;
	$image = octify(readFile($dir . '/img1.png')) if getConfig('dbms') eq 'pg';
	$image = readFile($dir . '/img1.png') if getConfig('dbms') eq 'mysql';
	$image = readFile($dir . '/img1.png') if getConfig('dbms') eq 'MariaDB';

	# read in the align mode
	#
	my $imagespl = readFile($dir . '/images.pl');
	my $align = 'bottom';	# default align

	if ($imagespl =~ /ALIGN="(.+?)"/) {
			$align = lc($1);
	}

	# insert into database
	#
	my $sth = $dbh->prepare('insert into rendered_images (imagekey, variant, align, image) values (?, ?, ?, ?)');
	$sth->execute($math, $variant, $align, $image);
	$sth->finish();
	}
	
	# remove the rendering directory
	#
	`rm -rf $dir`;
        # Ben, testing this since what happens is that the dir created in tmp
        # cannot be deleted if the latex2html process does not finish
        # this is a horrible way to solve this problem so expect this to be temprorary
	dwarn "singleRenderLaTeX ended";
	return 0;	# return success
}

# the low-level interface to LaTeX rendering methods
#
sub renderLaTeX {
	my $table = shift;
	my $id = shift;
	my $latex = shift;
	my $method = shift;
	my $fname = shift;

	dwarn "renderLaTeX started";
	if (not defined($table) or $table eq '.') {
		$table = "temp";
		$id =~ /\/(.*)$/;
		$id = $1;
	}
	
	my $path = getConfig('cache_root');
	dwarn "renderLaTeX path: $path";
	my $dir = "$path/$table/$id";
	dwarn "renderLaTeX dir: $dir";

	if (not defined($fname)) {
		dwarn "had to use default name when rendering object $id!\n";
		$fname = "obj";								 # generic name
	}

	my $cwd = `pwd`;
	dwarn "renderLaTeX cwd: $cwd";
	# make sure the object directory is there & clean
	#
	if ( ! -e $dir ) {
		dwarn "renderLaTeX object not there, mkdir $dir";
		mkdir $dir;
	}
	chdir $dir;

	# make sure output method dir is there
	#
	$dir = "$dir/$method";
	dwarn "renderLaTeX dir method: $dir";
	if ( ! -e $dir ) {
		dwarn "renderLaTeX object not there, mkdir for dir method $dir";
		mkdir $dir;
	}
	chdir $dir;

	# get web URL for rendered images
	#
	my $url = getConfig('cache_url')."/$table/$id/$method";
	dwarn "renderLaTeX url: $url";
	# BB: convert UTF8 international characters to TeX
	$latex = UTF8toTeX($latex);

	# flat png image output (nicest looking)
	#
	if ( $method eq "png" ) {
		dwarn "renderLaTeX png started\n";
		$latex = png_preprocess($latex);
	
		my $retval = latex_error_check($fname, $latex);

		if (!$retval) {

			write_out_latex($fname, $latex);
			
			# main meat of rendering
			render_png($fname, $latex, $url);
		}

		else {
			write_error_output($fname, $table, $id, $method);
		}
		dwarn "renderLaTeX png ended\n";
	}
	
	# latex2html output (best-looking for the [download] speed)
	#
	elsif ( $method eq "l2h" ) {
		dwarn "renderLaTeX l2h png started\n";
		my $retval = latex_error_check($fname, $latex);

		if (1) {
			
			write_out_latex($fname, $latex);

			# l2h rendering core
			render_l2h($fname, $latex, $url);
		} 
		
		else {
			write_error_output($fname, $table, $id, $method);
		}
		dwarn "renderLaTeX l2h png ended\n";
	}

	# source output ... just make HTML presentable and print to output file
	#
	elsif ( $method eq "src" ) {
		print "src started\n";
		write_out_latex($fname, $latex);

		# BEN - bringing in new code from noosphere
		# 2007-06-06 - ".html" added a-la Thomas Foregger
#		system("rm -f .$fname.tex.html.swp");	# just in case vim crashed before
		my @lines = split( /\n/, $latex );
		foreach my $l (@lines) {
			encode_entities($l);
		}

		my $cleaned =  join("\n<br/>", @lines);
		#write to file
		my $outfilename = getConfig('rendering_output_file');
		open( OUT, ">$outfilename" );
		print OUT $cleaned;
		close(OUT);

		#$ENV{TERM} = "xterm";
		## commented out as it was popping up during renderall for things like no newline at EOF
		##BENsystem(getConfig('vimcmd')." $dir/$fname.tex".' +:so\ \\'.getConfig('stemplate_path').'/2pmhtml.vim +:w\!\ '.getConfig('rendering_output_file').' +:q +:q 2>/dev/null');
		#print "src ended\n";
	}
	dwarn "renderLaTeX end";
	chdir $cwd;
}

# do a non-fonts render just to check syntax of LaTeX
#
sub latex_error_check {
	my $fname = shift;
	my $latex = shift;

	# add in syntax-only package and enactment directive
	#
	$latex =~ s/(\\documentclass.*?\n)/$1\\usepackage{syntonly}\n/so;
	$latex =~ s/(\\begin{document}.*?\n)/\\syntaxonly\n$1/so;

	# BB: convert UTF8 international characters to TeX
	$latex = UTF8toTeX($latex);

	write_out_latex($fname, $latex);

	# run with easily-parsable line-error option
	#
	my $retval = system("/usr/bin/latex -file-line-error-style -interaction=nonstopmode $fname.tex");

	return $retval;
}

# latex2html rendering core
#
sub render_l2h {
	my $fname = shift;
	my $latex = shift;
	my $url = shift;

	my $cwd = getcwd();
	my $tpath = getConfig("stemplate_path");	# grab latex2html init file
	dwarn "render_l2h before cp .latex2tml-init, tpath $tpath, cwd $cwd";
	`cp $tpath/.latex2html-init .`;
	dwarn "render_l2h after cp .latex2tml-init";

	# run latex to get an aux file for refs
	#
	if ($latex =~ /\\($reruns)\W/) { 
		system("/usr/bin/latex -interaction=batchmode $fname.tex"); 
	}

	# init graphics AA flag
	$ENV{'GS_GRAPHICSAA'} = 0;

	my $renderProgram = "";
	my $run = "";
	
	# run l2h
	$renderProgram = getConfig('latex2htmlcmd');
	warn "calling from here";
	$run = "$renderProgram " . getConfig ('l2h_opts'). " $fname >error.out 2>&1";

	# run l2h
	#my $cmd = getConfig('timeoutprog') . "$run";
	my $cmd = "$run";
	warn "EXECING $cmd\n";
	my $retval = system($cmd);

	#my $retval = system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." $fname >error.out 2>&1");

	# run latex2html again after deleting some image files if these images 
	# need to be antialiased
	#
	##if ($retval == 0) {
	##	my @aaimages = getAAImages();
	##	if (scalar @aaimages) {
			# delete all of the offending image files.	when we re-render, they
			# will be the only images l2h re-processes.
			#
	##		foreach my $file (@aaimages) {
	##			unlink $file;
	##		}

			# turn on our graphics anti-alias flag
	##		$ENV{'GS_GRAPHICSAA'} = 1;

			# run l2h again (ignore retval- if there were no errors before, there
			# shouldn't be any now)
			#system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." $fname >/dev/null 2>&1");
	##		system($cmd);

	##	}
	##}
 
	# post process l2h's HTML output
	#
	postProcessL2hIndex($url);
}


# do any preprocessing on LaTeX source for png mode
#
sub png_preprocess {
	my $latex = shift;

	# make colours work right in png view
	#
	# APK - 2003-06-24: this is going to need fixing.
	#
	if ($latex =~ /\\color/) {
		$latex =~ s/(\\usepackage\{.+?\})/$1\n\\usepackage\{colordvi\}\n\\usepackage\{color\}\n/;
	}

	return $latex;
}

# do rendering for PNG method
#
sub render_png {
	my $fname = shift;
	my $latex = shift;
	my $url = shift;

	# see if there are any hyperlinks.
	#
	my $haslinks = ($latex =~ /\\htmladdnormallink/);

	# run mapper to produce image map data and highlighted TeX.  this 
	# will be filename-HI.tex, which further processing will occur on.
	# 
	if ($haslinks) {
		my $mapprog = getConfig('base_dir')."/bin/map/MAP";
		system("$mapprog $fname");
	}

	my $fullname = $fname;
	if ($haslinks) {
		$fullname = "$fname-HI";
	}

	# make a dvi (run latex twice to get numberings for refs)
	if ($latex =~ /\\($reruns)\W/) { 
		 system("/usr/bin/latex -interaction=batchmode $fullname.tex"); 
	}
	# final rendering runi
	system("/usr/bin/latex -interaction=batchmode $fullname.tex");

	print "dvips cmd: /usr/bin/dvips -t letter -f $fullname.dvi > $fullname.ps";
	# make a postscript file
	system("/usr/bin/dvips -t letter -f $fullname.dvi > $fullname.ps");

	# make a pnm 
	system("/usr/bin/gs -q -dBATCH -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -dNOPAUSE -sDEVICE=pnmraw -r100 -sOutputFile=$fullname%03d.pnm $fullname.ps");

	# make the output file
	#
	open HTMLFILE,">".getConfig('rendering_output_file');

	print HTMLFILE "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";

	# loop through pnm output (pages)
	#
	my @pnms = <*.pnm>;
	foreach my $pnm (@pnms) {
		my $png = $pnm;
		$png =~ s/pnm$/png/;

		# get the series number
		$pnm =~ /\d(\d\d)\.pnm/;

		# TODO: MAP should use 3 digits here.
		#
		my $ord = "$1";

		# make a png 
		#
		system("/usr/bin/pnmcrop < $pnm | /usr/bin/pnmpad -white -l20 -r20 -t20 -b20 | /usr/bin/pnmtopng > $png");
	
		# add image to the output html file 
		#
		print HTMLFILE "<tr><td>";

		if ($haslinks) {
			print HTMLFILE "<img src=\"".htmlescape($url."/$png")."\" border=\"0\" usemap=\"#ImageMap".int($ord)."\"/>\n\n";
			# read in the image map and output it to the HTML file
			#
			my $map = readFile($fname."$ord.map");

			print HTMLFILE $map;

		} else { 
			my $alttext = $latex;
			if (length($latex) > 1024) {
				$alttext = "[too big for ALT]";
			}
			print HTMLFILE "<img src=\"".htmlescape($url."/$png")."\" alt=\"".qhtmlescape($alttext)."\" />\n";
		}

		print HTMLFILE "\n\n</td></tr>\n";

		# remove the pnm
		unlink $pnm;
	}

	print HTMLFILE "</table>\n";
	
	unlink "$fullname.aux";
	unlink "$fullname.pnm";
	unlink "$fullname.log";

	close HTMLFILE;
}

# write latex out to a file for rendering
#
sub write_out_latex {
	my $fname = shift;
	my $latex = shift;
	
	open OFILE,">$fname.tex";
	print OFILE $latex;
	close OFILE;
}

# get error log data
#
sub get_latex_error_data {
	my $logfile = shift;	# log file
	my $table = shift;		# path components
	my $id = shift;
	my $method = shift;

	# change to working dir
	#
	chdir(getConfig('cache_root')."/$table/$id/$method");

	# open and read log
	#
	my $log = readFile($logfile);

	my %errors;

	# scan log just for error lines; pick them out and return essential data
	#
	while ($log =~ /^\S+\.tex:(\d+):\s+(.+?)$/mgo) {
		my $line = $1;
		my $error = $2;
		
		$line -= 1;  # adjust for \usepackage{syntonly} and \syntaxonly

		$errors{$line} = $error;
	}
	
	return {%errors};
}

# "explain" a latex source file error with annotated source.
#
sub explainError {
	my $params = shift;
	my $userinf = shift;

	my $table = $params->{'from'};
	my $id = $params->{'id'};
	my $method = $params->{'method'};
	my $name = $params->{'name'};

	my $logfile = "$name.log";
	my $srcfile = "$name.tex";

    my $errors = get_latex_error_data($logfile, $table, $id, $method);

	# we'll also need to open the source file for printing
	#
	chdir(getConfig('cache_root')."/$table/$id/$method");
	open SRCFILE, $srcfile;
	my @srclines = <SRCFILE>;
	close SRCFILE;
	
	my $html = '';  # output

	$html .= "<font face=\"monospace, courier, fixed\">\n";

	for (my $i = 0; $i < scalar @srclines; $i++) {
	
		my $line = $srclines[$i];
		chomp $line;

		if (exists $errors->{$i}) {
			$html .= "<font color=\"#ff0000\">${i}: ".$line."<br>\n";
			$html .= "<b>!!! $errors->{$i}</b></font><br>\n";
		} else {
			$html .= "${i}: ".$line."<br>\n";
		}
	}

	$html .= "</font>\n";

	return $html;
}

# write error log output to rending results file
#
sub write_error_output {
	my $name = shift;	# canonical name.
	my $table = shift;		# path components
	my $id = shift;
	my $method = shift;

	my $logfile = "$name.log";

	# get error data
	#
	my $errors = get_latex_error_data($logfile, $table, $id, $method);

	# output error data
	
	# open rendering output file, start output
	#
	open HTMLFILE,">".getConfig('rendering_output_file');
		
	print HTMLFILE "<table width=\"100%\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n<tr><td><font size=\"+1\" color=\"#ff0000\">\n";

	print HTMLFILE "Rendering failed.  LaTeX errors: <br /><br />";

	foreach my $lnum (sort { int($a) <=> int($b) } keys %$errors) {

		print HTMLFILE "line ${lnum}: $errors->{$lnum} <br />";
	}
	
	my $root = getConfig('main_url');

	print HTMLFILE "</font></td></tr>
	
	<tr>
		<td align=\"center\">
			<font size=\"-1\">
				<br />
	 			(<a href=\"$root/?op=explain_err&amp;name=$name&amp;from=$table&amp;id=$id&amp;method=$method\" target=\"_pm_err_win\">view source annotated with errors</a>)
			</font>
		</td>
	</tr>
	</table>\n";

	close HTMLFILE;
}

# determine if there was a rendering error, based on return value of latex
# command, and log output. we can't just use return value, since warnings
# and errors aren't distinguished.
#
sub renderError {
	my $retval = shift;
	my $logfile = shift;

	# open and read log
	#
	my $log = readFile($logfile);

	# if no error or warning, we're ok
	#
	return 0 if $retval == 0;

	# separate errors from warnings
	#
	if ($log =~ /^! /m) {
		return 1;
	}
	
	return 0;
}

# get file names of (included graphics) images to be anti-aliased. 
#
sub getAAImages {
	
	my @imgfiles = ();
	dwarn " getAAImages Started";
	# we use the images.pl file l2h produces (should be in the current dir.)
	do "images.pl";

	foreach my $key (keys %cached_env_img) {
		# look for tell-tale signs of things we should antialias
		#
		if ($key =~ /(includegraphics|figura)/) {
			my $val = $cached_env_img{$key};
			$val =~ /SRC="(.+)?"/;
			my $imgfile = $1;
			
			dwarn "*** getAAImages : graphics-antialiasing $imgfile";
			
			push @imgfiles, $imgfile;
		}

		delete $cached_env_img{$key};	# clear all entries
	}
	dwarn " getAAImages Ended";
	return @imgfiles;
}

# process latex2html generated index.html file to produce just the html 
# Noosphere needs to include in pages.	Writes this output to the rendering
# output file.
# 
sub postProcessL2hIndex {
	my $url = shift;

	my $path = getConfig('cache_root');

	# just write the latex2html to the rendering output 
	# file, with some minor post-processing
	#
	my $file = '';

	# read output of l2h, running it through tidy to get XHTML
	#
	$file = readFile(getConfig('tidycmd')." -wrap 1024 -asxml index.html 2>/dev/null |");
	
	# pull out just the body, clean some stuff up
	#
	$file =~ /<body.*?>(.*?)<hr\s*?\/>\s*?<\/body>/sio;
	$file = $1;
	$file =~ s/src=\s*\"(.*?)\"/src=\"$url\/$1\"/igso;
	
	# add title tooltips
	$file =~ s/(alt="(.+?)")/$1 title="$2" /igso;
	$file = "<table border=\"0\" width=\"100%\"><td>$file</td></table>";

	# write it out to standard location
	#
	open OUTFILE,">".getConfig('rendering_output_file');
	print OUTFILE "$file";
	close OUTFILE;
	
=quote
	# something went wrong, replace rendering output file with the contents of 
	# error.out, with some minor post-processing (pull out just error section)
	#
	else {
		$file = readFile("error.out");
		$file =~ s/^.*?(\*\*\* Error:)/$1/gs;
		$file =~ s/Died at.+$//gs;
		$file =~ s/\n+/\n/gs;
	
		my $newfile = $file;
		while ($file =~ /<<([0-9]+)>>/gs) {
			my $num = $1;
			$newfile =~ s/<<$num>>(.*?)<<$num>>/{$1}/gs;
		}
		$file = $newfile;
		$file = tohtmlascii($file);
		$file =~ s/\n/<br \/>/gs;
		$file = "<table border=\"0\" width=\"100%\"><tr><td><font color=\"#ff0000\"><b>$file</b></font></td></tr></table>";
	}
=cut
}

# write reference links to a file in the rendering output dir
#
sub writeLinksToFile {
	my ($table,$id,$method,$links) = @_;
	
	my $path = getConfig('cache_root');
	my $dir = "$path/$table/$id/$method";
	print "writeLinksToFile dir:\n $dir";
	open OUTFILE,">$dir/pmlinks.html";
	print OUTFILE "$links";
	close OUTFILE;
}

# this sub grabs the contents of cacheroot/table/objid/method/pmlinks.html file
#
sub getRenderedObjectLinks {
	my ($table,$id,$method) = @_;
	
	my $path = getConfig('cache_root');
	my $dir = "$path/$table/$id/$method";
	
	return readFile("$dir/pmlinks.html");
}

# this sub grabs the contents of the cacheroot/objid/method/output.html file
# no checking on existence is done (where output.html is the rendering output
# file)
#
sub getRenderedObjectHtml {
	my ($table, $id, $method) = @_;
	
	my $path = getConfig('cache_root');
	my $dir = "$path/$table/$id/$method";
 	 	
	my $html = readFile("$dir/".getConfig('rendering_output_file'));
        #dwarn "PATH to object is $path $dir";
	#dwarn "The html is : $html";


	return $html;
}
	
1;
