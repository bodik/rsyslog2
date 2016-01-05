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
		require => File["${install_dir}/elastichoney", "${install_dir}/warden_client_elastichoney.cfg", "${install_dir}/config.json"],
		notify => [Service["elastichoney"], Exec["systemd_reload"]],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "elastichoney": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/elastichoney"], Exec["systemd_reload"]],
	}


	#autotest
	#package { ["netcat"]: ensure => installed, }


	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0640",
		require => File["${install_dir}"],
	}

	#reporting

 	file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${elastichoney_user}", group => "${elastichoney_user}", mode => "0755",
        }
	package { ["python-dateutil"]: ensure => installed, }
	file { "${install_dir}/warden_sender_elastichoney.py":
		source => "puppet:///modules/${module_name}/sender/warden_sender_elastichoney.py",
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0755",
		require => File["${install_dir}"],
	}
 	file { "${install_dir}/${logfile}":
                ensure  => 'present',
                replace => 'no',
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0644",
                content => "",
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden_client_elastichoney.cfg":
		content => template("${module_name}/warden_client_elastichoney.cfg.erb"),
		owner => "$elastichoney_user", group => "$elastichoney_user", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "/etc/cron.d/warden_elastichoney":
		content => template("${module_name}/warden_elastichoney.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$elastichoney_user"],
	}
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register elastichoney sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.elastichoney -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
