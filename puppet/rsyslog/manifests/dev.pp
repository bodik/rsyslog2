# == Class: rsyslog::dev
#
# Class will ensure installcompilation and debugging rsyslog7. Also disables
# stripping binaries for whole node because of generation debug enabled
# packages.
#
# === Examples
#
#   include rsyslog::dev
#
class rsyslog::dev { 
	exec { "apt-get update": 
		command => "/usr/bin/apt-get update", 
		refreshonly => true, 
	}

	file { "/etc/apt/sources.list.d/wheezy-backports.list":
	        source => "puppet:///modules/rsyslog/etc/apt/sources.list.d/wheezy-backports.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}

	package { ["dpkg-dev", "gcc", "make", "fakeroot", "git-buildpackage", "debhelper", "dh-autoreconf", "dh-systemd", "bison", "pkg-config", "dh-exec"]:
		ensure => installed,
		require => [File["/etc/apt/sources.list.d/wheezy-backports.list"],Exec["apt-get update"]],
	}

	#nevim jak jinak vypnout stripovani binarek v rules/buildpackage...
	file { "/usr/bin/strip":
		ensure => link,
		target => "/bin/true",
	}

	# v7.6 build deps
	package { 
		[ 
		"zlib1g-dev", "libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", "libcurl4-gnutls-dev", "libkrb5-dev", 
		"libgnutls-dev", "librelp-dev", "libestr-dev", "libee-dev", "liblognorm-dev", 
		"liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev"
		]:
		ensure => installed,
		require => [File["/etc/apt/sources.list.d/wheezy-backports.list"],Exec["apt-get update"]],
	}
}


