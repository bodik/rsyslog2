
#TODO BY MELO JIT ROZTRHAT
#ES
puppet module install elasticsearch-elasticsearch
puppet module install puppetlabs-apt
puppet apply -dv elk_esd.pp


#LOGSTASH
puppet module install elasticsearch-logstash
puppet apply -dv elk_logstash.pp


#KIBANA
puppet module install example42-kibana
puppet module install example42-puppi
puppet module install example42-apache
puppet apply -dv elk_kibana.pp


