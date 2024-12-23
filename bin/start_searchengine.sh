#!/bin/bash

# (re)start the search engine. indexes from database every time.  this
# should be deprecated when the search engine utilizes a swapped image of
# the index.
#
kill -TERM `cat /var/www/pp/noosphere/bin/run/essexd.pid` > /dev/null 2>&1

cd /var/www/pp/noosphere/essex/essex_2004-01-05/server

./essexd -f /var/www/pp/noosphere/etc/essex.conf

echo "indexing"

/var/www/pp/noosphere/bin/ir_index.pl

