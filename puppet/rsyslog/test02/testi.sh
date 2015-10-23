#!/bin/bash

set -e

if [ -z $2 ]; then
	TESTID="ti$(date +%s)"
else
	TESTID=$2
fi

I=0
while [ $I -lt $1 ]; do
        logger -t logger "$TESTID tmsg$I"
	#/rsyslog2/usleep 500
	I=$(($I+1))
done

