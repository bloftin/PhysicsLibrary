package Noosphere;

use strict;
use Noosphere::TemplateNS;
use Cwd;
use File::chdir;
use File::Path qw(make_path remove_tree); 
use File::Remove 'remove';
###use Cwd qw(chdir);
use File::Copy::Recursive qw(rcopy pathrm rmove);

# determine if a directory is "bad"; either nonexistant, equal to root
#	or containing a //
#
sub baddir {
	my $dir = shift;

	if ($dir =~ /^\/*$/ || $dir=~/^\/\//) {
		dwarn "*** filebox : bad dir [$dir]"; 
		return 1 
	}
	if (not -e "$dir") {
		dwarn "*** filebox : nonexistant dir [$dir]";
		return 1;
	}

	return 0;
}

# cleanCache - clear out a cache dir
#
sub cleanCache {
	my $table = shift;
	my $id = shift;
	my $method = shift;
	
	my $cacheroot = getConfig('cache_root');


	my $dir = "$cacheroot/$table/$id/$method";
	#dwarn "*** filebox : cleancache in [$dir]";

	return if (baddir($dir));

	pathrm("$dir/*");
}

# cacheFileBox - copy filebox to a cache dir
#
sub cacheFileBox {
	my $table = shift;
	my $id = shift;
	my $method = shift;

	my $fileroot = getConfig('file_root');
	my $cacheroot = getConfig('cache_root');
 
	return if (not -e "$fileroot/$table/$id");
	
	make_path("$cacheroot/$table/$id", {verbose => 1}) if (not -e "$cacheroot/$table/$id");
	make_path("$cacheroot/$table/$id/$method", {verbose => 1}) if (not -e "$cacheroot/$table/$id/$method");

	my @files = <$fileroot/$table/$id/*>;
	for my $file (@files) {
		copy($file,"$cacheroot/$table/$id/$method");
		dwarn "copy $file to $cacheroot/$table/$id/$method";
	}
}

# does what it says
#
sub deleteFileBox {
	my $table = shift;
	my $id = shift;
	
	my $fileroot = getConfig('file_root');
	my $dir = "$fileroot/$table/$id";
	
	return if (baddir($dir));

	pathrm("$dir");
}

# cloneFileBox - copy filebox to a new one
#
sub cloneFileBox {
	my $table = shift;
	my $old = shift;	# source box id
	my $new = shift;	# dest box id

	my $fileroot = getConfig('file_root');
	my $src = "$fileroot/$table/$old";
	my $dest = "$fileroot/$table/$new";
	
	copy($src, $dest) if (-e $src);
}

# copyBoxFilesToTemp - make a temporary directory and move filebox
#	contents into it (this way editing can happen 
#	without disrupting object viewing) 
#
sub copyBoxFilesToTemp {
	my $table = shift;
	my $params = shift;

	dwarn "copyBoxFilesToTemp  start cwd: $CWD";
	my $id = $params->{'id'};
	my $fileroot = getConfig('file_root');
	my $cacheroot = getConfig('cache_root');

	# make a new cache dir and remember it 
	#
	$params->{'tempdir'} = makeTempCacheDir();

	my $source = "$fileroot/$table/$id";
	my $dest = "$cacheroot/$params->{tempdir}";

	#system("cp -r $source/* $dest");
	File::Copy::Recursive::rcopy_glob("$source/*", $dest) or dwarn "Problem copying Box Files to Temp: $!";
	dwarn "copyBoxFilesToTemp  end cwd: $CWD";
}

# moveTempFilesToBox - move temporary cache dir files to file box.
#
sub moveTempFilesToBox {
	my $params = shift;
	my $id = shift;
	my $table = shift;

	# we need a temp dir
	#
	if (!nb($params->{'tempdir'})) {
		dwarn "*** moveTempFilesToBox: no tempdir is set!";
		return;
	}
	
	# preliminaries - get file root, make dir
	#
	my $fileroot = getConfig('file_root');
	my $cacheroot = getConfig('cache_root');
	
	my $dest = "$fileroot/$table/$id";
	my $source = "$cacheroot/$params->{tempdir}";
	
	# make sure file box directory exists and is clear
	dwarn "source:\n$source\ndest:\n$dest";
	if (-e $dest) {
		dwarn "destination exists, remove all files in $dest";
		remove("$dest/*");
	} else {
		dwarn "destination does not exist, make";
		make_path("$dest", {verbose => 1});
	}

	# move non-rendering dir files over.
	#
	dwarn "*** move temp files to box: changing to dir $source";
	##chdir "$source";
	##chdir("$source");# or dwarn "ERROR chdir: cannot change: $!\n";
	local $CWD = "$source";
	my $dir = getcwd();
	$dir =~ s/\s*$//;
	dwarn "temp dir to remove: $dir";
	if (baddir($dir)) {
		dwarn "*** move temp files to box: failed to change to dir $source, ended up in root! aborting.";
	return;
	}
	my @files = <*>;
	my @methoddirs = getMethods();
	foreach my $file (@files) {
		if (not inset($file,@methoddirs)) {
			dwarn "attempt to move $file,$dest";
			rmove($file, $dest);
		} else {
			dwarn "attempt to remove $file, all is removed in removeTempCacheDir";
			#remove_tree("$file");
			#pathrm("$file");
		}
	}

	# clean up cache dir
	#
	local $CWD = $cacheroot;
	dwarn "curernt directory $CWD";
	#removeTempCacheDir($params->{'tempdir'});
	dwarn "curernt directory after removeTempCacheDir: $CWD";
}

# handleFileManager - get files, display manager, uses new template system
# 
sub handleFileManager {
	my $template = shift;
	my $params = shift;
	my $upload = shift;
	
	my $ftemplate = new TemplateNS('filemanagerform.html');
	my $table = $params->{'from'};
	my $dest = '';
	my $ferror = '';
	my $changes = 0;

	# figure out destination. if we are editing an existing objects, 
	# copyBoxFilesToTemp should already have been called to make a temp dir 
	# and set $params->{tempdir}
	#
	dwarn "handleFileManager started";
	if (nb($params->{'tempdir'})) {
		dwarn "params->{tempdir} was not empty";
		$ftemplate->setKey('tempdir', $params->{'tempdir'});
		$dest = getConfig('cache_root')."/$params->{tempdir}";
		dwarn "fileManager tempdir: $ftemplate, $dest";
	} elsif (nb($params->{'id'})) {
		$dest = getConfig('file_root')."/$table/$params->{id}";
		dwarn "fileManager id: $ftemplate, $dest";
	} else {	# make a new cache dir if we have no info
		$params->{'tempdir'} = makeTempCacheDir();
		
		$ftemplate->setKey('tempdir', $params->{'tempdir'});
		$dest = getConfig('cache_root')."/$params->{tempdir}";
		dwarn "fileManager new cache dir: $params->{'tempdir'}, $ftemplate, $dest";
	}

	#dwarn "managing files in box at $dest";

	# grab URLs 
	#
	if (defined $params->{filebox} && $params->{filebox} eq "upload" && nb($params->{fb_urls})) {
		dwarn "fileManager grab urls: $params->{filebox}, nb($params->{fb_urls})";
		my @urls = split(/\s*\n\s*/,$params->{fb_urls});
		foreach my $url (@urls) {
			if (not wget($url,$dest)) {
				$ferror .= "Problem getting $url<br/>" if (not wget($url,$dest));
			} else {
				$changes = 1;
			}
		}
		if ($ferror ne '') {
		$ftemplate->setKey('fb_urls', $params->{fb_urls});
		}
	} else {
		dwarn "fileManager grab urls else set key";
		$ftemplate->setKey('fb_urls', $params->{fb_urls});
	}
	
	# move an uploaded file
	#
	if (defined $upload and $upload->{'filename'}) {
		dwarn "moving uploaded file $upload->{tempfile} to $dest/$upload->{filename}";
		$ENV{'PATH'} = "/bin:/usr/bin:/usr/local/bin";
		rmove($upload->{tempfile},"$dest/$upload->{filename}") or dwarn "Failed to move uploaded file: $!";
		$changes = 1;
	}

	# handle file removal request
	# 
	if (nb($params->{'remove'})) {
		dwarn "fileManager handle file removal request";
		my @files = map("$dest/$_",split(',',$params->{'remove'}));
		my $cnt = unlink @files; 
	if ($cnt > 0 ) { $changes = 1; }
	}

	# generate the file removal chooser and file list
	#
	my $filelist = '';
	my @filelist = ();
	my $rmlist = '';
	my $returnValue;
	if ( -e $dest ) {
		dwarn "file removal chooser and file list";
		$ENV{'PATH'} = "/bin:/usr/bin:/usr/local/bin";
		local $CWD = "$dest";  # chdir seems to be crashing mod_perl, looking for worarounds
		my @files = <*>;
		if ($#files < 0) {
	 		dwarn "files < 0, [no files]";
	 		$rmlist = "[no files]"; 
	 	}
		else {
			my @methoddirs = getMethods();
	 		my $count = 0; 
		
	 		foreach my $file (@files) {
	 			dwarn "file: $file";	
				
				if (not inset($file,@methoddirs)) {
					my $ftext;
					if (defined $params->{'id'}) {
						$ftext = "<a href=\"".getConfig('file_url')."/$table/$params->{id}/$file\">$file</a>";
					} else { 
						$ftext = "<a href=\"".getConfig('cache_url')."/$params->{tempdir}/$file\">$file</a>";
					}
			
					$rmlist .= "<input type=\"checkbox\" name=\"remove\" value=\"$file\" />$ftext<br />";
					push @filelist, $file; 
					$count++;
				}
			}
			if ($count == 0) {
				$rmlist = "[no files]";
			} else {
				$filelist = join(';', @filelist);
			}
		}
		
		#my $cwd = getcwd();
		#dwarn "getcwd() cwd: $cwd";
		#$returnValue = chomp $cwd;
		#dwarn "returnValue chomp: $returnValue, $cwd";
		#$returnValue = chdir("$dest");
		#dwarn "returnValue chdir dest: $returnValue";
		#my $cwddes = getcwd();
		#dwarn "chdir des cwd: $cwddes";
		#$returnValue = chdir("$cwd");
		#dwarn "returnValue chdir cwd: $returnValue";
		#$cwddes = getcwd();
		#dwarn "chdir return cwd: $cwddes";
	}
	else {
	 	dwarn "rmlist is [no files]";
	 	$rmlist = "[no files]";
	}
	# if ( -e $dest ) {
	# 	dwarn "file removal chooser and file list";
	# 	$ENV{'PATH'} = "/bin:/usr/bin:/usr/local/bin";
	# 	my $cwd = getcwd();
	# 	dwarn "getcwd() cwd: $cwd";
	# 	chomp $cwd;
	# 	##chdir $dest;
	# 	chdir("$dest");# or dwarn "ERROR chdir: cannot change: $!\n"; 
	# 	my @files = <*>;
	# 	##chdir $cwd;
	# 	chdir("$cwd");# or dwarn "ERROR chdir: cannot change: $!\n"; 
	# 	if ($#files < 0) {
	# 		dwarn "files < 0, [no files]";
	# 		$rmlist = "[no files]"; 
	# 	} else {
			
	# 		my @methoddirs = getMethods();
	# 		my $count = 0; 
		
	# 		foreach my $file (@files) {
	# 			dwarn "file: $file";
	# 			if (not inset($file,@methoddirs)) {
	# 				dwarn "not inset";
	# 				my $ftext;
	# 				if (defined $params->{'id'}) {
	# 					dwarn "defined params->id";
	# 					$ftext = "<a href=\"".getConfig('file_url')."/$table/$params->{id}/$file\">$file</a>";
	# 				} else { 
	# 					dwarn "not defined params->id";
	# 					$ftext = "<a href=\"".getConfig('cache_url')."/$params->{tempdir}/$file\">$file</a>";
	# 				}
			
	# 				$rmlist .= "<input type=\"checkbox\" name=\"remove\" value=\"$file\" />$ftext<br />";
	# 				push @filelist, $file; 
	# 				$count++;
	# 				dwarn "current count: $count";
	# 			}
	# 		}
	# 		if ($count == 0) {
	# 				dwarn "count == 0";
	# 				$rmlist = "[no files]";
	# 			} else {
	# 				dwarn "count 1= 0";
	# 				$filelist = join(';', @filelist);
	# 				dwarn "filelist:\n $filelist";
	# 			}
	# 	}
	# } else {
	# 	dwarn "rmlist is [no files]";
	# 	$rmlist = "[no files]";
	# }
	
	# put info in the file manager template
	#
	$ftemplate->setKeys('rmlist' => $rmlist, 'ferror' => $ferror, 'filelist' => $filelist);
	$params->{'filechanges'} = "yes" if ($changes == 1);
	if (nb($params->{'filechanges'})) {
		dwarn "filemanager template set key";
		$ftemplate->setKey('filechanges', $params->{'filechanges'});
	}
	
	# combine file manager template and parent template
	#
	my $html_fmanager = $ftemplate->expand();
	$template->setKey('fmanager', $html_fmanager);
	dwarn "handleFileManager ended";
	return ($template, $html_fmanager);
}

# wget - low level interface to wget method. return 1 success, 0 fail.
#
sub wget { 
	my $source = shift;	 # source url to download from
	my $dest = shift;		# local location (directory) to place file in
	my $cmd = getConfig('wgetcmd');
	#my $cwd = getcwd();
	dwarn "Wget strted: probably wont work";
	if (not -d $dest) {
		return 0;
	}

	##chdir $dest;
	local $CWD ="$dest";# or dwarn "ERROR chdir: cannot change: $!\n"; 
	
	
	my @args = split(/\s+/,$cmd);
	push @args,$source;
	##system(@args);

	my $ret = (($?>>8)==0)?1:0;
	##chdir $cwd;
	#local $CWD ="$cwd";# or dwarn "ERROR chdir: cannot change: $!\n"; 

	return $ret;
}

sub httpUpload { 
	my $params = shift;
	my $userinf = shift;
	my $upload = shift;
	my $html = '';

	$html .= "<form method=\"post\" action=\"".getConfig("main_url")."/?op=httpupload\" enctype=\"multipart/form-data\">";
	$html .= "<input type=\"file\" size=\"50\" name=\"upload\" />";
	$html .= "<input type=\"submit\" name=\"submit\" value=\"upload\" />";
	$html .= "</form>";
	if (defined($params->{submit})) {
		$html .= "got file: $upload->{filename} @ $upload->{tempfile}";
	}
	
	return paddingTable(makeBox('upload',$html));

}

1;

