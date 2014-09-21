class netflow::pmacct (
	$collector_server = undef,
	$collector_port = 5555,
	$collector_auto = true,
	$collector_service = "_rediser._tcp",
) {
	include metalib::avahi
	
	package { "pmacct":
		ensure => installed,
	}
	service { "pmacct":
		ensure => running,
		hasstatus => false,
	}


	if ($collector_server) {
		$collector_server_real = $collector_server
	} elsif ( $collector_auto == true ) {
		include metalib::avahi
		$collector_server_real = avahi_findservice($collector_service)
	}

	if ( $collector_server_real ) {
		file { "/etc/pmacct/pmacctd.conf":
			content => template("${module_name}/pmacctd.conf.erb"),
			require => Package["pmacct"],
			notify => Service["pmacct"],
		}
	} else {
		warning("WARN: pmacct config missing facts")
	}
}
