#!/bin/sh

. /puppet/metalib/bin/lib.sh

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

DELIVERED=$(find /var/log/ -type f -name "syslog" -exec grep -r "logger: $TESTID tmsg" {} \; | wc -l | awk '{print $1}')
DELIVEREDUNIQ=$(find /var/log/ -type f -name "syslog" -exec grep -r "logger: $TESTID tmsg" {} \; | rev | awk '{print $1}' | sort | uniq | wc -l | awk '{print $1}')
if [ -z "$DELIVERED" ]; then
	DELIVERED=0
fi

if [ -z "$DELIVEREDUNIQ" ]; then
	DELIVEREDUNIQ=0
fi

#ano muze dojit az ke 101% kvuli opakovanemu prenaseni zprave
awk -F':' -v LEN=$LEN -v DELIVEREDUNIQ=$DELIVEREDUNIQ -v DELIVERED=$DELIVERED -v CLIENT=$CLIENT -v TESTID=$TESTID '
BEGIN {
	PERC=DELIVERED/(LEN/100);
	PERCUNIQ=DELIVEREDUNIQ/(LEN/100);
	if(PERCUNIQ >= 99.9 && PERCUNIQ <= 101 )
		RES="OK";
	else
		RES="FAILED";
	print "RESULT TEST NODE:",RES,TESTID,CLIENT,"len",LEN,"deliv",DELIVERED,"rate",PERC"%","delivuniq",DELIVEREDUNIQ,"rateuniq",PERCUNIQ"%";
}'
