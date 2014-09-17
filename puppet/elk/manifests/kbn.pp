#!/usr/bin/puppet apply

class elk::kbn () {

	class { 'kibana':
		webserver   => 'apache',
		virtualhost => $fqdn,
		
		#tady v te casti je modul velmi osklivy
		#jak s konfigurakem sem nevycetl ale meni mu prava na default 664
		file_mode => "0644",
	
	}
	$kibana_elasticsearch_url = 'http://"+window.location.hostname+":39200'
	file { "/opt/kibana/config.js":
		content => template("${module_name}/opt/kibana/config.js.erb"),
		owner => "root", group => "root", mode => "0644",
	}
	file { "/etc/apache2/sites-enabled/000-default":
		ensure => absent,
		require => Package["apache2"],
		notify => Service["apache2"],
	}
	file { "/opt/kibana/dash.html":
		source => "puppet:///modules/${module_name}/opt/kibana/dash.html",
		owner => "root", group => "root", mode => "0644",
		require => Class["kibana::install"],
		
	}
	file { "/opt/kibana/app/dashboards":
		source => "puppet:///modules/${module_name}/opt/kibana/app/dashboards",
		recurse => true,
		owner => "root", group => "root", mode => "0644",
		require => Class["kibana::install"],
	}
}

