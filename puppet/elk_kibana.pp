#!/usr/bin/puppet apply

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
	require => Package["apache2"],
	notify => Service["apache2"],
}

