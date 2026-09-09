#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";

# Preserve every unrelated field, including settings unknown to this version.
sub hidden_email_prefs {
    my ($raw) = @_;
    my @fields = split /;/, $raw // '', -1;
    my $found = 0;
    for my $field (@fields) {
        my ($key) = split /=/, $field, 2;
        if (defined($key) && $key eq 'hideemail') {
            $field = 'hideemail=on';
            $found = 1;
        }
    }
    return join(';', @fields) if $found;
    return ($raw // '') . (length($raw // '') && $raw !~ /;$/ ? ';' : '') . 'hideemail=on';
}

sub main {
    my ($mode) = @ARGV;
    die "Usage: perl $0 --dry-run|--apply\n"
        unless @ARGV == 1 && ($mode eq '--dry-run' || $mode eq '--apply');
    require Noosphere;
    require Noosphere::DB;
    require Noosphere::Config;
    my $db = Noosphere::dbConnect() or die "Cannot connect to database\n";
    $db->{RaiseError} = 1;
    my $table = $db->quote_identifier(Noosphere::getConfig('user_tbl'));
    my $rows = $db->selectall_arrayref("SELECT uid, prefs FROM $table");
    my ($changed, $unchanged, $conflicts) = (0, 0, 0);
    for my $row (@$rows) {
        my ($uid, $old) = @$row;
        my $new = hidden_email_prefs($old);
        if (defined($old) && $old eq $new) { $unchanged++; next; }
        if ($mode eq '--dry-run') { $changed++; next; }
        # Avoid overwriting preferences saved by a user during this reset.
        my $count = defined($old)
            ? $db->do("UPDATE $table SET prefs=? WHERE uid=? AND prefs=?", undef, $new, $uid, $old)
            : $db->do("UPDATE $table SET prefs=? WHERE uid=? AND prefs IS NULL", undef, $new, $uid);
        if ($count > 0) { $changed++; } else { $conflicts++; }
    }
    print "$mode: $changed users " . ($mode eq '--apply' ? 'updated' : 'would change') .
        "; $unchanged already hidden; $conflicts concurrent changes.\n";
    $db->disconnect;
    die "Some preferences changed during the reset; rerun to finish.\n" if $conflicts;
}

main() unless caller;
1;
