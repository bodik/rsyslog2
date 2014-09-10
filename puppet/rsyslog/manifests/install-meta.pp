class rsyslog::install-meta { 

	exec {"apt-get update":
	        command => "/usr/bin/apt-get update",
	        refreshonly => true,
	}

	file { "/etc/apt/sources.list.d/meta-rsyslog.list":
	        source => "puppet:///modules/rsyslog/etc/apt/sources.list.d/meta-rsyslog.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	file { "/etc/apt/preferences.d/meta-rsyslog.pref":
	        source => "puppet:///modules/rsyslog/etc/apt/preferences.d/meta-rsyslog.pref",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	file { "/etc/apt/apt.conf.d/99auth":       
		content => "APT::Get::AllowUnauthenticated yes;\n",
		owner => "root", group => "root", mode => "0644",
 	}

	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => latest,
		require => [File["/etc/apt/sources.list.d/meta-rsyslog.list", "/etc/apt/preferences.d/meta-rsyslog.pref", "/etc/apt/apt.conf.d/99auth"], Exec["apt-get update"]],
	}


}

