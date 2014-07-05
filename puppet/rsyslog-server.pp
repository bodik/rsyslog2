#!/usr/bin/puppet apply

import '/puppet/rsyslog.pp'
class { "rsyslog": }

#tcp + relp - gssapi
file { "/etc/rsyslog.conf":
	source => "/puppet/templates/etc/rsyslog-server.conf",
	owner => "root", group=> "root", mode=>"0644",
	require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
	notify => Service["rsyslog"],
	
}

package { ["avahi-daemon", "avahi-utils"]:
	ensure => installed,
}
file { "/etc/avahi/services/sysel.service":
	source => "/puppet/templates/etc/avahi/sysel.service",
	owner => "root", group => "root", mode => "0644",
	require => Package["avahi-deamon"],
	notify => Service["avahi-daemon"],
}

