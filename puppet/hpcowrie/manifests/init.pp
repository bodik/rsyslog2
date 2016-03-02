#!/usr/bin/puppet apply

class hpcowrie (
	$install_dir = "/opt/cowrie",
	
	$cowrie_port = 45356,
	$cowrie_ssh_version_string = undef,
	$cowrie_user = "cowrie",

	$mysql_host = "localhost",
	$mysql_port = 3306,
	$mysql_db = "cowrie",
	$mysql_user = "cowrie",
	$mysql_password = undef,
	
	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",
) {

	if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
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

	#mysql db
        if( $mysql_db and $mysql_user) {
                mysql_database { "${mysql_db}":
                        ensure  => 'present',
                }

                if ( $mysql_password ) {
                        $mysql_password_real = $mysql_password
                } else {
                        if ( file_exists("${install_dir}/cowrie.cfg") == 1 ) {
                                $mysql_password_real = myexec("/bin/grep ^password ${install_dir}/cowrie.cfg | /usr/bin/awk -F'=' '{print \$2}'")
                                #notice("INFO: mysql ${mysql_user}@localhost secret preserved")
                        } else {
                                $mysql_password_real = myexec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print \$1}'")
                                notice("INFO: mysql ${mysql_user}@localhost secret generated")
                        }
                }
                        
                mysql_user { "${mysql_user}@localhost":
                                ensure => present,
                                password_hash => mysql_password($mysql_password_real),
				require => Mysql_database["${mysql_db}"],
                }
                mysql_grant { "${mysql_db}@localhost/${mysql_db}.*":
                                ensure     => present,
                                privileges => ["SELECT", "INSERT", "DELETE", "UPDATE"],
                                table      => "${mysql_db}.*",
                                user       => "${mysql_db}@localhost",
                                require => Mysql_user["${mysql_db}@localhost"],
                }
		exec { "install database":
			command => "/usr/bin/mysql ${mysql_db} < ${install_dir}/doc/sql/mysql.sql",
			#command runs if ret is not 0
			unless => "/usr/bin/test \"$(echo 'select count(*) from tables where TABLE_SCHEMA=\"${mysql_db}\"' | /usr/bin/mysql -Nb information_schema)\" -eq \"$(cat ${install_dir}/doc/sql/mysql.sql | grep 'CREATE TABLE' | wc -l)\" ",
			require => [ Mysql_database["${mysql_db}"], Exec["clone cowrie"] ],
		}
        }



	# application
	exec { "clone cowrie":
		#command => "/usr/bin/git clone https://github.com/desaster/kippo.git ${install_dir}",
		#command => "/usr/bin/git clone https://gitlab.labs.nic.cz/honeynet/kippo.git ${install_dir}",
		command => "/usr/bin/git clone https://github.com/micheloosterhof/cowrie.git ${install_dir}; cd ${install_dir}; git checkout 61ec8dde1f12d46d84285bb378ac2a7e8918c5d5; sh /puppet/hpcowrie/bin/postinst.sh ${install_dir}",
		creates => "${install_dir}/start.sh",
	} 
	package { ["python-twisted", "python-mysqldb", "python-simplejson"]: 
		ensure => installed, 
	}
	user { "$cowrie_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/false",
		home => "${install_dir}",
		require => [Exec["clone cowrie"]],
	}
	file { ["${install_dir}/dl", "${install_dir}/dl/tty", "${install_dir}/data", "${install_dir}/log", "${install_dir}/log/tty"]:
		owner => "$cowrie_user", group => "$cowrie_user", mode => "0755",
		require => [Exec["clone cowrie"], User["$cowrie_user"]],
	}

	$cowrie_ssh_version_strings = [
		"SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2",
		"SSH-1.99-OpenSSH_4.7",
		"SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze2",
		"SSH-2.0-Cisco-1.25",
		"SSH-2.0-OpenSSH_5.5 FIPS",
		"SSH-2.0-OpenSSH_6.6",
		"SSH-2.0-OpenSSH_5.9 FIPS",
		"SSH-2.0-V-ij-eMDESX231d"
	]

        if ( $cowrie_ssh_version_string ) {
                $corwie_ssh_version_string_real = $cowrie_ssh_version_string
        } else {
        	if ( file_exists("${install_dir}/cowrie.cfg") == 1 ) {
                	$cowrie_ssh_version_string_real = myexec("/bin/grep ^ssh_version_string ${install_dir}/cowrie.cfg | /usr/bin/awk -F'= ' '{print \$2}'")
                } else {
       			$seed = myexec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print \$1}'")
	                $cowrie_ssh_version_string_real = $cowrie_ssh_version_strings[ fqdn_rand(size($cowrie_ssh_version_strings), $seed) ]
       			notice("INFO: cowrie ssh version string generated as '$cowrie_ssh_version_string_real'")
                }
        }
	file { "${install_dir}/cowrie.cfg":
		content => template("${module_name}/cowrie.cfg.erb"),
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => [Exec["clone cowrie"], Package["python-twisted", "python-mysqldb", "python-simplejson"], File["${install_dir}/dl", "${install_dir}/dl/tty", "${install_dir}/data","${install_dir}/log", "${install_dir}/log/tty"]],
		notify => Service["cowrie"],
	}
	file { "${install_dir}/data/userdb.txt":
		source => "puppet:///modules/${module_name}/userdb.txt",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}
	file { "${install_dir}/honeyfs/etc/motd":
		source => "puppet:///modules/${module_name}/motd",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}
	file { "${install_dir}/honeyfs/etc/passwd":
		source => "puppet:///modules/${module_name}/pas-swd",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}
	file { "${install_dir}/honeyfs/etc/shadow":
		source => "puppet:///modules/${module_name}/sha-dow",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}
	file { "${install_dir}/cowrie/commands/base.py":
		source => "puppet:///modules/${module_name}/base.py",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}
	file { "${install_dir}/cowrie/commands/uname.py":
		source => "puppet:///modules/${module_name}/uname.py",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/cowrie.cfg"],
	}

	service { "fail2ban": }
	file { "/etc/fail2ban/jail.local":
		source => "puppet:///modules/${module_name}/jail.local",
		owner => "root", group => "root", mode => "0644",
		notify => Service["fail2ban"],
	}

	file { "/etc/init.d/cowrie":
		content => template("${module_name}/cowrie.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/cowrie.cfg"],
		notify => [Service["cowrie"], Exec["systemd_reload"]]
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "cowrie": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/cowrie"], Exec["systemd_reload"], Exec["install database"], Mysql_grant["${mysql_db}@localhost/${mysql_db}.*"] ],
	}


	#autotest
	package { ["medusa","sshpass"]: ensure => installed, }





	# warden_client pro kippo/cowrie (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}

	#reporting

	file { "${install_dir}/warden/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${$cowrie_user}", group => "${$cowrie_user}", mode => "0755",
        }

	file { "${install_dir}/warden/warden_sender_cowrie.py":
		source => "puppet:///modules/${module_name}/sender/warden_sender_cowrie.py",
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden/warden_client_cowrie.cfg":
		content => template("${module_name}/warden_client_cowrie.cfg.erb"),
		owner => "${cowrie_user}", group => "${cowrie_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	file { "/etc/cron.d/warden_cowrie":
		content => template("${module_name}/warden_cowrie.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$cowrie_user"],
	}
	
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register cowrie sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.cowrie -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => Exec["clone cowrie"],
	}
}
