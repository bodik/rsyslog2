#!/usr/bin/puppet apply

class warden3::2rediser (
	$install_dir = "/opt/warden_2rediser",
	
	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",

	$rediser_server = undef,
	$rediser_server_auto = true,
	$rediser_server_service = "_rediser._tcp",
	$rediser_server_warden_port = 34564,
) {
	file { "${install_dir}":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}


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
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_2rediser.cfg":
		content => template("${module_name}/warden_2rediser.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}

	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/opt/warden_2rediser/warden_client/warden_client.py",
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	file { "${install_dir}/warden_2rediser.py":
		source => "puppet:///modules/${module_name}/opt/warden_2rediser/warden_2rediser.py",
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}

	exec { "register warden_2rediser sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh ${warden_server_real} warden_2rediser ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
