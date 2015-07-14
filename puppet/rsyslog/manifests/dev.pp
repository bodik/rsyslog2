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

	# v7.6 build deps
	package { 
		[ "zlib1g-dev", "libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", "libcurl4-gnutls-dev", 
		  "libkrb5-dev", "librelp-dev", "libestr-dev", "libee-dev", "liblognorm-dev", 
		  "liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev", "libgcrypt-dev", "flex", "libgnutls28-dev",
		  "librdkafka-dev", "libsystemd-dev"
		]:
		ensure => installed,
	}
}


