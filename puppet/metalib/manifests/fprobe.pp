#!/usr/bin/puppet apply

class fprobe (
	$rediser_auto = true,
	$rediser_service = "_rediser._tcp",
	$rediser_server = undef,
) {
	include metalib::avahi

	package { "fprobe":
		ensure => installed,
	}
	service { "fprobe":
		ensure => running,
	}

	if ( ($rediser_auto == true) ) {
		include metalib::avahi
		$rediser_server_real = avahi_findservice($rediser_service)
	} elsif ($rediser_server) {
		$rediser_server_real = $rediser_server
	}

	if ( $rediser_server_real ) {
		augeas { "/etc/default/fprobe" :
			context => "/files/etc/default/fprobe",
			changes => [
				"set FLOW_COLLECTOR \"'$rediser_server_real:5555'\""
			],
			require => Package["fprobe"],
			notify => Service["fprobe"],
		}
	} else {
		warning("WARN: fprobe config missing facts")
	}
}

