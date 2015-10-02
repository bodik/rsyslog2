#!/bin/sh

set -e

. /puppet/metalib/lib.sh

TESTID="ti$(date +%s)"

if [ -z $1 ]; then
    LEN=4000
else
    LEN=$1
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






#fill client local disk
for all in $VMLIST; do
	echo "INFO: client $all init disk filling"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "(time dd if=/dev/zero of=/vyplndisku bs=8M)" &
done
echo "INFO: waiting for clients to finish disk filling"
wait

#run the test
for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "(sh /rsyslog2/test02/testi.sh $LEN $TESTID </dev/null 1>/dev/null 2>/dev/null)" &
done
echo "INFO: waiting for clients to finish testi"
wait

# cleanup
for all in $VMLIST; do
	echo "INFO: client $all disk full cleanup"
	VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh "(rm /vyplndisku)"
done







# VYHODNOCENI VYSLEDKU
for all in $VMLIST; do
CLIENT=$( VMNAME=$all /puppet/jenkins/bin/$CLOUD.init ssh 'facter ipaddress' |grep -v "RESULT")
/puppet/jenkins/bin/$CLOUD.init sshs "sh /rsyslog2/test02/results_client.sh $LEN $TESTID $CLIENT" | grep "RESULT TEST NODE:" | tee -a /tmp/test_results.$TESTID.log
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


