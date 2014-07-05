#!/usr/bin/puppet apply

import '/puppet/rsyslog.pp'
class { "rsyslog": }

#tcp + relp - gssapi
file { "/etc/rsyslog.conf":
	source => "/puppet/templates/etc/rsyslog-client.conf",
	owner => "root", group=> "root", mode=>"0644",
	require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
	notify => Service["rsyslog"],
	
}
file { "/etc/rsyslog.d/meta-remote-tcp.conf":
	source => "/puppet/templates/etc/rsyslog.d/meta-remote-tcp.conf",
	owner => "root", group=> "root", mode=>"0644",
	require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
	notify => Service["rsyslog"],
	
}

