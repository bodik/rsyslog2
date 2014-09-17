# == Class: glastopf
#
# Full description of class glastopf here.
#
# === Examples
#
#  class { glastopf: }
#
# === Authors
#
# bodik@cesnet.cz
#
class glastopf {

	package { 
		["python", "python-openssl", "python-gevent", "libevent-dev", "python-dev", "build-essential", "make",
		"python-argparse", "python-chardet", "python-requests", "python-sqlalchemy", "python-lxml",
		"python-beautifulsoup", "mongodb", "python-pip", "python-setuptools",
		"g++", "git", "php5", "php5-dev", "liblapack-dev", "gfortran",
		"libxml2-dev", "libxslt1-dev",
		"libmysqlclient-dev",
		]: 
		ensure => installed,
	}

	package { "distribute":
		ensure => latest,
		provider => "pip",
		require => Package["python-pip"],
	}
	package { "greenlet":
		ensure => latest,
		provider => "pip",
		require => Package["python-pip"],
	}

	$api_version = "20100525"
	exec { "/puppet/glastopf/make-bfr.sh":
		command => "/bin/sh /puppet/glastopf/make-bfr.sh",
		creates => "/usr/lib/php5/${api_version}/bfr.so",
		require => Package["php5-dev"],
	}
	
	file { "/etc/php5/conf.d/bfr.ini":
		content => template("${module_name}/bfr.ini.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [Package["php5"], Exec["/puppet/glastopf/make-bfr.sh"]],
	}

	package { "glastopf":
		ensure => installed,
		provider => "pip",
		require => [Package["python-pip"], File["/etc/php5/conf.d/bfr.ini"]],
	}

	#perun mi ji krade
	group { "glastopf":
		ensure => present,
	}
	user { "glastopf":
		ensure => present,
		require => Group["glastopf"],
	}
	file { "/opt/glastopf":
		ensure => directory,
		group => "glastopf", owner => "glastopf", mode => "0644",
		require => User["glastopf"],
	}
	file { "/opt/glastopf/glastopf.init":
		content => template("${module_name}/glastopf.init"),
		group => "root", owner => "root", mode => "0755",
		require => File["/opt/glastopf"],
	}
	file { "/etc/init.d/glastopf":
		ensure => link,
		target => "/opt/glastopf/glastopf.init",
		require => File["/opt/glastopf/glastopf.init"],
	}
	file { "/opt/glastopf/glastopf.cfg":
		content => template("${module_name}/glastopf.cfg"),
		group => "root", owner => "root", mode => "0644",
		require => File["/opt/glastopf"],
	}

	package { "libcap2-bin": ensure => installed }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
		unless => "/sbin/getcap /usr/bin/python2.7 | grep cap_net_bind_service",
		require => Package["python"],
	}

	service { "apache2":
		ensure => stopped,
		require => Package["glastopf"],
	}
	service { "glastopf":
		ensure => running,
		require => [File["/opt/glastopf/glastopf.cfg"], File["/etc/init.d/glastopf"], Package["glastopf"], Service["apache2"], Exec["python cap_net"]],
	}

}
