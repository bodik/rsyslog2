# == Class: metalib::base
#
# Class for ensuring basic setting of managed machine such as: editors, git,
# puppet, hostname, krb5 client lib, sources list.
#
# === Examples
#
# include metalib::base
#
class metalib::base {
	notice($name)

	# globals
	package { "wget": ensure => installed, }
	define download ($uri, $timeout = 300, $owner = "root", $group = "root", $mode = "0644") {
		exec { "download $uri":
			command => "/usr/bin/wget -q '$uri' -O $name",
			creates => $name,
			timeout => $timeout,
			require => Package[ "wget" ],
	        }
		file { "$name":
			owner => $owner, group => $group, mode => $mode,
			require => Exec["download $uri"],
		}
	}
	include metalib::apt-get-update


	# generic debianization from next,next,next,... install
	package { ["nfs-common","rpcbind"]: ensure => absent, }
	package { ["joe","nano", "pico"]: ensure => absent, }
	package { ["vim", "mc", "git", "puppet", "augeas-lenses", "nagios-plugins-basic", "screen", "psmisc"]: ensure => installed, }

	package { "krb5-user": ensure => installed, }
	download { "/etc/krb5.conf":
                uri => "https://download.zcu.cz/public/config/krb5/krb5.conf",
                owner => "root", group => "root", mode => "0644",
                timeout => 900;
	}

	case $lsbmajdistrelease {
		7: {
			$file_sourceslist = "puppet:///modules/metalib/etc/apt/sources.list.d/wheezy.list"
			$file_sourceslist_dst = "/etc/apt/sources.list.d/wheezy.list"
		}
		8: {
			$file_sourceslist = "puppet:///modules/metalib/etc/apt/sources.list.d/jessie.list"
			$file_sourceslist_dst = "/etc/apt/sources.list.d/jessie.list"
		}
	}
	file { "$file_sourceslist_dst":
	        source => $file_sourceslist,
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	
	#cron { "apt":
	#  command => "/usr/bin/aptitude update 1>/dev/null",
	#  user    => root,
	#  hour    => 0,
	#  minute  => 0
	#}
	#cron { "check_apt":
	#  command => "/usr/lib/nagios/plugins/check_apt | /bin/grep -v 'APT OK'",
	#  user    => root,
	#  hour    => 1,
	#  minute  => 0
	#}

	case $hostname {
	        default: { $tmp_file = "${module_name}/etc/hosts.erb" }
	}
	file { "/etc/hosts":
	        content => template($tmp_file),
	        owner => "root", group => "root", mode => "0644",
	}

}



