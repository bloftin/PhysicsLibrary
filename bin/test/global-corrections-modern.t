use strict;
use warnings;
use Test::More;
use File::Spec;

my $root = File::Spec->catdir(File::Spec->curdir());
my $corrections_path = File::Spec->catfile($root, 'lib', 'Noosphere', 'Corrections.pm');
my $template_path = File::Spec->catfile($root, 'stemplates', 'globalcors.tt');

open my $corrections_fh, '<', $corrections_path or die "Cannot read $corrections_path: $!";
my $corrections = do { local $/; <$corrections_fh> };
close $corrections_fh;

open my $template_fh, '<', $template_path or die "Cannot read $template_path: $!";
my $template = do { local $/; <$template_fh> };
close $template_fh;

my ($global) = $corrections =~ /^(sub globalViewCorrections \{.*?)(?=^# edit your corrections)/ms;
die 'globalViewCorrections not found' unless defined $global;

like($global, qr/Template->new/, 'global corrections page uses a dedicated presentation template');
like($global, qr/process\('globalcors\.tt'/, 'global corrections page renders the dedicated template');
like($global, qr/qhtmlescape\(\$row->\{title\}\).*qhtmlescape\(\$row->\{objtitle\}\)/s, 'correction and object titles are escaped before presentation');
like($global, qr/qhtmlescape\(\$row->\{userfrom\}\).*qhtmlescape\(\$row->\{userto\}\)/s, 'user names are escaped before presentation');
like($global, qr/where c\.closed is null/, 'pending-correction query semantics are retained');
like($global, qr/getPager\(\{op=>\$params->\{'op'\}, total=>\$total, offset=>\$offset\},\$userinf,2\)/, 'existing paging behavior is retained');
like($template, qr/INCLUDE modernboxheader\.tt title = 'Pending Corrections'/, 'template provides the page heading');
like($template, qr/awaiting review or resolution/, 'template explains the queue');
like($template, qr/\[% pager %\]/, 'template displays pagination');
like($template, qr/View correction<\/a>/, 'template exposes correction view action');
like($template, qr/There are no pending corrections/, 'template retains the empty state');

SKIP: {
	skip 'Template Toolkit is not installed in this environment', 5 unless eval { require Template; 1 };
	my $tt = Template->new({ INCLUDE_PATH => File::Spec->catdir($root, 'stemplates') });
	my $html = '';
	ok($tt->process('globalcors.tt', {
		total => 1,
		pager => '',
		corrections => [{
			date => '2026-09-26',
			correction_title => 'Correct a sign',
			correction_url => '/?op=getobj&amp;from=corrections&amp;id=1',
			object_title => 'A useful article',
			object_url => '/?op=getobj&amp;from=objects&amp;id=2',
			reporter => 'Ada', reporter_url => '/?op=getuser&amp;id=3',
			owner => 'Grace', owner_url => '/?op=getuser&amp;id=4',
		}],
	}, \$html), 'template renders representative correction rows') or diag($tt->error());
	like($html, qr/Correct a sign/, 'rendered output includes correction row');
	like($html, qr/A useful article/, 'rendered output includes target article');
	like($html, qr/Assigned to/, 'rendered output includes correction owner');
	like($html, qr/View correction/, 'rendered output includes correction action');
}

done_testing();
