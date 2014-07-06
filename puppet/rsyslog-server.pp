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

#kvuli testovani
#tcpkill
package { ["libpcap0.8", "libnet1"]:
	ensure => installed,
}

#autoconfig
import '/puppet/avahi.pp'
file { "/etc/avahi/services/sysel.service":
	source => "/puppet/templates/etc/avahi/sysel.service",
	owner => "root", group => "root", mode => "0644",
	require => Package["avahi-daemon"],
	notify => Service["avahi-daemon"],
}

