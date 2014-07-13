#!/usr/bin/puppet apply

import '/puppet/avahi.pp'

package { "fprobe":
	ensure => installed,
}
service { "fprobe":
	ensure => running,
}

if ( $rediser_server ) {
	augeas { "/etc/default/fprobe" :
		context => "/files/etc/default/fprobe",
		changes => [
			"set FLOW_COLLECTOR \"'$rediser_server:5555'\""
		],
		require => Package["fprobe"],
		notify => Service["fprobe"],
	}
} else {
	warning("WARN: fprobe config missing facts")
}

