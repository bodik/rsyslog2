#!/bin/sh

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

if [ -z $CLOUD ]; then
    CLOUD="metacloud"
fi


################# MAIN

/puppet/jenkins/$CLOUD.init login
VMLIST=$(/puppet/jenkins/$CLOUD.init list | grep "RC-" |awk '{print $4}')

# ZALOZENI TESTU
VMCOUNT=0
for all in $VMLIST; do
	echo "INFO: client $all config"
	VMNAME=$all /puppet/jenkins/$CLOUD.init ssh "(cat /etc/rsyslog.d/meta-remote.conf)" | awk -v VMNAME=$all '//{ print VMNAME,$0}'
	VMCOUNT=$(($VMCOUNT+1))
done

#reconnect all clients
/puppet/jenkins/$CLOUD.init sshs '/etc/init.d/rsyslog stop'
/puppet/jenkins/$CLOUD.init sshs '/etc/init.d/rsyslog start'
for all in $VMLIST; do
	echo "INFO: client $all restart"
	VMNAME=$all /puppet/jenkins/$CLOUD.init ssh "/etc/init.d/rsyslog restart"
done
CONNS=$(/puppet/jenkins/$CLOUD.init sshs 'netstat -nlpa | grep rsyslog | grep ESTA | awk "{print \$4}" | grep "51[456]" | wc -l' | head -n1)
if [ $CONNS -ne $VMCOUNT ]; then
	rreturn 1 "$0 missing clients on startup"
fi





for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all /puppet/jenkins/$CLOUD.init ssh "(sh /rsyslog2/test02/testi.sh $LEN $TESTID </dev/null 1>/dev/null 2>/dev/null)" &
done



# VYNUCOVANI CHYB
WAITRECOVERY=60

case $DISRUPT in
	tcpkill)
(
sleep 10;
TIMER=120
echo "INFO: tcpkill begin $TIMER";
/puppet/jenkins/$CLOUD.init sshs "cd /rsyslog2/test02;
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
/puppet/jenkins/$CLOUD.init sshs '/etc/init.d/rsyslog restart'
echo "INFO: restart end";
)
WAITRECOVERY=230
;;
	killserver)
(
sleep 10; 
echo "INFO: killserver begin";
/puppet/jenkins/$CLOUD.init sshs 'kill -9 `pidof rsyslogd`'
/puppet/jenkins/$CLOUD.init sshs '/etc/init.d/rsyslog restart'
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
	CLIENT=$( VMNAME=$all /puppet/jenkins/$CLOUD.init ssh 'facter ipaddress' |grep -v "RESULT")
	/puppet/jenkins/$CLOUD.init sshs "sh /rsyslog2/test02/results_client.sh $LEN $TESTID $CLIENT" | grep "RESULT TEST NODE:" | tee -a /tmp/test_results.$TESTID.log
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

