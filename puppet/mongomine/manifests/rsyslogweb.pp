#!/usr/bin/puppet

class mongomine::rsyslogweb {
	notice($name)


	package { ["apache2", "libapache2-mod-wsgi", "python-pip", "python-dateutil", "python-geoip"]:
		ensure => installed,
		notify => Service["apache2"],
	}
	service { "apache2": 
		ensure => running,
	}
	package { ["bottle", "pymongo"]:
		ensure => installed,
		provider => "pip",	
		notify => Service["apache2"],
	}
	file { "/opt/rsyslogweb":
		ensure => directory,
		source => "puppet:///modules/${module_name}/opt/rsyslogweb",
		recurse => "true",
		owner => "root", group => "root", mode => "0644",
	}
	
	file  { "/etc/apache2/conf.d/rsyslogweb.conf":
		ensure => link,
		source => "puppet:///modules/${module_name}/opt/rsyslogweb/apache-proxy-bottle.conf",
		owner => "root", group => "root", mode => "0644",
		require => [Package["libapache2-mod-wsgi"], File["/opt/rsyslogweb"]],
		notify => Service["apache2"],
	}




	package { ["libapache2-mod-php5", "php-pear", "php5-dev"]:
		ensure => installed,
		notify => Service["apache2"],
	}
	exec { ["pecl install mongo"]:
		command => "/usr/bin/pecl install mongo",
		unless => "/usr/bin/pecl list | grep mongo",
		require => [Package["php5-dev"], Package["php-pear"]],
		notify => Service["apache2"],
	}
	file { "/etc/php5/conf.d/mongo.ini":
		source => "puppet:///modules/${module_name}/etc/php5/conf.d/mongo.ini",
		owner => "root", group => "root", mode => "0644",
		require => [Package["libapache2-mod-php5"], Exec["pecl install mongo"]],
		notify => Service["apache2"],
	}
	file { "/opt/rock":
		ensure => directory,
		source => "puppet:///modules/${module_name}/opt/rock",
		recurse => "true",
		owner => "root", group => "root", mode => "0644",
	}
}

