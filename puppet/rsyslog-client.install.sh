puppet apply -vd avahi.pp

export FACTER_rsyslog_server=$(avahi-browse -t _syseltcp._tcp --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//')

puppet apply -vd rsyslog-client.pp

