#!/bin/sh

set -e

. /puppet/metalib/bin/lib.sh

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

/puppet/jenkins/bin/$CLOUD.init login
VMLIST=$(/puppet/jenkins/bin/$CLOUD.init list | grep "RC-" |awk '{print $4}')

# ZALOZENI TESTU
VMCOUNT=0
for all in $VMLIST; do
	echo "INFO: client $all config"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "(cat /etc/rsyslog.d/meta-remote.conf)" | awk -v VMNAME=$all '//{ print VMNAME,$0}'
	VMCOUNT=$(($VMCOUNT+1))
done

echo "INFO: VMCOUNT $VMCOUNT"

#reconnect all clients
/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog stop'
/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog start'
for all in $VMLIST; do
	echo "INFO: client $all restart"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "service rsyslog restart"
done
sleep 10
CONNS=$(/puppet/jenkins/bin/$CLOUD.init sshs 'netstat -nlpa | grep rsyslog | grep ESTA | awk "{print \$4}" | grep "51[456]" | wc -l' | head -n1)
if [ $CONNS -ne $VMCOUNT ]; then
	rreturn 1 "$0 missing clients on startup"
fi





for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "(sh /puppet/rsyslog/test02/testi.sh $LEN $TESTID </dev/null 1>/dev/null 2>/dev/null)" &
done



# VYNUCOVANI CHYB
WAITRECOVERY=60

case $DISRUPT in


	tcpkill)
(
sleep 10;
TIMER=240
echo "INFO: tcpkill begin $TIMER";
/puppet/jenkins/bin/$CLOUD.init sshs "cd /puppet/rsyslog/test02;
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
/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog restart'
echo "INFO: restart end";
)
WAITRECOVERY=230
;;


	killserver)
(
sleep 10; 
echo "INFO: killserver begin";
/puppet/jenkins/bin/$CLOUD.init sshs 'kill -9 `pidof rsyslogd`'
/puppet/jenkins/bin/$CLOUD.init sshs 'service rsyslog restart'
echo "INFO: killserver end";
)
WAITRECOVERY=230
;;


	ipdrop)
(
sleep 10;
TIMER=240
echo "INFO: ipdrop begin $TIMER";
/puppet/jenkins/bin/$CLOUD.init sshs "cd /puppet/rsyslog/test02;
/puppet/jenkins/bin/$CLOUD.init sshs 'iptables -I INPUT -m multiport -p tcp --dport 514,515,516 -j DROP'
sleep $TIMER;
/puppet/jenkins/bin/$CLOUD.init sshs 'iptables -D INPUT -m multiport -p tcp --dport 514,515,516 -j DROP'
"
echo "INFO: ipdrop end $TIMER";
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
	CLIENT=$( VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh 'facter ipaddress' |grep -v "RESULT")
	/puppet/jenkins/bin/$CLOUD.init sshs "sh /puppet/rsyslog/test02/results_client.sh $LEN $TESTID $CLIENT" | grep "RESULT TEST NODE:" | tee -a /tmp/test_results.$TESTID.log
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
	if(PERCUNIQ >= 99.9 && PERCUNIQ <= 100 ) {
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

