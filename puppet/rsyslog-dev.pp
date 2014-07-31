import '/puppet/lib.pp'

package { ["dpkg-dev", "gcc", "make", "fakeroot"]:
	ensure => installed,
}

file { "/etc/apt/sources.list.d/wheezy-backports.list":
        source => "/puppet/templates/etc/apt/sources.list.d/wheezy-backports.list",
        owner => "root", group => "root", mode => "0644",
        notify => Exec["apt-get update"],
}
file { "/etc/apt/sources.list.d/sid.list":
        source => "/puppet/templates/etc/apt/sources.list.d/sid.list",
        owner => "root", group => "root", mode => "0644",
        notify => Exec["apt-get update"],
}

# v7.6 build deps
package { 
	[ "debhelper", "dh-autoreconf", "dh-systemd", "zlib1g-dev", "libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", 
	"libcurl4-gnutls-dev", "libkrb5-dev", "libgnutls-dev", "librelp-dev", "libestr-dev", "libee-dev",
 	"liblognorm-dev", "liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev", "pkg-config", "bison",
	"libgcrypt-dev", "flex", "libgnutls28-dev"]:
	ensure => installed,
	require => [File["/etc/apt/sources.list.d/sid.list"],Exec["apt-get update"]],
}


