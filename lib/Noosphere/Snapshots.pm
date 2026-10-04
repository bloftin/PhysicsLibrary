package Noosphere;

use strict;
use Cwd ();
use Encode ();
use POSIX ();
use URI::Escape ();
use Template;

sub snapshotArchiveSize {
  my ($bytes) = @_;
  my @units = ('B', 'KiB', 'MiB', 'GiB', 'TiB');
  my $unit = 0;
  while ($bytes >= 1024 && $unit < $#units) {
    $bytes /= 1024;
    $unit++;
  }
  return $unit ? sprintf('%.1f %s', $bytes, $units[$unit]) : "$bytes B";
}

sub snapshotArchiveCatalog {
  my $data = Cwd::abs_path(getConfig('base_dir') . '/data');
  return { available => 0, archives => [] } unless defined $data;
  my $directory = "$data/snapshots";
  my $resolved = Cwd::abs_path($directory);
  # Match the protected download root; never expose files through symlinks.
  return { available => 0, archives => [] }
    unless defined($resolved) && $resolved eq $directory && !-l $directory;
  opendir my $dir, $directory or return { available => 0, archives => [] };
  my @archives;
  while (defined(my $name = readdir $dir)) {
    next if $name =~ /^(?:\.)|[\x00-\x1f\x7f\\]/;
    next unless $name =~ /\.(tar\.gz|tar\.bz2|tar\.xz|tgz|tar|zip)\z/i;
    my $format = uc($1);
    my $file = "$directory/$name";
    next if -l $file || !-f $file || !-r $file;
    my @stat = stat $file;
    next unless @stat;
    my $label = Encode::decode('UTF-8', $name, Encode::FB_DEFAULT | Encode::LEAVE_SRC);
    push @archives, {
      name => $label,
      format => $format,
      bytes => $stat[7],
      size => snapshotArchiveSize($stat[7]),
      modified_epoch => $stat[9],
      modified => POSIX::strftime('%Y-%m-%d %H:%M UTC', gmtime($stat[9])),
      modified_iso => POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($stat[9])),
      url => '/?op=downloadfile&path=' . URI::Escape::uri_escape("snapshots/$name"),
    };
  }
  closedir $dir;
  @archives = sort {
    $b->{modified_epoch} <=> $a->{modified_epoch} || $a->{name} cmp $b->{name}
  } @archives;
  return { available => 1, archives => \@archives };
}

sub getSnapshots {
  my ($params, $userinf) = @_;
  my $catalog = snapshotArchiveCatalog();
  my $tt = Template->new({ INCLUDE_PATH => getConfig('template_path') });
  my $html = '';
  $tt->process('snapshots.tt', {
    %$catalog,
    signed_in => $userinf && ($userinf->{uid} || 0) > 0,
  }, \$html) || die "Template process failed: ", $tt->error(), "\n";
  return $html;
}

1;
