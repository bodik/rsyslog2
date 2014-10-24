# == Class: elk::kbn
#
# Class will ensure installation of:
# - kibana and apache virtualhost using example42's modules
# - set of static dashboards
# - general dasboard /dash.html
#
# === Parameters
#
# [*kibana_webserver*]
#   which webserver should be managed with examples42-kibana class
#   set to false to disable automatic webserver configuration
#
# [*kibana_elasticsearch_url*]
#   specify ES rest endpoit url to config.js and dash.html, used in gated setup
#
# === Examples
#
#   class { "elk::kbn": }
#
class elk::kbn (
	$kibana_webserver = "apache",
	$kibana_elasticsearch_url = 'http://"+window.location.hostname+":39200',
) {
	notice($name)

	if ($kibana_webserver == false) {
		$kibana_webserver_real = undef
	} else {
		$kibana_webserver_real = $kibana_webserver
	}

	class { 'kibana':
		webserver => $kibana_webserver_real,
		virtualhost => $fqdn,
		
		#tady v te casti je modul velmi osklivy
		#jak s konfigurakem sem nevycetl ale meni mu prava na default 664
		file_mode => "0644",
	
	}
	file { "/opt/kibana/config.js":
		content => template("${module_name}/opt/kibana/config.js.erb"),
		owner => "root", group => "root", mode => "0644",
	}

	if ( $kibana_webserver_real ) {	
		file { ["/etc/apache2/sites-enabled/000-default", "/etc/apache2/sites-enabled/000-default.conf"]:
			ensure => absent,
			require => Package["apache2"],
			notify => Service["apache2"],
		}
	}
	file { "/opt/kibana/dash.html":
		content => template("${module_name}/opt/kibana/dash.html.erb"),
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

