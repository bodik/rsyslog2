#!/bin/bash
BASE=/puppet/rediser/bin
cd /tmp || exit 1

export A=`${BASE}/getpgrp`
NAME="auth"
LOGGER="logger -p syslog.info -t rediser-$NAME-filter.sh[$$]"

(stdbuf -i0 -o0 -e0 tr -c '[:print:][:cntrl:]' '?'; $LOGGER "fail tr"; sleep 20; pkill -g $A) | \
(ruby $BASE/rediser4.rb $NAME 1000 |$LOGGER; $LOGGER "fail rediser-$NAME"; sleep 20; pkill -g $A)

