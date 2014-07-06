#!/bin/sh

/etc/init.d/rsyslog stop
rm -r /var/log/hosts/*
rm /var/log/syslog
#rm /scratch/bodik/rsyslogddebug.log 2>/dev/null
/etc/init.d/rsyslog start
echo "INFO: logs cleaned"

