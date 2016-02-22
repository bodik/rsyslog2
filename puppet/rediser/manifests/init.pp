# == Class: rediser
#
# Class will install redis server and rediser. 
# Rediser will announce itself to others using avahi.
#
# === Examples
#
#  class { rediser: }
#
class rediser (
	$install_dir = "/opt/rediser",
	$rediser_user = "rediser",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	#redis
	package { "redis-server":
		ensure => installed,
	}
	service { "redis-server":
		ensure => running,
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
	user { "$rediser_user":
		ensure => present, 
		managehome => false,
		shell => "/bin/bash",
		home => "${install_dir}",
	}
	file { "${install_dir}":
		ensure => directory,
		owner => "${rediser_user}", group => "${rediser_user}", mode => "0755",
	}
	package { ["libpcap0.8", "libssl1.0.0", "ruby-dev", "make"]:
		ensure => installed,
	}
	exec { "gem install hiredis":
                command => "/usr/bin/gem install --no-rdoc --no-ri hiredis",
                unless => "/usr/bin/gem list | /bin/grep hiredis",
                require => Package["libpcap0.8", "libssl1.0.0", "ruby-dev", "make"],
        }
	file { "${install_dir}/rediser6.rb":
		source => "puppet:///modules/${module_name}/rediser6.rb",
		owner => "${rediser_user}", group => "${rediser_user}", mode => "0644",
		require => [File["${install_dir}"], Exec["gem install hiredis"]],
	}
	file { "/etc/init.d/rediser6":
		content => template("${module_name}/rediser6.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/rediser6.rb"],
		notify => Exec["systemd_reload"],
	}
	ensure_resource( 'exec', "systemd_reload", { "command" => '/bin/systemctl daemon-reload', refreshonly => true} )
	service { "rediser6":
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/rediser6"], Exec["systemd_reload"]],
	}
}
