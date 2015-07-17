# == Class: rediser
#
# Class will install redis server and rediser. Currently is redis installation
# enforced from wheezy-backports because of scripts support used by logstash
# input redis. Rediser will announce itself to others using avahi.
#
# === Examples
#
#  class { rediser: }
#
class rediser {
	notice($name)

	package { "redis-server":
		ensure => installed,
	}
	service { "redis-server":
		ensure => running,
	}

	include metalib::apt-get-update

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
	        require => [Package["redis-server"], Exec["gem install hiredis"]],
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
	package { ["libpcap0.8", "libssl1.0.0", "ruby-dev", "make"]:
		ensure => installed,
	}

	#gem provider strikes again -- invalid option: --include-dependencies
	#package { 'hiredis':
	#	ensure   => 'installed',
	#	provider => 'gem',
	#	require => Package["ruby-dev"]
	#}
	exec { "gem install hiredis":
                command => "/usr/bin/gem install --no-rdoc --no-ri hiredis",
                unless => "/usr/bin/gem list | grep hiredis",
                require => [Package["ruby-dev"], Package["make"]],
        }
	file { "/etc/init.d/rediser":
		ensure => link,
		target => "/puppet/rediser/rediser.init",
	}
	service { "rediser":
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/rediser"], Exec["gem install hiredis"], Package["libpcap0.8"], Package["libssl1.0.0"], Package["ruby-dev"]],
	}
}
