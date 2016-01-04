# == Resource: warden3::2warden
#
# TODO
#
# === Parameters
#
# [*install_dir*]
#   directory to install
#
# [*receiver/sender_warden_server*]
#   name or ip of warden server, overrides autodiscovery
#
# [*receiver/sender_warden_server_auto*]
#   enables warden server autodiscovery
#
# [*receiver/sender_warden_server_service*]
#   service name to be discovered
#
# [*receiver/sender_warden_server_port*]
#   warden server port number
#
# [*receiver_cert_path*]
#   warden client cert path
#
define warden3::2warden (
	$install_dir = "/opt/warden_2warden",
	
	$receiver_warden_server = undef,
	$receiver_warden_server_auto = true,
	$receiver_warden_server_service = "_warden-server._tcp",
	$receiver_warden_server_port = 45443,
	$receiver_cert_path = "/opt/hostcert",

	$sender_warden_server = undef,
	$sender_warden_server_auto = true,
	$sender_warden_server_service = "_warden-server._tcp",
	$sender_warden_server_port = 45443,
	$sender_cert_path = "/opt/warden_2warden/remotecert",
) {

	if ($receiver_warden_server) {
                $receiver_warden_server_real = $receiver_warden_server
        } elsif ( $receiver_warden_server_auto == true ) {
                include metalib::avahi
                $receiver_warden_server_real = avahi_findservice($receiver_warden_server_service)
        }
	if ($sender_warden_server) {
                $sender_warden_server_real = $sender_warden_server
        } elsif ( $sender_warden_server_auto == true ) {
                include metalib::avahi
                $sender_warden_server_real = avahi_findservice($sender_warden_server_service)
        }


	# warden_client, filer
	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/opt/warden_2warden/warden_client.py",
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_filer.py":
		source => "puppet:///modules/${module_name}/opt/warden_2warden/warden_filer.py",
		owner => "root", group => "root", mode => "0750",
		require => File["${install_dir}/warden_client.py"],
	}
	file { "${install_dir}/var":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}


	$w3c_name = "cz.cesnet.flab.${hostname}"

	#receiving w3 client
	file { "${install_dir}/warden_2warden_receiver.cfg":
		content => template("${module_name}/warden_2warden_receiver.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}/warden_filer.py"],
		before => Warden3::Hostcert["2warden ${name} receiver $fqdn"],
	}
	ensure_resource( 'warden3::hostcert', "2warden ${name} receiver $fqdn", { "dest_dir" => "${receiver_cert_path}", "warden_server" => "$receiver_warden_server_real"} )	
	exec { "2warden ${name} register receiver sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${receiver_warden_server_real} -n ${w3c_name}.2warden -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => [ File["${install_dir}/warden_2warden_receiver.cfg"], Warden3::Hostcert["2warden ${name} receiver $fqdn"] ],
	}

	#sending w3 client
	file { "${install_dir}/warden_2warden_sender.cfg":
		content => template("${module_name}/warden_2warden_sender.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}/warden_filer.py"],
		before => Warden3::Hostcert["2warden ${name} sender $fqdn"],
	}
	ensure_resource( 'warden3::hostcert', "2warden ${name} sender $fqdn", { "dest_dir" => "${sender_cert_path}", "warden_server" => "$sender_warden_server_real"} )
	exec { "2warden ${name} register sender sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${sender_warden_server_real} -n ${w3c_name}.2warden -d ${sender_cert_path}",
		creates => "${sender_cert_path}/registered-at-warden-server",
		require => [ File["${install_dir}/warden_2warden_sender.cfg"], Warden3::Hostcert["2warden ${name} sender $fqdn"] ],
	}


	file { "/etc/init.d/warden_2warden_${name}":
		content => template("${module_name}/warden_2warden.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [ Exec["2warden ${name} register receiver sensor"], Exec["2warden ${name} register sender sensor"]],
		notify => Exec["systemd_reload"],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "warden_2warden_${name}": 
		enable => true,
		ensure => running,
		provider => init,
		require => [File["/etc/init.d/warden_2warden_${name}"], Exec["systemd_reload"]],
	}


}
