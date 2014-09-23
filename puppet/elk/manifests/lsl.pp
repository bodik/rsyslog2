# == Class: elk::lsl
#
# Class will ensure installation of logstash using puppet-logstash modules 
# and creates single instance:
# - with additional custom patterns
# - input redis for fetching data from specific server or discovered rediser service (queues syslog, nz)
# - input netflow data using udp codec netflow
# - filtering/grokking data
# - output data to elasticsearch using node discovery
#
# === Parameters
#
# [*lsl_workers*]
#   logstash number of workers (default 2 or 4)
#
# [*rediser_server*]
#   hostname or ip to fetch data for all queues, has precedence over rediser_auto
#   (default undef)
#
# [*rediser_auto*]
#   perform rediser autodiscovery by avahi (defult true)
#
# [*rediser_service*]
#   name of rediser service to discover (default "_rediser._tcp")
# === Examples
#
#   class { "elk::lsl": 
#     lsl_workers => "1",
#     rediser_server => "1.2.3.4",
#   }
#
class elk::lsl (
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
	file { '/etc/logstash/patterns/metacentrum':
		source => "puppet:///modules/${module_name}/etc/logstash/patterns/metacentrum",
		owner => "root", group => "root", mode => "0644",
		require => File["/etc/logstash/patterns"],
		notify => Service["logstash"],
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
			"set LS_OPTS \"'-w $lsl_workers_real'\""
		],
		require => Package["logstash"],
		notify => Service["logstash"],
	}

	logstash::configfile { 'simple':
		content => template("${module_name}/etc/logstash/conf.d/simple.conf"),
	#	order => 10,
	}

	if ($rediser_server) {
		$rediser_server_real = $rediser_server
	} elsif ( $rediser_auto == true ) {
		include metalib::avahi
		$rediser_server_real = avahi_findservice($rediser_service)
	}

	if ( $rediser_server_real ) {
		logstash::configfile { 'input-rediser-syslog':
	        	content => template("${module_name}/etc/logstash/conf.d/input-rediser-syslog.conf.erb"),
			order => 10,
			notify => Service["logstash"],
		}
		logstash::configfile { 'input-rediser-nz':
	        	content => template("${module_name}/etc/logstash/conf.d/input-rediser-nz.conf.erb"),
			order => 10,
			notify => Service["logstash"],
		}
		notify { "input rediser active":
			require => [Logstash::Configfile['input-rediser-syslog'], Logstash::Configfile['input-rediser-nz']],
		}
	} else {
		logstash::configfile { 'input-rediser-syslog':
	        	content => "#input-rediser-syslog passive\n",
			order => 10,
			notify => Service["logstash"],
		}
		logstash::configfile { 'input-rediser-nz':
	        	content => "#input-rediser-nz passive\n",
			order => 10,
			notify => Service["logstash"],
		}
		notify { "input rediser passive": }
	}

	logstash::configfile { 'netflow':
		content => template("${module_name}/etc/logstash/conf.d/input-netflow.conf"),
		order => 10,
	}





	logstash::configfile { 'filter-syslog':
		content => template("${module_name}/etc/logstash/conf.d/filter-syslog.conf"),
		order => 30,
		notify => Service["logstash"],
	}
	logstash::configfile { 'filter-nz':
		content => template("${module_name}/etc/logstash/conf.d/filter-nz.conf"),
		order => 30,
		notify => Service["logstash"],
	}

	logstash::configfile { 'filter-nf':
		content => template("${module_name}/etc/logstash/conf.d/filter-nf.conf"),
		order => 40,
		notify => Service["logstash"],
	}
	logstash::configfile { 'filter-nf-tcpflags':
		content => template("${module_name}/etc/logstash/conf.d/filter-nf-tcpflags.conf"),
		order => 41,
		notify => Service["logstash"],
	}
	logstash::configfile { 'filter-nf-proto':
		content => template("${module_name}/etc/logstash/conf.d/filter-nf-proto.conf"),
		order => 41,
		notify => Service["logstash"],
	}



	logstash::configfile { 'output-es':
		content => template("${module_name}/etc/logstash/conf.d/output-es-node.conf"),
		#content => template("${module_name}/etc/logstash/conf.d/output-esh-local.conf"),
		order => 50,
		notify => Service["logstash"],
	}

}

