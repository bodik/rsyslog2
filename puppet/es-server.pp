
import '/puppet/avahi.pp'

class { 'elasticsearch':
	manage_repo  => true,
	repo_version => '1.2',
	java_install => true,
	config => { 
		'cluster.name' => 'mrx',
		'transport.tcp.port' => '39300-39400',
		'http.port' => '39200-39300',
		###'discovery.zen.minimum_master_nodes' => '2',
		###'index.number_of_replicas' => '1',
		###'index.number_of_shards' => '8',
	 }
}
elasticsearch::instance { 
	'es01': 
	before => Class["logstash"],
}
elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
	module_dir => 'kopf',
	instances  => 'es01'
}
elasticsearch::plugin{'mobz/elasticsearch-head':
	module_dir => 'head',
	instances  => 'es01'
}
elasticsearch::plugin{'bleskes/sense':
	module_dir => 'sense',
	instances  => 'es01'
}





class { 'logstash':
	manage_repo  => true,
	repo_version => '1.4',
}
logstash::configfile { 'simple':
	content => template("/puppet/templates/etc/logstash/conf.d/simple.conf"),
#	order => 10,
}





class { 'kibana':
	webserver   => 'apache',
	virtualhost => $fqdn,
	
	#tady v te casti je modul velmi osklivy
	#jak s konfigurakem sem nevycetl ale meni mu prava na default 664
	file_mode => "0644",

}
$kibana_elasticsearch_url = 'http://"+window.location.hostname+":39200'
file { "/opt/kibana/config.js":
	content => template("/puppet/templates/opt/kibana/config.js.erb"),
	owner => "root", group => "root", mode => "0644",
}
file { "/etc/apache2/sites-enabled/000-default":
	ensure => absent,
	notify => Service["apache2"],
}

