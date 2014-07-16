puppet apply -vd avahi.pp

export FACTER_rsyslog_server=$(/puppet/avahi.findservice.sh _syseltcp._tcp)

puppet apply -vd rsyslog-client.pp

