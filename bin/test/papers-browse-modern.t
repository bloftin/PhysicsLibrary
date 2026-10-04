use strict;
use warnings;

use Test::More;

sub slurp {
	my $path = shift;
	open(my $fh, '<', $path) or die "Cannot read $path: $!";
	local $/;
	return <$fh>;
}

my $generic = slurp('lib/Noosphere/GenericObject.pm');
my $list = slurp('stemplates/paperslist.tt');

like($generic, qr/\$params->\{op\} = 'listobj';\s*return listGeneric\(\$params, \$userinf\)/,
	'Papers landing delegates to the browse and search route');
like($generic, qr/from\} eq 'papers' \? 'paperslist\.tt' :/,
	'Papers use a dedicated list template');
like($generic, qr/genericListWhereSql\(\$search\)/,
	'Papers retain the generic search query behavior');
like($generic, qr/genericListSortOptions\(\)/,
	'Papers retain the generic sort options');
like($generic, qr/getPager\(\$params, \$userinf, \$factor\)/,
	'Papers retain pagination');

like($list, qr/name="from" value="papers"/,
	'Papers landing page search targets the papers collection');
like($list, qr/Browse and search/,
	'Papers landing page exposes browsing');
like($list, qr/Latest additions/,
	'Papers landing page exposes recent papers');
like($list, qr/Add Paper/,
	'Papers landing page keeps the add-paper action');

like($list, qr/INCLUDE modernboxheader\.tt title = 'Search Papers'/,
	'Papers list provides a search heading');
like($list, qr/name="q" value="\[% search \| html %\]"/,
	'Papers list preserves the search query');
like($list, qr/name="sort"/,
	'Papers list exposes sorting');
like($list, qr/name="group"/,
	'Papers list exposes grouping');
like($list, qr/\[% pager %\]/,
	'Papers list renders pagination');
like($list, qr/\[% object\.authors \| html %\]/,
	'Papers list renders authors safely');
like($list, qr/No papers match these filters\./,
	'Papers list provides an empty state');

done_testing();
