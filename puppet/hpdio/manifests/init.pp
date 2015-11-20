#!/usr/bin/puppet apply

class hpdio (
	$install_dir = "/opt/dionaea",

	$dio_user = "dio",
	
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
	user { "$dio_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/bash",
		home => "${install_dir}",
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "$dio_user", group => "$dio_user", mode => "0755",
		require => User["$dio_user"],
	}

	exec { "wget dio automat":
		command => "/usr/bin/wget http://esb.metacentrum.cz/hpdio/dio-standalone.tar.gz -O ${install_dir}/dio-standalone.tar.gz",
		creates => "${install_dir}/dio-standalone.tar.gz",
		require => File["${install_dir}"],
	}
	exec { "untar dio automat":
		command => "/bin/tar xzf ${install_dir}/dio-standalone.tar.gz -C ${install_dir}",
		creates => "${install_dir}/dio-standalone/install.sh",
		require => Exec["wget dio automat"],
	}
	exec { "do install":
		command => "/bin/bash ${install_dir}/dio-standalone/install.sh",
		cwd => "${install_dir}/dio-standalone",
		timeout => 1800,
		creates => "/opt/dionaea/bin/dionaea",
		require => Exec["untar dio automat"],
	}



	package { "p0f":
		ensure => installed,
	}
	file { "/etc/init.d/p0f":
		content => template("${module_name}/p0f.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => Package["p0f"],
		notify => [Service["p0f"], Exec["systemd_reload"]]
	}
	service { "p0f": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/p0f"], Package["p0f"], Exec["systemd_reload"]],
	}



	file { "${install_dir}/var":
		owner => "$dio_user", group => "$dio_user", #nomode
		recurse => true,
		require => Exec["do install"],
	}
	file { "/etc/init.d/dio":
		content => template("${module_name}/dio.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/var"], File["/etc/init.d/p0f"]],
		notify => [Service["dio"], Exec["systemd_reload"]]
	}
	file { "${install_dir}/etc/dionaea/dionaea.conf":
		content => template("${module_name}/dionaea.conf.erb"),
		owner => "root", group => "root", mode => "0755",
		require => File["/etc/init.d/dio"],
		notify => Service["dio"],
	}
	exec { "install selfcert":
		command => "/bin/sh /puppet/metalib/bin/install_sslselfcert.sh ${install_dir}/etc/dionaea",
		creates => "${install_dir}/etc/dionaea/${fqdn}.crt",
		require => File["${install_dir}/etc/dionaea/dionaea.conf"],
	}
	file { "${install_dir}/etc/dionaea/server.key":
		ensure => link,
		target => "${install_dir}/etc/dionaea/${fqdn}.key",
		require => Exec["install selfcert"],
	}
	file { "${install_dir}/etc/dionaea/server.crt":
		ensure => link,
		target => "${install_dir}/etc/dionaea/${fqdn}.crt",
		require => Exec["install selfcert"],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "dio": 
		enable => true,
		ensure => running,
		provider => init,
		require => [File["/etc/init.d/dio", "${install_dir}/etc/dionaea/dionaea.conf", "${install_dir}/etc/dionaea/server.key", "${install_dir}/etc/dionaea/server.crt"], Exec["systemd_reload"]],
	}



	#autotest
	package { ["netcat"]: ensure => installed, }


	# warden_client pro kippo (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${dio_user}", group => "${dio_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "${dio_user}", group => "${dio_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${dio_user}", group => "${dio_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}


	#reporting
	file { "${install_dir}/warden/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${dio_user}", group => "${dio_user}", mode => "0755",
        }
	file { "${install_dir}/warden/warden_sender_dio.py":
		source => "puppet:///modules/${module_name}/sender/warden_sender_dio.py",
		owner => "${dio_user}", group => "${dio_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$anonymised = "yes"
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden/warden_client_dio.cfg":
		content => template("${module_name}/warden_client_dio.cfg.erb"),
		owner => "${dio_user}", group => "${dio_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	file { "/etc/cron.d/warden_dio":
		content => template("${module_name}/warden_dio.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$dio_user"],
	}

	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register dio sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n dionaea -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => Exec["do install"],
	}
}
