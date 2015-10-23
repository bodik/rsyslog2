#!/bin/sh

. /puppet/metalib/bin/lib.sh


/usr/lib/nagios/plugins/check_procs --argument-array=/usr/share/jenkins/jenkins.war -c 2:2
if [ $? -ne 0 ]; then
	rreturn 1 "$0 jenkins check_procs"
fi

AGE=$(ps h -o etimes $(pgrep -f /usr/share/jenkins/jenkins.war|tail -1))
if [ $AGE -lt 30 ] ; then
	echo "INFO: Jenkins warming up"
	sleep 30
fi

wget "http://$(facter fqdn):8081/" -q -O - | grep '<title>Dashboard \[Jenkins\]</title>' 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 jenkins web interface not found"
fi

rreturn 0 "$0"
