#!/bin/sh

service rsyslog stop
rm -r /var/log/hosts/*
rm /var/log/syslog
#rm /scratch/bodik/rsyslogddebug.log 2>/dev/null
service rsyslog start
echo "INFO: logs cleaned"

