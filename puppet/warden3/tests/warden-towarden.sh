#!/bin/sh

. /puppet/metalib/bin/lib.sh

/usr/lib/nagios/plugins/check_procs --argument-array=warden_towarden_receiver.cfg -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden_towarden.py receiver check_procs"
fi

/usr/lib/nagios/plugins/check_procs --argument-array=warden_towarden_sender.cfg -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 warden_towarden.py receiver check_procs"
fi

rreturn 0 "$0"
