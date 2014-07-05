#!/usr/bin/puppet apply

import '/puppet/rsyslog.pp'
class { "rsyslog": }

$rsyslog_server => "sysel.metacentrum.cz"

#tcp + relp - gssapi
file { "/etc/rsyslog.conf":
	source => "/puppet/templates/etc/rsyslog-client.conf",
	owner => "root", group=> "root", mode=>"0644",
	require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
	notify => Service["rsyslog"],
	
}
file { "/etc/rsyslog.d/meta-remote-tcp.conf":
	content => template("/puppet/templates/etc/rsyslog.d/meta-remote-tcp.conf.erb"),
	owner => "root", group=> "root", mode=>"0644",
	require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
	notify => Service["rsyslog"],
	
}

