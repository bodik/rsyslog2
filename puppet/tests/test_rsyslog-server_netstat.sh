#!/bin/sh

. /puppet/tests/lib.sh

/usr/lib/nagios/plugins/check_procs -C rsyslogd -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd check_procs"
fi

netstat -nlpa | grep "$(pidof rsyslogd)/rsy" | grep LISTEN | grep :514
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd tcp listener"
fi

#TODO: facter::file_exists vs FACTER/bash
if [ -f /etc/krb5.keytab ]; then
	netstat -nlpa | grep "$(pidof rsyslogd)/rsy" | grep LISTEN | grep :515
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 rsyslogd gssapi listener"
	fi
else
	echo "WARN: rsyslog-server gssapi listener SKIPPED"
fi

netstat -nlpa | grep "$(pidof rsyslogd)/rsy" | grep LISTEN | grep :516
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd relp listener"
fi

rreturn 0 "$0"


