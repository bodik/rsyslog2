#!/bin/sh
#
# modified by bodik@cesnet.cz

. /puppet/metalib/lib.sh

WS=$(/puppet/metalib/avahi.findservice.sh _warden-server._tcp)
if [ -z "$WS" ]; then
        echo "ERROR: cannt discover warden_ca server"
        exit 1
fi

curl -k "http://${WS}:45444/get_ca_crt" 2>/dev/null | grep "BEGIN CERTIFICATE" 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 ca not running"
fi

rreturn 0 "$0"
