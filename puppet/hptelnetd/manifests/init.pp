#!/usr/bin/puppet apply

class hptelnetd (
	$install_dir = "/opt/telnetd",

	$telnetd_user = "root",

	$telnetd_port = 63023,

	$logfile = "telnetd.log",	
	
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
	user { "$telnetd_user": 	
		ensure => present, 
		managehome => false,
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => User["$telnetd_user"],
	}
	file { "${install_dir}/telnetd.py":
		source => "puppet:///modules/${module_name}/telnetd.py",
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => File["${install_dir}"],
	}
	package { ["python-twisted"]:
		ensure => installed, 
	}
	
    	file { "${install_dir}/telnetd.cfg":
                content => template("${module_name}/telnetd.cfg.erb"),
                owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
                require => File["${install_dir}/telnetd.py"],
        }

	file { "/etc/init.d/telnetd":
		content => template("${module_name}/telnetd.init.erb"),
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => File["${install_dir}/telnetd.py", "${install_dir}/telnetd.cfg"],
	}
	service { "telnetd": 
		enable => true,
		ensure => running,
		require => File["/etc/init.d/telnetd", "${install_dir}/telnetd.py"],
	}


	#autotest
	package { ["netcat"]: ensure => installed, }


	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$telnetd_user", group => "$telnetd_user", mode => "0640",
		require => File["${install_dir}"],
	}

	# reporting

	file { "${install_dir}/w3utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/w3utils_flab.py",
                owner => "${telnetd_user}", group => "${telnetd_user}", mode => "0755",
        }
	file { "${install_dir}/warden3-telnetd-sender.py":
                source => "puppet:///modules/${module_name}/sender/warden3-telnetd-sender.py",
                owner => "${telnetd_user}", group => "${telnetd_user}", mode => "0755",
        	require => File["${install_dir}/w3utils_flab.py"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
   	file { "${install_dir}/warden_client-telnetd.cfg":
                content => template("${module_name}/warden_client-telnetd.cfg.erb"),
                owner => "$telnetd_user", group => "$telnetd_user", mode => "0755",
                require => File["${install_dir}/telnetd.py","${install_dir}/w3utils_flab.py","${install_dir}/warden3-telnetd-sender.py"],
        }
    	file { "/etc/cron.d/warden-telnetd":
                content => template("${module_name}/warden-telnetd.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$telnetd_user"],
        }

	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}

	exec { "register telnetd sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n telnetd -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}
}
