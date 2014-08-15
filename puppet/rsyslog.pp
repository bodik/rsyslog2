import '/puppet/lib.pp'

class rsyslog {
	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => installed,
	}
	service { "rsyslog":
		ensure => running,
	}

	file { "/etc/apt/sources.list.d/meta-rsyslog.list":
	        source => "/puppet/templates/etc/apt/sources.list.d/meta-rsyslog.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}

	file { "/etc/apt/sources.list.d/jessie.list":
	        source => "/puppet/templates/etc/apt/sources.list.d/jessie.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	exec { "install_rsyslog":
		#command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confold  -t jessie rsyslog rsyslog-gssapi rsyslog-relp",
		command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confnew rsyslog=8.2.2-3.rb20 rsyslog-gssapi=8.2.2-3.rb20 rsyslog-relp=8.2.2-3.rb20",
		timeout => 600,
		unless => "/usr/bin/dpkg -l rsyslog | grep ' 8\\.[0-9]'",
		require => [File["/etc/apt/sources.list.d/jessie.list", "/etc/apt/sources.list.d/meta-rsyslog.list"], Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]],

	}
}

