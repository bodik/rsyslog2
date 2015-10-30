#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array=org.elasticsearch.bootstrap.Elasticsearch -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 org.elasticsearch.bootstrap.Elasticsearch check_procs"
fi

ESDAGE=$(ps h -o etimes $(pgrep -f org.elasticsearch.bootstrap.Elasticsearch))
if [ $ESDAGE -lt 60 ] ; then
	echo "INFO: ESD warming up"
	sleep 60
fi

netstat -nlpa | grep " $(pgrep -f org.elasticsearch.bootstrap.Elasticsearch)/java" | grep LISTEN | grep ":39200"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 esd http listener"
fi

wget "http://$(facter fqdn):39200" -q -O /dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 esd http interface"
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






#TODO: TOTO BY SE MELO PRESTEHOVAT AZ SE ROZTRHNE ES A LOGSTASH
/usr/lib/nagios/plugins/check_procs -C apache2 -c 1:
if [ $? -ne 0 ]; then
	rreturn 1 "$0 apache/kibana not running"
fi

wget --no-check-certificate "https://$(facter fqdn)" -q -O - | grep "<title>Kibana 3" 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 kibana not found on webserver"
fi

wget --no-check-certificate "https://$(facter fqdn)/dash.html" -q -O - | grep "dashboard/file/logstashesb" 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 dashboard not found on webserver"
fi



echo "require 'elasticsearch'" | ruby
if [ $? -ne 0 ]; then
        rreturn 1 "$0 gem elasticsearch not installed"
fi


elasticdump --help | head -n1 | grep "elasticdump: Import and export tools for elasticsearch"
if [ $? -ne 0 ]; then
        rreturn 1 "$0 elasticdump not installed"
fi


rreturn 0 "$0"

