# == Class: warden3::2warden
#
# TODO
#
# === Parameters
#
# [*install_dir*]
#   directory to install
#
# [*receiver_warden_server*]
#   name or ip of warden server, overrides autodiscovery
#
# [*receiver_warden_server_auto*]
#   enables warden server autodiscovery
#
# [*receiver_warden_server_service*]
#   service name to be discovered
#
# [*receiver_warden_server_port*]
#   warden server port number
#
class warden3::2warden (
	$install_dir = "/opt/warden_2rediser",
	
	$receiver_warden_server = undef,
	$receiver_warden_server_auto = true,
	$receiver_warden_server_service = "_warden-server._tcp",
	$receiver_warden_server_port = 45443,

	$sender_warden_server = undef,
	$sender_warden_server_auto = true,
	$sender_warden_server_service = "_warden-server._tcp",
	$sender_warden_server_port = 45443,
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
		require => File["${install_dir}"],
	}

	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	define w3cclientcert($dest_dir, $warden_server) {
		warden3::hostcert { "$name":
	                dest_dir => $dest_dir,
        	        warden_server => $warden_server,
	        }
	}

	#receiving w3 client
	file { "${install_dir}/warden_2warden_receiver.cfg":
		content => template("${module_name}/warden_2warden_receiver.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	ensure_resource( 'warden3::2warden::w3cclientcert', "receiver cert", { 'dest_dir' => '/opt/hostcert', 'warden_server' => "$receiver_warden_server_real" } )
#	exec { "register warden_2warden receiver sensor":
#		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${receiver_warden_server_real} -n 2warden -d ${install_dir}",
#		creates => "${install_dir}/registered-at-warden-server",
#		require => [ File["${install_dir}" ],
#	}

	#sending w3 client
	file { "${install_dir}/warden_2warden_sender.cfg":
		content => template("${module_name}/warden_2warden_sender.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	ensure_resource( 'warden3::2warden::w3cclientcert', "sender cert", { 'dest_dir' => "${install_dir}/sendercert", 'warden_server' => "$sender_warden_server_real" } )
	exec { "register warden_2warden sender sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${receiver_warden_server_real} -n 2warden -d ${install_dir}/sendercert",
		creates => "${install_dir}/sendercert/registered-at-warden-server",
		require => [ W3cclientcert["sender cert"], File["${install_dir}"] ],
	}


#	file { "/etc/init.d/warden_2rediser":
#		source => "puppet:///modules/${module_name}/opt/warden_2rediser/warden_2rediser.init",
#		owner => "root", group => "root", mode => "0755",
#		require => [File["${install_dir}/warden_client.cfg", "${install_dir}/warden_2rediser.cfg", "${install_dir}/warden_client.py", "${install_dir}/warden_2rediser.py"], Exec["register warden_2rediser sensor"]],
#		notify => Exec["systemd_reload"],
#	}
#	exec { "systemd_reload":
#		command     => '/bin/systemctl daemon-reload',
#		refreshonly => true,
#	}
#	service { "warden_2rediser": 
#		enable => true,
#		ensure => running,
#		provider => init,
#		require => [File["/etc/init.d/warden_2rediser"], Exec["systemd_reload"]],
#	}


}
