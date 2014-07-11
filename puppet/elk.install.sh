
#TODO BY MELO JIT ROZTRHAT
#ES
puppet module install elasticsearch-elasticsearch
puppet module install puppetlabs-apt
puppet apply -dv elk_esd.pp


#LOGSTASH
puppet module install elasticsearch-logstash
export FACTER_rediser_server=$(avahi-browse -t _rediser._tcp --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//')
puppet apply -dv elk_lsl.pp


#KIBANA
puppet module install example42-kibana
puppet module install example42-puppi
puppet module install example42-apache
puppet apply -dv elk_kibana.pp


