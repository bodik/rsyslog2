#!/bin/sh

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs -C rsyslogd -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd check_procs"
fi

RCAGE=$(ps h -o etimes $(pgrep -f rsyslogd))
if [ $RCAGE -lt 60 ] ; then
	echo "INFO: rsyslog-client warming up"
	sleep 60
fi

netstat -nlpa | grep "$(pidof rsyslogd)/rsy" | grep ESTA | grep :51[456]
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd shipper"
fi

rreturn 0 "$0"
