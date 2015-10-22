# == Class: jenkins
#
# Class provides Jenkins installation from vendor repository packages and
# configures basic set of jobs for building host with specified roles as well
# as running autotests at the ends of the scenarios.
#
# === Examples
#
#  class { jenkins: }
#
class jenkins() {
	include metalib::base

	apt::source { 'jenkins':
		location   => 'http://pkg.jenkins-ci.org/debian',
		release => 'binary/',
		repos => '',
		include_src => false,
        	key         => 'D50582E6',
	        key_source  => 'http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key',
	}

	package { ["jenkins"]:
		ensure => installed,
		require => Apt::Source["jenkins"],
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
		source => "puppet:///modules/${module_name}/jobs",
		recurse => true,
		owner => "jenkins", group=> "jenkins", mode=>"0644",
		require => Package["jenkins"],
		notify => Service["jenkins"],
	}

	#metacloud
	package { ["libexpat1-dev", "libcurl4-openssl-dev", "rake", "libxml2-dev", "libxslt1-dev", "zlib1g-dev", "gcc", "make", "ruby-dev"]:
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
		command => "/usr/bin/gem install opennebula-cli",
		unless => "/usr/bin/gem list | grep opennebula-cli",
		require => [Package["ruby-dev"], Package["make"]],
	}
	file { "/usr/local/bin/metacloud.init":
		ensure => link,
		target => "/puppet/jenkins/bin/metacloud.init",
	}

	#magrathea
	file { "/usr/local/bin/magrathea.init":
		ensure => link,
		target => "/puppet/jenkins/bin/magrathea.init",
	}
}

