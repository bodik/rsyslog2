#!/usr/bin/puppet apply

package { "redis-server":
	ensure => installed,
}
service { "redis-server":
	ensure => running,
}
file { "/etc/redis/redis.conf":
	source => "/puppet/templates/etc/redis/redis.conf",
	owner => "root", group => "root", mode => "0644",
	require => Package["redis-server"],
	notify => Service["redis-server"],
}

import '/puppet/avahi.pp'
file { "/etc/avahi/services/rediser.service":
	source => "/puppet/templates/etc/avahi/rediser.service",
	owner => "root", group => "root", mode => "0644",
	require => Package["avahi-daemon"],
	notify => Service["avahi-daemon"],
}

#rediser
package { ["libpcap0.8", "libssl1.0.0", "ruby-dev"]:
	ensure => installed,
}
package { 'hiredis':
	ensure   => 'installed',
	provider => 'gem',
	require => Package["ruby-dev"]
}
file { "/etc/init.d/rediser":
	ensure => link,
	target => "/puppet/rediser/rediser.init"
}
service { "rediser":
	enable => true,
	ensure => running,
	require => [File["/etc/init.d/rediser"], Package["hiredis"], Package["libpcap0.8"], Package["libssl1.0.0"], Package["ruby-dev"]],
}

