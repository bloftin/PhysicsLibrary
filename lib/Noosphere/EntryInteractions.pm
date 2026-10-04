package Noosphere;

use strict;
use Template;
use URI;

sub entryInteractionURL {
  my ($op, @params) = @_;
  my $url = URI->new('/');
  $url->query_form(op => $op, @params);
  return "$url";
}

sub entryInteractionTemplate {
  my ($file, $vars) = @_;
  my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
  my $html = '';
  $tt->process($file, $vars, \$html)
    || die "Template process failed: ", $tt->error(), "\n";
  return $html;
}

sub entryInteractionSection {
  my ($title, $content, $admin) = @_;
  return entryInteractionTemplate('entrysection.tt', {
    title => $title, content => $content, admin => $admin,
  });
}

sub entryInteractionActions {
  my ($actions, $label, $rating) = @_;
  return entryInteractionTemplate('entryactions.tt', {
    actions => $actions, label => $label, rating => $rating,
  });
}

1;
