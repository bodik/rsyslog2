puppet apply -vd avahi.pp

export FACTER_rediser_server=$(/puppet/avahi/avahi.findservice.sh _rediser._tcp)
puppet apply -vd rsyslog-server.pp
