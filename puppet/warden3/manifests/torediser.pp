# == Class: warden3::torediser
#
# Class will ensure installation of warden3 client which receives new events from server and sends them to rediser for ELK processing
#
# === Parameters
#
# [*install_dir*]
#   directory to install w3 server
#
# [*torediser_user*]
#   user to run the service
#
# [*warden_server*]
#   name or ip of warden server, overrides autodiscovery
#
# [*warden_server_auto*]
#   enables warden server autodiscovery
#
# [*warden_server_service*]
#   service name to be discovered
#
# [*warden_server_port*]
#   warden server port number
#
# [*rediser_server*]
#   name or ip of rediser
#
# [*rediser_server_auto*]
#   enables rediser autodiscovery
#
# [*rediser_server_service*]
#   service name to be discovered
#
# [*rediser_server_warden_port*]
#   rediser port for warden stream input
#
class warden3::torediser (
	$install_dir = "/opt/warden_torediser",

	$torediser_user = "torediser",
	
	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",

	$rediser_server = undef,
	$rediser_server_auto = true,
	$rediser_server_service = "_rediser._tcp",
	$rediser_server_warden_port = 49556,
) {

	if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }
	if ($rediser_server) {
                $rediser_server_real = $rediser_server
        } elsif ( $rediser_server_auto == true ) {
                include metalib::avahi
                $rediser_server_real = avahi_findservice($rediser_server_service)
        }


	# application
	user { "$torediser_user": 	
		ensure => present, 
		managehome => false,
		shell => "/bin/bash",
		home => "${install_dir}",
	}

	file { "${install_dir}":
		ensure => directory,
		owner => "${torediser_user}", group => "${torediser_user}", mode => "0755",
		require => User["${torediser_user}"],
	}
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/opt/warden_torediser/warden_client.py",
		owner => "${torediser_user}", group => "${torediser_user}", mode => "0640",
		require => File["${install_dir}"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${torediser_user}", group => "${torediser_user}", mode => "0640",
		require => File["${install_dir}"],
	}
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register warden_torediser sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.torediser -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

	file { "${install_dir}/warden_torediser.py":
		source => "puppet:///modules/${module_name}/opt/warden_torediser/warden_torediser.py",
		owner => "${torediser_user}", group => "${torediser_user}", mode => "0750",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_torediser.cfg":
		content => template("${module_name}/warden_torediser.cfg.erb"),
		owner => "${torediser_user}", group => "${torediser_user}", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "/etc/init.d/warden_torediser":
		content => template("${module_name}/warden_torediser.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/warden_client.cfg", "${install_dir}/warden_torediser.cfg", "${install_dir}/warden_client.py", "${install_dir}/warden_torediser.py"], Exec["register warden_torediser sensor"]],
		notify => [Service["warden_torediser"], Exec["systemd_reload"]],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "warden_torediser": 
		enable => true,
		ensure => running,
		require => [File["/etc/init.d/warden_torediser"], Exec["systemd_reload"]],
	}

}
