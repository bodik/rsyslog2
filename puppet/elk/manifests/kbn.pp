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
	$kibana_elasticsearch_url = 'http://"+window.location.hostname+":39200',
	$kibana_version = "3.1.0",
	$install_dir = "/opt/kibana",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	class { 'elk::kbn_install':
		kibana_version => $kibana_version,
		install_dir => $install_dir,
	}


	package { "apache2": ensure => installed, }
	service { "apache2": }
	file { ["/etc/apache2/sites-enabled/000-default", "/etc/apache2/sites-enabled/000-default.conf"]:
		ensure => absent,
		require => Package["apache2"],
		notify => Service["apache2"],
	}
	exec { "a2enmod ssl":
                command => "/usr/sbin/a2enmod ssl",
                unless => "/usr/sbin/a2query -m ssl",
		require => Package["apache2"],
                notify => Service["apache2"],
        }
	file { "/etc/apache2/sites-enabled/01kibana.conf":
                content => template("${module_name}/etc/apache2/sites-enabled/01kibana.conf.erb"),
                owner => "root", group => "root", mode => "0644",
                require => [
                        Package["apache2"],
			Class["elk::kbn_install"],
                        Exec["a2enmod ssl"],
                        ],
                notify => Service["apache2"],
        }



	file { "/opt/kibana/config.js":
		content => template("${module_name}/opt/kibana/config.js.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Class["elk::kbn_install"],
	}

	file { "/opt/kibana/dash.html":
		content => template("${module_name}/opt/kibana/dash.html.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Class["elk::kbn_install"],
		
	}
	file { "/opt/kibana/app/dashboards":
		source => "puppet:///modules/${module_name}/opt/kibana/app/dashboards",
		recurse => true,
		owner => "root", group => "root", mode => "0644",
		require => Class["elk::kbn_install"],
	}
}

