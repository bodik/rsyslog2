# == Class: glastopf
#
# Install glastopf honeypot and logstash consuming it's logs 
#
class glastopf {

	package { 
		["python", "python-openssl", "python-gevent", "libevent-dev", "python-dev", "build-essential", "make",
		"python-argparse", "python-chardet", "python-requests", "python-sqlalchemy", "python-lxml",
		"python-beautifulsoup", "python-pip", "python-setuptools", "python-greenlet",
		"g++", "git", "php5", "php5-dev", "liblapack-dev", "gfortran",
		"libxml2-dev", "libxslt1-dev",
		"libmysqlclient-dev",
		]: 
		ensure => installed,
	}

	$api_version = "20131226"
	exec { "/puppet/glastopf/bin/make-bfr.sh":
		command => "/bin/sh /puppet/glastopf/bin/make-bfr.sh",
		creates => "/usr/lib/php5/${api_version}/bfr.so",
		require => Package["php5-dev"],
	}
	
	file { "/etc/php5/cli/conf.d/bfr.ini":
		content => template("${module_name}/bfr.ini.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [Package["php5"], Exec["/puppet/glastopf/bin/make-bfr.sh"]],
	}

	exec { "pip install glastopf":
                command => "/usr/bin/pip install glastopf",
                creates => "/usr/local/lib/python2.7/dist-packages/glastopf/glastopf.cfg.dist",
		require => [Package["python-pip", "python-setuptools", "python-dev"], File["/etc/php5/cli/conf.d/bfr.ini"]],
        }


	#perun mi ji krade
 	package { ["perun-slave", "perun-slave-meta"]: ensure => absent }	
	user { "glastopf":
		ensure => present,
		require => Package["perun-slave", "perun-slave-meta"],
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
		unless => "/sbin/getcap /usr/bin/python2.7 | /bin/grep cap_net_bind_service",
		require => Package["python"],
	}

	service { "apache2":
		ensure => stopped,
		require => Exec["pip install glastopf"],
	}
	service { "glastopf":
		ensure => running,
		provider => init,
		require => [File["/opt/glastopf/glastopf.cfg"], File["/etc/init.d/glastopf"], Exec["pip install glastopf"], Service["apache2"], Exec["python cap_net"]],
	}
	
	class { "glastopf::lsl":
		require => Service["glastopf"],
	}
}
