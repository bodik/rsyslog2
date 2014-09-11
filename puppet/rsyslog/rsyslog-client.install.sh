export FACTER_rsyslog_server=$(/puppet/avahi/avahi.findservice.sh _syseltcp._tcp)

puppet apply --modulepath=/puppet -vd rsyslog-client.pp

