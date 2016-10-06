#!/bin/sh

if [ -z $1 ]; then
	echo "ERROR: no client"
	exit 1
fi
CLIENT=$1


for all in $(find /var/log/hosts/$(date +%Y)/ -type f ! -name "*7z" | sort -r | head -72); do 
	LAST=$(tac $all | awk '{print $1,$2,$3,$4}' | grep -m1 " $CLIENT ")
	if [ $? -eq 0 ]; then
		break
	fi
done
if [ -z "$LAST" ]; then
	LAST="1971-01-01T01:01:01.01010101+01:00"
fi

LAST_TIMESTAMP=$(date --date="$(echo $LAST | awk '{print $1}')" +%s)
HORIZONT=$(( $(date +%s) - $((3600*24*2)) ))
if [ $LAST_TIMESTAMP -le $HORIZONT ]; then
	echo -n "ERROR: lost $CLIENT "
else
	echo -n "INFO: ok $CLIENT "
fi
echo $LAST


