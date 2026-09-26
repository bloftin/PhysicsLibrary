use strict;
use warnings;
use Test::More;
use File::Spec;

my $root = File::Spec->catdir(File::Spec->curdir());
my $stats_path = File::Spec->catfile($root, 'lib', 'Noosphere', 'Stats.pm');
my $template_path = File::Spec->catfile($root, 'stemplates', 'unclassified.tt');

open my $stats_fh, '<', $stats_path or die "Cannot read $stats_path: $!";
my $stats = do { local $/; <$stats_fh> };
close $stats_fh;

open my $template_fh, '<', $template_path or die "Cannot read $template_path: $!";
my $template = do { local $/; <$template_fh> };
close $template_fh;

like($stats, qr/sub unclassifiedObjects.*?Template->new/s, 'unclassified page uses a dedicated presentation template');
like($stats, qr/process\('unclassified\.tt'/, 'unclassified page renders the dedicated template');
like($stats, qr/qhtmlescape\(\$row->\{'title'\}\)/, 'article titles are escaped before presentation');
like($stats, qr/qhtmlescape\(\$username\)/, 'contributor names are escaped before presentation');
like($stats, qr/op=adminclassify/, 'classification route remains available');
like($stats, qr/getPager\(\$params, \$userinf, 1\)/, 'existing paging behavior is retained');
like($stats, qr/where c\.objectid is null/, 'unclassified query semantics are retained');
like($template, qr/<h1>Unclassified Articles<\/h1>/, 'template provides the page heading');
like($template, qr/awaiting subject classification/, 'template explains the queue');
like($template, qr/\[% pager %\]/, 'template displays pagination');
like($template, qr/Classify<\/a>/, 'template exposes classification action');
like($template, qr/Every published article currently has a subject classification/, 'template retains the empty state');

SKIP: {
	skip 'Template Toolkit is not installed in this environment', 4 unless eval { require Template; 1 };
	my $tt = Template->new({ INCLUDE_PATH => File::Spec->catdir($root, 'stemplates') });
	my $html = '';
	ok($tt->process('unclassified.tt', {
		total => 1,
		pager => '',
		objects => [{
			title => 'Unclassified article', owner => 'Contributor',
			object_url => '/?op=getobj&amp;from=objects&amp;id=1',
			owner_url => '/?op=getuser&amp;id=2',
			classify_url => '/?op=adminclassify&amp;from=objects&amp;id=1',
		}],
	}, \$html), 'template renders representative unclassified rows') or diag($tt->error());
	like($html, qr/Unclassified article/, 'rendered output includes article row');
	like($html, qr/Contributor/, 'rendered output includes contributor');
	like($html, qr/Classify/, 'rendered output includes classification control');
}

done_testing();
