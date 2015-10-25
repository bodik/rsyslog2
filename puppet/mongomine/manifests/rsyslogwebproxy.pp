# == Class: mongomine::rsyslogwebproxy
#
# Class will ensure installation of apache and proxy modules to proxy rsyslogweb from the gate to actual application server/cloud member
#
# === Parameters
#
# [*mongomine_server*]
#   hostname or ip to proxy rsyslogweb requests to, has precedence over mongomine_auto
#   (default undef)
#
# [*mongomine_auto*]
#   perform mongomine autodiscovery by avahi (defult true)
#
# [*mongomine_service*]
#   name of mongomine service to discover (default "_mongomine._tcp")
#
# === Examples
#
#   class { "mongomine::mongomine":  }
#
class mongomine::rsyslogwebproxy (
	$mongomine_server = undef,
	$mongomine_auto = true,
	$mongomine_service = "_mongomine._tcp",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	if ($mongomine_server) {
                $mongomine_server_real = $mongomine_server
        } elsif ( $mongomine_auto == true ) {
                include metalib::avahi
                $mongomine_server_real = avahi_findservice($mongomine_service)
        }

	file { "/opt/rsyslogwebproxy":
		ensure => directory,
		owner => "root", group => "root", mode => "0644",
	}

	file { "/opt/rsyslogwebproxy/rewritemap.txt":
		content => "mongomine_server_real http://${mongomine_server_real}\n",
		owner => "root", group => "root", mode => "0644",
		require => File["/opt/rsyslogwebproxy"],
	}
	file { "/opt/rsyslogwebproxy/offline.html":
		content => "rsyslogweb offline\n",
		owner => "root", group => "root", mode => "0644",
		require => File["/opt/rsyslogwebproxy"],
	}
	file { "/opt/rsyslogwebproxy/rsyslogwebproxy.conf":
		source => "puppet:///modules/${module_name}/opt/rsyslogwebproxy/rsyslogwebproxy.conf",
		owner => "root", group => "root", mode => "0644",
		require => [File["/opt/rsyslogwebproxy"], Package["apache2"]],
		notify => Service["apache2"],
	}

	include metalib::apache2
	exec { "a2enmod rewrite":
		command => "/usr/sbin/a2enmod rewrite",
		unless => "/usr/sbin/a2query -m rewrite",
		notify => Service["apache2"],
	}
	exec { "a2enmod proxy":
		command => "/usr/sbin/a2enmod proxy",
		unless => "/usr/sbin/a2query -m proxy",
		notify => Service["apache2"],
	}
	exec { "a2enmod proxy_http":
		command => "/usr/sbin/a2enmod proxy_http",
		unless => "/usr/sbin/a2query -m proxy_http",
		notify => Service["apache2"],
	}
}
