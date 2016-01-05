#!/usr/bin/puppet apply

class hpucho::web (
	$install_dir = "/opt/uchoweb",

	$uchoweb_user = "uchoweb",
	
	$port = 8080,
	$personality = "Apache Tomcat/7.0.56 (Debian)",
	$content = "content-tomcat.tgz",

	$logfile = "uchoweb.log",
	
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

	package { ["python", "python-jinja2"]: 
		ensure => installed, 
	}
	user { "$uchoweb_user":
                ensure => present,
                managehome => false,
        }
	file { ["${install_dir}"]:
		ensure => directory,
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
	}
        file { "${install_dir}/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
		require => File["${install_dir}"],
        }
	file { "${install_dir}/uchoweb.py":
		source => "puppet:///modules/${module_name}/uchoweb/uchoweb.py",
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
		require => [File["${install_dir}"], File["${install_dir}/warden_utils_flab.py"], Package["python-jinja2"]],
		notify => Service["uchoweb"],
	}
	file { "${install_dir}/uchoweb.cfg":
                content => template("${module_name}/uchoweb.cfg.erb"),
                owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
                require => File["${install_dir}/uchoweb.py"],
        }
	file { "${install_dir}/content.tgz":
		source => "puppet:///modules/${module_name}/uchoweb/${content}",
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0644",
		require => File["${install_dir}"],
	}
	exec { "content":
		command => "/bin/tar xzf content.tgz; chown -R $uchoweb_user:$uchoweb_user content",
		cwd => "${install_dir}",
		creates => "${install_dir}/content",
		require => File["${install_dir}/content.tgz"],
	}
	package { "libcap2-bin": ensure => installed }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
		unless => "/sbin/getcap /usr/bin/python2.7 | /bin/grep cap_net_bind_service",
		require => Package["python"],
	}

	file { "/etc/init.d/uchoweb":
		content => template("${module_name}/uchoweb.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/uchoweb.py", "${install_dir}/uchoweb.cfg"], Exec["content"], Exec["python cap_net"]],
		notify => [Service["uchoweb"], Exec["systemd_reload"]]
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "uchoweb": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/uchoweb"], Exec["systemd_reload"]]
	}


	#autotest
	package { ["netcat"]: ensure => installed, }




	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0640",
		require => File["${install_dir}"],
	}

        # reporting

        file { "${install_dir}/warden_sender_uchoweb.py":
                source => "puppet:///modules/${module_name}/sender/warden_sender_uchoweb.py",
                owner => "${uchoweb_user}", group => "${uchoweb_user}", mode => "0755",
                require => File["${install_dir}/warden_utils_flab.py"],
        }
 	file { "${install_dir}/${logfile}":
                ensure  => 'present',
                replace => 'no',
                owner => "${uchoweb_user}", group => "${uchoweb_user}", mode => "0644",
                content => "",
        }
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
        file { "${install_dir}/warden_client_uchoweb.cfg":
                content => template("${module_name}/warden_client_uchoweb.cfg.erb"),
                owner => "$uchoweb_user", group => "$uchoweb_user", mode => "0755",
                require => File["${install_dir}/uchoweb.py","${install_dir}/warden_utils_flab.py","${install_dir}/warden_sender_uchoweb.py"],
        }
        file { "/etc/cron.d/warden_uchoweb":
                content => template("${module_name}/warden_uchoweb.cron.erb"),
                owner => "root", group => "root", mode => "0644",
                require => User["$uchoweb_user"],
        }
	
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register uchoweb sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.uchoweb -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}
}
