#!/bin/sh

. /puppet/metalib/lib.sh

RUNNIG=$(iptables-save | grep INPUT| wc -l | awk '{print $1}')
CONFIG=$(cat /etc/iptables/rules.v4 | grep INPUT | wc -l | awk '{print $1}')

if [ "x$RUNNIG" != "x$CONFIG" ]; then
	rreturn 1 "$0 running firewall differs from config"
fi



RUNNIG=$(ip6tables-save | grep INPUT| wc -l | awk '{print $1}')
CONFIG=$(cat /etc/iptables/rules.v6 | grep INPUT | wc -l | awk '{print $1}')

if [ "x$RUNNIG" != "x$CONFIG" ]; then
	rreturn 1 "$0 running firewall6 differs from config"
fi


rreturn 0 "$0"

