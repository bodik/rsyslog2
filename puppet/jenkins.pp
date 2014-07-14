#!/usr/bin/puppet

import '/puppet/lib.pp'

package { ["debootstrap", "qemu-kvm", "qemu-utils", "grub-pc"]:
	ensure => installed,
}
package { ["dbus"]:
	ensure => absent,
}

file { "/etc/apt/sources.list.d/jenkins.list":
	source => "/puppet/templates/etc/apt/sources.list.d/jenkins.list",
	owner => "root", group => "root", mode => "0644",
	notify => Exec["apt-get update"],
}

#kvuli generovani image musi mit jenkins sudo, beztak je to super chlapek
package { ["jenkins", "sudo"]:
	ensure => installed,
	require => [File["/etc/apt/sources.list.d/jenkins.list"], Exec["apt-get update"]],
}

file { "/etc/sudoers.d/jenkins":
	source => "/puppet/jenkins/jenkins.sudoers",
	#TODO: enforce /puppet 640 jinak to nema smysl :)
	owner => "root", group => "root", mode => "0640",
	require => Package["sudo"],
}

user { "jenkins":
	groups => ["kvm"],
	require => [Package["jenkins"], Package["sudo"]],
}
augeas { "/etc/default/jenkins" :
	context => "/files/etc/default/jenkins",
	changes => [
		"set HTTP_PORT 8081"
	],
	require => Package["jenkins"],
	notify => Service["jenkins"],
}

service { "jenkins": }
file { "/var/lib/jenkins/jobs":
	ensure => directory,
	source => "/puppet/jenkins/jobs",
	recurse => true,
	owner => "jenkins", group=> "nogroup", mode=>"0644",
	notify => Service["jenkins"],
	require => User["jenkins"],
}


#metacloud
package { ["libexpat1-dev", "libcurl4-openssl-dev", "rake", "libxml2-dev", "libxslt1-dev", "gcc", "libopenssl-ruby", "make", "ruby-dev"]:
	ensure => installed,
}

file { "/root/.one":
	ensure => link,
	target => "/dev/shm",
}
file { "/var/lib/jenkins/.one":
	ensure => link,
	target => "/dev/shm",
	require => Package["jenkins"],
}
exec { "gem_install_opennebula-cli":
	command => "/usr/bin/gem install opennebula-cli -v '~> 4.4.0'",
	unless => "/usr/bin/gem list | grep opennebula-cli",
	require => [Package["ruby-dev"], Package["make"]],
}

file { "/usr/local/bin/metacloud.init":
	ensure => link,
	target => "/puppet/jenkins/metacloud.init",
}
file { "/usr/local/bin/magrathea.init":
	ensure => link,
	target => "/puppet/jenkins/magrathea.init",
}


