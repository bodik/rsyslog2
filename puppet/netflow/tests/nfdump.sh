#!/bin/sh

. /puppet/metalib/lib.sh

#sw emitor
/usr/lib/nagios/plugins/check_procs -C pmacctd -c 2:2
if [ $? -ne 0 ]; then
	rreturn 1 "$0 pmacctd check_procs"
fi

#collector
/usr/lib/nagios/plugins/check_procs -C nfcapd
if [ $? -ne 0 ]; then
	rreturn 1 "$0 nfcapd check_procs"
fi

if [ ! -f /var/cache/nfdump/nfcapd.current ]; then
	rreturn 1 "$0 nfcapd output missing"
fi
