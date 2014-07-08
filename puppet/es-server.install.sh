
#TODO BY MELO JIT ROZTRHAT
#ES
puppet module install elasticsearch-elasticsearch
puppet module install puppetlabs-apt


#LOGSTASH
puppet module install elasticsearch-logstash


#KIBANA
puppet module install example42-kibana
puppet module install example42-puppi
puppet module install example42-apache


puppet apply -dv es-server.pp


