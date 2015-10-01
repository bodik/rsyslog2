# == Class: elk::esd
#
# Class will ensure installation of elasticsearch using puppet-elasticsearch modules 
# and creates single instance:
# - heapsize as memorytotal/2
# - set of basic plugins
#
# === Parameters
#
# [*cluster_name*]
#   set a specific cluster name for node
#
# === Examples
#
#   class { "elk::esd": cluster_name => "abc", }
#
class elk::esd (
	$cluster_name = "mry",
	$esd_heap_size = undef,
) {
	notice($name)

	if ( $esd_heap_size ) {
		$esd_heap_size_real = $esd_heap_size
	} else {
		$m = split($::memorytotal, " ")
		if ( $m[1] == "GB" ) {
			$half = max(floor($m[0] / 2), 1)
			$esd_heap_size_real = "${half}g"
		}
	}

	$config_hash = {
		  'ES_HEAP_SIZE' => $esd_heap_size_real,
	}

	class { 'elasticsearch':
		manage_repo  => true,
		repo_version => '1.4',
		java_install => true,
		datadir => '/scratch',
		init_defaults => $config_hash,
		config => { 
			'cluster.name' => $cluster_name,
			'transport.tcp.port' => '39300-39400',
			'http.port' => '39200-39300',
			'script.disable_dynamic' => false,
			'discovery.zen.ping.multicast.group' => '224.0.0.251',
			#es 1.4 cross default enable
			'http.cors.enabled' => true,
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

	# needed for elk script queries
	package { ["curl", "python-requests"]:
		ensure => installed,
	}

	#https://tickets.puppetlabs.com/browse/PUP-1073
	#package { 'elasticsearch':
        #        ensure   => 'installed',
        #        provider => 'gem',
        #}
	exec { "gem install elasticsearch":
		command => "/usr/bin/gem install elasticsearch",
		unless => "/usr/bin/gem list | /bin/grep elasticsearch",
	}
}
