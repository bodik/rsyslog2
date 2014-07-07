#!/bin/bash

set -e

. /puppet/tests/lib.sh

TESTID="ti$(date +%s)"

if [ -z $1 ]; then
    LEN=4
else
    LEN=$1
fi

if [ -z $2 ]; then
    DISRUPT="none"
else
    DISRUPT=$2
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
	echo "INFO: counter finished"
}

################# MAIN

/puppet/jenkins/metacloud.init login
VMLIST=$(/puppet/jenkins/metacloud.init list | grep "RC-" |awk '{print $4}')

# ZALOZENI TESTU
VMCOUNT=0
for all in $VMLIST; do
	echo "INFO: client $all config"
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "(cat /etc/rsyslog.d/meta-remote.conf)" > /tmp/tconf.$$
	cat /tmp/tconf.$$ | VMNAME=$all sed "s/^/$VMNAME /"
	rm /tmp/tconf.$$
	VMCOUNT=$(($VMCOUNT+1))
done


for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "(sh /rsyslog2/test02/testi.sh $LEN $TESTID </dev/null 1>/dev/null 2>/dev/null)" &
done



# VYNUCOVANI CHYB
WAITRECOVERY=60

case $DISRUPT in
	tcpkill)
(
sleep 10;
TIMER=120
echo "INFO: tcpkill begin $TIMER";
/puppet/jenkins/metacloud.init sshs "cd /rsyslog2/test02;
./tcpkill -i eth0 port 515 or port 514 or port 516 2>/dev/null &
PPP=\$!; 
sleep $TIMER;
kill \$PPP;
"
echo "INFO: tcpkill end $TIMER";
)
WAITRECOVERY=230
;;
	restart)
(
sleep 10; 
echo "INFO: restart begin";
/puppet/jenkins/metacloud.init sshs '/etc/init.d/rsyslog restart'
echo "INFO: restart end";
)
WAITRECOVERY=230
;;
	killserver)
(
sleep 10; 
echo "INFO: killserver begin";
/puppet/jenkins/metacloud.init sshs 'kill -9 `pidof rsyslogd`'
/puppet/jenkins/metacloud.init sshs '/etc/init.d/rsyslog restart'
echo "INFO: killserver end";
)
WAITRECOVERY=230
;;

	manual)
(
sleep 10;
TIMER=120
echo "INFO: manual begin $TIMER";
count $TIMER
echo "INFO: manual end $TIMER";
)
WAITRECOVERY=230
;;

esac

echo "INFO: waiting for clients to finish"
wait
echo "INFO: test finished"






# CEKANI NA DOTECENI VYSLEDKU
#nemusi to dotect vsechno, interval je lepsi prodlouzit, ale ted nechci cekat
echo "INFO: waiting to sync for $WAITRECOVERY secs"
count $WAITRECOVERY





# VYHODNOCENI VYSLEDKU
for all in $VMLIST; do
	CLIENT=$( VMNAME=$all /puppet/jenkins/metacloud.init ssh 'facter ipaddress' |grep -v "RESULT")
	/puppet/jenkins/metacloud.init sshs "sh /rsyslog2/test02/test_results_client.sh $LEN $TESTID $CLIENT" | grep "RESULT TEST NODE:" | tee -a /tmp/test_results.$TESTID.log
done
echo =============

awk -v LEN=$LEN -v VMCOUNT=$VMCOUNT -v TESTID=$TESTID -v DISRUPT=$DISRUPT ' 
BEGIN {
	DELIVERED=0;
	DELIVEREDUNIQ=0;
	TOTALLEN=LEN*VMCOUNT;
}
//{
	DELIVERED = DELIVERED + $10;
	DELIVEREDUNIQ = DELIVEREDUNIQ + $14;
}
END {
	PERC=DELIVERED/(TOTALLEN/100);
	PERCUNIQ=DELIVEREDUNIQ/(TOTALLEN/100);
	if(PERCUNIQ >= 99.99 && PERCUNIQ <= 100 ) {
		RES="OK";
		RET=0;
	} else {
		RES="FAILED";
		RET=1;
	}
	print "RESULT TEST FINAL:",RES,TESTID,"disrupt",DISRUPT,"totallen",TOTALLEN,"deliv",DELIVERED,"rate",PERC"%","delivuniq",DELIVEREDUNIQ,"rateuniq",PERCUNIQ"%";
	exit RET
}' /tmp/test_results.$TESTID.log
RET=$?

rm /tmp/test_results.$TESTID.log

rreturn $RET "$0"

