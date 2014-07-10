#!/usr/bin/puppet apply

class { 'logstash':
	manage_repo  => true,
	repo_version => '1.4',
}
logstash::configfile { 'simple':
	content => template("/puppet/templates/etc/logstash/conf.d/simple.conf"),
#	order => 10,
}


