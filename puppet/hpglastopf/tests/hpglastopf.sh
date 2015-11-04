#!/bin/sh

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array=/usr/local/bin/glastopf-runner -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /usr/local/bin/glastopf-runner check_procs"
fi

GAGE=$(ps h -o etimes $(pgrep -f /usr/local/bin/glastopf-runner))
if [ $GAGE -lt 60 ] ; then
	echo "INFO: glastopf-runner warming up"
	sleep 60
fi

if [ ! -f /opt/glastopf/db/glastopf.db ]; then
	rreturn 1 "$0 glastopf-runner output database not created"
fi

NOW=$(date +%s)
wget -O /dev/null -q "http://localhost/autotest_message_$NOW"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 glastopf-runner webserver unavailable"
fi

sleep 1
grep "autotest_message_$NOW" /var/log/syslog 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 glastopf-runner not logging properly"
fi


