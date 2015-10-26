#!/bin/sh 

. /puppet/metalib/lib.sh

INSTALL_DIR=/opt/telnetd
NOW=$(date +%s)

PORT=$(cat $INSTALL_DIR/warden_client-telnetd.cfg | grep twisted_port_spec | awk '{print $2}' | sed 's/"tcp:\([0-9]\+\)"/\1/')

(echo "autotest $NOW"; sleep 1) | telnet $(facter ipaddress) $PORT | grep "login: "; echo $?
if [ $? -ne 0 ]; then
	rreturn 0 "$0 failed to open telnetd connection"
fi

rreturn 0 "$0"

