package Noosphere;

use strict;

# show license information for the site
#
sub getLicense {
  
  return paddingTable(clearBox("Creative Commons Attribution-ShareAlike CC BY-SA 4.0 License",(new TemplateNS("license.html"))->expand())); 
  
}

# get the "about" (history, background) page.
#
sub getAbout {
  my $params = shift;
	#dwarn "getAbout start";

  my $file = 'about.tt';
	my $htmlout = "";
  my $vars;

  my $tt = Template->new({
		INCLUDE_PATH => '/var/www/pp/stemplates',
	});

	
  my $ret = $tt->process($file, $vars, \$htmlout) || die "Template process failed: ", $tt->error(), "\n";
	#dwarn "templat html:\n$htmlout\nreturn value:\n$ret";
	#dwarn "templateTestPerl end";
  return $htmlout;

}
sub getAboutOld {

  return paddingTable(clearBox('The '.getConfig('projname').' Story',(new TemplateNS('about.html'))->expand())); 
  
}

# get the feedback info page
#
sub getFeedback {

  return paddingTable(clearBox('Feedback',(new TemplateNS('feedback.html'))->expand()));

}
# get the Google seach page
#
sub getGoogleSearch {
  return paddingTable(clearBox('Search',(new TemplateNS('googlesearch.html'))->expand()));
}

1;
