#!/usr/bin/puppet apply

package { ["libgeoip1", "geoip-database"]:
	ensure => installed,
}

class { 'logstash':
	manage_repo  => true,
	repo_version => '1.4',
}
file { '/etc/logstash/patterns/metacentrum':
	source => '/puppet/templates/etc/logstash/patterns/metacentrum',
	owner => "root", group => "root", mode => "0644",
	require => File["/etc/logstash/patterns"],
	notify => Service["logstash"],
}

if $processorcount < 6 {
	$lsl_workers = 2
} else {
	$lsl_workers = 4
}
augeas { "/etc/default/logstash" :
	context => "/files/etc/default/logstash",
	changes => [
		"set LS_OPTS \"'-w $lsl_workers'\""
	],
	require => Package["logstash"],
	notify => Service["logstash"],
}



logstash::configfile { 'simple':
	content => template("/puppet/templates/etc/logstash/conf.d/simple.conf"),
#	order => 10,
}


if ( $rediser_server ) {
	logstash::configfile { 'input-rediser-syslog':
        	content => template("/puppet/templates/etc/logstash/conf.d/input-rediser-syslog.conf.erb"),
		order => 10,
		notify => Service["logstash"],
	}
	logstash::configfile { 'input-rediser-nz':
        	content => template("/puppet/templates/etc/logstash/conf.d/input-rediser-nz.conf.erb"),
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
	content => template("/puppet/templates/etc/logstash/conf.d/input-netflow.conf"),
	order => 10,
}





logstash::configfile { 'filter-syslog':
	content => template("/puppet/templates/etc/logstash/conf.d/filter-syslog.conf"),
	order => 30,
	notify => Service["logstash"],
}
logstash::configfile { 'filter-nz':
	content => template("/puppet/templates/etc/logstash/conf.d/filter-nz.conf"),
	order => 30,
	notify => Service["logstash"],
}







logstash::configfile { 'output-es':
	content => template("/puppet/templates/etc/logstash/conf.d/output-es-node.conf"),
	#content => template("/puppet/templates/etc/logstash/conf.d/output-esh-local.conf"),
	order => 50,
	notify => Service["logstash"],
}



