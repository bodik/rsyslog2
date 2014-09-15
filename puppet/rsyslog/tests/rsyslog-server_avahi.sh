#!/bin/sh

. /puppet/metalib/lib.sh

/usr/lib/nagios/plugins/check_procs -C avahi-daemon -c 2:2
if [ $? -ne 0 ]; then
	rreturn 1 "$0 avahi-daemon check_procs"
fi

SERVICE=_syseltcp._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress)
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _syseltcp._tcp not found"
fi

SERVICE=_syselgss._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress)
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _syseltcp._tcp not found"
fi
SERVICE=_syselrelp._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress)
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _syseltcp._tcp not found"
fi

rreturn 0 "$0"

