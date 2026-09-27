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
my $lobby = slurp('stemplates/paperslobby.tt');
my $list = slurp('stemplates/paperslist.tt');

like($generic, qr/from\} eq 'papers' \? 'paperslobby\.tt' : 'genericlobby\.tt'/,
	'Papers use a dedicated browse landing template');
like($generic, qr/from\} eq 'papers' \? 'paperslist\.tt' : 'genericlist\.tt'/,
	'Papers use a dedicated list template');
like($generic, qr/genericListWhereSql\(\$search\)/,
	'Papers retain the generic search query behavior');
like($generic, qr/genericListSortOptions\(\)/,
	'Papers retain the generic sort options');
like($generic, qr/getPager\(\$params, \$userinf, \$factor\)/,
	'Papers retain pagination');

like($lobby, qr/<h1>Physics Library Papers<\/h1>/,
	'Papers landing page provides a collection heading');
like($lobby, qr/name="from" value="papers"/,
	'Papers landing page search targets the papers collection');
like($lobby, qr/Browse and search papers/,
	'Papers landing page exposes browsing');
like($lobby, qr/Latest additions/,
	'Papers landing page exposes recent papers');
like($lobby, qr/Add Paper/,
	'Papers landing page keeps the add-paper action');

like($list, qr/<h1>Search Papers<\/h1>/,
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
