#!/usr/bin/puppet apply

import '/puppet/lib.pp'

file { "/etc/apt/sources.list.d/wheezy-backports.list":
        source => "/puppet/templates/etc/apt/sources.list.d/wheezy-backports.list",
        owner => "root", group => "root", mode => "0644",
        notify => Exec["apt-get update"],
}

package { ["rsyslog", "rsyslog-gssapi"]:
	ensure => installed,
}

exec { "install_rsyslog_wheezy-backports":
	command => "/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confold  -t wheezy-backports rsyslog rsyslog-gssapi",
	timeout => 600,
	unless => "/usr/bin/dpkg -l rsyslog | grep ' 7\\.[0-9]'",
	require => [File["/etc/apt/sources.list.d/wheezy-backports.list"], Package["rsyslog"], Package["rsyslog-gssapi"]],
}

