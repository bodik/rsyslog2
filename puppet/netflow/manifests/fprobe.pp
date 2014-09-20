#!/usr/bin/puppet apply

class netflow::fprobe (
	$collector_server = undef,
	$collector_port = 5555,
	$collector_auto = true,
	$collector_service = "_rediser._tcp",
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

	if ($collector_server) {
		$collector_server_real = $collector_server
	} elsif ( $collector_auto == true ) {
		include metalib::avahi
		$collector_server_real = avahi_findservice($collector_service)
	}

	if ( $collector_server_real ) {
		augeas { "/etc/default/fprobe" :
			context => "/files/etc/default/fprobe",
			changes => [
				"set FLOW_COLLECTOR \"'$collector_server_real:$collector_port'\""
			],
			require => Package["fprobe"],
			notify => Service["fprobe"],
		}
	} else {
		warning("WARN: fprobe config missing facts")
	}
}

