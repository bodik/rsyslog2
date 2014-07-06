#!/bin/bash

set -e

. /puppet/tests/lib.sh

LEN=4
TESTID="ti$(date +%s)"
if [ -z $1 ]; then
    DISRUPT="none"
else
    DISRUPT=$1
fi

#if [ -z $2 ]; then
#    ROUND=0
#else
#    ROUND=$2
#fi


count() {
	TIMER=$1
	while [ $TIMER -gt 0 ]; do
        	echo -n $TIMER;
	        sleep 1
	        echo -n $'\b\b\b';
		TIMER=$(($TIMER-1))
	done
}

################# MAIN

/puppet/jenkins/metacloud.init login
VMLIST=$(/puppet/jenkins/metacloud.init list | grep "RC-" |awk '{print $4}')

# ZALOZENI TESTU
VMCOUNT=0
for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "(sh /rsyslog2/test02/testi_logclean.sh)"
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "(sh /rsyslog2/test02/testi.sh $LEN $TESTID </dev/null 1>/dev/null 2>/dev/null)" &
	VMCOUNT=$(($VMCOUNT+1))
done



# VYNUCOVANI CHYB
case $DISRUPT in
	kill)
(
sleep 10;
TIMER=120
echo "INFO: killing begin $TIMER";
./tcpkill -i eth0 port 515 or port 514 2>/dev/null &
PPP=$!; 
count $TIMER
kill $PPP;
echo "INFO: killing end $TIMER";
)
;;
	restart)
(
sleep 10; 
echo "INFO: restart begin";
/puppet/jenkins/metacloud.init sshs '/etc/init.d/rsyslog restart'
echo "INFO: restart end";
)
;;

	manual)
(
sleep 10;
TIMER=120
echo "INFO: manual begin $TIMER";
count $TIMER
echo "INFO: manual end $TIMER";
)
;;

esac

wait
echo "INFO: test finished"




# CEKANI NA DOTECENI VYSLEDKU
#nemusi to dotect vsechno, interval je lepsi prodlouzit, ale ted nechci cekat
SL=90
echo "INFO: waiting to sync for $SL secs"
count $SL


for all in $VMLIST; do
	CLIENT=$( VMNAME=$all /puppet/jenkins/metacloud.init ssh 'facter ipaddress' |grep -v "RESULT")
	/puppet/jenkins/metacloud.init sshs "sh /rsyslog2/test02/test_results_client.sh $LEN $TESTID $CLIENT" | grep "RESULT TEST NODE:" | tee -a /tmp/test_results.$TESTID.log
done
echo =============

awk -v LEN=$LEN -v VMCOUNT=$VMCOUNT -v TESTID=$TESTID -v DISRUPT=$DISRUPT ' 
BEGIN {
	DELIVERED=0;
	TOTALLEN=LEN*VMCOUNT;
}
//{
	DELIVERED = DELIVERED + $10;
	print $0
	print $10
}
END {
	PERC=DELIVERED/(TOTALLEN/100);
	if(PERC >= 99.99 && PERC <= 100 ) {
		RES="OK";
		RET=0;
	} else {
		RES="FAILED";
		RET=1;
	}
	print "RESULT TEST FINAL:",RES,TESTID,"disrupt",DISRUPT,"totallen",TOTALLEN,"deliv",DELIVERED,"rate",PERC"%";
	exit RET
}' /tmp/test_results.$TESTID.log
RET=$?

rm /tmp/test_results.$TESTID.log

rreturn $RET "$0"

