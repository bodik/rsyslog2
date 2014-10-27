#!/bin/sh

. /puppet/metalib/lib.sh

/usr/lib/nagios/plugins/check_procs -C mongod  -c 5:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 some mongod process missing"
fi

/usr/lib/nagios/plugins/check_procs -C mongos  -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 mongos not running"
fi



/usr/lib/nagios/plugins/check_procs -C apache2  -c 2:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache2 not running"
fi

wget "http://localhost/rsyslogweb/stats" -O - | grep table_mapRemoteResult 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogweb not available"
fi

wget "http://localhost/rock/index.php?action=server.status" -O - | grep uptimeEstimate 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rock not available"
fi





#TODO: TOTO BY SE MELO PRESTEHOVAT AZ SE ROZTRHNE ES A LOGSTASH
/usr/lib/nagios/plugins/check_procs --argument-array=/opt/logstash/lib/logstash/runner.rb -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /opt/logstash/lib/logstash/runner.rb check_procs"
fi

LSLAGE=$(ps h -o etimes $(pgrep -f /opt/logstash/lib/logstash/runner.rb))
if [ $LSLAGE -lt 60 ] ; then
	echo "INFO: LSL warming up"
	sleep 60
fi

netstat -nlpa | grep " $(pgrep -f /opt/logstash/lib/logstash/runner.rb)/java" | egrep "(LISTEN|ESTABLISHED)"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /opt/logstash/lib/logstash/runner.rb not connected anywhere"
fi






