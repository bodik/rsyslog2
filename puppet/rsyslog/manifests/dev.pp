# == Class: rsyslog::dev
#
# Class will ensure installcompilation and debugging rsyslog8. Also disables
# stripping binaries for whole node because of generation debug enabled
# packages.
#
# === Examples
#
#   include rsyslog::dev
#
class rsyslog::dev { 
	package { ["dpkg-dev", "gcc", "make", "fakeroot", "git-buildpackage", "debhelper", "dh-autoreconf", "dh-systemd", "bison", "pkg-config", "dh-exec"]:
		ensure => installed,
	}



	#nevim jak jinak vypnout stripovani binarek v rules/buildpackage...
	file { "/usr/bin/strip":
		ensure => link,
		target => "/bin/true",
	}




	exec {"apt-get update":
	        command => "/usr/bin/apt-get update",
	        refreshonly => true,
	}
	file { "/etc/apt/apt.conf.d/99auth":       
		content => "APT::Get::AllowUnauthenticated yes;\n",
		owner => "root", group => "root", mode => "0644",
 	}
	file { "/etc/apt/sources.list.d/meta-rsyslog.list":
	        source => "puppet:///modules/rsyslog/etc/apt/sources.list.d/meta-rsyslog.list",
        	owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	exec { "install liblognorm":
		command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y --force-yes -o DPkg::Options::=--force-confold  -t jessie-backports liblognorm-dev",
		timeout => 600,
		unless => "/usr/bin/dpkg -l liblognorm-dev | /bin/grep ' 8.16'",
		require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], Exec["apt-get update"]],
	}



	package { 
		[ "zlib1g-dev", "libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", "libcurl4-gnutls-dev", 
		  "libkrb5-dev", "librelp-dev", "libestr-dev", "libee-dev", "liblognorm-dev", 
		  "liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev", "libgcrypt-dev", "flex", "libgnutls28-dev",
		  "librdkafka-dev", "libsystemd-dev",
		  "faketime",
		]:
		ensure => installed,
		require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], Exec["apt-get update"]],
	}
}

