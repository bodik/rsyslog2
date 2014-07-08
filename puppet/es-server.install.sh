puppet module install elasticsearch-elasticsearch
puppet module install puppetlabs-apt
puppet apply -dv es-server.pp
