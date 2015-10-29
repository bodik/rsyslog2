#!/bin/sh

. /puppet/metalib/bin/lib.sh

python -c 'print "root\ntoor\nid\nexit"' | timeout 2s nc $(facter ipaddress) 23 | grep 'uid=0'
if [ $? -ne 0 ]; then
        rreturn 1 "$0 failed to login to hptelnetd"
fi 

rreturn 0 "$0"
