# == Class: rsyslog::install
#
# Class will ensure installation of rsyslog packages in specific version or distribution flavor.
#
# === Parameters
#
# [*version*] 
#   specific version to install. Valid values: "meta", "jessie"
#
class rsyslog::install ( 
	$version = "meta" 
) { 
	exec {"apt-get update":
	        command => "/usr/bin/apt-get update",
	        refreshonly => true,
	}

	case $version {
		"jessie": { 
			file { "/etc/apt/apt.conf.d/99auth": ensure => absent, } 
			exec { "install_rsyslog":
				command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y --force-yes -o DPkg::Options::=--force-confold  -t jessie rsyslog/jessie rsyslog-gssapi/jessie rsyslog-relp/jessie",
				timeout => 600,
				unless => "/usr/bin/dpkg -l rsyslog | /bin/grep ' 8.4'",
			}
		}
		"meta": { 
			$src = "puppet:///modules/rsyslog/etc/apt/sources.list.d/meta-rsyslog.list"
			file { "/etc/apt/apt.conf.d/99auth":       
				content => "APT::Get::AllowUnauthenticated yes;\n",
				owner => "root", group => "root", mode => "0644",
		 	}
			$myver="8.16.0~bpo8+1.rb40"
			exec { "install_rsyslog":
				command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y --force-yes -o DPkg::Options::=--force-confnew rsyslog=${myver} rsyslog-gssapi=${myver} rsyslog-relp=${myver}",
				timeout => 600,
				unless => "/usr/bin/dpkg -l rsyslog | /bin/grep ' ${myver}'",
				require => [File["/etc/apt/sources.list.d/meta-rsyslog.list"], Exec["apt-get update"]],
			}
			file { "/etc/apt/sources.list.d/meta-rsyslog.list":
			        source => $src,
		        	owner => "root", group => "root", mode => "0644",
			        notify => Exec["apt-get update"],
			}
		}
	} 

	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => installed,
	}

	package { ["bc"]:
		ensure => installed,
	}


	define config() {
		file { "${name}":
			content => template("${module_name}/${name}.erb"),
			owner => "root", group=> "root", mode=>"0644",
			require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
			notify => Service["rsyslog"],
		}
	}
}

