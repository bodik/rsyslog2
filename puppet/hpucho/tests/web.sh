#!/bin/sh 

. /puppet/metalib/bin/lib.sh

INSTALL_DIR=/opt/uchoweb

AGE=$(ps h -o etimes $(pgrep -f uchoweb.py) | head -1)
if [ $AGE -lt 30 ] ; then
	echo "INFO: Uchoweb warming up"
	sleep 30
fi

NOW=$(date +%s)

PORT=$(cat ${INSTALL_DIR}/uchoweb.cfg | grep port | awk '{print $2}' | sed 's/,//')
curl -s "http://$(facter ipaddress):${PORT}/manager/html" | grep "Tomcat Version"
if [ $? -ne 0 ]; then
	rreturn 1 "$0 failed to check on uchoweb basic content"
fi

rreturn 0 "$0"
