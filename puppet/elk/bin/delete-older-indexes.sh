#!/bin/bash
# deletes indexes older int()
#
# cronline
# 0 1 * * * /bin/sh /puppet/elk/bin/delete-older-indexes.sh 14

if [ -z $1 ]; then
	echo "ERROR: no horizont specified"
	exit 1
fi
TODAY=$(date +"%s")
HORIZONT=$(( $TODAY - 3600*24*$1 ))
ESD=$(netstat -nlpa | grep LISTEN | grep :39200 | head -1 | awk '{print $4}')

for all in $(sh $(dirname $0)/listindexes.sh | grep logstash | awk '{print $3}'); do
	TMP=$(date -d $(echo $all | sed 's/logstash\-//' | sed 's/\./\-/g') +"%s")
	if [ $TMP -lt $HORIZONT ]; then
		#echo "$all to be deleted"
		curl --silent -XDELETE "http://${ESD}:39200/${all}"
	fi
done
