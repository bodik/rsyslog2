#!/usr/bin/puppet apply

class hpjdwpd (
	$install_dir = "/opt/jdwpd",

	$jdwpd_user = "jdwpd",
	$jdwpd_port = 58000,
	$jdwpd_logfile = "jdwpd.log",
	
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

	# application
	user { "$jdwpd_user": 	
		ensure => present, 
		managehome => false,
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "$jdwpd_user", group => "$jdwpd_user", mode => "0755",
		require => User["$jdwpd_user"],
	}
	package { ["python-twisted"]:
		ensure => installed, 
	}                            	
	file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${jdwpd_user}", group => "${jdwpd_user}", mode => "0755",
                require => File["${install_dir}"],
        }
	file { "${install_dir}/jdwpd.py":
		source => "puppet:///modules/${module_name}/jdwpd.py",
		owner => "$jdwpd_user", group => "$jdwpd_user", mode => "0755",
		require => File["${install_dir}", "${install_dir}/warden_utils_flab.py"],
	}



    	file { "${install_dir}/jdwpd.cfg":
                content => template("${module_name}/jdwpd.cfg.erb"),
                owner => "$jdwpd_user", group => "$jdwpd_user", mode => "0644",
                require => File["${install_dir}/jdwpd.py"],
        }
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	file { "/etc/init.d/jdwpd":
		content => template("${module_name}/jdwpd.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/jdwpd.py", "${install_dir}/jdwpd.cfg"]],
		notify => Exec["systemd_reload"],
	}
	service { "jdwpd": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/jdwpd"], Exec["systemd_reload"]],
	}


	#autotest
	package { ["netcat"]: ensure => installed, }


	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$jdwpd_user", group => "$jdwpd_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$jdwpd_user", group => "$jdwpd_user", mode => "0640",
		require => File["${install_dir}"],
	}

	# reporting
	file { "${install_dir}/warden_sender_jdwpd.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_jdwpd.py",
                owner => "${jdwpd_user}", group => "${jdwpd_user}", mode => "0755",
        	require => File["${install_dir}/warden_utils_flab.py"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
   	file { "${install_dir}/warden_client_jdwpd.cfg":
                content => template("${module_name}/warden_client_jdwpd.cfg.erb"),
                owner => "$jdwpd_user", group => "$jdwpd_user", mode => "0755",
                require => File["${install_dir}/jdwpd.py", "${install_dir}/warden_sender_jdwpd.py"],
        }
    	file { "/etc/cron.d/warden_jdwpd":
                content => template("${module_name}/warden_jdwpd.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$jdwpd_user"],
        }

	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}

	exec { "register jdwpd sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.jdwpd -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}
}
