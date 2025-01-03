package Noosphere;

use strict;
#Ben changed Apache to Apache2 for mod_perl 2
use Apache2::compat ();
use CGI::Util();

# let us know whether the user is sending data in MIME format or standard
#
sub ismime {
  my $req=shift;
  my $ct=$req->header_in("Content-type") || '';
  
  return 1 if ($ct =~ m!^multipart/form-data!);
  return 0;
}

# parse parameters in MIME format
#
sub parseMime {
  my $boundary=shift;
  my $body=shift;
  my %upload;
  my %formdata;

  $upload{filename} = '';
  
  my @parts=split(/--$boundary[\r\-][\n\-]/,$body);
  foreach my $part (@parts) {
	next if ( $part =~/^\s*$/ );
	my @lines=split(/\r\n/,$part);
	
	# grab header info for part
	#
	my $name="";
	my $filename="";
	my $type="";
	foreach my $line (@lines) {

	  if ($line =~ /^Content-Disposition: (.*)$/i) {
	    # handle content-disposition line
		foreach my $d (split(/;\s*/,$1)) {
		  my ($key,$val)=split('=',$d);
		  $val=~s/\"//g;
		  $val=~s/\r//g;
		  $filename=$val if ($key eq "filename");
		  $name=$val if ($key eq "name");
		}
	  } elsif ($line =~ /^Content-Type: (.*)$/i) {
	    # handle content type
		$type=$1;
	  }
	 
	  last if ($line =~ /^\s*$/);
	}
	
	# grab actual data of part
	#
	$part=~/\r\n\r\n(.+?)\s*$/s;
	my $mimedata=$1;
    
	# regular form variable
	#
	if ($filename eq "") {
	  $mimedata=~s/\r//gs;    # kill ^M
	  if (defined $formdata{$name}) {
	    $formdata{$name}.=",$mimedata";   # collapse same keys into CSV list
	  } else {
	    $formdata{$name}=$mimedata;
	  }
      #dwarn "\t$name=>$mimedata\n";
	} 
	# uploaded file
	#
	else {
	  #dwarn "uploaded file name $filename";
	  #dwarn "upload data [$mimedata]";

	  $upload{formname}=$name;
	  $upload{filename}=basefilename($filename);
	  $upload{type}=$type;
	  my $tempfile=getTempFileName();
	  # write out to the temp file
	  #
	  open OUT,">$tempfile";
	  binmode OUT;
	  syswrite OUT,$mimedata;
	  close OUT;
	  $upload{tempfile}=$tempfile;
      #dwarn "\tfile=>[$filename,$type,$tempfile]\n";
	}
  }

  return ({%formdata},{%upload});
}

# readmime - read in user data in MIME format
#
sub readMime {
  my $req=shift;
  my $params=shift;
  my $ct=$req->header_in("Content-type") || "";
  my $formdata;
  my $upload;

  #my $content=$req->content;
  #my $debug=$req->as_string;
  #dwarn "request is [$debug]";
  
  $ct=~/boundary=(.*)/;
  my $boundary=$1;
  my $buff;
  my $len=$req->header_in("Content-Length");
  $req->read($buff, $len);

  #dwarn "mime data: [$buff]";
 
  # TODO: figure out if passing an entire file in the buffer is a bad idea
  # maybe we should just read in the entire multipart data to a temp file, 
  # then pass the file name
  #
  ($formdata,$upload)=parseMime($boundary,$buff);
  foreach my $key (keys %$formdata) { $params->{$key}=$formdata->{$key} }
  return $upload;
}

# parseGetArgs - why use this instead of just Apache.pm's args() in array 
#                context?  Well, we need to account for instances where we 
#                have more than one arg in the query string with the same
#                key/variable name.  In this case, we collapse all such args
#                into one key with comma-separated values.
#
sub parseGetArgs {
  #dwarn "Begin parseGetArgs";
  my $args=shift;
  my %arghash;
  #dwarn "Before return of not defined args";
  return if (not(defined $args or $args));
  #dwarn "Args are defined";
#Ben
  my @keyvals=split(/[&;]/,$args);
  foreach my $keyval (@keyvals) {
    my ($key,$val)=split(/=/,$keyval);
	#dwarn $key;
	$key=lc($key);
#	$val=Apache::unescape_url_info($val);
	#dwarn "Before unescape";
	#dwarn $val;
	$val=CGI::Util::unescape($val);
	#dwarn "After unescape";
	#dwarn $val;
#	$val=Apache::compat->unescape_url_info($val);
	if (defined $arghash{$key}) {
	  $arghash{$key}.=",$val";
	} else {
	  $arghash{$key}=$val;
	}
  }

  return %arghash;
}

# parseParams - main entry point for turning the information the user sends
#               into a hash of key/value
#
sub parseParams {
  dwarn "Enter parseParams";
  my $req=shift;
  my $ismime=ismime($req);
  #dwarn "After ismine";
  #dwarn $ismime;
  #dwarn $req;
  my %get_params=parseGetArgs(scalar($req->args));
  #dwarn "After parseGetARgs";
  my %post_params=$req->content if (not $ismime);
  #dwarn "THE BODY IS:\n";
  my @bdy = %post_params;
  #dwarn "@bdy\n";
  my %params;
  my $upload;
 
  dwarn "get_params:\n @{[%get_params]}\n";
  dwarn "post_params:\n @{[%post_params]}\n";	
  # parse GET params
  #
  if (scalar keys %get_params) {
    dwarn "get params\n" if (keys %get_params);
    foreach my $key (keys %get_params) {
      if ($key) {
	  my $k=lc($key);
	  $params{$k}=$get_params{$key};
	  $params{$k}=~s/\r//sg;   # kill ^M's
	  dwarn "\t$key=>$params{$k}\n";
      } 
    }
  }

  # conventionally parse POST params
  #
  if (not $ismime) {
    dwarn "post params\n" if (keys %post_params);
    foreach my $key (keys %post_params) {
      if ($key) { #BB: Apache 2 seems to send an empty $key on GET request
	  my $k=lc($key);
	  $params{$k}=$post_params{$key};
	  $params{$k}=~s/\r//sg;   # kill ^M's
	  dwarn "\t$key=>$params{$k}\n";
      }
    }
  } 
  
  # parse MIME POST params
  #
  else {
    dwarn "mime/multipart params\n";
	  $upload=readMime($req,\%params);
  }
  return({%params},$upload); 
}

# split a param line into a hash
#
sub paramsToHash {
  my $string = shift;
 
  my %hash;
  
  my @pairs = split('&', $string);
  foreach my $pair (@pairs) {
    my ($key, $val) = split ('=', $pair);
	$hash{$key} = $val;
  }

  return {%hash};
}

1;
