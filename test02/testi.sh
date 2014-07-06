#!/bin/bash

if [ -z $2 ]; then
	TESTID="$(date +%s)"
else
	TESTID=$2
fi

for i in `seq 1 $1`; do
                logger "test$i $TESTID"
		#/rsyslog2/usleep 500
done

