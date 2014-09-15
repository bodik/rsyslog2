#!/bin/sh

if [ -z $1 ]; then
	echo "ERROR: no service specified"
	exit 1
fi

which avahi-browse 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	puppet apply --modulepath=/puppet -e 'include metalib::avahi' 1>/dev/null 2>/dev/null
fi

#avahi-browse -t $1 --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1 | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//'
IP=$(avahi-browse -t $1 --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)
if [ -z $IP ]; then
	exit 0
else
	host -t A $IP | rev | awk '{print $1}' | rev | sed 's/\.$//'	
	exit 1
fi
