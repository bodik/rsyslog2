# == Class: hpkippo
#
# Full description of class hpkippo here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { hpkippo:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2011 Your name here, unless otherwise noted.
#
class hpkippo (

	$install_dir = "/opt/kippo",
	
	$kippo_port = 45356,
	$kippo_ssh_version_string = "SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2",
	$kippo_user = "kippo",

	$mysql_host = "localhost",
	$mysql_port = 3306,
	$mysql_db = "kippo",
	$mysql_user = "kippo",
	$mysql_password = undef,
) {


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


        if( $mysql_db and $mysql_user) {
                mysql_database { "${mysql_db}":
                        ensure  => 'present',
                }

                if ( $mysql_password ) {
                        $mysql_password_real = $mysql_password
                } else {
                        if ( file_exists("${install_dir}/kippo.cfg") == 1 ) {
                                $mysql_password_real = myexec("/bin/grep ^password ${install_dir}/kippo.cfg | /usr/bin/awk -F'=' '{print \$2}'")
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
                                user       => "${mysql_db}@localhost",
                                require => Mysql_user["${mysql_db}@localhost"],
                }
        }


	exec { "clone kippo":
		command => "/usr/bin/git clone https://github.com/desaster/kippo.git ${install_dir}",
		creates => "${install_dir}/start.sh",
	}
	package { ["python-twisted", "python-mysqldb"]: 
		ensure => installed, 
	}
	# no cap needed now, using prerouting in kippo.init
	#package { "libcap2-bin": ensure => installed }
	#exec { "python bind cap":
	#	command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
	#	unless => "/sbin/getcap /usr/bin/python2.7 | grep 'cap_net_bind_service+ep'",
	#	require => Package["libcap2-bin"],
	#}
	user { "$kippo_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/false",
		home => "${install_dir}",
		require => [Exec["clone kippo"]],
	}
	file { ["${install_dir}/dl", "${install_dir}/data", "${install_dir}/log", "${install_dir}/log/tty"]:
		owner => "$kippo_user", group => "$kippo_user", mode => "0755",
		require => [Exec["clone kippo"], User["$kippo_user"]],
	}
	file { "${install_dir}/kippo.cfg":
		content => template("${module_name}/kippo.cfg.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [Exec["clone kippo"], Package["python-twisted", "python-mysqldb"], File["${install_dir}/dl", "${install_dir}/data","${install_dir}/log", "${install_dir}/log/tty"]],
	}

	service { "fail2ban": }
	file { "/etc/fail2ban/jail.local":
		source => "puppet:///modules/${module_name}/jail.local",
		owner => "root", group => "root", mode => "0644",
		notify => Service["fail2ban"],
	}

	file { "/etc/init.d/kippo":
		content => template("${module_name}/kippo.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/kippo.cfg"],
	}
	service { "kippo": 
		enable => true,
		ensure => running,
		require => File["/etc/init.d/kippo"],
	}


	#autotest
	package { "medusa": ensure => installed, }

}
