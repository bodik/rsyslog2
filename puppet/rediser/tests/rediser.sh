#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array=redis-server -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 redis-server check_procs"
fi

redis-cli -p 16379 script load "return 1"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 redis-server version not sufficient"
fi


echo "rpush test_rediser.sh test_rediser.sh-$$" | redis-cli -p 16379 1>/dev/null
echo "lpop test_rediser.sh" | redis-cli -p 16379 | grep "test_rediser.sh-$$" 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 redis-server rpush/lpop failed"
fi

/usr/lib/nagios/plugins/check_procs --argument-array=rediser-syslog-filter -c 1:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rediser check_procs"
fi

netstat -nlpa | grep "/ncat " | grep LISTEN | grep :49558
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rediser listener"
fi

SERVICE=_rediser._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress)
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _rediser._tcp not found"
fi


rreturn 0 "$0"
