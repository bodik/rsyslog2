# == Class: elk::esc
#
# Class will ensure installation of elasticsearch client node using puppet-elasticsearch modules 
# and creates single instance with 'heapsize as memorysize/2' and set of basic plugins.
#
# === Parameters
#
# [*cluster_name*]
#   set a specific cluster name for node
#
# [*network_host*]
#   set a network.host ES setting, eg. bind to specific interface
#
# [*es_heap_size*]
#   sets a heap size for ES jvm
#
# === Examples
#
#   class { "elk::esc": cluster_name => "abc", }
#
class elk::esc (
	$cluster_name = "mry",
	$network_host = undef,
	$esd_heap_size = undef,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	if ( $esd_heap_size ) {
		$esd_heap_size_real = $esd_heap_size
	} else {
		$m = split($::memorysize, " ")
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
		repo_version => '1.6',
		version => "1.6.*",
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
			'node.master' => 'false',
			'node.data' => 'false',
			'node.client' => 'true',
		 }
	}
	if $network_host {
		elasticsearch::instance { 'es01': 
			config => { 'network.host' => $network_host }
		}
	} else {
		elasticsearch::instance { 'es01': }
	}
	
	elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
		instances  => 'es01'
	}
	elasticsearch::plugin{'royrusso/elasticsearch-HQ':
		instances  => 'es01'
	}
	elasticsearch::plugin{'lukas-vlcek/bigdesk':
		instances  => 'es01'
	}
	elasticsearch::plugin{'mobz/elasticsearch-head':
		instances  => 'es01'
	}
	elasticsearch::plugin{'karmi/elasticsearch-paramedic':
		instances  => 'es01'
	}

	contain elk::utils
}
