#!/bin/bash

if [ -z $2 ]; then
	TESTID="ti$(date +%s)"
else
	TESTID=$2
fi

for i in `seq 1 $1`; do
                logger "$TESTID tmsg$i"
		#/rsyslog2/usleep 500
done

