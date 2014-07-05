#!/bin/sh

rreturn() {
	RET=$1
	MSG=$2
	if [ $RET -eq 0 ]; then
		echo "RESULT: OK $MSG"
		exit 0
	else
		echo "RESULT: FAILED $MSG"
		exit 1
	fi

	echo "RESULT: FAILED THIS SHOULD NOT HAPPEN $0 $@"
	exit 1
}

/usr/lib/nagios/plugins/check_procs -C avahi-daemon -c 2:2
if [ $? -ne 0 ]; then
	rreturn 1 "$0 avahi-daemon check_procs"
fi

SERVICE=_syseltcp._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress); echo $?
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _syseltcp._tcp not found"
fi

SERVICE=_syselgss._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress); echo $?
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _syseltcp._tcp not found"
fi
SERVICE=_syselrelp._tcp
avahi-browse -t $SERVICE --resolve -p | grep $(facter ipaddress); echo $?
if [ $? -ne 0 ]; then
	rreturn 1 "$0 _syseltcp._tcp not found"
fi

rreturn 0 "$0"

