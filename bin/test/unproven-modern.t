use strict;
use warnings;
use Test::More;
use File::Spec;

my $root = File::Spec->catdir(File::Spec->curdir());
my $stats_path = File::Spec->catfile($root, 'lib', 'Noosphere', 'Stats.pm');
my $template_path = File::Spec->catfile($root, 'stemplates', 'unproven.tt');

open my $stats_fh, '<', $stats_path or die "Cannot read $stats_path: $!";
my $stats = do { local $/; <$stats_fh> };
close $stats_fh;

open my $template_fh, '<', $template_path or die "Cannot read $template_path: $!";
my $template = do { local $/; <$template_fh> };
close $template_fh;

like($stats, qr/sub unprovenTheorems.*?Template->new/s, 'unproven theorem page uses a dedicated presentation template');
like($stats, qr/process\('unproven\.tt'/, 'unproven theorem page renders the dedicated template');
like($stats, qr/mathTitle\(\$row->\{'title'\}, 'highlight'\)/, 'theorem titles retain math rendering');
like($stats, qr/op=adden.*?type=Proof/s, 'proof creation route remains available');
like($stats, qr/getPager\(\$params, \$userinf, 1\)/, 'existing paging behavior is retained');
like($stats, qr/getUnprovenTheorems\(\)/, 'existing unproven-theorem selection is retained');
like($template, qr/<h1>Unproven Theorems<\/h1>/, 'template provides the page heading');
like($template, qr/awaiting a proof/, 'template explains the queue');
like($template, qr/\[% pager %\]/, 'template displays pagination');
like($template, qr/Write proof<\/a>/, 'template exposes proof contribution action');
like($template, qr/Every theorem in the collection currently has a proof/, 'template retains the empty state');

SKIP: {
	skip 'Template Toolkit is not installed in this environment', 4 unless eval { require Template; 1 };
	my $tt = Template->new({ INCLUDE_PATH => File::Spec->catdir($root, 'stemplates') });
	my $html = '';
	ok($tt->process('unproven.tt', {
		total => 1,
		pager => '',
		theorems => [{
			ord => 1,
			title => 'Representative theorem',
			object_url => '/?op=getobj&amp;from=objects&amp;id=1',
			proof_url => '/?op=adden&amp;request=1&amp;type=Proof',
		}],
	}, \$html), 'template renders representative theorem rows') or diag($tt->error());
	like($html, qr/Representative theorem/, 'rendered output includes theorem row');
	like($html, qr/View theorem/, 'rendered output includes theorem view action');
	like($html, qr/Write proof/, 'rendered output includes proof contribution control');
}

done_testing();
