#!/bin/bash

if [ -z $2 ]; then
	TESTID="ti$(date +%s)"
else
	TESTID=$2
fi

i=0
while [ $i -lt 10000000 ]; then 
        logger "$TESTID tmsg$i"
	#/rsyslog2/usleep 500
	I=$(($I+1))
done

