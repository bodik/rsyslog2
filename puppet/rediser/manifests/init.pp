# == Class: rediser
#
# rediser installation class
#
# === Examples
#
#  class { rediser: }
#
# === Authors
#
# bodik@cesnet.cz
#
class rediser {

	package { "redis-server":
		ensure => installed,
	}
	service { "redis-server":
		ensure => running,
	}


	exec {"apt-get update": 
                command => "/usr/bin/apt-get update",
                refreshonly => true,
        }


	file { "/etc/apt/sources.list.d/wheezy-backports.list":
	        source => "puppet:///modules/${module_name}/etc/apt/sources.list.d/wheezy-backports.list",
	        owner => "root", group => "root", mode => "0644",
	        notify => Exec["apt-get update"],
	}
	exec { "install_redis-server_wheezy-backports":
		command => "/usr/bin/apt-get update;/usr/bin/apt-get install -q -y -o DPkg::Options::=--force-confold  -t wheezy-backports redis-server",
		timeout => 600,
		onlyif => "/usr/bin/dpkg -l redis-server | grep ':2\\.4'",
		require => [File["/etc/apt/sources.list.d/wheezy-backports.list"], Package["redis-server"]],
	}

	augeas { "/etc/redis/redis.conf" :
		lens => 'Spacevars.lns',
	        incl => "/etc/redis/redis.conf",
	        context => "/files/etc/redis/redis.conf",
	        changes => [
			"set port 16379",
			"set bind 0.0.0.0",
			"set maxmemory 1024000000",
			"rm save",
	        ],
	        require => [Package["redis-server"], Exec["install_redis-server_wheezy-backports"]],
       		notify => Service["redis-server"],
	}

	include metalib::avahi
	file { "/etc/avahi/services/rediser.service":
		source => "puppet:///modules/${module_name}/etc/avahi/rediser.service",
		owner => "root", group => "root", mode => "0644",
		require => Package["avahi-daemon"],
		notify => Service["avahi-daemon"],
	}

	#rediser
	package { ["libpcap0.8", "libssl1.0.0", "ruby-dev"]:
		ensure => installed,
	}
	package { 'hiredis':
		ensure   => 'installed',
		provider => 'gem',
		require => Package["ruby-dev"]
	}
	file { "/etc/init.d/rediser":
		ensure => link,
		target => "/puppet/rediser/rediser.init",
	}
	service { "rediser":
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/rediser"], Package["hiredis"], Package["libpcap0.8"], Package["libssl1.0.0"], Package["ruby-dev"]],
	}
}
