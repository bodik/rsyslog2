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
	#exec { "install_rsyslog":
        #       #command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confold  -t jessie rsyslog rsyslog-gssapi rsyslog-relp",
        #       #command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confnew --force-yes rsyslog=8.2.2-3.rb20 rsyslog-gssapi=8.2.
        #       command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confnew --force-yes rsyslog=7.6.3-3.rb20 rsyslog-gssapi=7.6.3
        #       timeout => 600,
        #       unless => "/usr/bin/dpkg -l rsyslog | grep ' 8\\.[0-9]'",
        #       require => [File["/etc/apt/sources.list.d/wheezy-backports.list", "/etc/apt/sources.list.d/meta-rsyslog.list"], Package["rsyslog", "rsyslog-gssapi", "rsysl
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

