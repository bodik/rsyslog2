#!/usr/bin/puppet apply

class hpucho::udp (
	$install_dir = "/opt/uchoudp",

	$uchoudp_user = "uchoudp",
	
	$port_start = 1,
	$port_end = 32768,
	$port_skip = "[67, 137, 138, 1433, 5678, 65535]",

	$logfile = "uchoudp.log",
		
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
	user { "$uchoudp_user":
                ensure => present,
                managehome => false,
        }

	file { "${install_dir}":
		ensure => directory,
		owner => "$uchoudp_user", group => "$uchoudp_user", mode => "0755",
	}
	file { "${install_dir}/uchoudp.py":
		source => "puppet:///modules/${module_name}/uchoudp/uchoudp.py",
		owner => "$uchoudp_user", group => "$uchoudp_user", mode => "0755",
		require => File["${install_dir}"],
		notify => Service["uchoudp"],
	}
        file { "${install_dir}/uchoudp.cfg":
                content => template("${module_name}/uchoudp.cfg.erb"),
                owner => "$uchoudp_user", group => "$uchoudp_user", mode => "0755",
                require => File["${install_dir}/uchoudp.py"],
        }
	package { ["python", "python-twisted", "python-scapy"]: 
		ensure => installed, 
	}
	package { "libcap2-bin": ensure => installed }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
		unless => "/sbin/getcap /usr/bin/python2.7 | grep cap_net_bind_service",
		require => [Package["python"], Package["libcap2-bin"]]
	}

	file { "/etc/init.d/uchoudp":
		content => template("${module_name}/uchoudp.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/uchoudp.py", "${install_dir}/uchoudp.cfg"] , Exec["python cap_net"]],
		notify => [Service["uchoudp"], Exec["systemd_reload"]]
	}
	file { "/lib/systemd/system/uchoudp.service":
		content => template("${module_name}/uchoudp.service.erb"),
		owner => "root", group => "root", mode => "0644",
		require => File["/etc/init.d/uchoudp"],
		notify => [Service["uchoudp"], Exec["systemd_reload"]]
	}

	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "uchoudp": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/uchoudp", "/lib/systemd/system/uchoudp.service"], Exec["systemd_reload"]],
	}


	#autotest
	package { ["netcat"]: ensure => installed, }


	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$uchoudp_user", group => "$uchoudp_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$uchoudp_user", group => "$uchoudp_user", mode => "0640",
		require => File["${install_dir}"],
	}

        # reporting

        file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${uchoudp_user}", group => "${uchoudp_user}", mode => "0755",
        }
        file { "${install_dir}/warden_sender_uchoudp.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchoudp.py",
                owner => "${uchoudp_user}", group => "${uchoudp_user}", mode => "0755",
                require => File["${install_dir}/warden_utils_flab.py"],
        }
 	file { "${install_dir}/${logfile}":
                ensure  => 'present',
                replace => 'no',
                owner => "${uchoudp_user}", group => "${uchoudp_user}", mode => "0644",
                content => "",
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/warden_client_uchoudp.cfg":
                content => template("${module_name}/warden_client_uchoudp.cfg.erb"),
                owner => "$uchoudp_user", group => "$uchoudp_user", mode => "0755",
                require => File["${install_dir}/uchoudp.py","${install_dir}/warden_utils_flab.py","${install_dir}/warden_sender_uchoudp.py"],
        }
        file { "/etc/cron.d/warden_uchoudp":
                content => template("${module_name}/warden_uchoudp.cron.erb"),
                owner => "root", group => "root", mode => "0644",
        #        require => User["$uchoudp_user"],
        }

	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register uchoudp sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.uchoudp -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}


}
