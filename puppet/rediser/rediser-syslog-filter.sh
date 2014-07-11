#!/bin/bash
BASE=/puppet/rediser
cd /tmp || exit 1

export A=`${BASE}/getpgrp`
LOGGER="logger -p syslog.info -t rediser-syslog-filter.sh[$$]"

(stdbuf -i0 -o0 -e0 tr -c '[:print:][:cntrl:]' '?'; $LOGGER "fail tr"; sleep 20; pkill -g $A) | \
#(grep --line-buffered -v -f ./lsloader-es-all.ignore; echo "`date` fail grep" >> $BASE/var/lsloader-rediser-filter.log; sleep 20; pkill -g $A) | \
#($BASE/pv -i 10 -f -r -N PID${A} 2>> $BASE/var/lsloader-rediser-filter.log; echo "`date` fail pv" >> $BASE/var/lsloader-rediser-filter.log; sleep 20; pkill -g $A) | \
(ruby $BASE/rediser4.rb syslog 1000 |$LOGGER; $LOGGER "fail rediser-syslog"; sleep 20; pkill -g $A)

