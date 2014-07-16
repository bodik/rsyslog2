#!/bin/sh

if [ -z $1 ]; then
	echo "ERROR: no service specified"
	exit 1
fi

avahi-browse -t $1 --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1 | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//'
