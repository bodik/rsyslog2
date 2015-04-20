#documentation: tbd

class warden3::server (
	#params ...
	$install_dir = "/opt/warden_server",
	$ca_dir = "/opt/warden_ca",
	$port = 45443,

	$mysql_host = "localhost",
	$mysql_port = 3306,
        $mysql_db = "warden3",
        $mysql_user = "warden3",
        $mysql_password = false,

	$avahi_enable = true,
) {

	include warden3::ca

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
                                privileges => ["SELECT", "INSERT", "DELETE"],
                                table      => "${mysql_db}.*",
                                user       => "${mysql_user}@localhost",
                                require => Mysql_user["${mysql_user}@localhost"],
                }
        }

	#server application
	package { ["python-mysqldb", "python-m2crypto", "python-pip"]: ensure => installed, }
	package { "jsonschema":
		ensure => installed,
		provider => "pip",
		require => Package["python-pip"],
	}
	file { "$install_dir":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}

	#$sources = "/warden/warden3/warden_server/"
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
	}
	file { "/etc/apache2/mods-enabled/ssl.load":        ensure => "link",        target => "../mods-available/ssl.load",
	        require => Package["apache2"]
	}
	file { "/etc/apache2/mods-enabled/ssl.conf":        ensure => "link",        target => "../mods-available/ssl.conf",
	        require => Package["apache2"]
	}

	exec { "gen cert":
		command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca_local.sh ${install_dir}/etc",
		creates => "${install_dir}/etc/${fqdn}.crt",
		#require => Class["warden3::ca"],
		require => [File["${ca_dir}/puppet.conf"], File["${ca_dir}/warden_ca.sh"]],
	}

	file { "/etc/apache2/sites-enabled/00warden3.conf":
		content => template("${module_name}/apache2-virtualhost.conf.rb"),
		owner => "root", group => "root", mode => "0644",
		require => [
			Package["apache2", "libapache2-mod-wsgi"], 
			Exec["gen cert"], 
			File["/etc/apache2/mods-enabled/ssl.load", "/etc/apache2/mods-enabled/ssl.conf"], 
			],
		notify => Service["apache2"],
	}

	#tests
	package { "curl": ensure => installed, }


}


