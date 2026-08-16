package Noosphere;

use strict;
use Noosphere::Util;
use Noosphere::Charset;
use HTML::Entities;
use HTML::Tidy;
use Apache2::SubProcess ();
use Encode qw(decode FB_CROAK);
use File::chdir;
use File::Copy qw( copy );
use File::Path qw(make_path); 
use File::Copy::Recursive qw(pathrm);

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
	$math = UTF8toTeX($math);
	# make a rendering directory in /tmp
	# 
	my $suffix = 0;
	my $root = getConfig('single_render_root');
	while (-e "$root$suffix") {
		$suffix++;
	}
	my $dir = $root . $suffix;
	dwarn "singleRenderLaTeX dir to make: $dir";
	make_path("$dir", {verbose => 1, mode => 0771});
	dwarn "after make_path $dir;";

	# copy over templates we need
	#
	my $template_root = getConfig('stemplate_path');
	# BEN TODO - need to confirm this fix of string command actually works
	#system("cp $template_root/.latex2html-singlerender-init $dir/.latex2html-init");
	copy("$template_root/.latex2html-singlerender-init", "$dir/.latex2html-init");

	my $prefix = getConfig('single_render_template_prefix');

	# loop through each variant, render the math and load the image into the 
	# database (if its not there already, this is a last line of defens failsafe)
	# 
	foreach my $variant (@$variants) {
	next if (variant_exists($math, $variant));

	# do the rendering
	#
	require Noosphere::Template;
	my $template = new TemplateNS($prefix . "_$variant.tex");
	$template->setKey('math', $math);
	writeFile("$dir/single_render.tex", $template->expand());
	##chdir $dir;
	#chdir("$dir");# or dwarn "ERROR chdir: cannot change: $!\n";
	local $CWD = "$dir";
	#Ben - error.out is filling the harddrive, remove for now
	##my $retval = system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." single_render.tex > /dev/null 2>&1");
	#my $retval = system(getConfig('base_dir') . "/bin/latex2html ".getConfig('l2h_opts')." single_render.tex > /dev/null 2>&1");

	my $renderProgram = getConfig('latex2htmlcmd');
	warn "calling from here";
	my $run = $renderProgram;#"$renderProgram " . getConfig ('l2h_opts'). " $dir/$fname";

	# run l2h
	#my $cmd = getConfig('timeoutprog') . "$run";
	my $cmd = "$run";
	warn "EXECING $run\n";
	# get the global request object (requires PerlOptions +GlobalRequest)
    my $r = Apache2::RequestUtil->request;
	my $in_fh = "";
	my $out_fh = "";
	my $err_fh = "";
	my @run_args = ("-dir",$dir,"-init_file", "$dir/.latex2html-init","$dir/single_render.tex");
	($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($run,\@run_args);
	my $output = read_data($out_fh);
 	my $error  = read_data($err_fh);

	dwarn "Error from single_render.tex: \n $error"; 
	# abort if a render failed	
	# hmm need better way to exit
	if ($error > 0) {
			dwarn "GOT ERRROR: abort, rm $dir";
			pathrm($dir);
			return $error;
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
	pathrm($dir);
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

	#my $cwd = getcwd();
	#dwarn "renderLaTeX cwd: $cwd";
	# make sure the object directory is there & clean
	#
	if ( ! -e $dir ) {
		dwarn "renderLaTeX object not there, make_path $dir";
		make_path("$dir", {verbose => 1, mode => 0771});
	}
	##chdir $dir;
	##chdir("$dir");# or dwarn "ERROR chdir: cannot change: $!\n";
	local $CWD = "$dir"; 
	# make sure output method dir is there
	#
	$dir = "$dir/$method";
	dwarn "renderLaTeX dir method: $dir";
	if ( ! -e $dir ) {
		dwarn "renderLaTeX object not there, make_path for dir method $dir";
		make_path("$dir", {verbose => 1, mode => 0771});
	}
	##chdir $dir;
	##chdir("$dir");# or dwarn "ERROR chdir: cannot change: $!\n";
	local $CWD = "$dir"; 
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
	
		my $retval = latex_error_check($fname, $latex, $dir);
		dwarn "latex_error_check retval: $retval";
		if (!$retval) {
			dwarn "write_out_latex before";
			write_out_latex($fname, $latex);
			dwarn "write_out_latex before";
			# main meat of rendering
			render_png($fname, $latex, $url, $dir);
		}

		else {
			write_error_output($fname, $table, $id, $method);
		}
		dwarn "renderLaTeX png ended\n";
	}
	
	# latex2html output (best-looking for the [download] speed)
	#
	elsif ( $method eq "l2h" ) {
		dwarn "renderLaTeX l2h started\n";
		my $retval = latex_error_check($fname, $latex, $dir);
		dwarn "latex_error_check ended \n";
		if (!$retval) {
			dwarn "no errors\n";
			write_out_latex($fname, $latex);
			dwarn "write_out_latex ended\n";
			# l2h rendering core
			render_l2h($fname, $latex, $url, $dir);
			dwarn "render_l2h ended\n";
		} 
		
		else {
			dwarn "error with latex_error_check\n";
			dwarn "retval: $retval";
			write_error_output($fname, $table, $id, $method);
		}
		dwarn "renderLaTeX l2h ended\n";
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
	# experimental to see if we can have some print formated downloads and things like png/jpg
	elsif ( $method eq "pdf" ) {
		dwarn "renderLaTeX pdf started\n";
	
		my $retval = latex_error_check($fname, $latex, $dir);  # consider using special case for pdflatex
		dwarn "latex_error_check retval: $retval";
		if (!$retval) {
			dwarn "write_out_latex before";
			write_out_latex($fname, $latex);
			dwarn "write_out_latex before";
			# main meat of rendering
			render_pdf($fname, $latex, $url, $dir);
		}

		else {
			write_error_output($fname, $table, $id, $method);
		}
		dwarn "renderLaTeX png ended\n";

	}
	# experimental to see if we use make4ht instead of latex2html
	elsif ( $method eq "make4ht" ) {
		dwarn "renderLaTeX make4ht started\n";
	
		my $retval = latex_error_check($fname, $latex, $dir);
		dwarn "latex_error_check ended \n";
		if (!$retval) {
			dwarn "no errors\n";
			write_out_latex($fname, $latex);
			dwarn "write_out_latex ended\n";
			# l2h rendering core
			render_make4ht($fname, $latex, $url, $dir);
			dwarn "render_make4ht ended\n";
		} 
		
		else {
			dwarn "error with latex_error_check\n";
			dwarn "retval: $retval";
			write_error_output($fname, $table, $id, $method);
		}
		dwarn "renderLaTeX l2h ended\n";

	}
	dwarn "renderLaTeX end";
	##chdir $cwd;
	#chdir("$cwd");# or dwarn "ERROR chdir: cannot change: $!\n";
	#local $CWD = "$cwd"; # we should not have to do this, the local $CWD should go back once scope leaves but need to test first
	#local $CWD = "$path"; 
}

# do a non-fonts render just to check syntax of LaTeX
#
sub latex_error_check {
	my $fname = shift;
	my $latex = shift;
	my $dir = shift;

	# get the global request object (requires PerlOptions +GlobalRequest)
	my $in_fh = "";
	my $out_fh = "";
	my $err_fh = "";
    my $r = Apache2::RequestUtil->request;

	my $latexprog = "/usr/bin/latex";

	# add in syntax-only package and enactment directive
	#
	$latex =~ s/(\\documentclass.*?\n)/$1\\usepackage{syntonly}\n/so;
	$latex =~ s/(\\begin{document}.*?\n)/\\syntaxonly\n$1/so;

	# BB: convert UTF8 international characters to TeX
	$latex = UTF8toTeX($latex);

	write_out_latex($fname, $latex);

	# run with easily-parsable line-error option
	#
	#dwarn "Executing system cmd : /usr/bin/latex -file-line-error-style -interaction=nonstopmode $fname.tex";
	local $CWD = "$dir";

	my @run_args = ("-file-line-error-style","-interaction=nonstopmode","$dir/$fname.tex");
	#my @run_args = qw("-interaction=batchmode" "$dir/$fname.tex");
	dwarn "EXECING $latexprog -interaction=batchmode -interaction=nonstopmode $dir/$fname.tex\n";
	#dwarn "dir: $dir";
	($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($latexprog,\@run_args);
	my $output = read_data($out_fh);
 	my $error  = read_data($err_fh);
	dwarn "latex_error_check output: $output";
	dwarn "latex_error_check  error: $error";
	#my $error = system("/usr/bin/latex -file-line-error-style -interaction=nonstopmode $dir/$fname.tex");
	dwarn "latex_error_check  error: $error";
	# for now let all errors go by until this is more robust, as it is not letting png/jpg through as example
	$error = 0;
	return $error;
}

# latex2html rendering core
#
sub render_l2h {
	my $fname = shift;
	my $latex = shift;
	my $url = shift;
	my $dir = shift;

	#my $cwd = getcwd();
	local $CWD = "$dir";
	my $tpath = getConfig("stemplate_path");	# grab latex2html init file
	my $latexprog = getConfig('latex2htmlcmd');
	dwarn "render_l2h before cp .latex2tml-init, tpath $tpath";
	## BEN TODO system("cp $tpath/.latex2html-init .");
	copy("$tpath/.latex2html-init","$dir");
	
	dwarn "render_l2h after cp .latex2tml-init";
	dwarn "dir: $dir";

	my $r = Apache2::RequestUtil->request;
	my $in_fh = "";
	my $out_fh = "";
	my $err_fh = "";

	# run latex to get an aux file for refs
	#
	if ($latex =~ /\\($reruns)\W/) { 
		dwarn "running system /usr/bin/latex -interaction=batchmode $fname.tex";
		## BEN system("/usr/bin/latex -interaction=batchmode $fname.tex"); 
		dwarn "latex reruns: $latex";
		 #system("/usr/bin/latex -interaction=batchmode $fullname.tex"); 
		my @run_args = ("-dir",$dir,"-init_file", "$dir/.latex2html-init","$dir/$fname.tex");
		dwarn "EXECING $latexprog -init_file $tpath/.latex2html-init $fname.tex \n";
		($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($latexprog,\@run_args);
		my $output = read_data($out_fh);
 		my $error  = read_data($err_fh);
		dwarn "latex reruns output: $output";
		dwarn "latex reruns  error: $error";
	}

	# init graphics AA flag
	$ENV{'GS_GRAPHICSAA'} = 0;

	my $renderProgram = "";
	my $run = "";
	
	# run l2h
	$renderProgram = getConfig('latex2htmlcmd');
	warn "calling from here";
	$run = $renderProgram;#"$renderProgram " . getConfig ('l2h_opts'). " $dir/$fname";

	# run l2h
	#my $cmd = getConfig('timeoutprog') . "$run";
	my $cmd = "$run";
	warn "EXECING $run\n";
	# get the global request object (requires PerlOptions +GlobalRequest)
    
	my @run_args = ("-dir",$dir,"-init_file", "$dir/.latex2html-init","$dir/$fname.tex");
	($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($run,\@run_args);
	my $output = read_data($out_fh);
 	my $error  = read_data($err_fh);
	dwarn "latex2html input: " . scalar($in_fh);
	dwarn "latex2html output: $output";
	dwarn "latex2html error: $error";

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
	postProcessL2hIndex($url,$dir);
}

# latex2html rendering core
#
sub render_make4ht {
	my $fname = shift;
	my $latex = shift;
	my $url = shift;
	my $dir = shift;

	#my $cwd = getcwd();
	local $CWD = "$dir";
	my $tpath = getConfig("stemplate_path");	# grab latex2html init file
	my $latexprog = getConfig('latex2htmlcmd');
	dwarn "render_l2h before cp .latex2tml-init, tpath $tpath";
	## BEN TODO system("cp $tpath/.latex2html-init .");
	##copy("$tpath/.latex2html-init","$dir"); # maybe add a make4ht config file
	
	dwarn "render_l2h after cp .latex2tml-init";
	dwarn "dir: $dir";

	my $r = Apache2::RequestUtil->request;
	my $in_fh = "";
	my $out_fh = "";
	my $err_fh = "";

	# run latex to get an aux file for refs
	#
	if ($latex =~ /\\($reruns)\W/) { 
		dwarn "running system /usr/bin/latex -interaction=batchmode $fname.tex";
		## BEN system("/usr/bin/latex -interaction=batchmode $fname.tex"); 
		dwarn "latex reruns: $latex";
		 #system("/usr/bin/latex -interaction=batchmode $fullname.tex"); 
		my @run_args = ("-dir",$dir,"-init_file", "$dir/.latex2html-init","$dir/$fname.tex");
		dwarn "EXECING rerun make4ht -d $dir $dir/$fname.tex";
		system("make4ht -d $dir $dir/$fname.tex");
	}

	dwarn "EXECING make4ht -d $dir $dir/$fname.tex";
	system("make4ht -d $dir $dir/$fname.tex");

	# post process HTML output
	postProcess_make4htIndex($url,$dir,"$fname.html");
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
	my $dir = shift;

	

	# change directory to the objects dir
	local $CWD = "$dir";

	my $tpath = getConfig("stemplate_path");	# grab latex2html init file
	copy("$tpath/.latex2html-init","$dir");

	dwarn "render_png started";
	
	my $mapprog = getConfig('base_dir')."/bin/map/MAP";
	my $latexprog = '/usr/bin/latex';
	my $dvipsprog = '/usr/bin/dvips';
	my $gsprog ='/usr/bin/gs';
	my $pnmcrop = '/usr/bin/pnmcrop';

	# get the global request object (requires PerlOptions +GlobalRequest)
    my $r = Apache2::RequestUtil->request;

	my $in_fh = "";
	my $out_fh = "";
	my $err_fh = "";
	my $error = "";
	
	# see if there are any hyperlinks.
	#
	my $haslinks = ($latex =~ /\\htmladdnormallink/);


	

	dwarn "render_png dir: $dir";

	# run mapper to produce image map data and highlighted TeX.  this 
	# will be filename-HI.tex, which further processing will occur on.
	# 
	dwarn "haslinks: $haslinks";
	if ($haslinks) {
		
		##system("$mapprog $fname");
		my @run_args = ("$dir/$fname");
		dwarn "EXECING $mapprog $fname\n";
		($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($mapprog,\@run_args);
		my $output = read_data($out_fh);
 		$error  = read_data($err_fh);
		dwarn "haslinks output: $output";
		dwarn "haslinks  error: $error";


	}

	my $fullname = $fname;
	dwarn "fullname: $fullname";
	if ($haslinks) {
		$fullname = "$fname-HI";
		dwarn "haslinks fullname: $fullname";
	}

	# make a dvi (run latex twice to get numberings for refs)
	if ($latex =~ /\\($reruns)\W/) { 
		dwarn "latex reruns: $latex";
		 #system("/usr/bin/latex -interaction=batchmode $fullname.tex"); 
		my @run_args = ("-interaction","=batchmode","$dir/$fullname.tex");
		dwarn "EXECING $latexprog -interaction=batchmode $dir/$fullname.tex \n";
		($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($latexprog,\@run_args);
		my $output = read_data($out_fh);
 		$error  = read_data($err_fh);
		dwarn "latex reruns output: $output";
		dwarn "latex reruns  error: $error";
	}
	# final rendering runi
	#system("/usr/bin/latex -interaction=batchmode $fullname.tex");
	##my @run_args = ("-interaction","=batchmode","$dir/$fullname.tex");
	##dwarn "EXECING $latexprog -interaction=batchmode $dir/$fullname.tex \n";
	##($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($latexprog,\@run_args);
	##my $output = read_data($out_fh);
	##my $error  = read_data($err_fh);
	##dwarn "final rendering output: $output";
	##dwarn "final rendering  error: $error";

	$error = system("/usr/bin/latex -interaction=batchmode $dir/$fullname.tex");
	dwarn "latex error: $error";

	#print "dvips cmd: /usr/bin/dvips -t letter -f $fullname.dvi > $fullname.ps";
	# make a postscript file
	#system("/usr/bin/dvips -t letter -f $fullname.dvi > $fullname.ps");
	##my @run_args = ("-t", "letter","-f","$dir/$fullname.dvi","-o","$dir/$fullname.ps");
	##dwarn "EXECING $dvipsprog -t letter -f $fullname.dvi > $fullname.ps\n";
	##($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($dvipsprog,\@run_args);
	##my $output = read_data($out_fh);
	##$error  = read_data($err_fh);
	##dwarn "postscript file output: $output";
	##dwarn "postscript file  error: $error";

	$error = system("/usr/bin/dvips -t letter -f $dir/$fullname.dvi > $dir/$fullname.ps");
	dwarn "postscript file  error: $error";

	# make a pnm 
	#system("/usr/bin/gs -q -dBATCH -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -dNOPAUSE -sDEVICE=pnmraw -r100 -sOutputFile=$fullname%03d.pnm $fullname.ps");

	##my @run_args = ("-q", "-dBATCH","-dGraphicsAlphaBits=4","-dTextAlphaBits=4","-dNOPAUSE","-sDEVICE=pnmraw","-r100","-sOutputFile=$dir/$fullname%03d.pnm","$dir/$fullname.ps");
	##dwarn "EXECING $gsprog -q -dBATCH -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -dNOPAUSE -sDEVICE=pnmraw -r100 -sOutputFile=$dir/$fullname%03d.pnm  $dir/$fullname.ps\n";
	##($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($gsprog,\@run_args);
	##my $output = read_data($out_fh);
	##$error  = read_data($err_fh);
	##dwarn "gsprog output: $output";
	##dwarn "gsprog  error: $error";

	$error = system("/usr/bin/gs -q -dBATCH -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -dNOPAUSE -sDEVICE=pnmraw -r100 -sOutputFile=$dir/$fullname%03d.pnm $dir/$fullname.ps");
	dwarn "gsprog  error: $error";

	# make the output file
	#
	dwarn "Writing to HTMLFILE: ".getConfig('rendering_output_file');
	open HTMLFILE,">".getConfig('rendering_output_file');

	print HTMLFILE "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";

	# loop through pnm output (pages)
	#
	my @pnms = <*.pnm>;
	foreach my $pnm (@pnms) {
		my $png = $pnm;
		dwarn "png: $png";
		$png =~ s/pnm$/png/;
		dwarn "png: $png";

		# get the series number
		$pnm =~ /\d(\d\d)\.pnm/;
		dwarn "png: $png";

		# TODO: MAP should use 3 digits here.
		#
		my $ord = "$1";

		# make a png 
		#
		#system("/usr/bin/pnmcrop < $pnm | /usr/bin/pnmpad -white -l20 -r20 -t20 -b20 | /usr/bin/pnmtopng > $png");
		##my @run_args = ("< $dir/$pnm | /usr/bin/pnmpad -white -left=20 -right=20 -top=20 -bottom=20 | /usr/bin/pnmtopng > $dir/$png");
		##dwarn "EXECING $pnmcrop @run_args\n";
		##($in_fh, $out_fh, $err_fh) =  $r->spawn_proc_prog($pnmcrop,\@run_args);
		##my $output = read_data($out_fh);
		##$error  = read_data($err_fh);
		##dwarn "pnmpad output: $output";
		##dwarn "pnmpad  error: $error";

		$error  = system("/usr/bin/pnmcrop < $dir/$pnm | /usr/bin/pnmpad -white -left=20 -right=20 -top=20 -bottom=20 | /usr/bin/pnmtopng > $dir/$png");
		dwarn "pnmpad  error: $error";
		# add image to the output html file 
		#
		print HTMLFILE "<tr><td>";

		if ($haslinks) {
			dwarn "haslinks htmlfile";
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
		pathrm($pnm);
	}

	print HTMLFILE "</table>\n";
	
	pathrm("$fullname.aux");
	pathrm("$fullname.pnm");
	pathrm("$fullname.log");

	close HTMLFILE;
}

sub render_pdf {
	my $fname = shift;
	my $latex = shift;
	my $url = shift;
	my $dir = shift;

	my $error = "";

	# change directory to the objects dir
	local $CWD = "$dir";

	my $tpath = getConfig("stemplate_path");	# grab latex2html init file
	copy("$tpath/.latex2html-init","$dir");

	dwarn "render_png started";
	
	my $mapprog = getConfig('base_dir')."/bin/map/MAP";
	my $latexprog = '/usr/bin/pdflatex';

	# get the global request object (requires PerlOptions +GlobalRequest)
    my $r = Apache2::RequestUtil->request;

	# see if there are any hyperlinks.
	#
	my $haslinks = ($latex =~ /\\htmladdnormallink/);

	if ($haslinks) {
		$error = system("$mapprog $dir/$fname");
		dwarn "haslinks  error: $error";
	}

	my $fullname = $fname;
	dwarn "fullname: $fullname";
	if ($haslinks) {
		$fullname = "$fname-HI";
		dwarn "haslinks fullname: $fullname";
	}

	# make a pdf using pdflatex
	$error = system("$latexprog $dir/$fullname");
	dwarn "pdflatex  error: $error";

	dwarn "Writing to HTMLFILE: ".getConfig('rendering_output_file');
	open HTMLFILE,">".getConfig('rendering_output_file');

	print HTMLFILE "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";

	#print HTMLFILE "<img src=\"".htmlescape($url."/$png")."\" border=\"0\" usemap=\"#ImageMap".int($ord)."\"/>\n\n";
	print HTMLFILE "<iframe src=\"".htmlescape($url."/$fullname.pdf")."\" width=\"100%\" height=\"800\"></iframe>\n";

	print HTMLFILE "</table>\n";

	# find out which temp files to delete than enable this.
	#pathrm("$fullname.aux");
	#pathrm("$fullname.pnm");
	#pathrm("$fullname.log");

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
	#chdir(getConfig('cache_root')."/$table/$id/$method");
	local $CWD = getConfig('cache_root')."/$table/$id/$method"; 

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
	#chdir(getConfig('cache_root')."/$table/$id/$method");
	local $CWD = getConfig('cache_root')."/$table/$id/$method";
	
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
	my $dir = shift;

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
	my $dir = shift;

	my $path = getConfig('cache_root');

	# just write the latex2html to the rendering output 
	# file, with some minor post-processing
	#
	my $file = '';
	my $file_in = '';
	my $file_path = "$dir/index.html";
	# read output of l2h, running it through tidy to get XHTML
	# tidycmd causing apahce crash - need sub process?
	## BEN TODO $file = readFile(getConfig('tidycmd')." -wrap 1024 -asxml index.html 2>/dev/null |");
	dwarn "opening file $file_path";
	#sleep 1;  #need a better way to check for when file is ready to open ugh
	# Tyring a simple poll method with timeout
	my $max_wait_time = 30; # in seconds
	my $poll_interval = 1;  # in seconds
	my $elapsed_time = 0;

	while ($elapsed_time < $max_wait_time) {
		if (-e $file_path) {
			dwarn "File found: $file_path in $elapsed_time seconds";
			last;
		}
		sleep($poll_interval);
		$elapsed_time += $poll_interval;
	}

	if ($elapsed_time >= $max_wait_time) {
		dwarn "File did not appear within the wait time, $max_wait_time.";
	}

	if (open(my $filein, '<:raw', $file_path)) {
		$file_in = do { local $/; <$filein> };
		close $filein;
		$file_in = decodeRenderedHTML($file_in);
	} else {
		dwarn "postProcessL2hIndex could not open $file_path";
	}

	dwarn "postProcessL2hIndex raw html:\n $file_in";
	my $tidy = HTML::Tidy->new({
		output_xhtml => 1,
		wrap => 1024,
		char_encoding => 'utf8',
		numeric_entities => 1,
	});
	$tidy->ignore( type => TIDY_WARNING, type => TIDY_INFO );
	$file = $tidy->clean($file_in);
	dwarn "postProcessL2hIndex after tidy:\n $file";

	if ($file =~ /<body.*?>(.*?)<hr\s*?\/>\s*?<\/body>/sio) {
		$file = $1;
	} elsif ($file =~ m{<body\b[^>]*>([\s\S]*?)</body>}si) {
		$file = $1;
	} else {
		$file = normalizeKnownHTMLEntities($file_in);
		dwarn "postProcessL2hIndex could not find body element";
	}
	dwarn "postProcessL2hIndex 1st regular expression:\n $file";
	$file =~ s/src=\s*\"(.*?)\"/src=\"$url\/$1\"/igso;
	dwarn "postProcessL2hIndex 2nd regular expression:\n $file";
	
	# add title tooltips
	$file =~ s/(alt="(.+?)")/$1 title="$2" /igso;
	dwarn "postProcessL2hIndex 3rd regular expression:\n $file";

	$file = escapeNonAsciiAsHTMLEntities(normalizeKnownHTMLEntities($file));

	$file = "<table border=\"0\" width=\"100%\"><td>$file</td></table>";
	dwarn "postProcessL2hIndex final html:\n $file";
	# write it out to standard location
	#
	open OUTFILE,">", "$dir/".getConfig('rendering_output_file');
	print OUTFILE "$file";
	close OUTFILE;
	

	# something went wrong, replace rendering output file with the contents of 
	# error.out, with some minor post-processing (pull out just error section)
	#
	# else {
	# 	$file = readFile("error.out");
	# 	$file =~ s/^.*?(\*\*\* Error:)/$1/gs;
	# 	$file =~ s/Died at.+$//gs;
	# 	$file =~ s/\n+/\n/gs;
	
	# 	my $newfile = $file;
	# 	while ($file =~ /<<([0-9]+)>>/gs) {
	# 		my $num = $1;
	# 		$newfile =~ s/<<$num>>(.*?)<<$num>>/{$1}/gs;
	# 	}
	# 	$file = $newfile;
	# 	$file = tohtmlascii($file);
	# 	$file =~ s/\n/<br \/>/gs;
	# 	$file = "<table border=\"0\" width=\"100%\"><tr><td><font color=\"#ff0000\"><b>$file</b></font></td></tr></table>";
	# }

}

# process latex2html generated index.html file to produce just the html 
# Noosphere needs to include in pages.	Writes this output to the rendering
# output file.
# 
sub postProcess_make4htIndex {
	my $url = shift;
	my $dir = shift;
	my $filename = shift;

	my $path = getConfig('cache_root');

	# just write the latex2html to the rendering output 
	# file, with some minor post-processing
	#
	my $file = '';
	my $file_in = '';
	my $file_path = "$dir/$filename";
	# read output of l2h, running it through tidy to get XHTML
	# tidycmd causing apahce crash - need sub process?
	## BEN TODO $file = readFile(getConfig('tidycmd')." -wrap 1024 -asxml index.html 2>/dev/null |");
	dwarn "opening file $file_path";
	#sleep 1;  #need a better way to check for when file is ready to open ugh
	# Tyring a simple poll method with timeout
	my $max_wait_time = 30; # in seconds
	my $poll_interval = 1;  # in seconds
	my $elapsed_time = 0;

	while ($elapsed_time < $max_wait_time) {
		if (-e $file_path) {
			dwarn "File found: $file_path in $elapsed_time seconds";
			last;
		}
		sleep($poll_interval);
		$elapsed_time += $poll_interval;
	}

	if ($elapsed_time >= $max_wait_time) {
		dwarn "File did not appear within the wait time, $max_wait_time.";
	}

	if (open(my $filein, '<:raw', $file_path)) {
		$file_in = do { local $/; <$filein> };
		close $filein;
		$file_in = decodeRenderedHTML($file_in);
	} else {
		dwarn "postProcess_make4htIndex could not open $file_path";
	}

	# make4ht already emits UTF-8 HTML, so avoid HTML::Tidy here; it can
	# reinterpret Unicode text as Latin-1 and produce mojibake.
	dwarn "postProcess_makehtIndex raw html:\n $file_in";
	if ($file_in =~ m{<body\b[^>]*>[\s\S]*?</body>}si) {
		$file = $&;
	} else {
		$file = $file_in;
		dwarn "postProcess_makehtIndex could not find body element";
	}
	dwarn "postProcess_makehtIndex return 1st regular expression:\n $file";
	#$file =~ s/src=\s*\"(.*?)\"/src=\"$url\/$&\"/igso;
	$file =~ s{\bsrc=(["'])([^"']+?)\1}{src=$1$url/$2$1}g;
	dwarn "postProcessL2hIndex 2nd regular expression:\n $file";
	
	# add title tooltips
	$file =~ s/(alt="(.+?)")/$1 title="$2" /igso;
	dwarn "postProcessL2hIndex 3rd regular expression:\n $file";

	$file = escapeNonAsciiAsHTMLEntities($file);

	$file = "<table border=\"0\" width=\"100%\"><td>$file</td></table>";
	dwarn "postProcessL2hIndex final html:\n $file";
	# write it out to standard location
	#
	open OUTFILE,">", "$dir/".getConfig('rendering_output_file');
	print OUTFILE $file;
	close OUTFILE;
	

	# something went wrong, replace rendering output file with the contents of 
	# error.out, with some minor post-processing (pull out just error section)
	#
	# else {
	# 	$file = readFile("error.out");
	# 	$file =~ s/^.*?(\*\*\* Error:)/$1/gs;
	# 	$file =~ s/Died at.+$//gs;
	# 	$file =~ s/\n+/\n/gs;
	
	# 	my $newfile = $file;
	# 	while ($file =~ /<<([0-9]+)>>/gs) {
	# 		my $num = $1;
	# 		$newfile =~ s/<<$num>>(.*?)<<$num>>/{$1}/gs;
	# 	}
	# 	$file = $newfile;
	# 	$file = tohtmlascii($file);
	# 	$file =~ s/\n/<br \/>/gs;
	# 	$file = "<table border=\"0\" width=\"100%\"><tr><td><font color=\"#ff0000\"><b>$file</b></font></td></tr></table>";
	# }

}

# Decode rendered HTML from external TeX tools. Prefer UTF-8, but accept legacy
# Latin-1 output from older latex2html installations.
sub decodeRenderedHTML {
	my $bytes = shift;
	my $decoded = eval { decode('UTF-8', $bytes, FB_CROAK) };

	return defined $decoded ? $decoded : decode('ISO-8859-1', $bytes);
}

sub normalizeKnownHTMLEntities {
	my $html = shift;

	$html =~ s/&ldquo;/&#8220;/g;
	$html =~ s/&rdquo;/&#8221;/g;
	$html =~ s/&lsquo;/&#8216;/g;
	$html =~ s/&rsquo;/&#8217;/g;
	$html =~ s/&ndash;/&#8211;/g;
	$html =~ s/&mdash;/&#8212;/g;
	$html =~ s/&hellip;/&#8230;/g;
	$html =~ s/&minus;/&#8722;/g;
	$html =~ s/&nbsp;/&#160;/g;

	return $html;
}

# Keep cached fragments safe for legacy raw file reads and prints. Browsers
# render these entities as Unicode, while the stored HTML remains ASCII.
sub escapeNonAsciiAsHTMLEntities {
	my $html = shift;

	$html =~ s/([^\x00-\x7F])/sprintf("&#%d;", ord($1))/eg;

	return $html;
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
