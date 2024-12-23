#!/bin/bash

# 
# this script completely reloads the query spell-fixer daemon.
#

SPID=`cat /var/www/pp/noosphere/bin/run/spelld.pid`

kill -TERM $SPID
nohup /var/www/pp/noosphere/bin/spelld &
