#!/usr/bin/puppet apply

# if more params needed try 
# https://github.com/jvoss/puppet-module-nfdump

class netflow::nfdump (
	$collector_port = "9995",
	$data_dir = "/var/cache/nfdump",
	$period_exec = "\'/bin/sh /puppet/netflow/bin/send.sh -f /var/cache/nfdump/%f\'",
	$interval = "60",
) {
	class { "netflow::pmacct":
		collector_server => "localhost",
		collector_port => $collector_port,
	}

	package { "nfdump":
		ensure => installed,
	}
	service { "nfdump":
		ensure => running,
		hasstatus => false,
	}

	file { "/etc/default/nfdump":
		content => "#nfcapd is controlled by nfsen\nnfcapd_start=yes\n",
		owner => "root", group => "root", mode => "0644",
		require => Package["nfdump"],
		notify => Service["nfdump"],
	}
	file { "/etc/init.d/nfdump":
		content => template("${module_name}/nfdump.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => Package["nfdump"],
		notify => Service["nfdump"],
	}
}
