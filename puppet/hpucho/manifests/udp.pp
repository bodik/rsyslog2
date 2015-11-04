#!/usr/bin/puppet apply

class hpucho::udp (
	$install_dir = "/opt/uchoudp",
	
	$port_start = 1,
	$port_end = 32768,
	$port_skip = "[67, 137, 138, 1433, 5678, 65535]",
	
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
	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/uchoudp.py":
		source => "puppet:///modules/${module_name}/uchoudp.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
		notify => Service["uchoudp"],
	}
	package { ["python-twisted", "python-scapy"]: 
		ensure => installed, 
	}

	file { "/etc/init.d/uchoudp":
		content => template("${module_name}/uchoudp.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/uchoudp.py", "${install_dir}/warden_client-uchoudp.cfg"],
		notify => [Service["uchoudp"], Exec["systemd_reload"]]
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "uchoudp": 
		enable => true,
		ensure => running,
		provider => init,
		require => [File["/etc/init.d/uchoudp", "${install_dir}/uchoudp.py"], Exec["systemd_reload"]],
	}


	#autotest
	package { ["netcat"]: ensure => installed, }




	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/warden_client.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden_client-uchoudp.cfg":
		content => template("${module_name}/warden_client-uchoudp.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
		notify => Service["uchoudp"],
	}
	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register uchoudp sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n uchoudp -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
