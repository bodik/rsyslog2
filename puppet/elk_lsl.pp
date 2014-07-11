#!/usr/bin/puppet apply

class { 'logstash':
	manage_repo  => true,
	repo_version => '1.4',
}
logstash::configfile { 'simple':
	content => template("/puppet/templates/etc/logstash/conf.d/simple.conf"),
#	order => 10,
}

if ( $rediser_server ) {
       logstash::configfile { 'input-rediser-syslog':
               content => template("/puppet/templates/etc/logstash/conf.d/input-rediser-syslog.conf.erb"),
               order => 10,
       }
       notify { "input rediser active":
               require => Logstash::Configfile['input-rediser-syslog'],
       }
} else {
       notify { "input rediser passive": }
}


logstash::configfile { 'output-esh-local':
       content => template("/puppet/templates/etc/logstash/conf.d/output-esh-local.conf"),
       order => 50,
}



