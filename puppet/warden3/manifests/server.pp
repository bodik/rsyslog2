# == Class: warden3::server
#
# Class will ensure installation of warden3 server: apache2, wsgi, server, mysqldb, configuration
#
# === Parameters
#
# [*install_dir*]
#   directory to install w3 server
#
# [*port*]
#   port number to listen with apache vhost
#
# [*mysql_... *]
#   parameters for mysql database for w3 server
#
# [*avahi_enable*]
#   enable service announcement, enabled by default. for testing and debugging purposes
#
class warden3::server (
	#params ...
	$install_dir = "/opt/warden_server",
	$port = 45443,

	$mysql_host = "localhost",
	$mysql_port = 3306,
        $mysql_db = "warden3",
        $mysql_user = "warden3",
        $mysql_password = false,

	$avahi_enable = true,
) {

	if ($avahi_enable) {
		include metalib::avahi
	        file { "/etc/avahi/services/warden-server.service":
	                content => template("${module_name}/warden-server.service.erb"),
	                owner => "root", group => "root", mode => "0644",
	                require => Package["avahi-daemon"],
	                notify => Service["avahi-daemon"],
	        }
	}

	#mysql server
	#package { "mysql-server": ensure => installed, }
	class { 'mysql::server':
		manage_config_file => false,
	}
	#puppet module auth
	file { "/etc/mysql/debian.cnf":
	        owner => "root", group => "root", mode => "0600",
	        require => Package["mysql-server"],
	}
	file { "/root/.my.cnf":
	        ensure => "link",
	        target => "/etc/mysql/debian.cnf",
	        require => [Package["mysql-server"], File["/etc/mysql/debian.cnf"]],
	}




	#warden3

	#datastore
        if( $mysql_db and $mysql_user) {
                mysql_database { "${mysql_db}":
                        ensure  => 'present',
                }

                if ( $mysql_password ) {
                        $mysql_password_real = $mysql_password
                } else {
                        if ( file_exists("${install_dir}/warden_server.cfg") == 1 ) {
                                $mysql_password_real = warden_config_dbpassword("${install_dir}/warden_server.cfg")
                                #notice("INFO: mysql ${mysql_user}@localhost secret preserved")
                        } else {
                                $mysql_password_real = myexec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print \$1}'")
                                notice("INFO: mysql ${mysql_user}@localhost secret generated")
                        }
                }
                        
                mysql_user { "${mysql_user}@localhost":
                                ensure => present,
                                password_hash => mysql_password($mysql_password_real),
                }
                mysql_grant { "${mysql_db}@localhost/${mysql_db}.*":
                                ensure     => present,
                                privileges => ["SELECT", "INSERT", "DELETE", "UPDATE"],
                                table      => "${mysql_db}.*",
                                user       => "${mysql_user}@localhost",
                                require => Mysql_user["${mysql_user}@localhost"],
                }
        }

	#server application
	package { ["python-mysqldb", "python-m2crypto", "python-pip", "rsyslog"]: ensure => installed, }
	package { ["jsonschema", "functools32"]:
		ensure => installed,
		provider => "pip",
		require => Package["python-pip"],
	}

	file { "$install_dir":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}

	$sources = "puppet:///modules/${module_name}/opt/warden_server/"
	file { "${install_dir}/warden_server.wsgi":
		source => "${sources}warden_server.wsgi.dist",
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/warden_server.py":
		source => "${sources}/warden_server.py",
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/catmap_mysql.json":
		source => "${sources}/catmap_mysql.json",
		owner => "root", group => "root", mode => "0644",
	}
	file { "${install_dir}/tagmap_mysql.json":
		source => "${sources}/tagmap_mysql.json",
		owner => "root", group => "root", mode => "0644",
	}
	file { "${install_dir}/idea.schema":
		source => "${sources}/idea.schema",
		owner => "root", group => "root", mode => "0644",
	}
	file { "${install_dir}/warden_server.cfg":
		content => template("${module_name}/warden_server.cfg.erb"),
		owner => "root", group => "www-data", mode => "0640",
	}




	#apache2
	package { ["apache2", "libapache2-mod-wsgi"]: ensure => installed, }
	service { "apache2": }
	file { ["/etc/apache2/mods-enabled/cgid.conf", "/etc/apache2/mods-enabled/cgid.load", "/etc/apache2/sites-enabled/000-default"]: 
		ensure => absent,
		require => Package["apache2"],
		notify => Service["apache2"],
	}
	exec { "a2enmod ssl":
		command => "/usr/sbin/a2enmod ssl",
		unless => "/usr/sbin/a2query -m ssl",
		notify => Service["apache2"],
	}
	warden3::hostcert { "hostcert":
		#there might be a better idea to have avahi service for warden_ca, but for simplicity and puppet2.7 we just use fqdn
		warden_server => $fqdn,
		require => File["/etc/avahi/services/warden-server.service"],
	}
	file { "/etc/apache2/sites-enabled/00warden3.conf":
		content => template("${module_name}/warden3-virtualhost.conf.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [
			Package["apache2", "libapache2-mod-wsgi"], 
			Warden3::Hostcert["hostcert"],
			Exec["a2enmod ssl"],
			],
		notify => Service["apache2"],
	}

	#tests
	#already in warden3::hostcert
	#package { "curl": ensure => installed, }

}


