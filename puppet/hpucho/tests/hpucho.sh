#!/bin/sh 

. /puppet/metalib/lib.sh

INSTALL_DIR=/opt/ucho
NOW=$(date +%s)

PORT=$(cat /opt/ucho/warden_client-ucho.cfg | grep port_start | awk '{print $2}' | sed 's/,//')
echo "autotest $NOW" | nc -q0 $(facter ipaddress) $PORT;
if [ $? -ne 0 ]; then
	rreturn 0 "$0 failed to open port_start"
fi

PORT=$(cat /opt/ucho/warden_client-ucho.cfg | grep port_end | awk '{print $2}' | sed 's/,//')
echo "autotest $NOW" | nc -q0 $(facter ipaddress) $((PORT-1));
if [ $? -ne 0 ]; then
	rreturn 0 "$0 failed to open port_end"
fi

rreturn 0 "$0"

