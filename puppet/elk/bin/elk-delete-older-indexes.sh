#!/bin/bash

if [ -z $1 ]; then
	echo "ERROR: no horizont specified"
	exit 1
fi
TODAY=$(date +"%s")
HORIZONT=$(( $TODAY - 3600*24*$1 ))
ESD=$(facter ipaddress_eth1 ipaddress_eth0 | sort -r | awk '{print $3}' | tr '\n' ' ' | awk '{print $1}')

for all in $(sh /puppet/elk/bin/elk-listindexes.sh | grep logstash | awk '{print $3}'); do
	TMP=$(date -d $(echo $all | sed 's/logstash\-//' | sed 's/\./\-/g') +"%s")
	if [ $TMP -lt $HORIZONT ]; then
		#echo "$all to be deleted"
		curl -XDELETE "http://${ESD}:39200/${all}"
	fi
done
