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


/usr/lib/nagios/plugins/check_procs -C rsyslogd -c 1:1
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd check_procs"
fi

netstat -nlp | grep "$(pidof rsyslogd)/rsy" | grep LISTEN | grep :514
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd tcp listener"
fi

echo "WARN: RSYSLOG-SERVET GSSAPI LISTENER SKIPPED #################################"
echo "WARN: RSYSLOG-SERVET GSSAPI LISTENER SKIPPED #################################"
echo "WARN: RSYSLOG-SERVET GSSAPI LISTENER SKIPPED #################################"
#netstat -nlp | grep "$(pidof rsyslogd)/rsy" | grep LISTEN | grep :515
#if [ $? -ne 0 ]; then
#	rreturn 1 "$0 rsyslogd gssapi listener"
#fi

netstat -nlp | grep "$(pidof rsyslogd)/rsy" | grep LISTEN | grep :516
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rsyslogd relp listener"
fi

rreturn 0 "$0"


