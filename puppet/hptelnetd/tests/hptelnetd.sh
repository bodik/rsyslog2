#!/bin/sh

. /puppet/metalib/bin/lib.sh

python -c 'print "autotest\nautotest\nroot\ntoor\nid\nexit"' | timeout 2s nc $(facter ipaddress) $(facter telnetd_port) | grep 'uid=0'
if [ $? -ne 0 ]; then
        rreturn 1 "$0 failed to login to hptelnetd"
fi 

rreturn 0 "$0"
