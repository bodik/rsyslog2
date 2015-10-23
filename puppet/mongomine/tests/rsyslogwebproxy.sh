#!/bin/sh

. /puppet/metalib/lib.sh

#for now we consider rediser something like a headnode
REDISER=$(/puppet/metalib/bin/avahi.findservice.sh _rediser._tcp)

wget "http://${REDISER}/rsyslogweb/stats" -O - | grep table_mapRemoteResult 1>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogweb/stats not available over proxy"
fi

rreturn 0 "$0 rsyslogwebproxy found and working"
