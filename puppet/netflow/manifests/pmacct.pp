# == Class: netflow::pmacct
#
# Class will ensure installation of pmacctd pcap based netflow emitor. All data
# are emited towards configured netflow collector (netflow::nfdump, logstash, ...)
#
# === Parameters
#
# [*collector_server*]
#   collector hosname or ip address
#
# [*collector_port*]
#   netflow collector destination port
#
# [*collector_auto*]
#   flag if netflow collector should be autodiscovered,
#   collector_server parameter has precedence over autodiscovery
#
# [*collector_service*]
#   name of collector service to be discovered
#
# === Examples
#
#   class { "netflow::pmacct": collector_server => "collector.domain.cz", }
#
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
	service { "pmacctd":
		ensure => running,
		hasstatus => false,
		require => Package["pmacct"],
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
			notify => Service["pmacctd"],
		}
	} else {
		warning("WARN: pmacct config missing facts")
	}
}
