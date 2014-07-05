import '/puppet/lib.pp'

class rsyslog {

	file { "/etc/apt/sources.list.d/wheezy-backports.list":
	        source => "/puppet/templates/etc/apt/sources.list.d/wheezy-backports.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	
	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => installed,
	}
	service { "rsyslog":
		ensure => running,
	}

	exec { "install_rsyslog_wheezy-backports":
		command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confold  -t wheezy-backports rsyslog rsyslog-gssapi rsyslog-relp",
		timeout => 600,
		unless => "/usr/bin/dpkg -l rsyslog | grep ' 7\\.[0-9]'",
		require => [File["/etc/apt/sources.list.d/wheezy-backports.list"], Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]],
	}
}
