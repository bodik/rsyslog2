#!/usr/bin/puppet apply

class hpucho::tcp (
	$install_dir = "/opt/uchotcp",

	$uchotcp_user = "root",
	
	$port_start = 1,
	$port_end = 9999,
	$port_skip = "[1433,65535]",

	$logfile = "uchotcp.log",
	
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
	user { "$uchotcp_user":
                ensure => present,
                managehome => false,
        }

	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/uchotcp.py":
		source => "puppet:///modules/${module_name}/uchotcp/uchotcp.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
		notify => Service["uchotcp"],
	}
        file { "${install_dir}/uchotcp.cfg":
                content => template("${module_name}/uchotcp.cfg.erb"),
                owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
                require => File["${install_dir}/uchotcp.py"],
        }
	package { ["python-twisted"]: 
		ensure => installed, 
	}

	file { "/etc/init.d/uchotcp":
		content => template("${module_name}/uchotcp.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/uchotcp.py", "${install_dir}/uchotcp.cfg"],
		notify => [Service["uchotcp"], Exec["systemd_reload"]]
	}

	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "uchotcp": 
		enable => true,
		ensure => running,
		provider => init,
		require => [File["/etc/init.d/uchotcp", "${install_dir}/uchotcp.py"], Exec["systemd_reload"]]
	}


	#autotest
	package { ["netcat"]: ensure => installed, }


	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}

        # reporting

        file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${uchotcp_user}", group => "${uchotcp_user}", mode => "0755",
        }
        file { "${install_dir}/warden_sender_uchotcp.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchotcp.py",
                owner => "${uchotcp_user}", group => "${uchotcp_user}", mode => "0755",
                require => File["${install_dir}/warden_utils_flab.py"],
        }
 	file { "${install_dir}/${logfile}":
    		ensure  => 'present',
    		replace => 'no',
                owner => "${uchotcp_user}", group => "${uchotcp_user}", mode => "0644",
    		content => "",
  	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/warden_client_uchotcp.cfg":
                content => template("${module_name}/warden_client_uchotcp.cfg.erb"),
                owner => "$uchotcp_user", group => "$uchotcp_user", mode => "0755",
                require => File["${install_dir}/uchotcp.py","${install_dir}/warden_utils_flab.py","${install_dir}/warden_sender_uchotcp.py"],
        }
        file { "/etc/cron.d/warden_uchotcp":
                content => template("${module_name}/warden_uchotcp.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$uchotcp_user"],
        }
		
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register uchotcp sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n uchotcp -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
