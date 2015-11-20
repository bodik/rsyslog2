#!/bin/sh

. /puppet/metalib/bin/lib.sh

AGE=$(ps h -o etimes $(pgrep -f /opt/dionaea/bin/dionaea) | head -n1)
if [ $AGE -lt 30 ] ; then
	echo "INFO: dio warming up"
	sleep 30
fi

for PORT in 3306 21 445; do 
	netstat -nlpa | grep "/dionaea" | grep LISTEN | grep :$PORT
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 dionaea $PORT listener"
	fi
done

netstat -nlpa | grep "/dionaea" | grep "^udp.*:69 "
if [ $? -ne 0 ]; then
	rreturn 1 "$0 dionaea 69 listener"
fi

netstat -nlpa | grep "/dionaea" | grep "^udp.*:5060 "
if [ $? -ne 0 ]; then
	rreturn 1 "$0 dionaea 5060 listener"
fi



ls -l /opt/dionaea/var/dionaea/logsql.sqlite
if [ $? -ne 0 ]; then
        rreturn 1 "$0 dionaea logdb not created"
fi

printf "USER autotest\nPASS autotest\nautotest command" | nc -q1 $(facter fqdn) 21 | grep "230 User logged in"
if [ $? -ne 0 ]; then
        rreturn 1 "$0 dionaea ftp pot not working"
fi

	
rreturn 0 "$0"


