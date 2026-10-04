package Noosphere;

use strict;
use Noosphere::Snapshots;

# show license information for the site
#
sub getLicense {
  my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
  my $html = '';
  $tt->process('license.tt', {}, \$html)
    || die "Template process failed: ", $tt->error(), "\n";
  return $html;
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
		INCLUDE_PATH => getConfig('template_path'),
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
  my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
  my $html = '';
  $tt->process('feedback.tt', {
    email => qhtmlescape(getAddr('feedback')),
  }, \$html) || die "Template process failed: ", $tt->error(), "\n";
  return $html;
}
# get the Google seach page
#
sub getGoogleSearch {
  return paddingTable(clearBox('Search',(new TemplateNS('googlesearch.html'))->expand()));
}

1;
