#!/usr/bin/puppet apply

# if more params needed try 
# https://github.com/jvoss/puppet-module-nfdump

class netflow::nfdump (
	$collector_port = "9995",
	$data_dir = "/var/cache/nfdump",
	$period_exec = "\'/bin/sh /puppet/netflow/bin/send.sh -f /var/cache/nfdump/%%f\'",
	$interval = "60",
) {
	class { "netflow::pmacct":
		collector_server => "localhost",
		collector_port => $collector_port,
	}

	#there's no nfdump package in jessie as of 22.10.2015, we'll use ubuntu's build
	#package { "nfdump":
	#	ensure => installed,
	#}
	include metalib::wget
	metalib::wget::download { "/var/cache/apt/nfdump_1.6.12-0.1_amd64.deb":
                uri => "http://launchpadlibrarian.net/192836530/nfdump_1.6.12-0.1_amd64.deb",
                owner => "root", group => "root", mode => "0644",
                timeout => 900;
	}
	package { "nfdump":
		name      =>  "nfdump",
		ensure    =>  installed,
		provider  =>  dpkg,
		source    =>  "/var/cache/apt/nfdump_1.6.12-0.1_amd64.deb",
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
	file { "/lib/systemd/system/nfdump.service":
		content => template("${module_name}/nfdump.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => Package["nfdump"],
		notify => Service["nfdump"],
	}
}
