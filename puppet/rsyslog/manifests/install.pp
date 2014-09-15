#!/usr/bin/puppet apply

class rsyslog::install ( 
	$version = "meta" 
) { 
	exec {"apt-get update":
	        command => "/usr/bin/apt-get update",
	        refreshonly => true,
	}

	case $version {
		"jessie": { 
			$src = "puppet:///modules/rsyslog/etc/apt/sources.list.d/jessie.list"
			file { "/etc/apt/apt.conf.d/99auth": ensure => absent, } 
			exec { "install_rsyslog":
				command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y --force-yes -o DPkg::Options::=--force-confold  -t jessie rsyslog/jessie rsyslog-gssapi/jessie rsyslog-relp/jessie",
				timeout => 600,
				unless => "/usr/bin/dpkg -l rsyslog | grep ' 8.4'",
				require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], Exec["apt-get update"]],
			}
		}
		"bpo": { 
			$src = "puppet:///modules/rsyslog/etc/apt/sources.list.d/wheezy-backports.list"
			file { "/etc/apt/apt.conf.d/99auth": ensure => absent, } 
			exec { "install_rsyslog":
				command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y --force-yes -o DPkg::Options::=--force-confold  -t wheezy-backports rsyslog/wheezy-backports rsyslog-gssapi/wheezy-backports rsyslog-relp/wheezy-backports",
				timeout => 600,
				unless => "/usr/bin/dpkg -l rsyslog | grep ' ~bpo70'",
				require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], Exec["apt-get update"]],
			}
		}
		"meta": { 
			$src = "puppet:///modules/rsyslog/etc/apt/sources.list.d/meta-rsyslog.list"
			file { "/etc/apt/apt.conf.d/99auth":       
				content => "APT::Get::AllowUnauthenticated yes;\n",
				owner => "root", group => "root", mode => "0644",
		 	}
			exec { "install_rsyslog":
				command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y --force-yes -o DPkg::Options::=--force-confold rsyslog=7.6.3-3.rb20 rsyslog-gssapi=7.6.3-3.rb20 rsyslog-relp=7.6.3-3.rb20",
				timeout => 600,
				unless => "/usr/bin/dpkg -l rsyslog | grep ' 7.6.3-3.rb20'",
				require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], Exec["apt-get update"]],
			}
		}
	} 
	file { "/etc/apt/sources.list.d/meta-rsyslog.list":
	        source => $src,
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}

	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => installed,
	}
}

