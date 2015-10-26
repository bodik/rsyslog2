# == Class: elk::lsl
#
# Class will ensure installation of logstash using puppet-logstash modules 
# and creates single instance:
# - with additional custom patterns
# - input redis for fetching data from specific server or discovered rediser service (queues syslog, nz)
# - input netflow data using udp codec netflow
# - filtering/grokking data
# - output data to elasticsearch using node discovery (special multicast group s fixed because of magrathea)
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
#
# [*output_es_cluster_name*]
#   output elasticsearch plugin cluster name config
#
# [*process_stream_auth*]
#   boolean expresion if node has to process auth log
#   currently is auth stream processed by mongomine, thus defauls to false
#
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
	$output_es_cluster_name = "mry",
	$process_stream_auth = false,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	package { ["libgeoip1", "geoip-database"]:
		ensure => installed,
	}

	class { 'logstash':
		manage_repo  => true,
		repo_version => '1.4',
		version => '1.4.2-*',
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
			"set LS_OPTS \"'-w $lsl_workers_real'\"",
			"set LS_JAVA_OPTS \"'-Des.discovery.zen.ping.multicast.group=224.0.0.251'\""
		],
		require => Package["logstash"],
		notify => Service["logstash"],
	}




	logstash::configfile { 'simple':
		content => template("${module_name}/etc/logstash/conf.d/simple.conf"),
	#	order => 10,
	}



	if ($rediser_server) {
		$mongomine = $rediser_server
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
		notice("input-rediser-syslog active")
	} else {
		notice("input-rediser-syslog passive")
	}
	if ( $rediser_server_real ) {
		logstash::configfile { 'input-rediser-nz':
	        	content => template("${module_name}/etc/logstash/conf.d/input-rediser-nz.conf.erb"),
			order => 10,
			notify => Service["logstash"],
		}
		notice("input-rediser-nz active")
	} else {
		notice("input-rediser-nz passive")
	}
	if ( $rediser_server_real and $process_stream_auth ) {
		logstash::configfile { 'input-rediser-auth':
	        	content => template("${module_name}/etc/logstash/conf.d/input-rediser-auth.conf.erb"),
			order => 10,
			notify => Service["logstash"],
		}
		notice("input-rediser-auth active")
	} else {
		notice("input-rediser-auth passive")
	}
	if ( $rediser_server_real ) {
                logstash::configfile { 'input-rediser-wb':
                        content => template("${module_name}/etc/logstash/conf.d/input-rediser-wb.conf.erb"),
                        order => 10,
                        notify => Service["logstash"],
                }
                notice("input-rediser-wb active")
        } else {
                notice("input-rediser-wb passive")
        }







	logstash::configfile { 'filter-syslog':
		content => template("${module_name}/etc/logstash/conf.d/filter-syslog.conf"),
		order => 30,
		notify => Service["logstash"],
	}
	logstash::configfile { 'filter-auth':
		content => template("${module_name}/etc/logstash/conf.d/filter-auth.conf"),
		order => 30,
		notify => Service["logstash"],
	}
	logstash::configfile { 'filter-nz':
		content => template("${module_name}/etc/logstash/conf.d/filter-nz.conf"),
		order => 30,
		notify => Service["logstash"],
	}
	logstash::configfile { 'filter-wb':
                content => template("${module_name}/etc/logstash/conf.d/filter-wb.conf"),
                order => 30,
                notify => Service["logstash"],
        }




	logstash::configfile { 'output-es':
		content => template("${module_name}/etc/logstash/conf.d/output-es-node.conf.erb"),
		#content => template("${module_name}/etc/logstash/conf.d/output-esh-local.conf.erb"),
		order => 50,
		notify => Service["logstash"],
	}

}

