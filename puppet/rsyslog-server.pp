#!/usr/bin/puppet apply


import '/puppet/rsyslog.pp'
class { "rsyslog": }

file { "/etc/rsyslog.d.cloud":
	ensure => directory,
}

#tcp + relp - gssapi
file { "/etc/rsyslog.conf":
	source => "/puppet/templates/etc/rsyslog-server.conf",
	owner => "root", group=> "root", mode=>"0644",
	require => [Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"], File["/etc/rsyslog.d.cloud"]],
	notify => Service["rsyslog"],
}

if ( $rediser_server ) {
	file { "/etc/rsyslog.d.cloud/20-forwarder-rediser-syslog.conf":
		content => template("/puppet/templates/etc/rsyslog.d.cloud/20-forwarder-rediser-syslog.conf.erb"),
		owner => "root", group=> "root", mode=>"0644",
		require => [File["/etc/rsyslog.d.cloud"], Package["rsyslog"]],
		notify => Service["rsyslog"],
	}
        notice("forward rediser active")
} else {
	notice("forward rediser passive")
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

