export FACTER_rediser_server=$(/puppet/avahi/avahi.findservice.sh _rediser._tcp)
puppet apply --modulepath=/puppet rsyslog-server.pp
