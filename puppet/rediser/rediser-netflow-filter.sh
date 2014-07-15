#!/bin/bash
BASE=/puppet/rediser
cd /tmp || exit 1

export A=`${BASE}/getpgrp`
LOGGER="logger -p syslog.info -t rediser-netflow-filter.sh[$$]"

(stdbuf -i0 -o0 -e0 tr -c '[:print:][:cntrl:]' '?'; $LOGGER "fail tr"; sleep 20; pkill -g $A) | \
(ruby $BASE/rediser4.rb netflow 1000 |$LOGGER; $LOGGER "fail rediser-netflow"; sleep 20; pkill -g $A)

