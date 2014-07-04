import '/puppet/lib.pp'

package { ["dpkg-dev", "gcc", "make", "fakeroot"]:
	ensure => installed,
}


#jessie v7.6 build deps
package { 
	[ "debhelper", "dh-autoreconf", "dh-systemd", "zlib1g-dev", "libmysqlclient-dev", "libpq-dev", "libmongo-client-dev", 
	"libcurl4-gnutls-dev", "libkrb5-dev", "libgnutls28-dev", "librelp-dev", "libestr-dev", "libee-dev",
 	"liblognorm-dev", "liblogging-stdlog-dev", "libjson-c-dev", "uuid-dev", "pkg-config", "bison"]:
	ensure => installed,
}


