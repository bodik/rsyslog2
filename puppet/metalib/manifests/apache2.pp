# == Class: metalib::apache2
#
# todo comment on default settings and sslvhost
#
class metalib::apache2 {
	package { "apache2": ensure => installed, }
	service { "apache2": }
	file { ["/etc/apache2/sites-enabled/000-default", "/etc/apache2/sites-enabled/000-default.conf"]:
		ensure => absent,
		require => Package["apache2"],
		notify => Service["apache2"],
	}

	#apache config
	define a2enmod() {
		exec { "a2enmod $name":
	                command => "/usr/sbin/a2enmod $name",
	                unless => "/usr/sbin/a2query -m $name",
			require => Package["apache2"],
	                notify => Service["apache2"],
	        }
	}

	a2enmod { "ssl": }

	file { "/etc/apache2/ssl":
		ensure => directory,
		owner => root, group => root, mode => 750,
		require => Package["apache2"],
	}
	exec { "install_sslselfcert.sh":
		command => "/bin/sh /puppet/metalib/bin/install_sslselfcert.sh /etc/apache2/ssl/",
		creates => "/etc/apache2/ssl/${fqdn}.crt",
		require => File["/etc/apache2/ssl"],
	}

	file { "/etc/apache2/rsyslog2.cloud.d":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
		require => Package["apache2"],
	}

	file { "/opt/rsyslog2-www":
		ensure => directory, recurse => true, purge => false,
		source => "puppet:///modules/${module_name}/opt/rsyslog2-www/",
		owner => "root", group => "root", mode => "644",
	}
	file { "/etc/apache2/sites-enabled/01rsyslog2-sslhost.conf":
                content => template("${module_name}/etc/apache2/sites-enabled/01rsyslog2-sslhost.conf.erb"),
                owner => "root", group => "root", mode => "0644",
                require => [
                        Package["apache2"],
                        A2enmod["ssl"],
			Exec["install_sslselfcert.sh"],
			File["/opt/rsyslog2-www"],
                        ],
                notify => Service["apache2"],
        }

}
