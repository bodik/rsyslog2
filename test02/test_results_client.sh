#!/bin/sh

. /puppet/tests/lib.sh

if [ -z $1 ]; then
	rreturn 1 "$0 len missing"
else
	LEN=$1
fi
if [ -z $2 ]; then
	rreturn 1 "$0 testid missing"
else
	TESTID=$2
fi
if [ -z $3 ]; then
	rreturn 1 "$0 client missing"
else
	CLIENT=$3
fi

DELIVERED=$(find /var/log/hosts/`date +%Y/%m` -type f -path "*/$CLIENT/*" -name "syslog" -exec grep -rcH "logger: $TESTID tmsg[0-9]*" {} \; | awk -F":" '{print $2}')
#PERC=$(echo "scale=2; $DELIVERED/($LEN/100)" | bc -l)

awk -F':' -v LEN=$LEN -v DELIVERED=$DELIVERED -v CLIENT=$CLIENT -v TESTID=$TESTID '
BEGIN {
	PERC=DELIVERED/(LEN/100);
	if(PERC >= 99.99 && PERC <= 100 )
		RES="OK";
	else
		RES="FAIL";
	print "RESULT TEST NODE:",TESTID,CLIENT,RES,"len",LEN,"deliv",DELIVERED,"rate",PERC"%";
}'
