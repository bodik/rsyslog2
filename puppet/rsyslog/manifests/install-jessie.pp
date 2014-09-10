class rsyslog::install-jessie { 

	exec {"apt-get update":
	        command => "/usr/bin/apt-get update",
	        refreshonly => true,
	}

	file { "/etc/apt/sources.list.d/jessie.list":
	        source => "puppet:///modules/rsyslog/etc/apt/sources.list.d/jessie.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	exec { "install_rsyslog":
               command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confold  -t jessie rsyslog rsyslog-gssapi rsyslog-relp",
               timeout => 600,
               unless => "/usr/bin/dpkg -l rsyslog | grep ' 8\\.[0-9]'",
               require => [File["/etc/apt/sources.list.d/jessie.list"], Exec["apt-get update"]],
	}
}

