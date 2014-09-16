#!/usr/bin/puppet apply

class metalib::fprobe (
	$rediser_server = undef,
	$rediser_auto = true,
	$rediser_service = "_rediser._tcp",
) {
	include metalib::avahi

	package { "fprobe":
		ensure => installed,
	}
	service { "fprobe":
		ensure => running,
		hasstatus => false,
		hasrestart => false,
		stop => "/etc/init.d/fprobe stop; sleep 5",
	}

	if ($rediser_server) {
		$rediser_server_real = $rediser_server
	elsif ( $rediser_auto == true ) {
		include metalib::avahi
		$rediser_server_real = avahi_findservice($rediser_service)
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

