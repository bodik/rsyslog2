#!/usr/bin/puppet apply

class glastopf::lsl (
	$lsl_workers = undef,
	$rediser_server = undef,
	$rediser_auto = true,
	$rediser_service = "_rediser._tcp",
) {
	package { ["libgeoip1", "geoip-database"]:
		ensure => installed,
	}

	class { 'logstash':
		manage_repo  => true,
		repo_version => '1.4',
		install_contrib => true,
	}


	if ( $lsl_workers == undef ) {
		if $processorcount < 6 {
			$lsl_workers_real = 2
		} else {
			$lsl_workers_real = 4
		}
	} else {
		$lsl_workers_real = $lsl_workers
	}
	augeas { "/etc/default/logstash" :
		context => "/files/etc/default/logstash",
		changes => [
			"set LS_OPTS \"'-w $lsl_workers_real'\"",
			"set LS_USER \"'root'\""
		],
		require => Package["logstash"],
		notify => Service["logstash"],
	}

	user { "logstash":
		groups => "glastopf",
	}

	logstash::configfile { 'glastopf':
		content => template("${module_name}/glastopf-logstash.conf"),
	#	order => 10,
	}

}

