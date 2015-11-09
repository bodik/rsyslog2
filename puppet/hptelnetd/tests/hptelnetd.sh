#!/bin/sh

#. /puppet/metalib/lib.sh

netstat -vlanp | grep -E "0.0.0.0:23\s+"

if [ $? -ne 0 ]; then
        rreturn 1 "$0 failed to start telnetd"
fi      

python -c 'print "autotest\nautotest.123456\nid\nexit"' | timeout 2s nc $(facter ipaddress) 23 | grep 'uid=0'

if [ $? -ne 0 ]; then
        rreturn 2 "$0 failed to login to telnetd"
fi 

rreturn 0 "$0"
