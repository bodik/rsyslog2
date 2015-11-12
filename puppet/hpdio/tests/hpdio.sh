#!/bin/sh

. /puppet/metalib/bin/lib.sh


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
	
rreturn 0 "$0"


