#!/bin/sh

rreturn() {
	RET=$1
	MSG=$2
	if [ $RET -eq 0 ]; then
		echo "RESULT: OK $MSG"
		exit 0
	else
		echo "RESULT: FAILED $MSG"
		exit 1
	fi

	echo "RESULT: FAILED THIS SHOULD NOT HAPPEN $0 $@"
	exit 1
}

count() {
	TIMER=$1
	while [ $TIMER -gt 0 ]; do
        	echo -n $TIMER;
	        sleep 1
	        echo -n $'\b\b\b';
		TIMER=$(($TIMER-1))
	done
	echo "INFO: counter finished"
}
