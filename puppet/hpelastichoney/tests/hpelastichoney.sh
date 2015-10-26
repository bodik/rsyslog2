#!/bin/sh

. /puppet/metalib/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array=/opt/elastichoney/elastichoney -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 elastichoney check_procs"
fi

AGE=$(ps h -o etimes $(pgrep -f /opt/elastichoney/elastichoney))
if [ $AGE -lt 10 ] ; then
	echo "INFO: elastichoney warming up"
	sleep 10
fi

NOW=$(date +%s)
wget -O /dev/null -q "http://$(facter ipaddress):9200/_search?autotest_message_$NOW"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 elastichoney webserver unavailable"
fi

sleep 1
grep "autotest_message_$NOW" /opt/elastichoney/elastichoney.log 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 elastichoney not logging properly"
fi

rreturn 0 "$0 hpelastichoney ok"
