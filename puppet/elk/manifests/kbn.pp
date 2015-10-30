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
# [*proxyto*]
#   will create https proxy for connecting to local es instance. Parameter
#   can be either static or will be selected automatically as eth1 (gate) or eth0
#   (public/singlenode) ipaddress
#
# === Examples
#
#   class { "elk::kbn": }
#
class elk::kbn (
	$kibana_version = "3.1.0",
	$install_dir = "/opt/kibana",
	$proxyto = undef,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	class { 'elk::kbn_install':
		kibana_version => $kibana_version,
		install_dir => $install_dir,
	}


	#apache svc
	package { "apache2": ensure => installed, }
	service { "apache2": }
	file { ["/etc/apache2/sites-enabled/000-default", "/etc/apache2/sites-enabled/000-default.conf"]:
		ensure => absent,
		require => Package["apache2"],
		notify => Service["apache2"],
	}

	#apache config
	define a2enmod() {
		exec { "a2enmod $name":
	                command => "/usr/sbin/a2enmod $name",
	                unless => "/usr/sbin/a2query -m $name",
			require => Package["apache2"],
	                notify => Service["apache2"],
	        }
	}
	a2enmod { "ssl": }
	file { "/etc/apache2/ssl":
		ensure => directory,
		owner => root, group => root, mode => 750,
		require => Package["apache2"],
	}
	exec { "install_sslselfcert.sh":
		command => "/bin/sh /puppet/metalib/bin/install_sslselfcert.sh /etc/apache2/ssl/",
		creates => "/etc/apache2/ssl/${fqdn}.crt",
		require => File["/etc/apache2/ssl"],
	}

	if ($proxyto) {
		$proxyto_real = $proxyto
	} else {
		if ($ipaddress_eth1) {
	                $proxyto_real = $ipaddress_eth1
	        } else {
	                $proxyto_real = $ipaddress_eth0
	        }
	}
        notice("will proxy to esd at $proxyto_real")
	a2enmod { "proxy": }
	a2enmod { "proxy_http": }


	file { "/etc/apache2/sites-enabled/01kibana.conf":
                content => template("${module_name}/etc/apache2/sites-enabled/01kibana.conf.erb"),
                owner => "root", group => "root", mode => "0644",
                require => [
                        Package["apache2"],
			Class["elk::kbn_install"],
                        A2enmod["ssl", "proxy", "proxy_http"],
			Exec["install_sslselfcert.sh"],
                        ],
                notify => Service["apache2"],
        }



	#kibana app config and customization
	file { "/opt/kibana/config.js":
		source => "puppet:///modules/${module_name}/opt/kibana/config.js",
		owner => "root", group => "root", mode => "0644",
		require => Class["elk::kbn_install"],
	}
	file { "/opt/kibana/dash.html":
		source => "puppet:///modules/${module_name}/opt/kibana/dash.html",
		owner => "root", group => "root", mode => "0644",
		require => Class["elk::kbn_install"],
	}
	file { "/opt/kibana/app":
		ensure => directory, recurse => true, purge => false, 
		owner => "root", group => "root", mode => "0644",
		source => "puppet:///modules/${module_name}/opt/kibana/app",
		require => Class["elk::kbn_install"],
	}
	file { "/opt/kibana/dash":
		ensure => directory, recurse => true, purge => false, 
		owner => "root", group => "root", mode => "0644",
		source => "puppet:///modules/${module_name}/opt/kibana/dash",
		require => Class["elk::kbn_install"],
	}
}

