# == Class: warden3::tester
#
# Class will ensure installation of example warden3 testing client. Tester will generate ammount of idea messages and sends them to w3 server.
# Used for testing.
#
# TODO: warden server port selection missing
#
# === Parameters
#
# [*install_dir*]
#   directory to install w3 server
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
class warden3::tester (
	$install_dir = "/opt/warden_tester",
	
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

	# warden_client pro tester
	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/opt/warden_tester/warden_client/warden_client.py",
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_client_tester.cfg":
		content => template("${module_name}/warden_client_tester.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register warden_tester sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n tester -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

	file { "${install_dir}/tester.py":
		source => "puppet:///modules/${module_name}/opt/warden_tester/tester.py",
		owner => "root", group => "root", mode => "0750",
		require => File["${install_dir}"],
	}

}
