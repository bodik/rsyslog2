#!/usr/bin/puppet apply

class warden3::hostcert (
	$dest_dir = "/opt/hostcert",

        $warden_server = undef,
        $warden_server_auto = true,
        $warden_server_service = "_warden-server._tcp",
) {
	notice("INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include ${name}\"")

        if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }


	package { "curl": ensure => installed }

	file { "$dest_dir":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}

        exec { "gen cert":
                command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca.sh -s ${warden_server_real} -d ${dest_dir}",
                creates => "${dest_dir}/${fqdn}.crt",
		require => [File["$dest_dir"], Package["curl"]],
        }
}
