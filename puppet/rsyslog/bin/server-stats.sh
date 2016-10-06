#!/bin/bash

echo "-- BEGIN server --"
uptime
df -h /db
echo "-- END server --"

echo "-- BEGIN stats --"
pbsnodes > /tmp/rsyslog-stats.pbsnodes
cat /tmp/rsyslog-stats.pbsnodes | grep "^[a-zA-Z]" | sort | uniq > /tmp/rsyslog-stats.hosts
netstat -nlpa | grep ESTABLISHED | grep $(facter ipaddress):515 | awk '{print $5}' | sed 's/:.*//' > /tmp/rsyslog-stats.esta
TOT=`cat /tmp/rsyslog-stats.hosts | wc -l`
OFFLINE=`cat /tmp/rsyslog-stats.pbsnodes | grep "state =" | sort | uniq -c | egrep "(offline|down)" | awk 'BEGIN{I=0}//{I=I+$1}END{print I}'`
ONLINE=$(($TOT-$OFFLINE))
ESTA=`cat /tmp/rsyslog-stats.esta | wc -l`
NODES=`sort /tmp/rsyslog-stats.esta | uniq | wc -l`

echo -n "Total PBS nodes:        "; echo $TOT
echo -n "Online PBS nodes:        "; echo $ONLINE
echo -n "Established conns:      "; echo $ESTA
echo -n "Connected nodes:        "; echo $NODES
echo -n "Servers online A [%]:     "; echo "$NODES / ($TOT/100)" | bc -l
echo -n "Servers online B [%]:     "; echo "$NODES / ($ONLINE/100)" | bc -l
echo "-- END stats --"


echo "-- BEGIN more conns --"
cat /tmp/rsyslog-stats.esta | sort | uniq -c | grep -v "\ *1 "
echo "-- END more conns --"


echo "-- BEGIN cluster stats --"
cat /tmp/rsyslog-stats.hosts | sed 's/[0-9\.\-]\+.*//' | sort | uniq -c | sed 's/ \([a-zA-Z]\)/,\1/'  > /tmp/rsyslog-stats.clustercount
for all in `sort /tmp/rsyslog-stats.esta | uniq`; do
	host $all | rev | awk '{print $1}' | rev
done | sed 's/[0-9\.\-]\+.*//' | sort | uniq -c | sed 's/\.$//' > /tmp/rsyslog-stats.hostsonline

printf "%20s %10s %10s\n" Cluster Total Online
for all in `cat /tmp/rsyslog-stats.clustercount`; do
	CLUSTER=`echo $all | awk -F',' '{print $2}'`
	NODES=`echo $all | awk -F',' '{print $1}'`
	ONLINE=`grep "${CLUSTER}$" /tmp/rsyslog-stats.hostsonline | awk '{print $1}'`
	printf "%20s %10s %10s\n" $CLUSTER $NODES $ONLINE
done
echo "-- END cluster stats --"


echo "-- BEGIN lost contact --"
/puppet/rsyslog/bin/server-lostcontact.sh
echo "-- END lost contact --"


echo "-- BEGIN talkers today --"
find /var/log/hosts/$(date +%Y/%m/%d/) -type f -exec cat {} \; | awk '{print $3}' | sort | uniq -c | sort -n > /tmp/rsyslog-stats.talkers
echo -n "most:  "; cat /tmp/rsyslog-stats.talkers | tail -5 | head -5
echo -n "few:   "; cat /tmp/rsyslog-stats.talkers | head -1
echo -n "total: "; du -sh /var/log/hosts/`date +%Y/%m/%d/`
echo "-- END talkers today --"

