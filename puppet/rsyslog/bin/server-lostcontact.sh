#!/bin/bash

HOSTS=$( find /var/log/hosts/$(date +%Y/%m/) -type f ! -name "*7z" -exec sh -c "cat {} | awk '{print \$3}' | sort | uniq" \; | sort | uniq )
for all in $HOSTS; do
	sh /puppet/rsyslog/bin/server-lastcontact.sh $all | grep -v "^INFO: ok"
done

