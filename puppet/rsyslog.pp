import '/puppet/lib.pp'

class rsyslog {
	service { "rsyslog":
		ensure => running,
	}

	#file { "/etc/apt/sources.list.d/wheezy-backports.list":
	#        source => "/puppet/templates/etc/apt/sources.list.d/wheezy-backports.list",
	#        owner => "root", group => "root", mode => "0644",
	#        notify => Exec["apt-get update"],
	#}


	file { "/etc/apt/sources.list.d/meta-rsyslog.list":
	        source => "/puppet/templates/etc/apt/sources.list.d/meta-rsyslog.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	file { "/etc/apt/preferences.d/meta-rsyslog.pref":
	        source => "/puppet/templates/etc/apt/preferences.d/meta-rsyslog.pref",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}

	file { "/etc/apt/apt.conf.d/99auth":       
		content => "APT::Get::AllowUnauthenticated yes;",
		owner => "root", group => "root", mode => "0644",
 	}

	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => latest,
		require => [File["/etc/apt/sources.list.d/meta-rsyslog.list", "/etc/apt/preferences.d/meta-rsyslog.pref", "/etc/apt/apt.conf.d/99auth"], Exec["apt-get update"]],
	}
}

