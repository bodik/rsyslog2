#!/bin/sh

. /puppet/metalib/bin/lib.sh

python -c 'print "autotest\nautotest.123456\nid\nexit"' | timeout 2s nc $(facter ipaddress) 63023 | grep 'uid=0'

if [ $? -ne 0 ]; then
        rreturn 2 "$0 failed to login to hptelnetd"
fi 

rreturn 0 "$0"
