
#TODO BY MELO JIT ROZTRHAT
#ES
puppet module install elasticsearch-elasticsearch
puppet module install puppetlabs-apt
puppet apply -dv elk_esd.pp


#LOGSTASH
puppet module install elasticsearch-logstash
export FACTER_rediser_server=$(/puppet/avahi.findservice.sh _rediser._tcp)
puppet apply -dv elk_lsl.pp


#KIBANA
puppet module install example42-kibana
puppet module install example42-puppi
puppet module install example42-apache
puppet apply -dv elk_kibana.pp


