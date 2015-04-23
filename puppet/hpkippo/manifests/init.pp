#!/usr/bin/puppet apply

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
	
	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",
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

	#mysql db
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



	# application
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
		owner => "${kippo_user}", group => "${kippo_user}", mode => "0640",
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





	# warden_client pro kippo
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${kippo_user}", group => "${kippo_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/warden_client.py",
		owner => "${kippo_user}", group => "${kippo_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	file { "${install_dir}/warden/warden3-kippo-sender.py":
		source => "puppet:///modules/${module_name}/warden3-kippo-sender.py",
		owner => "${kippo_user}", group => "${kippo_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$sensor_ip4 = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*$/.x.x/'")
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden/warden_client-kippo.cfg":
		content => template("${module_name}/warden_client-kippo.cfg.erb"),
		owner => "${kippo_user}", group => "${kippo_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}


	if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${kippo_user}", group => "${kippo_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	exec { "register kippo sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh ${warden_server_real} kippo ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => Exec["clone kippo"],
	}

	file { "/etc/cron.d/warden-kippo-sender":
		content => template("${module_name}/warden-kippo-sender.cron.erb"),
		owner => "root", group => "root", mode => "0644",
	}

}
