#!/usr/bin/puppet apply

class hpelastichoney (
	$install_dir = "/opt/elastichoney",

	$elastichoney_user = "elhon",
	
	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",

	$logfile = "elastichoney.log",

) {

	if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }

	# application
	user { "$elastichoney_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/bash",
		home => "${install_dir}",
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => User["$elastichoney_user"],
	}
	file { "${install_dir}/elastichoney":
		source => "puppet:///modules/${module_name}/elastichoney",
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => File["${install_dir}"],
		notify => Service["elastichoney"],
	}
	file { "${install_dir}/config.json":
		content => template("${module_name}/config.json.erb"),
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0644",
		require => File["${install_dir}"],
		notify => Service["elastichoney"],
	}
	file { "/etc/init.d/elastichoney":
		content => template("${module_name}/elastichoney.init.erb"),
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => File["${install_dir}/elastichoney", "${install_dir}/warden_client-elastichoney.cfg", "${install_dir}/config.json"],
		notify => [Service["elastichoney"], Exec["systemd_reload"]],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "elastichoney": 
		enable => true,
		ensure => running,
		provider => init,
		require => [File["/etc/init.d/elastichoney", "${install_dir}/elastichoney"], Exec["systemd_reload"]],
	}


	#autotest
	#package { ["netcat"]: ensure => installed, }


	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/warden_client.py",
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0640",
		require => File["${install_dir}"],
	}
	package { ["python-dateutil"]: ensure => installed, }
	file { "${install_dir}/warden3-elastichoney-sender.py":
		source => "puppet:///modules/${module_name}/warden3-elastichoney-sender.py",
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden_client-elastichoney.cfg":
		content => template("${module_name}/warden_client-elastichoney.cfg.erb"),
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "/etc/cron.d/warden-elastichoney":
		content => template("${module_name}/warden-elastichoney.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$elastichoney_user"],
	}
	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register elastichoney sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n elastichoney -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
