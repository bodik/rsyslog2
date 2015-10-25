# == Class: metalib::wget
#
# Class for installling wget, and defines download resource. Used internally.
#
class metalib::wget() {
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
}
