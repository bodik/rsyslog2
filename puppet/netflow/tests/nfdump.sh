#!/bin/sh

. /puppet/metalib/lib.sh

#sw collector
/usr/lib/nagios/plugins/check_procs -C fprobe -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 fprobe check_procs"
fi


/usr/lib/nagios/plugins/check_procs -C nfcapd
if [ $? -ne 0 ]; then
	rreturn 1 "$0 nfcapd check_procs"
fi

if [ ! -f /var/cache/nfdump/nfcapd.current ]; then
	rreturn 1 "$0 nfcapd output missing"
fi
