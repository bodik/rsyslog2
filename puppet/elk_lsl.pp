#!/usr/bin/puppet apply

package { ["libgeoip1", "geoip-database"]:
	ensure => installed,
}

class { 'logstash':
	manage_repo  => true,
	repo_version => '1.4',
}
logstash::configfile { 'simple':
	content => template("/puppet/templates/etc/logstash/conf.d/simple.conf"),
#	order => 10,
}
file { '/etc/logstash/patterns/metacentrum':
	source => '/puppet/templates/etc/logstash/patterns/metacentrum',
	owner => "root", group => "root", mode => "0644",
	require => File["/etc/logstash/patterns"],
	notify => Service["logstash"],
}


if ( $rediser_server ) {
	logstash::configfile { 'input-rediser-syslog':
        	content => template("/puppet/templates/etc/logstash/conf.d/input-rediser-syslog.conf.erb"),
		order => 10,
		notify => Service["logstash"],
	}
	notify { "input rediser active":
		require => Logstash::Configfile['input-rediser-syslog'],
	}
} else {
	logstash::configfile { 'input-rediser-syslog':
        	content => "#input-rediser-syslog passive\n",
		order => 10,
		notify => Service["logstash"],
	}
	notify { "input rediser passive": }
}

logstash::configfile { 'filter-syslog':
	content => template("/puppet/templates/etc/logstash/conf.d/filter-syslog.conf"),
	order => 30,
	notify => Service["logstash"],
}

logstash::configfile { 'output-esh-local':
	content => template("/puppet/templates/etc/logstash/conf.d/output-esh-local.conf"),
	order => 50,
	notify => Service["logstash"],
}



