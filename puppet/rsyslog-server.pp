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



