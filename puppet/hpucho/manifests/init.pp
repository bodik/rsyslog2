#!/usr/bin/puppet apply

class hpucho (
	$install_dir = "/opt/ucho",
	
	$port_start = 1,
	$port_end = 9999,
	$port_skip = "[1433,65535]",
	
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
	file { "${install_dir}/ucho.py":
		source => "puppet:///modules/${module_name}/ucho.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
		notify => Service["ucho"],
	}
	package { ["python-twisted"]: 
		ensure => installed, 
	}

	file { "/etc/init.d/ucho":
		content => template("${module_name}/ucho.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}/ucho.py", "${install_dir}/warden_client-ucho.cfg"],
	}
	service { "ucho": 
		enable => true,
		ensure => running,
		require => File["/etc/init.d/ucho", "${install_dir}/ucho.py"],
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
	file { "${install_dir}/warden_client-ucho.cfg":
		content => template("${module_name}/warden_client-ucho.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
		notify => Service["ucho"],
	}
	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register ucho sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ucho -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
