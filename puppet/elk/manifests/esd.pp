#!/usr/bin/puppet apply

class elk::esd () {

	$m = split($::memorytotal, " ")
	if ( $m[1] == "GB" ) {
		$half = floor($m[0] / 2)
		$config_hash = {
		  'ES_HEAP_SIZE' => "${half}g",
		}
	}

	class { 'elasticsearch':
		manage_repo  => true,
		repo_version => '1.2',
		java_install => true,
		datadir => '/scratch',
		init_defaults => $config_hash,
		config => { 
			'cluster.name' => 'mrx',
			'transport.tcp.port' => '39300-39400',
			'http.port' => '39200-39300',
			'script.disable_dynamic' => false,
			###'discovery.zen.minimum_master_nodes' => '2',
			###'index.number_of_replicas' => '1',
			###'index.number_of_shards' => '8',
		 }
	}
	elasticsearch::instance { 'es01': }
	
	elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
		module_dir => 'kopf',
		instances  => 'es01'
	}
	elasticsearch::plugin{'royrusso/elasticsearch-HQ':
		module_dir => 'HQ',
		instances  => 'es01'
	}
	elasticsearch::plugin{'lukas-vlcek/bigdesk':
		module_dir => 'bigdesk',
		instances  => 'es01'
	}
	elasticsearch::plugin{'mobz/elasticsearch-head':
		module_dir => 'head',
		instances  => 'es01'
	}
	elasticsearch::plugin{'karmi/elasticsearch-paramedic':
		module_dir => 'paramedic',
		instances  => 'es01'
	}

	package { ["curl", "python-requests"]:
		ensure => installed,
	}
}
