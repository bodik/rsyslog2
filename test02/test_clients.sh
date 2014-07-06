#!/bin/bash

#BASE="/afs/zcu.cz/users/b/bodik/public/meta/rsyslog/test01"
#usage: aklog;sh /afs/zcu.cz/users/b/bodik/public/meta/rsyslog/test_clean_logs.sh; aklog; sh /afs/zcu.cz/users/b/bodik/public/meta/rsyslog/test_clients.sh

LEN=4
TESTID="ti$(date +%s)"
VMLIST=$(/puppet/jenkins/metacloud.init list | grep "RC-" |awk '{print $4}')
if [ -z $1 ]; then
    DISRUPT="restart"
else
    DISRUPT=$1
fi

if [ -z $2 ]; then
    ROUND=0
else
    ROUND=$2
fi


count() {
	TIMER=$1
	for all in `seq -w 0 $TIMER`; do
        	echo -n $all;
	        sleep 1
	        echo -n $'\b\b\b';
	done
}

################# MAIN

# ZALOZENI TESTU
for all in $VMLIST; do
	echo "INFO: client $all testi.sh init"
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "(sh /rsyslog2/test02/testi.sh $LEN $TESTID </dev/null 1>/dev/null 2>/dev/null) &"
done



# CEKANI NA DOTECENI VYSLEDKU
#nemusi to dotect vsechno, interval je lepsi prodlouzit, ale ted nechci cekat
#SL=230
#echo "INFO: waiting to sync for $SL secs"
#count $SL

for all in $VMLIST; do
	CLIENT=$( VMNAME=$all /puppet/jenkins/metacloud.init ssh 'facter ipaddress' )
	echo "INFO: client $all test_result.sh $LEN $TESTID $CLIENT"
	sh test_results_client.sh $LEN $TESTID $CLIENT
done

exit 0

# VYHODNOCENI TESTU
echo "INFO: test results"
find /var/log/hosts/`date +%Y` -mindepth 2 -type d -exec grep -rcH "logger: $TESTID tmsg[0-9]*" {} \; | grep -v ":0$" > /tmp/cache_teststats1
cat /tmp/cache_teststats1 | awk -F'/' '{printf("%s:", $0);system("host "$7"|rev |cut -d\" \" -f 1|rev|sed \"s/.$//\"");}' > /tmp/cache_teststats

#TODO: tohle by se melo asi prepsat na explicitni kontrolu poctu jednotlivych klientu a ne dopocitani kolik jich melo prijit
# asi by se to cele trosku narovnalo
awk -F':' -v LEN=$LEN -v CLIENTS=`cat 01test_hosts.txt | wc -l` -v DISRUPT=$DISRUPT -v ROUND=$ROUND '
BEGIN {
	TOTALMSGS=0
}
//{
        TOTALMSGS = TOTALMSGS + $2;

	PERC=$2/(LEN/100);
	if(PERC >= 99.99 && PERC <= 100 )
		RES="OK";
	else
		RES="FAIL";
	print "RESULT NODE:",DISRUPT,ROUND,RES,$1,$3,$2,PERC"%";
}
END {
	TESTLEN=LEN*CLIENTS;
	PERC=TOTALMSGS/(TESTLEN/100)
	if(PERC >= 99.99 && PERC <= 100 )
		RES="OK";
	else
		RES="FAIL";
	print "RESULT:",DISRUPT,ROUND,RES,TOTALMSGS,PERC"%";
}
' /tmp/cache_teststats



exit 0
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
/etc/init.d/rsyslog restart;
aklog ZCU.CZ;
echo "INFO: restart end";
)
;;

	manual)
(
sleep 10;
TIMER=120
echo "INFO: manual begin $TIMER";
count $TIMER
aklog ZCU.CZ;
echo "INFO: manual end $TIMER";
)
;;

esac
aklog ZCU.CZ


wait
echo "INFO: test finished"


