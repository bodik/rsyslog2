#!/bin/sh

. /puppet/tests/lib.sh

/usr/lib/nagios/plugins/check_procs -C rsyslogd -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd check_procs"
fi

netstat -nlpa | grep "$(pidof rsyslogd)/rsy" | grep ESTA | grep :514
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd tcp shipper"
fi

rreturn 0 "$0"
