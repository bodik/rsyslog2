# == Class: mongomine::lsl
#
# Class will ensure installation of logstash using puppet-logstash modules 
# and creates single instance:
# TODO to write
#
# caveat: some files taken from elk class, we dont want to duplicate things as mongomine will be replaced soon
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
# === Examples
#
#   class { "mongomine::lsl": 
#     lsl_workers => "1",
#     rediser_server => "1.2.3.4",
#   }
#
class mongomine::lsl (
	$lsl_workers = undef,
	$rediser_server = undef,
	$rediser_auto = true,
	$rediser_service = "_rediser._tcp",
	$output_es_cluster_name = "mry",
) {
	notice($name)
	package { ["libgeoip1", "geoip-database"]:
		ensure => installed,
	}

	class { 'logstash':
		manage_repo  => true,
		repo_version => '1.4',
		install_contrib => true,
	}
	file { '/etc/logstash/patterns/metacentrum':
		source => "puppet:///modules/elk/etc/logstash/patterns/metacentrum",
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



	if ($rediser_server) {
		$rediser_server_real = $rediser_server
	} elsif ( $rediser_auto == true ) {
		include metalib::avahi
		$rediser_server_real = avahi_findservice($rediser_service)
	}
	if ( $rediser_server_real ) {
		logstash::configfile { 'input-rediser-auth':
	        	content => template("elk/etc/logstash/conf.d/input-rediser-auth.conf.erb"),
			order => 10,
			notify => Service["logstash"],
		}
		notify { "input rediser active":
			require => [Logstash::Configfile['input-rediser-auth']],
		}
	} else {
		logstash::configfile { 'input-rediser-auth':
	        	content => "#input-rediser-auth passive\n",
			order => 10,
			notify => Service["logstash"],
		}
		notify { "input rediser passive": }
	}






	logstash::configfile { 'filter-auth':
		content => template("elk/etc/logstash/conf.d/filter-auth.conf"),
		order => 30,
		notify => Service["logstash"],
	}





	logstash::configfile { 'output-es':
		content => template("elk/etc/logstash/conf.d/output-es-node.conf.erb"),
		#content => template("${module_name}/etc/logstash/conf.d/output-esh-local.conf.erb"),
		order => 50,
		notify => Service["logstash"],
	}
	logstash::configfile { 'output-mongomine':
		content => template("${module_name}/etc/logstash/conf.d/output-mongomine.conf"),
		order => 51,
		notify => Service["logstash"],
	}

}

