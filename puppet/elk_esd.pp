#!/usr/bin/puppet apply

import '/puppet/avahi.pp'

class { 'elasticsearch':
	manage_repo  => true,
	repo_version => '1.2',
	java_install => true,
	datadir => '/scratch',
	config => { 
		'cluster.name' => 'mrx',
		'transport.tcp.port' => '39300-39400',
		'http.port' => '39200-39300',
		###'discovery.zen.minimum_master_nodes' => '2',
		###'index.number_of_replicas' => '1',
		###'index.number_of_shards' => '8',
	 }
}
elasticsearch::instance { 'es01': }
#docasne vypnuto, nepouziva se a nejak spatne se dela instalace (github fuckoff)
#elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
#	module_dir => 'kopf',
#	instances  => 'es01'
#}
elasticsearch::plugin{'mobz/elasticsearch-head':
	module_dir => 'head',
	instances  => 'es01'
}
elasticsearch::plugin{'bleskes/sense':
	module_dir => 'sense',
	instances  => 'es01'
}
elasticsearch::plugin{'karmi/elasticsearch-paramedic':
	module_dir => 'paramedic',
	instances  => 'es01'
}

package { ["curl", "python-requests"]:
	ensure => installed,
}
