#!/bin/sh

. /puppet/metalib/lib.sh

/usr/lib/nagios/plugins/check_procs -C fprobe -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 fprobe check_procs"
fi
