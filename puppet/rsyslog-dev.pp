import '/puppet/lib.pp'

package { ["dpkg-dev", "gcc", "make", "fakeroot", "git-buildpackage", "debhelper", "dh-autoreconf", "dh-systemd", "bison", "pkg-config"]:
	ensure => installed,
}

file { "/etc/apt/sources.list.d/wheezy-backports.list":
        source => "/puppet/templates/etc/apt/sources.list.d/wheezy-backports.list",
        owner => "root", group => "root", mode => "0644",
        notify => Exec["apt-get update"],
}
file { "/etc/apt/sources.list.d/jessie.list":
        source => "/puppet/templates/etc/apt/sources.list.d/jessie.list",
        owner => "root", group => "root", mode => "0644",
        notify => Exec["apt-get update"],
}

# v8.2 build deps
package { 
	[ "zlib1g-dev", "libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", "libcurl4-gnutls-dev", 
	  "libkrb5-dev", "libgnutls-dev", "librelp-dev", "libestr-dev", "libee-dev", "liblognorm-dev", 
	  "liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev", "libgcrypt-dev", "flex", "libgnutls28-dev"
	]:
	ensure => installed,
	require => [File["/etc/apt/sources.list.d/jessie.list"],Exec["apt-get update"]],
}


